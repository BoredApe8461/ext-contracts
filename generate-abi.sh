# Extract ABI
jq '.abi' out/DenverAuctionNFT.sol/DenverAuctionNFT.json > abi/DenverAuctionNFT.abi
jq '.abi' out/EnglishAuction.sol/EnglishAuction.json > abi/EnglishAuction.abi
jq '.abi' out/EnglishAuction.sol/IERC721.json > abi/IERC721.abi

# Extract Bytecode
jq -r '.bytecode.object' out/DenverAuctionNFT.sol/DenverAuctionNFT.json > abi/DenverAuctionNFT.bin
jq -r '.bytecode.object' out/EnglishAuction.sol/EnglishAuction.json > abi/EnglishAuction.bin
jq -r '.bytecode.object' out/EnglishAuction.sol/IERC721.json > abi/IERC721.bin
