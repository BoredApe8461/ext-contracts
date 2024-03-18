// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import  "../src/MockNFT.sol";

contract DeployDenverAuctionNFT is Script {

    function run() public {
        vm.startBroadcast();
        
        // Deploy the DenverAuctionNFT contract with the deployer's address as the initial owner
        MockNFT nft = new MockNFT(msg.sender);
        console.log("MockNFT deployed at:", address(nft));

        vm.stopBroadcast();
    }
}
