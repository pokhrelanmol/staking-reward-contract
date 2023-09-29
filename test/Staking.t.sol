// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Staking} from "../src/Staking.sol";
import {MaxiToken} from "../src/MaxiToken.sol";
import {WETH} from "../src/WETH.sol";
import {Deploy} from "../script/Deploy.s.sol";

contract StakingTest is Test {
    Staking staking;
    MaxiToken maxi;
    WETH weth;
    address user1;
    address user2;
    address user3;
    address owner = 0x4520897eD8816a1F9C497F1591e75F2E64e98804;
    uint256 STAKE_AMOUNT = 1000e18;
    uint256 REWARD_AMOUNT = 10000e18;

    function setUp() public {
        Deploy deploy = new Deploy();
        (maxi, weth, staking, user1, user2, user3) = deploy.run();
        assertEq(maxi.balanceOf(user1), STAKE_AMOUNT);
        assertEq(maxi.balanceOf(user2), STAKE_AMOUNT);
        assertEq(maxi.balanceOf(user3), STAKE_AMOUNT);
        assertEq(staking.owner(), owner);
        assertEq(weth.balanceOf(address(staking)), REWARD_AMOUNT);
        vm.startPrank(owner);
        staking.notifyRewardAmount(REWARD_AMOUNT);
        vm.stopPrank();
    }

    function testStakeRevertIfAmountZero() public {
        vm.startPrank(user1);
        vm.expectRevert("Cannot stake 0");
        staking.stake(0);
        vm.stopPrank();
    }

    function testStake() public {
        vm.startPrank(user1);
        maxi.approve(address(staking), STAKE_AMOUNT);
        staking.stake(1000e18);
        assertEq(staking.rewardPerTokenStored(), 0); // upon first stake the total supply is 0 so rewardPerTokenStored is 0
        uint256 rewardRate = REWARD_AMOUNT / uint256(7 days); // How many reward token will recieve every sec

        assertEq(rewardRate, staking.rewardRate());
        assertEq(staking.finishAt(), block.timestamp + 7 days); //This is set because we called notifyRewardAmount in setup
        assertEq(staking.updatedAt(), block.timestamp);
        assertEq(staking.rewards(user1), 0); // Nothing is earned
        assertEq(staking.userRewardPerTokenPaid(user1), 0);
        vm.stopPrank();
    }

    function testGetRewardAfter5DaysForSingleUserStake() public {
        vm.startPrank(user1);
        maxi.approve(address(staking), STAKE_AMOUNT);
        staking.stake(STAKE_AMOUNT);
        vm.warp(5 days); // After 5 days user should have some reward
        uint256 rewardRate = REWARD_AMOUNT / uint256(7 days); // How many reward token will recieve every sec
        uint256 rewardPerToken = 0 + (rewardRate * (block.timestamp - 1)) * 1e18 / STAKE_AMOUNT;
        assertEq(staking.rewardPerToken(), rewardPerToken); // manual verification
        //Reward earned after 5 days
        uint256 earned = STAKE_AMOUNT * (rewardPerToken - 0) / 1e18 + 0; //@dev reward[user] is 0 because no action is taken after stake
        assertEq(staking.earned(user1), earned); // 7142 * 1e18 rewards
        //getReward
        staking.getReward();
        // console2.log("RewardPerTokenStored", staking.rewardPerTokenStored() / 1e18);
        assertEq(weth.balanceOf(user1), earned);
    }

    function testClaimRewardAfterDurationIsOver() public {
        vm.startPrank(user1);
        maxi.approve(address(staking), STAKE_AMOUNT);
        staking.stake(STAKE_AMOUNT);
        vm.stopPrank();
        //  Let's see what happen if we claim rewards after the 7 day duration is over
        vm.warp(7 days);
        // after 7 days the owner will notify and set new finishAt
        vm.startPrank(owner);
        weth.transfer(address(staking), REWARD_AMOUNT); // add new reward balance
        staking.notifyRewardAmount(REWARD_AMOUNT); // update reward and update finish time
        vm.stopPrank();
        // Still we have not claimed the previous rewards-
        vm.warp(2 days); //2 more days passes
        vm.startPrank(user1);
        console2.log(staking.earned(user1));
        // staking.stake(); // let's see how much we have
        vm.stopPrank();
    }
}
