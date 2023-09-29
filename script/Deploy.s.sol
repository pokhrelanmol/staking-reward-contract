// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {MaxiToken} from "../src/MaxiToken.sol";
import {WETH} from "../src/WETH.sol";
import {Staking} from "../src/Staking.sol";

contract Deploy is Script {
    function run() public returns (MaxiToken, WETH, Staking, address, address, address) {
        address user1 = address(1);
        address user2 = address(2);
        address user3 = address(3);
        uint256 deployerPvKey = 0x9ed017d2ce6ba1bbdbe3a7eecba4754087cd4d4f532ef6477f9870b99925eeb6;
        vm.startBroadcast(deployerPvKey);
        MaxiToken maxi = new MaxiToken();
        WETH weth = new WETH();
        Staking staking = new Staking(address(maxi), address(weth), 7 days);

        maxi.mint(user1, 1000e18);
        maxi.mint(user2, 1000e18);
        maxi.mint(user3, 1000e18);

        weth.transfer(address(staking), 10000e18); // deposit reward token

        vm.stopBroadcast();

        return (maxi, weth, staking, user1, user2, user3);
    }
}
