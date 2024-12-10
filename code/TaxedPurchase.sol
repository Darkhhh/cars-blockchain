// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract TaxedPurchase {
    uint public price;
    uint public taxAmount;
    uint public escrow;

    address payable public seller;
    address payable public buyer;
    address payable public taxReceiver;
    bool public isExternal;

    enum State { Created, Locked, WaitForConfirmation, Released, Inactive }
    State public state;

    /// Only buyer can call this function.
    error OnlyBuyer();
    /// Only seller can call this function.
    error OnlySeller();
    /// The function cannot be called at the current state.
    error InvalidState();
    /// The payment supplied was not correct.
    error IncorrectPayment(uint expected);
    /// The buyer and seller cannot be the same person.
    error CannotSellToYourself();

    modifier onlyBuyer() {
        if (msg.sender != buyer)
            revert OnlyBuyer();
        _;
    }

    modifier onlySeller() {
        if (msg.sender != seller)
            revert OnlySeller();
        _;
    }

    modifier inState(State expected) {
        if (state != expected)
            revert InvalidState();
        _;
    }

    event Aborted();
    event AgreedToPurchase();
    event PaymentConfirmed();
    event ItemReceived();
    event SellerRefunded();

    /// Create the payment. Value of the transaction is the escrow value.
    constructor(bool isExternal_,
                address payable seller_, 
                address payable buyer_,
                uint price_,
                uint taxAmount_,
                address payable taxReceiver_) payable {
        if (buyer_ == seller_)
            revert CannotSellToYourself();
        isExternal = isExternal_;
        seller = seller_;
        buyer = buyer_;

        price = price_;
        escrow = msg.value;
        if (!isExternal) {
            taxAmount = taxAmount_;
            taxReceiver = taxReceiver_;
        }
    }

    /// Abort the purchase and reclaim the ether.
    /// Can only be called by the seller before
    /// the contract is locked.
    function abort()
        external
        onlySeller
        inState(State.Created)
    {
        emit Aborted();
        state = State.Inactive;

        seller.transfer(address(this).balance);
    }

    function amountToPay()
        public
        view
        returns (uint)
    {
        if (isExternal)
            return escrow;
        else
            return price+taxAmount+escrow;
    }

    /// Confirm the purchase as buyer.
    /// Transaction has to include `price + taxAmount + escrow` ether.
    /// The ether will be locked until confirmReceived
    /// is called.
    function agreeToPurchase()
        external
        onlyBuyer
        inState(State.Created)
        payable 
    {
        if (msg.value != amountToPay())
            revert IncorrectPayment(amountToPay());

        emit AgreedToPurchase();
        if (isExternal)
            state = State.WaitForConfirmation;
        else
            state = State.Locked;
    }

    /// Confirm the payment was received (as seller).
    /// Only relevant for external purchases
    function confirmPayment()
        external
        onlySeller
        inState(State.WaitForConfirmation)
    {
        require(isExternal);

        emit PaymentConfirmed();
        state = State.Locked;
    }

    /// Confirm that you (the buyer) received the item.
    /// This will release the locked ether.
    function confirmReceived()
        external
        onlyBuyer
        inState(State.Locked)
    {
        emit ItemReceived();
        state = State.Released;

        buyer.transfer(escrow);
        if (taxAmount > 0)
            taxReceiver.transfer(taxAmount);
    }

    /// This function refunds the seller, i.e.
    /// pays back the locked funds of the seller.
    function refundSeller()
        external
        onlySeller
        inState(State.Released)
    {
        emit SellerRefunded();
        state = State.Inactive;

        if (isExternal)
            seller.transfer(escrow);
        else
            seller.transfer(price + escrow);
    }

    function isDone() external view returns(bool)
    {
        return state == State.Released || state == State.Inactive;
    }
}