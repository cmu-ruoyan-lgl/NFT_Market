// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "../lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
/**
 * @title NFTMarketplace
 * @dev 一个完整的NFT市场合约，支持铸造、购买、出售和拍卖功能
 */
contract NFTMarketplace is ERC721, ERC721URIStorage, ReentrancyGuard, Ownable {
    uint256 private _tokenIds = 0;
    uint256 private _itemsSold = 0;
    
    // 平台费用比例 (2.5%)
    uint256 public platformFeePercentage = 250;
    uint256 public constant FEE_DENOMINATOR = 10000;
    
    // 最小价格
    uint256 public minPrice = 0.01 ether;
    
    // 市场项目结构
    struct MarketItem {
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
        bool isAuction;
        uint256 auctionEndTime;
        uint256 highestBid;
        address highestBidder;
    }
    
    // 映射：tokenId => MarketItem
    mapping(uint256 => MarketItem) public marketItems;
    
    // 事件
    event MarketItemCreated(
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold
    );
    
    event MarketItemSold(
        uint256 indexed tokenId,
        address seller,
        address buyer,
        uint256 price
    );
    
    event AuctionCreated(
        uint256 indexed tokenId,
        address seller,
        uint256 startingPrice,
        uint256 auctionEndTime
    );
    
    event BidPlaced(
        uint256 indexed tokenId,
        address bidder,
        uint256 amount
    );
    
    event AuctionEnded(
        uint256 indexed tokenId,
        address winner,
        uint256 amount
    );
    
    constructor() ERC721("NFT Marketplace", "NFTM") Ownable(msg.sender) {
        _tokenIds = 1; // 从1开始
    }
    
    /**
     * @dev 铸造新的NFT
     * @param uri NFT的元数据URI
     * @return tokenId 新铸造的NFT的ID
     */
    function mintNFT(string memory uri) public returns (uint256) {
        uint256 newTokenId = _tokenIds;
        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, uri);
        _tokenIds++;
        return newTokenId;
    }
    
    /**
     * @dev 创建市场项目（出售NFT）
     * @param tokenId NFT的ID
     * @param price 出售价格
     */
    function createMarketItem(uint256 tokenId, uint256 price) public payable {
        require(price >= minPrice, "Price must be at least minimum price");
        require(price > 0, "Price must be greater than 0");
        _requireOwned(tokenId);
        require(ownerOf(tokenId) == msg.sender, "You can only sell your own NFT");
        
        // 转移NFT到合约
        _transfer(msg.sender, address(this), tokenId);
        
        marketItems[tokenId] = MarketItem(
            tokenId,
            payable(msg.sender),
            payable(address(this)),
            price,
            false,
            false,
            0,
            0,
            address(0)
        );
        
        emit MarketItemCreated(tokenId, msg.sender, address(this), price, false);
    }
    
    /**
     * @dev 购买市场项目
     * @param tokenId NFT的ID
     */
    function buyMarketItem(uint256 tokenId) public payable nonReentrant {
        MarketItem storage item = marketItems[tokenId];
        require(item.sold == false, "Item is already sold");
        require(msg.value == item.price, "Please submit the asking price");
        require(item.isAuction == false, "This is an auction item");
        
        // 计算平台费用
        uint256 platformFee = (msg.value * platformFeePercentage) / FEE_DENOMINATOR;
        uint256 sellerAmount = msg.value - platformFee;
        
        // 转移费用
        payable(owner()).transfer(platformFee);
        item.seller.transfer(sellerAmount);
        
        // 转移NFT
        _transfer(address(this), msg.sender, tokenId);
        item.owner = payable(msg.sender);
        item.sold = true;
        _itemsSold++;
        
        emit MarketItemSold(tokenId, item.seller, msg.sender, msg.value);
    }
    
    /**
     * @dev 创建拍卖
     * @param tokenId NFT的ID
     * @param startingPrice 起拍价
     * @param duration 拍卖持续时间（秒）
     */
    function createAuction(uint256 tokenId, uint256 startingPrice, uint256 duration) public {
        require(startingPrice >= minPrice, "Starting price must be at least minimum price");
        require(duration > 0, "Duration must be greater than 0");
        _requireOwned(tokenId);
        require(ownerOf(tokenId) == msg.sender, "You can only auction your own NFT");
        
        // 转移NFT到合约
        _transfer(msg.sender, address(this), tokenId);
        
        marketItems[tokenId] = MarketItem(
            tokenId,
            payable(msg.sender),
            payable(address(this)),
            startingPrice,
            false,
            true,
            block.timestamp + duration,
            startingPrice,
            address(0)
        );
        
        emit AuctionCreated(tokenId, msg.sender, startingPrice, block.timestamp + duration);
    }
    
    /**
     * @dev 出价
     * @param tokenId NFT的ID
     */
    function placeBid(uint256 tokenId) public payable nonReentrant {
        MarketItem storage item = marketItems[tokenId];
        require(item.isAuction, "This is not an auction item");
        require(block.timestamp < item.auctionEndTime, "Auction has ended");
        require(msg.value > item.highestBid, "Bid must be higher than current highest bid");
        require(msg.sender != item.seller, "Seller cannot bid on their own auction");
        
        // 如果有之前的出价，退还资金
        if (item.highestBidder != address(0)) {
            payable(item.highestBidder).transfer(item.highestBid);
        }
        
        // 更新最高出价
        item.highestBid = msg.value;
        item.highestBidder = msg.sender;
        
        emit BidPlaced(tokenId, msg.sender, msg.value);
    }
    
    /**
     * @dev 结束拍卖
     * @param tokenId NFT的ID
     */
    function endAuction(uint256 tokenId) public nonReentrant {
        MarketItem storage item = marketItems[tokenId];
        require(item.isAuction, "This is not an auction item");
        require(block.timestamp >= item.auctionEndTime, "Auction has not ended yet");
        require(item.sold == false, "Auction already ended");
        
        if (item.highestBidder != address(0)) {
            // 计算平台费用
            uint256 platformFee = (item.highestBid * platformFeePercentage) / FEE_DENOMINATOR;
            uint256 sellerAmount = item.highestBid - platformFee;
            
            // 转移费用
            payable(owner()).transfer(platformFee);
            item.seller.transfer(sellerAmount);
            
            // 转移NFT
            _transfer(address(this), item.highestBidder, tokenId);
            item.owner = payable(item.highestBidder);
            item.sold = true;
            _itemsSold++;
            
            emit AuctionEnded(tokenId, item.highestBidder, item.highestBid);
        } else {
            // 没有人出价，退还NFT给卖家
            _transfer(address(this), item.seller, tokenId);
            delete marketItems[tokenId];
        }
    }
    
    /**
     * @dev 获取市场项目
     * @param tokenId NFT的ID
     * @return MarketItem 市场项目信息
     */
    function getMarketItem(uint256 tokenId) public view returns (MarketItem memory) {
        return marketItems[tokenId];
    }
    
    /**
     * @dev 获取所有市场项目
     * @return MarketItem[] 所有市场项目数组
     */
    function getAllMarketItems() public view returns (MarketItem[] memory) {
        uint256 itemCount = _tokenIds - 1;
        uint256 unsoldItemCount = itemCount - _itemsSold;
        uint256 currentIndex = 0;
        
        MarketItem[] memory items = new MarketItem[](unsoldItemCount);
        for (uint256 i = 1; i <= itemCount; i++) {
            if (marketItems[i].sold == false) {
                items[currentIndex] = marketItems[i];
                currentIndex += 1;
            }
        }
        return items;
    }
    
    /**
     * @dev 获取用户拥有的NFT
     * @param user 用户地址
     * @return uint256[] 用户拥有的NFT ID数组
     */
    function getMyNFTs(address user) public view returns (uint256[] memory) {
        uint256 totalItemCount = _tokenIds - 1;
        uint256 itemCount = 0;
        uint256 currentIndex = 0;
        
        // 计算用户拥有的NFT数量
        for (uint256 i = 1; i <= totalItemCount; i++) {
            if (ownerOf(i) == user) {
                itemCount += 1;
            }
        }
        
        uint256[] memory items = new uint256[](itemCount);
        for (uint256 i = 1; i <= totalItemCount; i++) {
            if (ownerOf(i) == user) {
                items[currentIndex] = i;
                currentIndex += 1;
            }
        }
        return items;
    }
    
    /**
     * @dev 获取用户创建的NFT
     * @param user 用户地址
     * @return uint256[] 用户创建的NFT ID数组
     */
    function getMyCreatedNFTs(address user) public view returns (uint256[] memory) {
        uint256 totalItemCount = _tokenIds - 1;
        uint256 itemCount = 0;
        uint256 currentIndex = 0;
        
        // 计算用户创建的NFT数量
        for (uint256 i = 1; i <= totalItemCount; i++) {
            if (marketItems[i].seller == user) {
                itemCount += 1;
            }
        }
        
        uint256[] memory items = new uint256[](itemCount);
        for (uint256 i = 1; i <= totalItemCount; i++) {
            if (marketItems[i].seller == user) {
                items[currentIndex] = i;
                currentIndex += 1;
            }
        }
        return items;
    }
    
    /**
     * @dev 设置平台费用比例（仅限合约拥有者）
     * @param newFeePercentage 新的费用比例
     */
    function setPlatformFeePercentage(uint256 newFeePercentage) public onlyOwner {
        require(newFeePercentage <= 1000, "Fee cannot exceed 10%");
        platformFeePercentage = newFeePercentage;
    }
    
    /**
     * @dev 设置最小价格（仅限合约拥有者）
     * @param newMinPrice 新的最小价格
     */
    function setMinPrice(uint256 newMinPrice) public onlyOwner {
        minPrice = newMinPrice;
    }
    
    /**
     * @dev 提取合约中的ETH（仅限合约拥有者）
     */
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        payable(owner()).transfer(balance);
    }
    
    // 重写必要的函数
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }
    
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
