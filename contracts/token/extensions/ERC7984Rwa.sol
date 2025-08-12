// SPDX-License-Identifier: MIT

pragma solidity ^0.8.27;

import {FHE, externalEuint64, euint64} from "@fhevm/solidity/lib/FHE.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC165, IERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {Multicall} from "@openzeppelin/contracts/utils/Multicall.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {IERCXXXXCRwa} from "./../../interfaces/draft-IERCXXXXCRwa.sol";
import {ConfidentialFungibleToken} from "./../ConfidentialFungibleToken.sol";

/**
 * @dev Extension of {ConfidentialFungibleToken} supporting confidential Real World Assets.
 */
abstract contract ERC7984Rwa is ConfidentialFungibleToken, Ownable, Pausable, Multicall, ERC165 {
    /// @dev The caller account is not authorized to perform the operation.
    error UnauthorizedSender(address account);
    /// @dev The transfer does not follow token compliance.
    error UncompliantTransfer(address from, address to, euint64 encryptedAmount);

    constructor() {}

    /// @dev Checks the sender is the owner or an authorized agent.
    modifier onlyOwnerOrAgent() {
        require(
            _msgSender() == owner(),
            //TODO: Add agent condition
            UnauthorizedSender(_msgSender())
        );
        _;
    }

    /// @inheritdoc ERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERCXXXXCRwa).interfaceId || super.supportsInterface(interfaceId);
    }

    /// @dev Pauses contract.
    function pause() public virtual onlyOwnerOrAgent {
        _pause();
    }

    /// @dev Unpauses contract.
    function unpause() public virtual onlyOwnerOrAgent {
        _unpause();
    }

    /// @dev Mints confidential amount of tokens to account with proof.
    function mint(
        address to,
        externalEuint64 encryptedAmount,
        bytes calldata inputProof
    ) public virtual returns (euint64) {
        return mint(to, FHE.fromExternal(encryptedAmount, inputProof));
    }

    /// @dev Mints confidential amount of tokens to account.
    function mint(address to, euint64 encryptedAmount) public virtual onlyOwnerOrAgent returns (euint64) {
        return _mint(to, encryptedAmount);
    }

    /// @dev Burns confidential amount of tokens from account with proof.
    function burn(
        address account,
        externalEuint64 encryptedAmount,
        bytes calldata inputProof
    ) public virtual returns (euint64) {
        return burn(account, FHE.fromExternal(encryptedAmount, inputProof));
    }

    /// @dev Burns confidential amount of tokens from account.
    function burn(address account, euint64 encryptedAmount) public virtual onlyOwnerOrAgent returns (euint64) {
        return _burn(account, encryptedAmount);
    }

    /// @dev Forces transfer of confidential amount of tokens from account to account with proof by skipping compliance checks.
    function forceTransfer(
        address from,
        address to,
        externalEuint64 encryptedAmount,
        bytes calldata inputProof
    ) public virtual returns (euint64) {
        return forceTransfer(from, to, FHE.fromExternal(encryptedAmount, inputProof));
    }

    /// @dev Forces transfer of confidential amount of tokens from account to account by skipping compliance checks.
    function forceTransfer(
        address from,
        address to,
        euint64 encryptedAmount
    ) public virtual onlyOwnerOrAgent returns (euint64) {
        //TODO: Add checks
        return super._update(from, to, encryptedAmount);
    }

    function _update(
        address from,
        address to,
        euint64 encryptedAmount
    ) internal override whenNotPaused returns (euint64) {
        //TODO: Add checks
        require(_isCompliantTransfer(from, to, encryptedAmount), UncompliantTransfer(from, to, encryptedAmount));
        return super._update(from, to, encryptedAmount);
    }

    /// @dev Checks if a transfer follows token compliance.
    function _isCompliantTransfer(address from, address to, euint64 encryptedAmount) internal virtual returns (bool);
}
