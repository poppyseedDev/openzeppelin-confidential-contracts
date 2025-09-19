---
title: OpenZeppelin Confidential Contracts – Guides
---

# Guides on the Open Zeppelin Smart Contracts repository

_give a description about Open Zeppelin's library on what it contains_

## Getting Started

_Format this better: this getting started guide is common across all docs._

### Prerequisites:

- Node.js >= 20
- Hardhat ^2.24
- Access to an FHEVM-enabled network and the Zama gateway/relayer

### Project Setup

First, you need to install a new project by cloning [Zama's Hardhat template](https://github.com/zama-ai/fhevm-hardhat-template) repository:

```bash
git clone https://github.com/zama-ai/fhevm-hardhat-template conf-token
cd conf-token
```

Install dependencies:
```bash
npm ci
```

Install OpenZeppelin's smart contract library:
```bash
npm i @openzeppelin/confidential-contracts
```

Compile contracts:

```bash
npm run compile
```

Run tests:

```bash
npm test
```

## Contents:

- ERC7984: [`erc7984.md`](erc7984.md)
- ERC7984 Tutorial: [`erc7984-tutorial.md`](erc7984-tutorial.md)
- ERC7984 to ERC20 Wrapper [`ERC7984ERC20WrapperMock.md`](ERC7984ERC20WrapperMock.md)
- Swap ERC7984 to ERC20: [`swapERC7984ToERC20.md](swapERC7984ToERC20.md)
- Swap ERC7984 to ERC7984: [`swapERC7984ToERC20.md](swapERC7984ToERC7984.md)
- Vesting Wallet: [`vesting-wallet.md`](vesting-wallet.md)
