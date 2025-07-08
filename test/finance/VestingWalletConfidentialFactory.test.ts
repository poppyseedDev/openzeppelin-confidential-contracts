import { $VestingWalletConfidentialFactory } from '../../types/contracts-exposed/finance/VestingWalletConfidentialFactory.sol/$VestingWalletConfidentialFactory';
import { time } from '@nomicfoundation/hardhat-network-helpers';
import { expect } from 'chai';
import { ethers, fhevm } from 'hardhat';

const name = 'ConfidentialFungibleToken';
const symbol = 'CFT';
const uri = 'https://example.com/metadata';

describe('WalletConfidentialFactory', function () {
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
    const factory = await ethers.deployContract('$VestingWalletConfidentialFactory', []);

    await (token as any)
      .connect(holder)
      ['$_mint(address,bytes32,bytes)'](factory.target, encryptedInput.handles[0], encryptedInput.inputProof);

    Object.assign(this, { accounts, holder, recipient, operator, token, factory, schedule, vestingAmount: 1000 });
  });

  it('should create predeterministic factory wallet address', async function () {
    const factory = this.factory as unknown as $VestingWalletConfidentialFactory;
    const startTimestamp = 9876543210;
    const duration = 1234;
    const executor = ethers.ZeroAddress;
    const predictedVestingWalletAddress = await factory.predictVestingWalletConfidential(
      executor,
      this.recipient,
      startTimestamp,
      duration,
    );
    const vestingWalletAddress = await factory.createVestingWalletConfidential.staticCall(
      executor,
      this.recipient,
      startTimestamp,
      duration,
    );
    expect(vestingWalletAddress).to.be.equal(predictedVestingWalletAddress);
  });
});
