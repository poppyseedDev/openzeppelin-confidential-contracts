import { FhevmType } from '@fhevm/hardhat-plugin';
import { anyValue } from '@nomicfoundation/hardhat-chai-matchers/withArgs';
import { time } from '@nomicfoundation/hardhat-network-helpers';
import { expect } from 'chai';
import { fhevm } from 'hardhat';

function shouldBehaveLikeVestingConfidential() {
  describe('vesting', async function () {
    it('should release nothing before vesting start', async function () {
      await this.vesting.release(this.token);

      const balanceOfHandle = await this.token.confidentialBalanceOf(this.recipient);
      await expect(
        fhevm.userDecryptEuint(FhevmType.euint64, balanceOfHandle, this.token.target, this.recipient),
      ).to.eventually.equal(0);
    });

    it('should release nothing at vesting start', async function () {
      await time.increaseTo(this.schedule[0]);
      await this.vesting.release(this.token);

      const balanceOfHandle = await this.token.confidentialBalanceOf(this.recipient);
      await expect(
        fhevm.userDecryptEuint(FhevmType.euint64, balanceOfHandle, this.token.target, this.recipient),
      ).to.eventually.equal(0);
    });

    it('should release half at midpoint', async function () {
      await time.increaseTo((this.schedule[1] + this.schedule[0]) / 2);
      await this.vesting.release(this.token);

      const balanceOfHandle = await this.token.confidentialBalanceOf(this.recipient);
      await expect(
        fhevm.userDecryptEuint(FhevmType.euint64, balanceOfHandle, this.token.target, this.recipient),
      ).to.eventually.equal(this.vestingAmount / 2);
    });

    it('should release entire amount after end', async function () {
      await time.increaseTo(this.schedule[1] + 1000);
      await this.vesting.release(this.token);

      const balanceOfHandle = await this.token.confidentialBalanceOf(this.recipient);
      await expect(
        fhevm.userDecryptEuint(FhevmType.euint64, balanceOfHandle, this.token.target, this.recipient),
      ).to.eventually.equal(this.vestingAmount);
    });
  });

  describe('call', async function () {
    it('should fail if not called by executor', async function () {
      await expect(this.vesting.call(this.token, 0, '0x')).to.be.revertedWithCustomError(
        this.vesting,
        'VestingWalletConfidentialOnlyExecutor',
      );
    });

    it('should call if called by executor', async function () {
      await expect(
        this.vesting
          .connect(this.operator)
          .call(
            this.token,
            0,
            (
              await this.token.confidentialTransfer.populateTransaction(
                this.recipient,
                await this.token.confidentialBalanceOf(this.vesting),
              )
            ).data,
          ),
      )
        .to.emit(this.token, 'ConfidentialTransfer')
        .withArgs(this.vesting, this.recipient, anyValue);
    });
  });
}

export { shouldBehaveLikeVestingConfidential };
