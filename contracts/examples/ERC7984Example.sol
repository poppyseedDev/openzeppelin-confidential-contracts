// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity ^0.8.24;

import {Ownable2Step, Ownable} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {FHE, externalEuint64, euint64} from "@fhevm/solidity/lib/FHE.sol";
import {SepoliaConfig} from "@fhevm/solidity/config/ZamaConfig.sol";
import {ERC7984} from "../token/ERC7984/ERC7984.sol";

contract ERC7984Example is SepoliaConfig, ERC7984, Ownable2Step {
    constructor(
        address owner,
        uint64 amount,
        string memory name_,
        string memory symbol_,
        string memory tokenURI_
    ) ERC7984(name_, symbol_, tokenURI_) Ownable(owner) {
        euint64 encryptedAmount = FHE.asEuint64(amount);
        _mint(owner, encryptedAmount);
    }
}