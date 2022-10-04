// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Staking {
    using SafeERC20 for IERC20;
    address public owner;

    struct Stats {
        uint totalStaked;
        uint totalDistributed;
        uint rewardRate;
        address stakingToken;
        uint64 lastRewardTimestamp;
        address rewardToken;
        uint tokenPerShare;
    }
    struct User {
        uint staked;
        uint claimed;
        uint rewardDept;
    }

    Stats public pool;

    mapping(address => User) public staker;
    // Modifiers
    modifier onlyOwner() {
        // require(msg.sender == i_owner);
        if (msg.sender != owner) revert Unauthorized("Not an owner");
        _;
    }

    // Events
    // This generates a public event on the blockchain that will notify clients
    event Staked(address indexed staker, uint256 amount);
    event Withdrawn(address indexed staker, uint256 amount);
    event Claimed(address indexed staker, uint256 amount);

    // Functions Order:
    //// constructor
    //// receive
    //// fallback
    //// external
    //// public
    //// internal
    //// private
    //// view / pure
    error Unauthorized(string);

    constructor(
        address _stakingToken,
        address _rewardToken,
        uint _rewardRate
    ) {
        pool.stakingToken = _stakingToken;
        pool.lastRewardTimestamp = uint64(block.timestamp);
        pool.rewardToken = _rewardToken;
        pool.rewardRate = _rewardRate;
    }

    function deposit(uint amount) public {
        require(amount > 0, "Invalid amount");
        _updateRewards();
        IERC20(pool.stakingToken).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
        pool.totalStaked += amount;
        staker[msg.sender].staked += amount;
        staker[msg.sender].rewardDept +=
            staker[msg.sender].staked *
            pool.tokenPerShare;
        emit Staked(msg.sender, amount);
    }

    function withdraw() public {
        uint amount = staker[msg.sender].staked;
        require(amount > 0, "Nothing to withdraw");
        _updateRewards();
        IERC20(pool.stakingToken).safeTransfer(msg.sender, amount);
        pool.totalStaked -= amount;
        staker[msg.sender].staked = 0;
        staker[msg.sender].rewardDept +=
            staker[msg.sender].staked *
            pool.tokenPerShare;
        emit Withdrawn(msg.sender, amount);
    }

    function harvest() public {
        _updateRewards();
        uint available = staker[msg.sender].staked *
            pool.tokenPerShare -
            staker[msg.sender].rewardDept;
        require(available > 0, "Nothing to harvest");
        IERC20(pool.rewardToken).safeTransfer(msg.sender, available);
        pool.totalDistributed += available;
        staker[msg.sender].claimed += available;
        emit Claimed(msg.sender, available);
    }

    function _updateRewards() internal {
        if (block.timestamp > pool.lastRewardTimestamp) {
            if (pool.totalStaked > 0) {
                uint multiplier = block.timestamp - pool.lastRewardTimestamp;
                uint reward = (multiplier * pool.rewardRate) / 3600;
                pool.tokenPerShare += reward / pool.totalStaked;
            }
        }
        pool.lastRewardTimestamp = uint64(block.timestamp);
    }

    function pendingReward(address user) external view returns (uint) {
        if (
            block.timestamp > pool.lastRewardTimestamp && pool.totalStaked > 0
        ) {
            uint multiplier = block.timestamp - pool.lastRewardTimestamp;
            uint reward = (multiplier * pool.rewardRate) / 3600;
            uint share = pool.tokenPerShare + reward / pool.totalStaked;
            return (share * staker[user].staked) - staker[user].rewardDept;
        } else {
            return
                (pool.tokenPerShare * staker[user].staked) -
                staker[user].rewardDept;
        }
    }
}
