// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Marketplace is ReentrancyGuard {

    mapping(uint => MarketOffering) private marketOffers;
    uint public marketOffersNonce;

    struct MarketOffering {
        address seller;
        address buyer;
        address contractAddress;
        uint price;
        uint offer;
        address offerAddress;
        uint[] tokenIds;
        bool closed;
    }



    function createSale(address _contractAddress,uint[] calldata _tokenIds, uint _price) external {
        require(_tokenIds.length != 0, "not the right amount of tokens");
        ERC721 collection = ERC721(_contractAddress);
        bool ownAll = true;
        for(uint i = 0 ; i <= _tokenIds.length ; i++){
            if(collection.ownerOf(_tokenIds[i]) != msg.sender) ownAll = false;
        }
        require(ownAll, "not owner");
        marketOffers[marketOffersNonce] = MarketOffering(msg.sender, address(0),_contractAddress, _price,0 , address(0), _tokenIds, false);
        // if(_tokenIds.length > 1) bundle = true; 
        for(uint i = 0; i <= _tokenIds.length; i++) {
            collection.safeTransferFrom(msg.sender, address(this), _tokenIds[i]);
            }   
    }

    function makeOffer(uint _marketOfferId) external payable{
        require(msg.value > marketOffers[_marketOfferId].offer, "not enough ether");
        if(marketOffers[_marketOfferId].offer != 0) {
            (bool sent, bytes memory data) = marketOffers[_marketOfferId].offerAddress.call{value: marketOffers[_marketOfferId].offer}("");
            require(sent, "failed to send ether");
        }
        marketOffers[_marketOfferId].offer = msg.value;
        marketOffers[_marketOfferId].offerAddress = msg.sender;
    }

    function acceptOffer(uint _marketOfferId) external {
        require(marketOffers[_marketOfferId].seller == msg.sender);
        ERC721 collection = ERC721(marketOffers[_marketOfferId].contractAddress);
        (bool sent, bytes memory data) = marketOffers[_marketOfferId].seller.call{value: marketOffers[_marketOfferId].offer}("");
        require(sent, "failed to send ether");
        marketOffers[_marketOfferId].buyer = marketOffers[_marketOfferId].offerAddress;
        marketOffers[_marketOfferId].price = marketOffers[_marketOfferId].offer;
        marketOffers[_marketOfferId].closed = true;
        for(uint i = 0; i <= marketOffers[_marketOfferId].tokenIds.length; i++) {
            collection.safeTransferFrom(msg.sender, address(this), marketOffers[_marketOfferId].tokenIds[i]);
            }
    }

    function cancelSale(uint _marketOfferId) external {
        ERC721 collection = ERC721(marketOffers[_marketOfferId].contractAddress);
        
        marketOffers[_marketOfferId].closed = true;
        for(uint i = 0; i <= marketOffers[_marketOfferId].tokenIds.length; i++)
        collection.safeTransferFrom(address(this), msg.sender, marketOffers[_marketOfferId].tokenIds[i]);
    }

    function buyOffer(uint _marketOfferId) external payable nonReentrant { 
        require(msg.value == marketOffers[_marketOfferId].price, "not the right amount");
        (bool sent, bytes memory data) = marketOffers[_marketOfferId].seller.call{value: msg.value}("");
        require(sent, "failed to send ether");
        marketOffers[_marketOfferId].buyer = msg.sender;
        marketOffers[_marketOfferId].closed = true;
        for(uint i = 0; i <= marketOffers[_marketOfferId].tokenIds.length; i++)
        ERC721(marketOffers[_marketOfferId].contractAddress).safeTransferFrom(address(this), msg.sender, marketOffers[_marketOfferId].tokenIds[i]);
    }

    function getOffer(uint _marketOfferId) external view returns(MarketOffering memory){
        return marketOffers[_marketOfferId];
    }
}