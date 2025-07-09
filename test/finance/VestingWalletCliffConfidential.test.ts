import { shouldBehaveLikeVestingConfidential } from './VestingWalletConfidential.behavior';
import { FhevmType } from '@fhevm/hardhat-plugin';
import { time } from '@nomicfoundation/hardhat-network-helpers';
import { expect } from 'chai';
import { EventLog } from 'ethers';
import { ethers, fhevm } from 'hardhat';

const name = 'ConfidentialFungibleToken';
const symbol = 'CFT';
const uri = 'https://example.com/metadata';

for (const useInitializable of [false, true]) {
  describe(`VestingWalletCliffConfidential${useInitializable ? 'Initializable' : ''}`, function () {
    beforeEach(async function () {
      const accounts = (await ethers.getSigners()).slice(3);
      const [holder, recipient, operator] = accounts;

      const token = await ethers.deployContract('$ConfidentialFungibleTokenMock', [name, symbol, uri]);

      const encryptedInput = await fhevm
        .createEncryptedInput(await token.getAddress(), holder.address)
        .add64(1000)
        .encrypt();

      const currentTime = await time.latest();
      const schedule = [currentTime + 60, currentTime + 60 * 121];

      let vesting;
      let clones;
      let impl;

      if (!useInitializable) {
        vesting = await ethers.deployContract('$VestingWalletCliffConfidentialMock', [
          operator,
          recipient,
          currentTime + 60,
          60 * 60 * 2 /* 2 hours */,
          60 * 60 /* 1 hour */,
        ]);
      } else {
        impl = await ethers.deployContract('$VestingWalletCliffConfidentialInitializableMock');
        clones = await ethers.deployContract('$Clones');

        const cloneAddr = await clones['$predictDeterministicAddress(address,bytes32)'](impl, ethers.ZeroHash);
        await clones.$cloneDeterministic(impl, ethers.ZeroHash);

        vesting = await ethers.getContractAt('$VestingWalletCliffConfidentialInitializableMock', cloneAddr);
        await vesting.initialize(
          operator,
          recipient,
          currentTime + 60,
          60 * 60 * 2 /* 2 hours */,
          60 * 60 /* 1 hour */,
        );
      }

      await (token as any)
        .connect(holder)
        ['$_mint(address,bytes32,bytes)'](vesting.target, encryptedInput.handles[0], encryptedInput.inputProof);

      Object.assign(this, {
        accounts,
        holder,
        recipient,
        operator,
        token,
        vesting,
        schedule,
        vestingAmount: 1000,
        clones,
        impl,
      });
    });

    it('should release nothing before cliff', async function () {
      await time.increaseTo(this.schedule[0] + 60);
      await this.vesting.release(this.token);

      const balanceOfHandle = await this.token.confidentialBalanceOf(this.recipient);
      await expect(
        fhevm.userDecryptEuint(FhevmType.euint64, balanceOfHandle, this.token.target, this.recipient),
      ).to.eventually.equal(0);
    });

    it('should fail construction if cliff is longer than duration', async function () {
      if (!useInitializable) {
        await expect(
          ethers.deployContract('$VestingWalletCliffConfidentialMock', [
            this.operator,
            this.recipient,
            (await time.latest()) + 60,
            60 * 10,
            60 * 60,
          ]),
        ).to.be.revertedWithCustomError(this.vesting, 'InvalidCliffDuration');
      } else {
        const cloneAddr = await this.clones['$predictDeterministicAddress(address,bytes32)'](
          this.impl,
          ethers.zeroPadBytes('0x01', 32),
        );
        await this.clones.$cloneDeterministic(this.impl, ethers.zeroPadBytes('0x01', 32));

        const newClone = await ethers.getContractAt('$VestingWalletCliffConfidentialInitializableMock', cloneAddr);

        await expect(
          newClone.initialize(this.operator, this.recipient, (await time.latest()) + 60, 60 * 10, 60 * 60),
        ).to.be.revertedWithCustomError(newClone, 'InvalidCliffDuration');
      }
    });

    if (useInitializable) {
      it('cannot reinitialize', async function () {
        await expect(
          this.vesting.initialize(
            this.operator,
            this.recipient,
            (await time.latest()) + 60,
            60 * 60 * 2 /* 2 hours */,
            60 * 60 /* 1 hour */,
          ),
        ).to.be.revertedWithCustomError(this.vesting, 'InvalidInitialization');
      });
    }

    shouldBehaveLikeVestingConfidential();
  });
}
