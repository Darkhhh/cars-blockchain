// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

library TaxInfo {
    enum TaxType { Default, NonResident, None }
    
    function calculateTax(TaxType t, uint newPrice, uint oldPrice)
        internal
        pure
        returns (uint)
    {
        if (t == TaxType.None)
            return 0;
        if (newPrice <= oldPrice)
            return 0;
        
        uint profit = newPrice - oldPrice;
        uint taxRate;
        if (t == TaxType.Default)
            taxRate = 13;
        else if (t == TaxType.NonResident)
            taxRate = 30;
        return profit * taxRate / 100;
    }
}