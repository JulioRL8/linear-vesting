// SPDX-License-Identifier: MIT
pragma solidity 0.8.36;

import {LinearVesting} from "../src/LinearVesting.sol";
import {TestBase} from "./TestBase.sol";

contract LinearVestingTest is TestBase {
    address payable private constant BENEFICIARY = payable(address(0xB0B));
    LinearVesting private vesting;

    function setUp() public {
        vm.deal(address(this), 20 ether);
        vm.warp(100);
        vesting = new LinearVesting{value: 9 ether}(BENEFICIARY, 200, 90);
    }

    function testRejectsZeroBeneficiary() public {
        vm.expectRevert(LinearVesting.InvalidBeneficiary.selector);
        new LinearVesting{value: 1}(payable(address(0)), 200, 90);
    }

    function testRejectsZeroDuration() public {
        vm.expectRevert(LinearVesting.InvalidSchedule.selector);
        new LinearVesting{value: 1}(BENEFICIARY, 200, 0);
    }

    function testRejectsPastStart() public {
        vm.expectRevert(LinearVesting.InvalidSchedule.selector);
        new LinearVesting{value: 1}(BENEFICIARY, 99, 90);
    }

    function testRejectsEmptyGrant() public {
        vm.expectRevert(LinearVesting.EmptyGrant.selector);
        new LinearVesting(BENEFICIARY, 200, 90);
    }

    function testReleasesOnlyNewlyVestedFunds() public {
        assertEq(vesting.vestedAt(200), 0);
        vm.expectRevert(LinearVesting.NothingToRelease.selector);
        vesting.release();

        vm.warp(230);
        vesting.release();
        assertEq(BENEFICIARY.balance, 3 ether);
        assertEq(vesting.released(), 3 ether);
        vm.expectRevert(LinearVesting.NothingToRelease.selector);
        vesting.release();

        vm.warp(290);
        vesting.release();
        assertEq(BENEFICIARY.balance, 9 ether);
        assertEq(vesting.released(), 9 ether);
        assertEq(address(vesting).balance, 0);
    }

    function testRevertedTransferPreservesAccounting() public {
        LinearVesting rejected = new LinearVesting{value: 1 ether}(payable(address(this)), 200, 90);
        vm.warp(290);
        vm.expectRevert(LinearVesting.TransferFailed.selector);
        rejected.release();
        assertEq(rejected.released(), 0);
        assertEq(address(rejected).balance, 1 ether);
    }

    function testFuzzVestingRoundsDown(uint8 rawElapsed, uint96 grant) public {
        vm.assume(grant > 0);
        vm.deal(address(this), grant);
        LinearVesting rounded = new LinearVesting{value: grant}(BENEFICIARY, 200, 90);
        uint256 elapsed = uint256(rawElapsed) % 91;
        assertEq(rounded.vestedAt(200 + elapsed), uint256(grant) * elapsed / 90);
    }
}
