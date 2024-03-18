// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC721 {
    function mint(address to, uint256 tokenId) external;
    function burn(uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract CoretimeRegions {
    // Events
    event RegionInitialized(uint256 indexed regionId, bytes metadata, uint version);
    event RegionRemoved(uint256 indexed regionId);

    // Constants & state variables
    uint256 public constant REGIONS_COLLECTION_ID = 42;
    mapping(uint256 => bytes) private regions; // Maps region ID to metadata
    mapping(uint256 => uint) private metadataVersions; // Tracks metadata version for each region

    IERC721 public nftContract; // Assuming an external NFT contract manages the actual tokens

    // Constructor to set NFT contract address
    constructor(address _nftContractAddress) {
        nftContract = IERC721(_nftContractAddress);
    }

    // Function to initialize region similar to Rust's init
    function initializeRegion(uint256 regionId, bytes calldata metadata) public {
        require(nftContract.ownerOf(regionId) == msg.sender, "Caller is not the owner");
        require(regions[regionId].length == 0, "Region already initialized");

        // Increment the metadata version or initialize it
        metadataVersions[regionId]++;
        
        // Update the regions mapping with the new metadata
        regions[regionId] = metadata;

        // Emit an event for the region initialization
        emit RegionInitialized(regionId, metadata, metadataVersions[regionId]);

        // NFT operations are handled outside this contract, we assume they're done before/after calling this
    }

    // Function to remove a region similar to Rust's remove
    function removeRegion(uint256 regionId) public {
        require(nftContract.ownerOf(regionId) == msg.sender, "Caller is not the owner");

        // Emit an event for region removal before clearing data
        emit RegionRemoved(regionId);

        // Clear metadata and decrement version
        delete regions[regionId];
        if (metadataVersions[regionId] > 0) {
            metadataVersions[regionId]--;
        }

        // NFT burning or transferring is handled externally
    }

    // Function to get region metadata
    function getRegionMetadata(uint256 regionId) public view returns (bytes memory metadata, uint version) {
        require(regions[regionId].length != 0, "Region not initialized");
        return (regions[regionId], metadataVersions[regionId]);
    }
}
