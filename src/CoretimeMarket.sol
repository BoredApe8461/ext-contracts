// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC1155 {
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
}

contract CoretimeMarket {
    struct Listing {
        address seller;
        uint256 timeslicePrice;
        address saleRecipient;
        uint version;
    }

    event RegionListed(uint256 indexed regionId, uint256 timeslicePrice, address indexed seller, address saleRecipient, uint version);
    event RegionUnlisted(uint256 indexed regionId, address indexed caller);
    event RegionPurchased(uint256 indexed regionId, address indexed buyer, uint256 totalPrice);
    event RegionPriceUpdated(uint256 indexed regionId, uint256 newTimeslicePrice);

    mapping(uint256 => Listing) public listings;
    uint256[] public listedRegions;
    address public xcRegionsContract;
    uint256 public listingDeposit;
    uint256 public timeslicePeriod;

    constructor(address _xcRegionsContract, uint256 _listingDeposit, uint256 _timeslicePeriod) {
        xcRegionsContract = _xcRegionsContract;
        listingDeposit = _listingDeposit;
        timeslicePeriod = _timeslicePeriod;
    }

    function listRegion(uint256 regionId, uint256 timeslicePrice, address saleRecipient) external payable {
        require(msg.value == listingDeposit, "Incorrect deposit amount");
        require(listings[regionId].seller == address(0), "Region already listed");

        listings[regionId] = Listing({
            seller: msg.sender,
            timeslicePrice: timeslicePrice,
            saleRecipient: saleRecipient == address(0) ? msg.sender : saleRecipient,
            version: 0 // Assuming version handling is done outside this contract
        });
        listedRegions.push(regionId);

        emit RegionListed(regionId, timeslicePrice, msg.sender, saleRecipient, 0); // Version is set to 0 for simplicity
    }

    function unlistRegion(uint256 regionId) external {
        require(listings[regionId].seller == msg.sender, "Only seller can unlist the region");
        
        delete listings[regionId];
        for (uint i = 0; i < listedRegions.length; i++) {
            if (listedRegions[i] == regionId) {
                listedRegions[i] = listedRegions[listedRegions.length - 1];
                listedRegions.pop();
                break;
            }
        }

        payable(msg.sender).transfer(listingDeposit);
        emit RegionUnlisted(regionId, msg.sender);
    }

    function updateRegionPrice(uint256 regionId, uint256 newTimeslicePrice) external {
        require(listings[regionId].seller == msg.sender, "Only seller can update price");
        listings[regionId].timeslicePrice = newTimeslicePrice;

        emit RegionPriceUpdated(regionId, newTimeslicePrice);
    }

    function purchaseRegion(uint256 regionId) external payable {
        Listing memory listing = listings[regionId];
        require(listing.seller != address(0), "Region not listed");
        require(msg.value >= listing.timeslicePrice, "Insufficient funds");

        payable(listing.saleRecipient).transfer(msg.value);
        IERC1155(xcRegionsContract).safeTransferFrom(address(this), msg.sender, regionId, 1, "");

        delete listings[regionId];
        for (uint i = 0; i < listedRegions.length; i++) {
            if (listedRegions[i] == regionId) {
                listedRegions[i] = listedRegions[listedRegions.length - 1];
                listedRegions.pop();
                break;
            }
        }

        emit RegionPurchased(regionId, msg.sender, msg.value);
    }

    // Additional contract methods and logic...
}
