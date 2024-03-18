// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

contract EnglishAuction {
    struct Auction {
        IERC721 nft;
        uint nftId;
        address payable seller;
        uint startingBid;
        uint endAt;
        bool started;
        bool ended;
        address highestBidder;
        uint highestBid;
        uint reservePrice;
        bool cancelled;
    }

    uint public auctionCount;
    mapping(uint => Auction) public auctions;
    mapping(uint => mapping(address => uint)) public bids;
    mapping(address => uint[]) public ownerToAuctions; // Maps an owner to their auction IDs

    event AuctionCreatedAndStarted(uint indexed auctionId, address indexed seller, uint duration, uint reservePrice);
    event Bid(uint indexed auctionId, address indexed sender, uint amount);
    event Withdraw(uint indexed auctionId, address indexed bidder, uint amount);
    event End(uint indexed auctionId, address winner, uint amount);
    event Cancel(uint indexed auctionId);

    function createAndStartAuction(
        IERC721 _nft, 
        uint _nftId, 
        uint _startingBid, 
        uint _duration, 
        uint _reservePrice
    ) external {
        require(_duration > 0, "Duration should be greater than zero");

        // Additional check to prevent duplicate auctions for the same NFT
        for (uint i = 1; i <= auctionCount; i++) {
            require(!(auctions[i].nft == _nft && auctions[i].nftId == _nftId && !auctions[i].ended), "Auction for NFT already exists");
        }

        Auction storage auction = auctions[++auctionCount];

        // auction.auctionId = auctionCount;
        auction.nft = IERC721(_nft);
        auction.nftId = _nftId;
        auction.seller = payable(msg.sender);
        auction.startingBid = _startingBid;
        auction.endAt = block.timestamp + _duration;
        auction.reservePrice = _reservePrice;
        auction.started = true; // Mark the auction as started
        auction.ended = false;
        auction.highestBidder = address(0);
        auction.highestBid = 0;
        auction.cancelled = false;

        // Transfer the NFT from the seller to the contract
        auction.nft.transferFrom(msg.sender, address(this), auction.nftId);

        // Update mapping of owner to auctions
        ownerToAuctions[msg.sender].push(auctionCount);

        emit AuctionCreatedAndStarted(auctionCount, msg.sender, _duration, _reservePrice);
    }

    function bid(uint _auctionId) external payable {
        Auction storage auction = auctions[_auctionId];
        require(auction.started, "Not started");
        require(block.timestamp < auction.endAt, "Ended");
        require(!auction.cancelled, "Cancelled");
        require(msg.value >= auction.startingBid && msg.value > auction.highestBid, "Bid too low");

        if (auction.highestBidder != address(0)) {
            bids[_auctionId][auction.highestBidder] += auction.highestBid;
        }

        auction.highestBidder = msg.sender;
        auction.highestBid = msg.value;

        emit Bid(_auctionId, msg.sender, msg.value);
    }

    function withdraw(uint _auctionId) external {
        uint amount = bids[_auctionId][msg.sender];
        require(amount > 0, "No funds to withdraw");

        bids[_auctionId][msg.sender] = 0;
        payable(msg.sender).transfer(amount);

        emit Withdraw(_auctionId, msg.sender, amount);
    }

    function cancel(uint _auctionId) external {
        Auction storage auction = auctions[_auctionId];
        require(msg.sender == auction.seller, "Not seller");
        require(!auction.ended, "Already ended");
        require(!auction.cancelled, "Already cancelled");

        auction.cancelled = true;
        auction.ended = true; // To prevent restarts
        if (auction.highestBidder != address(0)) {
            // Refund the highest bidder if there was a bid
            bids[_auctionId][auction.highestBidder] += auction.highestBid;
        }

        // Return the NFT to the seller
        auction.nft.safeTransferFrom(address(this), auction.seller, auction.nftId);

        emit Cancel(_auctionId);
    }

    function end(uint _auctionId) external {
        Auction storage auction = auctions[_auctionId];
        require(auction.started, "Not started");
        require(block.timestamp >= auction.endAt || auction.cancelled, "Not ended");
        require(!auction.ended, "Already ended");

        auction.ended = true;
        if (auction.highestBidder != address(0) && auction.highestBid >= auction.reservePrice && !auction.cancelled) {
            // Transfer NFT to the highest bidder and funds to the seller
            auction.nft.safeTransferFrom(address(this), auction.highestBidder, auction.nftId);
            //auction.seller.transfer(auction.highestBid);
            (bool sent, ) = auction.seller.call{value: auction.highestBid}("");
            require(sent, "Failed to send Ether");
        } else {
            // No valid bids or auction cancelled, return NFT to seller
            auction.nft.safeTransferFrom(address(this), auction.seller, auction.nftId);
            // Refund the highest bidder if there was a bid
            if (auction.highestBidder != address(0)) {
                bids[_auctionId][auction.highestBidder] += auction.highestBid;
            }
        }

        emit End(_auctionId, auction.highestBidder, auction.highestBid);
    }

    // State check functions
    function auction_info(uint _auctionId) external view returns (Auction memory) {
        return auctions[_auctionId];
    }

    // New function to view all auctions
    function getAllAuctions() external view returns (Auction[] memory) {
        Auction[] memory allAuctions = new Auction[](auctionCount);
        for (uint i = 1; i <= auctionCount; i++) {
            allAuctions[i - 1] = auctions[i];
        }
        return allAuctions;
    }

    // New function to view all auctions created by a specific address
    function getAuctionsByOwner(address owner) external view returns (Auction[] memory) {
        uint[] memory auctionIds = ownerToAuctions[owner];
        Auction[] memory ownerAuctions = new Auction[](auctionIds.length);
        for (uint i = 0; i < auctionIds.length; i++) {
            ownerAuctions[i] = auctions[auctionIds[i]];
        }
        return ownerAuctions;
    }

    function deposit_balance(uint _auctionId, address user) external view returns (uint) {
        return bids[_auctionId][user];
    }

    // New function to view the winning bidder of a specific NFT if the auction has ended
    function getNftBuyer(uint nftId) external view returns (address) {
        for (uint i = 1; i <= auctionCount; i++) {
            if (auctions[i].nftId == nftId && auctions[i].ended) {
                return auctions[i].highestBidder;
            }
        }
        revert("No completed auction found for this NFT");
    }

    function total_auctions() external view returns (uint) {
        return auctionCount;
    }

    // Function to check if an auction is already over
    function isAuctionOver(uint _auctionId) external view returns (bool) {
        Auction storage auction = auctions[_auctionId];
        require(_auctionId <= auctionCount, "Auction does not exist."); // Make sure the auction exists
        return (block.timestamp >= auction.endAt || auction.ended || auction.cancelled);
    }

}
