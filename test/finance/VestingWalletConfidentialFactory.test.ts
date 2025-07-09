import { VestingWalletConfidentialUpgradeable__factory } from '../../types';
import { $VestingWalletConfidentialFactory } from '../../types/contracts-exposed/finance/VestingWalletConfidentialFactory.sol/$VestingWalletConfidentialFactory';
import { time } from '@nomicfoundation/hardhat-network-helpers';
import { expect } from 'chai';
import { ethers, fhevm } from 'hardhat';

const name = 'ConfidentialFungibleToken';
const symbol = 'CFT';
const uri = 'https://example.com/metadata';
const startTimestamp = 9876543210;
const duration = 1234;
let factory: $VestingWalletConfidentialFactory;

describe('WalletConfidentialFactory', function () {
  beforeEach(async function () {
    const accounts = (await ethers.getSigners()).slice(3);
    const [holder, recipient, operator, executor] = accounts;

    const token = await ethers.deployContract('$ConfidentialFungibleTokenMock', [name, symbol, uri]);

    const encryptedInput = await fhevm
      .createEncryptedInput(await token.getAddress(), holder.address)
      .add64(1000)
      .encrypt();

    const currentTime = await time.latest();
    const schedule = [currentTime + 60, currentTime + 60 * 121];
    factory = (await ethers.deployContract(
      '$VestingWalletConfidentialFactory',
      [],
    )) as unknown as $VestingWalletConfidentialFactory;

    await (token as any)
      .connect(holder)
      ['$_mint(address,bytes32,bytes)'](factory.target, encryptedInput.handles[0], encryptedInput.inputProof);

    Object.assign(this, {
      accounts,
      holder,
      recipient,
      operator,
      executor,
      token,
      factory,
      schedule,
      vestingAmount: 1000,
    });
  });

  it('should create vesting wallet with predeterministic address', async function () {
    const predictedVestingWalletAddress = await factory.predictVestingWalletConfidential(
      this.executor,
      this.recipient,
      startTimestamp,
      duration,
    );
    const vestingWalletAddress = await factory.createVestingWalletConfidential.staticCall(
      this.executor,
      this.recipient,
      startTimestamp,
      duration,
    );
    expect(vestingWalletAddress).to.be.equal(predictedVestingWalletAddress);
  });

  it('should create vesting wallet', async function () {
    const vestingWalletAddress = await factory.predictVestingWalletConfidential(
      this.executor,
      this.recipient,
      startTimestamp,
      duration,
    );

    await expect(await factory.createVestingWalletConfidential(this.executor, this.recipient, startTimestamp, duration))
      .to.emit(factory, 'VestingWalletConfidentialCreated')
      .withArgs(this.recipient, vestingWalletAddress, startTimestamp);
    const vestingWallet = VestingWalletConfidentialUpgradeable__factory.connect(vestingWalletAddress, ethers.provider);
    expect(await vestingWallet.owner()).to.be.equal(this.recipient);
    expect(await vestingWallet.start()).to.be.equal(startTimestamp);
    expect(await vestingWallet.executor()).to.be.equal(this.executor);
  });

  it('should not create vesting wallet twice', async function () {
    await expect(
      await factory.createVestingWalletConfidential(this.executor, this.recipient, startTimestamp, duration),
    ).to.emit(factory, 'VestingWalletConfidentialCreated');
    await expect(
      factory.createVestingWalletConfidential(this.executor, this.recipient, startTimestamp, duration),
    ).to.be.revertedWithCustomError(factory, 'FailedDeployment');
  });
});
