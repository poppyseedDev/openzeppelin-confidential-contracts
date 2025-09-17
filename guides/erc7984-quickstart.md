# ERC7984 Quickstart

This tutorial explains how to create a confidential fungible token using Fully Homomorphic Encryption (FHE) and the OpenZeppelin smart contract library. By following this guide, you will learn how to build a token where balances and transactions remain encrypted while maintaining full functionality.

## Why FHE for Confidential Tokens?

Confidential tokens make sense in many real-world scenarios:

- **Privacy**: Users can transact without revealing their exact balances or transaction amounts
- **Regulatory Compliance**: Maintains privacy while allowing for selective disclosure when needed
- **Business Intelligence**: Companies can keep their token holdings private from competitors
- **Personal Privacy**: Individuals can participate in DeFi without exposing their financial position
- **Audit Trail**: All transactions are still recorded on-chain, just in encrypted form

FHE enables these benefits by allowing computations on encrypted data without decryption, ensuring privacy while maintaining the security and transparency of blockchain.



## Understanding the Architecture

Our confidential token will inherit from several key contracts:

1. **`ERC7984`** - OpenZeppelin's base for confidential tokens
2. **`Ownable2Step`** - Access control for minting and administrative functions
3. **`SepoliaConfig`** - FHE configuration for the Sepolia testnet

## The base smart contract

Create a new file `contracts/ERC7984Example.sol`:

Contract written like this assumes minimal privacy assumptions. Here you are minting a clear amount directly when instantiating.

base example it assumes that the mint has been done only once, with a clear amount.

```solidity
// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity ^0.8.24;

import {Ownable2Step, Ownable} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {FHE, externalEuint64, euint64} from "@fhevm/solidity/lib/FHE.sol";
import {SepoliaConfig} from "@fhevm/solidity/config/ZamaConfig.sol";
import {ERC7984} from "@openzeppelin/confidential-contracts/token/ERC7984.sol";

contract ERC7984Example is SepoliaConfig, ERC7984, Ownable2Step {
    constructor(
        uint64 amount,
        string memory name_,
        string memory symbol_,
        string memory tokenURI_
    ) ERC7984(name_, symbol_, tokenURI_) Ownable(msg.sender) {
        euint64 encryptedAmount = FHE.asEuint64(amount);
        _mint(msg.sender, encryptedAmount);
    }
}
```


## Test workflow
_here should be a simple tests that just allows you to deploy the contract_
_then it should showcase the transfer process_


## Possible "addons"

Additional "addons"
visible mint
```solidity
    function mint(address to, uint64 amount) external onlyOwner {
        _mint(to, FHE.asEuint64(amount));
    }
```

confidential mint
```solidity
    function confidentialMint(
        address to,
        externalEuint64 encryptedAmount,
        bytes calldata inputProof
    ) external onlyOwner returns (euint64 transferred) {
        return _mint(to, FHE.fromExternal(encryptedAmount, inputProof));
    }
```

visible burn
```solidity
    function burn(address from, uint64 amount) external onlyOwner {
        _burn(from, FHE.asEuint64(amount));
    }

confidential burn
```solidity
    function confidentialBurn(
        address from,
        externalEuint64 encryptedAmount,
        bytes calldata inputProof
    ) external onlyOwner returns (euint64 transferred) {
        return _burn(from, FHE.fromExternal(encryptedAmount, inputProof));
    }
```

if you want the owner to be able to view the total supply
```solidity
    function _update(address from, address to, euint64 amount) internal virtual override returns (euint64 transferred) {
        transferred = super._update(from, to, amount);
        FHE.allow(confidentialTotalSupply(), owner());
    }
```