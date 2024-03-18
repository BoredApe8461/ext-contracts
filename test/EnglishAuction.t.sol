// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import "../src/MockNFT.sol";
import "../src/EnglishAuction.sol";

contract MockERC721Receiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

contract DenverAuctionNFTTest is Test {
    MockNFT nft;

    function setUp() public {
        nft = new DenverAuctionNFT(address(this)); // Deploy the NFT contract
    }

    function testFailMintNotOwner() public {
        vm.prank(address(0)); // Simulate call from another address
        nft.safeMint(address(this), 1); // Should fail
    }
}

contract EnglishAuctionTest is Test, MockERC721Receiver {
    EnglishAuction auction;
    DenverAuctionNFT nft;

    function setUp() public {
        nft = new DenverAuctionNFT(address(this)); // Deploy the NFT contract
        nft.safeMint(address(this), 1); // Mint an NFT to this contract
        auction = new EnglishAuction(); // Deploy the auction contract without parameters
    }

    function testCreateAndStartAuction() public {
        nft.approve(address(auction), 1); // Approve the auction contract to take the NFT
        auction.createAndStartAuction(IERC721(address(nft)), 1, 1 ether, 2 days, 1.5 ether); // Correctly call createAndStartAuction
        uint auctionId = auction.auctionCount(); // Get the newly created auction ID
        assertTrue(auctionId > 0, "Auction should be created"); // Check that an auction was created

        EnglishAuction.Auction memory auctionInfo = auction.auction_info(auctionId);
        assertTrue(auctionInfo.started, "Auction should have started"); // Check that the auction has started
    }


    function testSuccessfulBid() public {
        testCreateAndStartAuction();
        uint auctionId = auction.auctionCount();
        
        address bidder1 = address(0x123);
        address bidder2 = address(0x456);

        // Bid by bidder1
        vm.deal(bidder1, 2 ether); // Provide some ether to the bidder address
        vm.prank(bidder1); // Simulate bidder1's address
        auction.bid{value: 2 ether}(auctionId); // Bid with 1.1 ether

        // Bid by bidder2
        vm.deal(bidder2, 3 ether); // Provide some ether to the bidder address
        vm.prank(bidder2); // Simulate bidder2's address
        auction.bid{value: 3 ether}(auctionId); // Bid with 2 ether

        // // Move forward in time to after the auction end
        vm.warp(block.timestamp + 4 days);
        auction.auction_info(auctionId).ended == true;

        uint contractBalance = address(auction).balance;
        emit log_named_uint("Auction contract balance is", contractBalance);
        assertEq(contractBalance, 5 ether, "The contract's balance should be 2 ether");

        // // End the auction
        // auction.end(auctionId);

        // // Check final auction state
        // EnglishAuction.Auction memory endedAuction = auction.auction_info(auctionId);
        // assertEq(endedAuction.highestBidder, bidder2, "Bidder 2 should have won the auction");
        // assertEq(endedAuction.highestBid, 2 ether, "Highest bid should be 2 ether");
    }

    // function testWithdrawalAfterBid() public {
    //     testSuccessfulBid();
    //     uint auctionId = auction.auctionCount();

    //     address bidder1 = address(0x123);
    //     uint bidder1InitialBalance = bidder1.balance;

    //     // Bidder1 withdraws their bid
    //     vm.prank(bidder1); // Simulate bidder1's address
    //     auction.withdraw(auctionId);

    //     uint bidder1FinalBalance = bidder1.balance;
    //     //assert(bidder1FinalBalance > bidder1InitialBalance, "Bidder 1 should have withdrawn their funds");
    // }
}
