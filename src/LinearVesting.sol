// SPDX-License-Identifier: MIT
pragma solidity 0.8.36;

contract LinearVesting {
    error InvalidBeneficiary();
    error InvalidSchedule();
    error EmptyGrant();
    error NothingToRelease();
    error TransferFailed();

    address payable public immutable beneficiary;
    uint256 public immutable allocation;
    uint256 public immutable startsAt;
    uint256 public immutable endsAt;
    uint256 public released;

    event Released(uint256 amount);

    constructor(address payable recipient, uint64 start, uint64 duration) payable {
        if (recipient == address(0)) revert InvalidBeneficiary();
        if (duration == 0) revert InvalidSchedule();
        if (start < block.timestamp) revert InvalidSchedule();
        if (msg.value == 0) revert EmptyGrant();

        beneficiary = recipient;
        allocation = msg.value;
        startsAt = start;
        endsAt = uint256(start) + duration;
    }

    function vestedAt(uint256 timestamp) public view returns (uint256) {
        if (timestamp <= startsAt) return 0;
        if (timestamp >= endsAt) return allocation;

        // Decompose the multiplication to keep every intermediate within uint256.
        uint256 duration = endsAt - startsAt;
        uint256 elapsed = timestamp - startsAt;
        return (allocation / duration) * elapsed + (allocation % duration) * elapsed / duration;
    }

    function release() external {
        uint256 vested = vestedAt(block.timestamp);
        uint256 amount = vested - released;
        if (amount == 0) revert NothingToRelease();

        released = vested;
        emit Released(amount);
        (bool sent,) = beneficiary.call{value: amount}("");
        if (!sent) revert TransferFailed();
    }
}
