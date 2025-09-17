# ERC7984 Quickstart

This quickstart shows how to deploy a simple `ERC7984` token and perform confidential transfers using input proofs.

Example token contract used here: `contracts/mocks/docs/ERC7984MintableBurnable.sol`.

## 1) Deploy a token

Constructor: `ERC7984MintableBurnable(address owner, string name, string symbol, string uri)`

Example Hardhat script snippet:

```ts
import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();
  const Token = await ethers.getContractFactory("ERC7984MintableBurnable");
  const token = await Token.deploy(deployer.address, "ConfToken", "CONF", "ipfs://token-metadata");
  await token.waitForDeployment();
  console.log("Token:", await token.getAddress());
}

main().catch((e) => { console.error(e); process.exit(1); });
```

## 2) Mint with input proof

The token owner can mint using an `externalEuint64` encrypted amount plus an `inputProof` provided by the fhEVM gateway.

```solidity
// Solidity example (owner context)
function mint(address to, externalEuint64 amount, bytes memory inputProof) public onlyOwner {
    _mint(to, FHE.fromExternal(amount, inputProof));
}
```

High-level flow:

- Obtain `amount` ciphertext and `inputProof` from the fhEVM gateway
- Call `mint(to, amount, inputProof)`

## 3) Confidential transfer with proof

Two ways to transfer:

- With proof: `confidentialTransfer(to, externalEuint64, bytes inputProof)`
- Without proof: `confidentialTransfer(to, euint64)` if caller already has ACL access to the encrypted amount

Example with proof:

```ts
// TypeScript sketch
const { ciphertext, inputProof } = await getProofFromGateway(/* amount = 100 */);
await token.confidentialTransfer(recipient, ciphertext, inputProof);
```

## 4) Transfer and call

If the receiver implements `IERC7984Receiver`, you can call:

```ts
await token.confidentialTransferAndCall(receiver, ciphertext, inputProof, "0x");
```

The receiver’s `onConfidentialTransferReceived` returns `ebool`. If false, the transfer must be reverted by the token and the funds are effectively refunded.

## 5) Operators

Grant an operator that can move funds until a timestamp:

```ts
await token.setOperator(operator, Math.floor(Date.now()/1000) + 3600);
```

Then the operator can use `confidentialTransferFrom(from, to, ...)` variants.

## 6) Balance and supply (encrypted)

```ts
const eSupply = await token.confidentialTotalSupply();
const eBal = await token.confidentialBalanceOf(user);
// These are encrypted handles. Use fhEVM gateway flows to disclose if necessary.
```

See `mocks/docs/SwapERC7984ToERC20.sol` and `mocks/docs/SwapERC7984ToERC7984.sol` for advanced, real-world patterns.