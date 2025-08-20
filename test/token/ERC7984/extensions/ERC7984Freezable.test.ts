import { IACL__factory } from '../../../../types';
import { $ERC7984FreezableMock } from '../../../../types/contracts-exposed/mocks/token/ERC7984FreezableMock.sol/$ERC7984FreezableMock';
import { $ERC7984Mock } from '../../../../types/contracts-exposed/mocks/token/ERC7984Mock.sol/$ERC7984Mock';
import { ACL_ADDRESS } from '../../../helpers/accounts';
import { shouldBehaveLikeERC7984 } from '../ERC7984.behaviour';
import { FhevmType } from '@fhevm/hardhat-plugin';
import { expect } from 'chai';
import { ethers, fhevm } from 'hardhat';

const name = 'ConfidentialFungibleToken';
const symbol = 'CFT';
const uri = 'https://example.com/metadata';

/* eslint-disable no-unexpected-multiline */
describe('ERC7984Freezable', function () {
  async function deployFixture() {
    const [holder, recipient, freezer, operator, anyone] = await ethers.getSigners();
    const token = (await ethers.deployContract('$ERC7984FreezableMock', [
      name,
      symbol,
      uri,
      freezer.address,
    ])) as any as $ERC7984FreezableMock;
    const encryptedInput = await fhevm
      .createEncryptedInput(await token.getAddress(), holder.address)
      .add64(1000)
      .encrypt();
    await token
      .connect(holder)
      ['$_mint(address,bytes32,bytes)'](holder, encryptedInput.handles[0], encryptedInput.inputProof);
    const acl = IACL__factory.connect(ACL_ADDRESS, ethers.provider);
    return { token, acl, holder, recipient, freezer, operator, anyone };
  }

  it('should set and get confidential frozen', async function () {
    const { token, acl, holder, recipient, freezer } = await deployFixture();
    const encryptedRecipientMintInput = await fhevm
      .createEncryptedInput(await token.getAddress(), holder.address)
      .add64(1000)
      .encrypt();
    await token
      .connect(holder)
      ['$_mint(address,bytes32,bytes)'](
        recipient.address,
        encryptedRecipientMintInput.handles[0],
        encryptedRecipientMintInput.inputProof,
      )
      .then(tx => tx.wait());
    const encryptedInput = await fhevm
      .createEncryptedInput(await token.getAddress(), freezer.address)
      .add64(100)
      .encrypt();
    await expect(
      token
        .connect(freezer)
        ['setConfidentialFrozen(address,bytes32,bytes)'](
          recipient.address,
          encryptedInput.handles[0],
          encryptedInput.inputProof,
        ),
    )
      .to.emit(token, 'TokensFrozen')
      .withArgs(recipient.address, encryptedInput.handles[0]);
    const frozenHandle = await token.confidentialFrozen(recipient.address);
    expect(frozenHandle).to.equal(ethers.hexlify(encryptedInput.handles[0]));
    expect(await acl.isAllowed(frozenHandle, recipient.address)).to.be.true;
    expect(await fhevm.userDecryptEuint(FhevmType.euint64, frozenHandle, await token.getAddress(), recipient)).to.equal(
      100,
    );
    const balanceHandle = await token.confidentialBalanceOf(recipient.address);
    expect(
      await fhevm.userDecryptEuint(FhevmType.euint64, balanceHandle, await token.getAddress(), recipient),
    ).to.equal(1000);
    const confidentialAvailableArgs = recipient.address;
    const availableHandle = await token.confidentialAvailable.staticCall(confidentialAvailableArgs);
    await (token as any)
      .connect(recipient)
      .confidentialAvailableAccess(confidentialAvailableArgs)
      .then(tx => tx.wait());
    expect(
      await fhevm.userDecryptEuint(FhevmType.euint64, availableHandle, await token.getAddress(), recipient),
    ).to.equal(900);
  });

  it('should not set confidential frozen if not called by freezer', async function () {
    const { token, holder, recipient, anyone } = await deployFixture();
    const encryptedRecipientMintInput = await fhevm
      .createEncryptedInput(await token.getAddress(), holder.address)
      .add64(1000)
      .encrypt();
    await token
      .connect(holder)
      ['$_mint(address,bytes32,bytes)'](
        recipient.address,
        encryptedRecipientMintInput.handles[0],
        encryptedRecipientMintInput.inputProof,
      )
      .then(tx => tx.wait());
    const encryptedInput = await fhevm
      .createEncryptedInput(await token.getAddress(), anyone.address)
      .add64(100)
      .encrypt();

    await expect(
      token
        .connect(anyone)
        ['setConfidentialFrozen(address,bytes32,bytes)'](
          recipient.address,
          encryptedInput.handles[0],
          encryptedInput.inputProof,
        ),
    )
      .to.be.revertedWithCustomError(token, 'AccessControlUnauthorizedAccount')
      .withArgs(anyone.address, ethers.id('FREEZER_ROLE'));
  });

  it('should transfer max available', async function () {
    const { token, holder, recipient, freezer, anyone } = await deployFixture();
    const encryptedRecipientMintInput = await fhevm
      .createEncryptedInput(await token.getAddress(), holder.address)
      .add64(1000)
      .encrypt();
    await token
      .connect(holder)
      ['$_mint(address,bytes32,bytes)'](
        recipient.address,
        encryptedRecipientMintInput.handles[0],
        encryptedRecipientMintInput.inputProof,
      )
      .then(tx => tx.wait());
    const encryptedInput = await fhevm
      .createEncryptedInput(await token.getAddress(), freezer.address)
      .add64(100)
      .encrypt();
    await token
      .connect(freezer)
      ['setConfidentialFrozen(address,bytes32,bytes)'](
        recipient.address,
        encryptedInput.handles[0],
        encryptedInput.inputProof,
      )
      .then(tx => tx.wait());
    const confidentialAvailableArgs = recipient.address;
    const availableHandle = await token.confidentialAvailable.staticCall(confidentialAvailableArgs);
    await (token as any)
      .connect(recipient)
      .confidentialAvailableAccess(confidentialAvailableArgs)
      .then(tx => tx.wait());
    expect(
      await fhevm.userDecryptEuint(FhevmType.euint64, availableHandle, await token.getAddress(), recipient),
    ).to.equal(900);
    const encryptedInput2 = await fhevm
      .createEncryptedInput(await token.getAddress(), recipient.address)
      .add64(900)
      .encrypt();
    await token
      .connect(recipient)
      ['confidentialTransfer(address,bytes32,bytes)'](
        anyone.address,
        encryptedInput2.handles[0],
        encryptedInput2.inputProof,
      )
      .then(tx => tx.wait());
    expect(
      await fhevm.userDecryptEuint(
        FhevmType.euint64,
        await token.confidentialBalanceOf(recipient.address),
        await token.getAddress(),
        recipient,
      ),
    ).to.equal(100);
  });

  it('should transfer zero if transferring more than available', async function () {
    const { token, holder, recipient, freezer, anyone } = await deployFixture();
    const encryptedRecipientMintInput = await fhevm
      .createEncryptedInput(await token.getAddress(), holder.address)
      .add64(1000)
      .encrypt();
    await token
      .connect(holder)
      ['$_mint(address,bytes32,bytes)'](
        recipient.address,
        encryptedRecipientMintInput.handles[0],
        encryptedRecipientMintInput.inputProof,
      )
      .then(tx => tx.wait());
    const encryptedInput = await fhevm
      .createEncryptedInput(await token.getAddress(), freezer.address)
      .add64(500)
      .encrypt();
    await token
      .connect(freezer)
      ['setConfidentialFrozen(address,bytes32,bytes)'](
        recipient.address,
        encryptedInput.handles[0],
        encryptedInput.inputProof,
      )
      .then(tx => tx.wait());
    const encryptedInput2 = await fhevm
      .createEncryptedInput(await token.getAddress(), recipient.address)
      .add64(501)
      .encrypt();
    await token
      .connect(recipient)
      ['confidentialTransfer(address,bytes32,bytes)'](
        anyone.address,
        encryptedInput2.handles[0],
        encryptedInput2.inputProof,
      )
      .then(tx => tx.wait());
    expect(
      await fhevm.userDecryptEuint(
        FhevmType.euint64,
        await token.confidentialBalanceOf(recipient.address),
        await token.getAddress(),
        recipient,
      ),
    ).to.equal(1000);
  });

  shouldBehaveLikeERC7984(async () => {
    const { token, holder, recipient, operator, anyone } = await deployFixture();
    return { token: token as any as $ERC7984Mock, holder, recipient, operator, anyone };
  });
});
/* eslint-disable no-unexpected-multiline */
