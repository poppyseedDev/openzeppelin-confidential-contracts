import { shouldBehaveLikeVestingConfidential } from './VestingWalletConfidential.behavior';
import { anyValue } from '@nomicfoundation/hardhat-chai-matchers/withArgs';
import { time } from '@nomicfoundation/hardhat-network-helpers';
import { encodeMode, encodeBatch, CALL_TYPE_BATCH } from '@openzeppelin/contracts/test/helpers/erc7579';
import { expect } from 'chai';
import { ethers, fhevm } from 'hardhat';

const name = 'ConfidentialFungibleToken';
const symbol = 'CFT';
const uri = 'https://example.com/metadata';

describe('VestingWalletExecutorConfidential', function () {
  beforeEach(async function () {
    const accounts = (await ethers.getSigners()).slice(3);
    const [holder, recipient, executor] = accounts;

    const token = await ethers.deployContract('$ConfidentialFungibleTokenMock', [name, symbol, uri]);

    const encryptedInput = await fhevm
      .createEncryptedInput(await token.getAddress(), holder.address)
      .add64(1000)
      .encrypt();

    const currentTime = await time.latest();
    const schedule = [currentTime + 60, currentTime + 60 * 61];
    const vesting = await ethers.deployContract('$VestingWalletExecutorConfidentialMock', [
      recipient,
      currentTime + 60,
      60 * 60 /* 1 hour */,
      executor,
    ]);

    await (token as any)
      .connect(holder)
      ['$_mint(address,bytes32,bytes)'](vesting.target, encryptedInput.handles[0], encryptedInput.inputProof);

    Object.assign(this, { accounts, holder, recipient, executor, token, vesting, schedule, vestingAmount: 1000 });
  });

  describe('execute', async function () {
    it('should fail if not called by executor', async function () {
      await expect(
        this.vesting
          .connect(this.holder)
          .execute(
            encodeMode({ callType: CALL_TYPE_BATCH }),
            encodeBatch({ target: this.token, value: 0n, data: '0x' }),
          ),
      )
        .to.be.revertedWithCustomError(this.vesting, 'AccountUnauthorized')
        .withArgs(this.holder);
    });

    it('should call if called by executor', async function () {
      const balance = await this.token.confidentialBalanceOf(this.vesting);

      await expect(
        this.vesting.connect(this.executor).execute(
          encodeMode({ callType: CALL_TYPE_BATCH }),
          encodeBatch({
            target: this.token,
            value: 0n,
            data: this.token.interface.encodeFunctionData('confidentialTransfer(address,bytes32)', [
              this.recipient.address,
              balance,
            ]),
          }),
        ),
      )
        .to.emit(this.token, 'ConfidentialTransfer')
        .withArgs(this.vesting, this.recipient, anyValue);
    });
  });

  shouldBehaveLikeVestingConfidential();
});
