// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/NFTMarketplace.sol";

contract InteractScript is Script {
    function run() external {
        // 获取合约地址（从环境变量或使用默认值）
        address contractAddress = vm.envOr("CONTRACT_ADDRESS", address(0));
        require(contractAddress != address(0), "Please set CONTRACT_ADDRESS environment variable");
        
        // 获取用户私钥
        uint256 user1PrivateKey = vm.envOr("USER1_PRIVATE_KEY", uint256(0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d));
        uint256 user2PrivateKey = vm.envOr("USER2_PRIVATE_KEY", uint256(0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a));
        
        NFTMarketplace marketplace = NFTMarketplace(contractAddress);
        
        // 创建用户地址变量以避免stack too deep
        address user1 = vm.addr(user1PrivateKey);
        address user2 = vm.addr(user2PrivateKey);
        
        console.log("=== NFT Marketplace Interaction Demo ===");
        console.log("Contract Address:", contractAddress);
        
        // 用户1铸造NFT
        vm.startPrank(user1);
        console.log("\n--- User 1 minting NFT ---");
        string memory tokenURI = "ipfs://QmExample123";
        uint256 tokenId = marketplace.mintNFT(tokenURI);
        console.log("NFT minted with ID:", tokenId);
        console.log("Token URI:", tokenURI);
        console.log("Owner:", marketplace.ownerOf(tokenId));
        
        // 用户1创建市场项目
        console.log("\n--- User 1 creating market item ---");
        uint256 price = 0.1 ether;
        marketplace.createMarketItem(tokenId, price);
        console.log("Market item created with price:", vm.toString(price));
        
        vm.stopPrank();
        
        // 用户2购买NFT
        vm.startPrank(user2);
        console.log("\n--- User 2 buying NFT ---");
        console.log("User 2 balance before:", vm.toString(user2.balance));
        marketplace.buyMarketItem{value: price}(tokenId);
        console.log("NFT purchased successfully!");
        console.log("New owner:", marketplace.ownerOf(tokenId));
        console.log("User 2 balance after:", vm.toString(user2.balance));
        
        vm.stopPrank();
        
        // 用户2铸造新NFT并创建拍卖
        vm.startPrank(user2);
        console.log("\n--- User 2 creating auction ---");
        string memory auctionTokenURI = "ipfs://QmExample456";
        uint256 auctionTokenId = marketplace.mintNFT(auctionTokenURI);
        console.log("New NFT minted for auction with ID:", auctionTokenId);
        
        uint256 startingPrice = 0.05 ether;
        uint256 duration = 1 hours;
        marketplace.createAuction(auctionTokenId, startingPrice, duration);
        console.log("Auction created with starting price:", vm.toString(startingPrice));
        console.log("Auction duration:", vm.toString(duration), "seconds");
        
        vm.stopPrank();
        
        // 用户1出价
        vm.startPrank(user1);
        console.log("\n--- User 1 placing bid ---");
        uint256 bidAmount = 0.08 ether;
        console.log("User 1 balance before bid:", vm.toString(user1.balance));
        marketplace.placeBid{value: bidAmount}(auctionTokenId);
        console.log("Bid placed successfully:", vm.toString(bidAmount));
        console.log("User 1 balance after bid:", vm.toString(user1.balance));
        
        vm.stopPrank();
        
        // 时间快进到拍卖结束
        console.log("\n--- Time warping to end auction ---");
        vm.warp(block.timestamp + duration + 1);
        console.log("Current time:", block.timestamp);
        
        // 结束拍卖
        vm.prank(user2);
        marketplace.endAuction(auctionTokenId);
        console.log("Auction ended successfully!");
        
        // 显示最终状态
        console.log("\n--- Final State ---");
        console.log("Auction NFT owner:", marketplace.ownerOf(auctionTokenId));
        console.log("User 1 balance:", vm.toString(user1.balance));
        console.log("User 2 balance:", vm.toString(user2.balance));
        
        console.log("\n=== Demo Completed Successfully ===");
    }
}
