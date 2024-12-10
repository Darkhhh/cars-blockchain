// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "./TaxedPurchase.sol";
import "./TaxInfo.sol";

contract CarRegistry {
    address payable public registry;

    enum Role { CarOwner, ServiceCenter, Manufacturer }
    mapping(address => Role) public roles;

    struct CarInfo {
        bytes32 registryCode;
        bytes32 specHash;
        
        uint mileage;

        address currentOwner;
        address currentSC;
        address previousOwner;
        uint previousPrice;
    }

    uint public nextCarId;
    mapping(uint carId => CarInfo info) public carInfo;
    mapping(address owner => uint[] carIds) public carsByOwner;
    mapping(uint carId => address) public purchasesPending;
    mapping(address owner => TaxInfo.TaxType) public taxType;

    event CarOperationLog(uint indexed carId, uint date, address indexed by, string operation);
    event CarSpecsUpdated(uint indexed carId, address indexed by, bytes32 newSpecs);
    event CarRegistryCodeUpdated(uint indexed carId, address indexed by, bytes32 indexed newRegistryCode);
    event CarCreated(uint indexed carId, address indexed by);
    event CarLentToServiceCenter(uint indexed carId, address indexed by, address indexed to);
    event CarTakenFromServiceCenter(uint indexed carId, address indexed by, address indexed from);
    event CarPurchaseStarted(uint indexed carId, address indexed by, uint price);
    event CarPurchaseCompleted(uint indexed carId, address indexed buyer);

    /// Only registry can call this function.
    error OnlyRegistry();
    /// Only manufacturer can call this function.
    error OnlyManufacturer();
    /// Only service center can call this function.
    error OnlyServiceCenter();
    /// Only car owner can call this function.
    error OnlyCarOwner();
    /// Only car owner or service center can call this function.
    error OnlyCarOwnerOrServiceCenter();
    /// Cannot call this function while the car is in the service center.
    error InServiceCenter();
    /// The seller should pay more than some minimum amount.
    error EscrowValueTooSmall(uint minEscrow);
    /// The car is already being sold.
    error CarPurchaseAlreadyPending(TaxedPurchase purchase);
    /// Cannot call this function while there is a pending purchase for this car.
    error ThereIsPendingPurchase(TaxedPurchase purchase);

    modifier onlyRegistry() {
        if (msg.sender != registry)
            revert OnlyRegistry();
        _;
    }

    modifier onlyManufacturer() {
        if (roles[msg.sender] != Role.Manufacturer)
            revert OnlyManufacturer();
        _;
    }

    modifier onlyServiceCenter(uint carId) {
        if (roles[msg.sender] != Role.ServiceCenter || carInfo[carId].currentSC != msg.sender)
            revert OnlyServiceCenter();
        _;
    }

    modifier onlyCarOwner(uint carId) {
        if (carInfo[carId].currentOwner != msg.sender)
            revert OnlyCarOwner();
        _;
    }

    modifier onlyCarOwnerOrServiceCenter(uint carId) {
        if (roles[msg.sender] == Role.ServiceCenter) {
            if (carInfo[carId].currentSC != msg.sender)
                revert OnlyCarOwnerOrServiceCenter();
        } else if (carInfo[carId].currentOwner != msg.sender)
            revert OnlyCarOwnerOrServiceCenter();
        _;
    }

    modifier notInServiceCenter(uint carId) {
        if (carInfo[carId].currentSC != address(0))
            revert InServiceCenter();
        _;
    }

    modifier noPurchasesPending(uint carId) {
        if (purchasesPending[carId] != address(0))
            revert ThereIsPendingPurchase(TaxedPurchase(purchasesPending[carId]));
        _;
    }


    constructor() {
        registry = payable(msg.sender);
    }

    function setRole(address[] calldata users, Role role) internal
    {
        for (uint i = 0; i < users.length; i++) {
            roles[users[i]] = role;
        }
    }

    /// Grants a Manufacturer role to a list of users
    function setManufacturers(address[] calldata users)
        external
        onlyRegistry
    {
        setRole(users, Role.Manufacturer);
    }

    /// Grants a ServiceCenter role to a list of users
    function setServiceCenters(address[] calldata users)
        external
        onlyRegistry
    {
        setRole(users, Role.ServiceCenter);
    }

    /// Drops roles for a list of users, setting them to CarOwner
    function unsetRole(address[] calldata users)
        external
        onlyRegistry
    {
        setRole(users, Role.CarOwner);
    }

    /// Sets tax type for a list of users.
    function setTaxType(address[] calldata users, TaxInfo.TaxType t)
        external
        onlyRegistry
    {
        for (uint i = 0; i < users.length; i++) {
            taxType[users[i]] = t;
        }
    }



    /// Creates a new car. Only a manufacturer can do this.
    function createCar(bytes32 registryCode, bytes32 specHash)
        external
        onlyManufacturer
        returns (uint carId)
    {
        carId = nextCarId;
        CarInfo storage info = carInfo[carId];
        require(info.registryCode == 0);

        nextCarId++;
        info.registryCode = registryCode;
        info.specHash = specHash;
        info.currentOwner = msg.sender;
        carsByOwner[msg.sender].push(carId);
        emit CarCreated(carId, msg.sender);

        return carId;
    }

    /// Changes a registry code. Only a service center can do this.
    function changeRegistryCode(uint carId, bytes32 registryCode)
        external
        onlyServiceCenter(carId)
        noPurchasesPending(carId)
    {
        CarInfo storage info = carInfo[carId];
        require(info.registryCode != 0);

        info.registryCode = registryCode;
        emit CarRegistryCodeUpdated(carId, msg.sender, registryCode);
    }

    /// Changes specs. Only a service center can do this.
    function changeSpecs(uint carId, bytes32 specHash)
        external
        onlyServiceCenter(carId)
        noPurchasesPending(carId)
    {
        CarInfo storage info = carInfo[carId];
        require(info.registryCode != 0);

        info.specHash = specHash;
        emit CarSpecsUpdated(carId, msg.sender, specHash);
    }

    /// Adds an operation to operation log. Only car owner or a service center can do this.
    function addOperation(uint carId, string calldata operation)
        external
        onlyCarOwnerOrServiceCenter(carId)
        noPurchasesPending(carId)
    {
        CarInfo storage info = carInfo[carId];
        require(info.registryCode != 0);

        emit CarOperationLog(carId, block.timestamp, msg.sender, operation);
    }

    /// Updates mileage. Only car owner or a service center can do this.
    function updateMileage(uint carId, uint mileage)
        external
        onlyCarOwnerOrServiceCenter(carId)
        noPurchasesPending(carId)
    {
        CarInfo storage info = carInfo[carId];
        require(info.registryCode != 0);
        if (mileage < info.mileage)
            require(roles[msg.sender] == Role.ServiceCenter);
        
        info.mileage = mileage;
    }

    function lendToServiceCenter(uint carId, address serviceCenter)
        external
        onlyCarOwner(carId)
        noPurchasesPending(carId)
        notInServiceCenter(carId)
    {
        CarInfo storage info = carInfo[carId];
        require(roles[serviceCenter] == Role.ServiceCenter);

        info.currentSC = serviceCenter;
        emit CarLentToServiceCenter(carId, msg.sender, serviceCenter);
    }

    function takeBackFromServiceCenter(uint carId)
        external
        onlyCarOwner(carId)
        noPurchasesPending(carId)
    {
        CarInfo storage info = carInfo[carId];
        require(info.currentSC != address(0));

        emit CarTakenFromServiceCenter(carId, msg.sender, info.currentSC);
        info.currentSC = address(0);
    }

    uint constant ESCROW_DENOM = 10;

    /// Initiate purchase.
    /// The value is the escrow value that will be returned after the purchase is complete.
    /// Note that for external purchases you must take care of taxes yourself.
    function sellCar(uint carId, uint price, bool isExternal, address payable buyer)
        external
        onlyCarOwner(carId)
        noPurchasesPending(carId)
        notInServiceCenter(carId)
        payable
        returns (TaxedPurchase)
    {
        if (purchasesPending[carId] != address(0))
            revert CarPurchaseAlreadyPending(TaxedPurchase(purchasesPending[carId]));
        
        uint minEscrow = price / ESCROW_DENOM;
        if (msg.value < minEscrow)
            revert EscrowValueTooSmall(minEscrow);

        emit CarPurchaseStarted(carId, msg.sender, price);

        uint previousPrice = carInfo[carId].previousPrice;
        TaxInfo.TaxType t = taxType[msg.sender];
        uint taxAmount = TaxInfo.calculateTax(t, price, previousPrice);

        TaxedPurchase purchase = new TaxedPurchase{value: msg.value}(
                                    isExternal,
                                    payable(msg.sender),
                                    buyer,
                                    price,
                                    taxAmount,
                                    registry
                                );
        purchasesPending[carId] = address(purchase);
        return purchase;
    }

    function deleteCarByOwner(address owner, uint carId) internal
    {
        uint[] storage arr = carsByOwner[owner];
        for (uint i = 0; i < arr.length; i++) {
            if (arr[i] == carId) {
                delete arr[i];
                if (i != arr.length - 1) {
                    arr[i] = arr[arr.length - 1];
                    arr.pop();
                    break;
                }
            }
        }
    }

    /// Complete purchase
    function completePurchase(uint carId) external
    {
        require(purchasesPending[carId] != address(0));
        TaxedPurchase purchase = TaxedPurchase(purchasesPending[carId]);

        require(purchase.isDone());
        require(msg.sender == purchase.buyer());

        purchasesPending[carId] = address(0);
        CarInfo storage info = carInfo[carId];

        info.previousOwner = info.currentOwner;
        info.currentOwner = msg.sender;
        info.previousPrice = purchase.price();

        deleteCarByOwner(info.previousOwner, carId);
        carsByOwner[msg.sender].push(carId);

        emit CarPurchaseCompleted(carId, msg.sender);
    }
}