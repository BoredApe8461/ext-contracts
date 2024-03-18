// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import "../src/EnglishAuction.sol";

contract DeployEnglishAuction is Script {
    function run() public {
        vm.startBroadcast();
        
        // Deploy the EnglishAuction contract
        EnglishAuction auction = new EnglishAuction();
        console.log("EnglishAuction deployed at:", address(auction));

        vm.stopBroadcast();
    }
}
