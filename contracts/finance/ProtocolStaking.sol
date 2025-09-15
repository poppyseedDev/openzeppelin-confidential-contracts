// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20Votes, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract ProtocolStaking is Ownable, ERC20Votes {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;

    struct UserStakingInfo {
        uint256 rewardsPerUnitPaid;
        uint256 rewards;
    }

    EnumerableSet.AddressSet private _operators;
    address private _stakingToken;
    uint256 private _totalStakedLog;
    uint256 private _lastUpdateBlock;
    uint256 private _rewardsPerUnit = 1;
    uint256 private _rewardRate;
    mapping(address => UserStakingInfo) private _userStakingInfo;

    event OperatorAdded(address operator);
    event OperatorRemoved(address operator);
    event TokensStaked(address operator, uint256 amount);
    event TokensUnstaked(address operator, uint256 amount);

    error InvalidAmount();
    error OperatorAlreadyExists(address operator);
    error OperatorDoesNotExist(address operator);

    constructor(
        string memory name,
        string memory symbol,
        string memory version,
        address governor
    ) Ownable(governor) ERC20(name, symbol) EIP712(name, version) {}

    function stake(uint256 amount) public virtual {
        _stake(amount);
    }

    function _stake(uint256 amount) internal virtual {
        _updateRewards();
        _updateRewards(msg.sender);

        require(amount != 0, InvalidAmount());

        if (isOperator(msg.sender)) {
            uint256 previousStakedAmount = balanceOf(msg.sender);
            uint256 newStakedAmount = previousStakedAmount + amount;

            _totalStakedLog = _totalStakedLog + log(newStakedAmount) - log(previousStakedAmount);
        }

        _mint(msg.sender, amount);
        IERC20(_stakingToken).safeTransferFrom(msg.sender, address(this), amount);

        emit TokensStaked(msg.sender, amount);
    }

    function unstake(uint256 amount) public virtual {
        _unstake(amount);
    }

    function _unstake(uint256 amount) internal virtual {
        _updateRewards();
        _updateRewards(msg.sender);

        require(amount != 0, InvalidAmount());

        if (isOperator(msg.sender)) {
            uint256 previousStakedAmount = balanceOf(msg.sender);
            uint256 newStakedAmount = previousStakedAmount - amount;

            _totalStakedLog = _totalStakedLog + log(newStakedAmount) - log(previousStakedAmount);
        }

        _burn(msg.sender, amount);
        IERC20(_stakingToken).safeTransfer(msg.sender, amount);

        emit TokensUnstaked(msg.sender, amount);
    }

    function earned(address account) public view virtual returns (uint256) {
        return _earned(account, log(balanceOf(account)));
    }

    function _earned(address account, uint256 logStakedAmount) internal view virtual returns (uint256) {
        UserStakingInfo memory userInfo = _userStakingInfo[account];
        if (userInfo.rewardsPerUnitPaid == 0) {
            return userInfo.rewards;
        }
        return (logStakedAmount * (_rewardsPerUnit - userInfo.rewardsPerUnitPaid)) / 1e18 + userInfo.rewards;
    }

    function claimRewards(address account) public virtual {
        _updateRewards();
        _updateRewards(account);

        // Ensure deposited tokens remain collateralized
        uint256 availableRewards = IERC20(_stakingToken).balanceOf(address(this)) - totalSupply();
        uint256 rewardsToPayOut = Math.min(_userStakingInfo[account].rewards, availableRewards);

        if (rewardsToPayOut > 0) {
            _userStakingInfo[account].rewards -= rewardsToPayOut;
            IERC20(_stakingToken).safeTransfer(account, rewardsToPayOut);
        }
    }

    function _updateRewards(address account) internal virtual {
        if (_userStakingInfo[account].rewardsPerUnitPaid == 0) return;
        _userStakingInfo[account] = UserStakingInfo({rewards: earned(account), rewardsPerUnitPaid: _rewardsPerUnit});
    }

    function _updateRewards() internal virtual {
        if (block.number == _lastUpdateBlock || totalSupply() == 0) {
            return;
        }

        uint256 blocksElapsed = block.number - _lastUpdateBlock;
        uint256 rewardsPerUnitDiff = (blocksElapsed * _rewardRate * 1e18) / _totalStakedLog;
        _rewardsPerUnit += rewardsPerUnitDiff;
        _lastUpdateBlock = block.number;
    }

    function operators() public view virtual returns (address[] memory) {
        return _operators.values();
    }

    function isOperator(address account) public view virtual returns (bool) {
        return _operators.contains(account);
    }

    function addOperator(address account) public virtual onlyOwner {
        require(_operators.add(account), OperatorAlreadyExists(account));

        _updateRewards();
        _userStakingInfo[account].rewardsPerUnitPaid = _rewardsPerUnit;

        _totalStakedLog += log(balanceOf(account));

        emit OperatorAdded(account);
    }

    function removeOperator(address account) public virtual onlyOwner {
        require(_operators.remove(account), OperatorDoesNotExist(account));

        _updateRewards();
        _updateRewards(account);
        _userStakingInfo[account].rewardsPerUnitPaid = 0;

        _totalStakedLog -= log(balanceOf(account));

        emit OperatorRemoved(account);
    }

    /// @dev Calculate the logarithm base 2 of the amount `amount`.
    function log(uint256 amount) public view virtual returns (uint256) {
        return Math.log2(amount);
    }

    /// @dev Returns the staking token which is used for staking and rewards.
    function stakingToken() public view virtual returns (address) {
        return _stakingToken;
    }

    // MARK: Disable Transfers
    function transfer(address, uint256) public virtual override returns (bool) {
        revert();
    }

    function transferFrom(address, address, uint256) public virtual override returns (bool) {
        revert();
    }
}
