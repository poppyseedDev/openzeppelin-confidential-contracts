import { $ERC7984Mock } from '../../../types/contracts-exposed/mocks/token/ERC7984Mock.sol/$ERC7984Mock';
import { shouldBehaveLikeERC7984 } from './ERC7984.behaviour';
import { ethers, fhevm } from 'hardhat';

const contract = '$ERC7984Mock';
const name = 'ConfidentialFungibleToken';
const symbol = 'CFT';
const uri = 'https://example.com/metadata';

async function deployFixture(_contract?: string, extraDeploymentArgs: any[] = []) {
  const [holder, recipient, operator, anyone] = await ethers.getSigners();
  const token = (await ethers.deployContract(_contract ? _contract : contract, [
    name,
    symbol,
    uri,
    ...extraDeploymentArgs,
  ])) as any as $ERC7984Mock;
  const encryptedInput = await fhevm
    .createEncryptedInput(await token.getAddress(), holder.address)
    .add64(1000)
    .encrypt();
  await token
    .connect(holder)
    ['$_mint(address,bytes32,bytes)'](holder, encryptedInput.handles[0], encryptedInput.inputProof);
  return { token, holder, recipient, operator, anyone };
}

describe('ERC7984', function () {
  shouldBehaveLikeERC7984(contract);
});

export { deployFixture as deployERC7984Fixture };
