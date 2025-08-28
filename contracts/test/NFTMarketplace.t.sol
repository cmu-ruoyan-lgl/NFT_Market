// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/NFTMarketplace.sol";

contract NFTMarketplaceTest is Test {
    NFTMarketplace public marketplace;
    address public owner;
    address public user1;
    address public user2;
    address public user3;
    
    uint256 public ownerPrivateKey;
    uint256 public user1PrivateKey;
    uint256 public user2PrivateKey;
    uint256 public user3PrivateKey;
    
    function setUp() public {
        // 生成测试账户
        (owner, ownerPrivateKey) = makeAddrAndKey("owner");
        (user1, user1PrivateKey) = makeAddrAndKey("user1");
        (user2, user2PrivateKey) = makeAddrAndKey("user2");
        (user3, user3PrivateKey) = makeAddrAndKey("user3");
        
        // 部署合约
        vm.prank(owner);
        marketplace = new NFTMarketplace();
        
        // 给测试账户一些ETH
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
        vm.deal(user3, 100 ether);
    }
    
    function testMintNFT() public {
        vm.startPrank(user1);
        
        string memory tokenURI = "ipfs://QmExample";
        uint256 tokenId = marketplace.mintNFT(tokenURI);
        
        assertEq(tokenId, 1);
        assertEq(marketplace.ownerOf(tokenId), user1);
        assertEq(marketplace.tokenURI(tokenId), tokenURI);
        
        vm.stopPrank();
    }
    
    function testCreateMarketItem() public {
        vm.startPrank(user1);
        
        // 先铸造NFT
        string memory tokenURI = "ipfs://QmExample";
        uint256 tokenId = marketplace.mintNFT(tokenURI);
        
        // 创建市场项目
        uint256 price = 1 ether;
        marketplace.createMarketItem(tokenId, price);
        
        NFTMarketplace.MarketItem memory item = marketplace.getMarketItem(tokenId);
        assertEq(item.tokenId, tokenId);
        assertEq(item.seller, user1);
        assertEq(item.price, price);
        assertEq(item.sold, false);
        assertEq(item.isAuction, false);
        
        vm.stopPrank();
    }
    
    function testBuyMarketItem() public {
        vm.startPrank(user1);
        
        // 铸造并出售NFT
        string memory tokenURI = "ipfs://QmExample";
        uint256 tokenId = marketplace.mintNFT(tokenURI);
        uint256 price = 1 ether;
        marketplace.createMarketItem(tokenId, price);
        
        vm.stopPrank();
        
        // 用户2购买NFT
        vm.startPrank(user2);
        marketplace.buyMarketItem{value: price}(tokenId);
        
        NFTMarketplace.MarketItem memory item = marketplace.getMarketItem(tokenId);
        assertEq(item.owner, user2);
        assertEq(item.sold, true);
        assertEq(marketplace.ownerOf(tokenId), user2);
        
        vm.stopPrank();
    }
    
    function testCreateAuction() public {
        vm.startPrank(user1);
        
        // 铸造NFT
        string memory tokenURI = "ipfs://QmExample";
        uint256 tokenId = marketplace.mintNFT(tokenURI);
        
        // 创建拍卖
        uint256 startingPrice = 0.5 ether;
        uint256 duration = 1 hours;
        marketplace.createAuction(tokenId, startingPrice, duration);
        
        NFTMarketplace.MarketItem memory item = marketplace.getMarketItem(tokenId);
        assertEq(item.isAuction, true);
        assertEq(item.highestBid, startingPrice);
        assertEq(item.auctionEndTime, block.timestamp + duration);
        
        vm.stopPrank();
    }
    
    function testPlaceBid() public {
        vm.startPrank(user1);
        
        // 铸造NFT并创建拍卖
        string memory tokenURI = "ipfs://QmExample";
        uint256 tokenId = marketplace.mintNFT(tokenURI);
        uint256 startingPrice = 0.5 ether;
        uint256 duration = 1 hours;
        marketplace.createAuction(tokenId, startingPrice, duration);
        
        vm.stopPrank();
        
        // 用户2出价
        vm.startPrank(user2);
        uint256 bidAmount = 1 ether;
        marketplace.placeBid{value: bidAmount}(tokenId);
        
        NFTMarketplace.MarketItem memory item = marketplace.getMarketItem(tokenId);
        assertEq(item.highestBid, bidAmount);
        assertEq(item.highestBidder, user2);
        
        vm.stopPrank();
    }
    
    function testEndAuction() public {
        vm.startPrank(user1);
        
        // 铸造NFT并创建拍卖
        string memory tokenURI = "ipfs://QmExample";
        uint256 tokenId = marketplace.mintNFT(tokenURI);
        uint256 startingPrice = 0.5 ether;
        uint256 duration = 1 hours;
        marketplace.createAuction(tokenId, startingPrice, duration);
        
        vm.stopPrank();
        
        // 用户2出价
        vm.startPrank(user2);
        uint256 bidAmount = 1 ether;
        marketplace.placeBid{value: bidAmount}(tokenId);
        vm.stopPrank();
        
        // 时间快进到拍卖结束
        vm.warp(block.timestamp + duration + 1);
        
        // 结束拍卖
        vm.prank(user1);
        marketplace.endAuction(tokenId);
        
        NFTMarketplace.MarketItem memory item = marketplace.getMarketItem(tokenId);
        assertEq(item.sold, true);
        assertEq(item.owner, user2);
        assertEq(marketplace.ownerOf(tokenId), user2);
    }
    
    function testGetAllMarketItems() public {
        vm.startPrank(user1);
        
        // 铸造多个NFT并出售
        for (uint256 i = 0; i < 3; i++) {
            string memory tokenURI = string(abi.encodePacked("ipfs://QmExample", i));
            uint256 tokenId = marketplace.mintNFT(tokenURI);
            marketplace.createMarketItem(tokenId, 1 ether);
        }
        
        vm.stopPrank();
        
        NFTMarketplace.MarketItem[] memory items = marketplace.getAllMarketItems();
        assertEq(items.length, 3);
    }
    
    function testGetMyNFTs() public {
        vm.startPrank(user1);
        
        // 铸造NFT
        string memory tokenURI = "ipfs://QmExample";
        uint256 tokenId = marketplace.mintNFT(tokenURI);
        
        vm.stopPrank();
        
        uint256[] memory myNFTs = marketplace.getMyNFTs(user1);
        assertEq(myNFTs.length, 1);
        assertEq(myNFTs[0], tokenId);
    }
    
    function testGetMyCreatedNFTs() public {
        vm.startPrank(user1);
        
        // 铸造NFT并出售
        string memory tokenURI = "ipfs://QmExample";
        uint256 tokenId = marketplace.mintNFT(tokenURI);
        marketplace.createMarketItem(tokenId, 1 ether);
        
        vm.stopPrank();
        
        uint256[] memory createdNFTs = marketplace.getMyCreatedNFTs(user1);
        assertEq(createdNFTs.length, 1);
        assertEq(createdNFTs[0], tokenId);
    }
    
    function testSetPlatformFeePercentage() public {
        uint256 newFee = 500; // 5%
        
        vm.prank(owner);
        marketplace.setPlatformFeePercentage(newFee);
        
        assertEq(marketplace.platformFeePercentage(), newFee);
    }
    
    function testSetMinPrice() public {
        uint256 newMinPrice = 0.05 ether;
        
        vm.prank(owner);
        marketplace.setMinPrice(newMinPrice);
        
        assertEq(marketplace.minPrice(), newMinPrice);
    }
    
    function test_RevertWhen_CreateMarketItemBelowMinPrice() public {
        vm.startPrank(user1);
        
        // 铸造NFT
        string memory tokenURI = "ipfs://QmExample";
        uint256 tokenId = marketplace.mintNFT(tokenURI);
        
        // 尝试以低于最低价格的价格出售
        uint256 lowPrice = 0.005 ether;
        vm.expectRevert("Price must be at least minimum price");
        marketplace.createMarketItem(tokenId, lowPrice);
        
        vm.stopPrank();
    }
    
    function test_RevertWhen_BuyMarketItemWrongPrice() public {
        vm.startPrank(user1);
        
        // 铸造并出售NFT
        string memory tokenURI = "ipfs://QmExample";
        uint256 tokenId = marketplace.mintNFT(tokenURI);
        uint256 price = 1 ether;
        marketplace.createMarketItem(tokenId, price);
        
        vm.stopPrank();
        
        // 尝试以错误的价格购买
        vm.startPrank(user2);
        uint256 wrongPrice = 0.5 ether;
        vm.expectRevert("Please submit the asking price");
        marketplace.buyMarketItem{value: wrongPrice}(tokenId);
        
        vm.stopPrank();
    }
    
    function test_RevertWhen_PlaceBidOnOwnAuction() public {
        vm.startPrank(user1);
        
        // 铸造NFT并创建拍卖
        string memory tokenURI = "ipfs://QmExample";
        uint256 tokenId = marketplace.mintNFT(tokenURI);
        uint256 startingPrice = 0.5 ether;
        uint256 duration = 1 hours;
        marketplace.createAuction(tokenId, startingPrice, duration);
        
        // 尝试对自己的拍卖出价
        vm.expectRevert("Seller cannot bid on their own auction");
        marketplace.placeBid{value: 1 ether}(tokenId);
        
        vm.stopPrank();
    }
}
