// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ESOP {
    address public owner;
    uint256 public totalShares;
    mapping(address => uint256) public balances;
    mapping(address => VestingSchedule[]) public vestingSchedules;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event SharesIssued(address indexed recipient, uint256 amount);
    event VestingScheduled(address indexed recipient, uint256 amount, uint256 vestingStart, uint256 vestingDuration);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    struct VestingSchedule {
        uint256 amount;
        uint256 vestingStart;
        uint256 vestingDuration;
    }

    constructor() {
        owner = msg.sender;
        totalShares = 1000; // Initial total shares
        balances[owner] = totalShares;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid new owner");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function issueShares(address recipient, uint256 amount) external onlyOwner {
        require(recipient != address(0), "Invalid recipient");
        require(amount > 0 && amount <= totalShares, "Invalid amount");
        balances[owner] -= amount;
        balances[recipient] += amount;
        emit SharesIssued(recipient, amount);
    }

    function scheduleVesting(address recipient, uint256 amount, uint256 vestingStart, uint256 vestingDuration) external onlyOwner {
        require(recipient != address(0), "Invalid recipient");
        require(amount > 0 && amount <= totalShares, "Invalid amount");
        require(vestingStart >= block.timestamp, "Vesting start must be in the future");
        require(vestingDuration > 0, "Invalid vesting duration");

        VestingSchedule memory newSchedule = VestingSchedule(amount, vestingStart, vestingDuration);
        vestingSchedules[recipient].push(newSchedule);

        emit VestingScheduled(recipient, amount, vestingStart, vestingDuration);
    }

    function claimVestedShares() external {
        uint256 totalVestedShares;
        VestingSchedule[] storage schedules = vestingSchedules[msg.sender];

        for (uint256 i = 0; i < schedules.length; i++) {
            VestingSchedule storage schedule = schedules[i];
            uint256 vestedShares = calculateVestedShares(schedule);
            
            if (vestedShares > 0) {
                totalVestedShares += vestedShares;
                schedule.amount -= vestedShares;
            }
        }

        require(totalVestedShares > 0, "No vested shares to claim");
        balances[msg.sender] += totalVestedShares;
        emit SharesIssued(msg.sender, totalVestedShares);
    }

    function calculateVestedShares(VestingSchedule memory schedule) internal view returns (uint256) {
        uint256 currentTime = block.timestamp;
        if (currentTime < schedule.vestingStart) {
            return 0;
        } else if (currentTime >= schedule.vestingStart + schedule.vestingDuration) {
            return schedule.amount;
        } else {
            uint256 elapsedTime = currentTime - schedule.vestingStart;
            uint256 vestedShares = (schedule.amount * elapsedTime) / schedule.vestingDuration;
            return vestedShares;
        }
    }
}