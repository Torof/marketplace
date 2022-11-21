/**
 *@author Torof
 *@title A custodial NFT MarketPlace
 *@notice This marketplace allows the listing and selling of {ERC721} and {ERC1155} Non Fungible & Semi Fungible Tokens
 *@dev The marketplace MUST hold the NFT and the offer funds in custody.
 */

/// TODO: security
/// TODO: gas opti
/// TODO: events & comments

/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Marketplace is
    ReentrancyGuard,
    IERC721Receiver,
    ERC1155Receiver,
    Ownable
{
    uint256 public marketOffersNonce = 1; /// sale id - all sales ongoing and closed
    uint256 private fees; /// All the fees gathered by the markeplace
    uint256 public marketPlaceFee; /// percentage of the fee. starts at 0, cannot be more than 10
    uint256 public minimumCancelTime = 86400 * 2; /// 48h
    mapping(uint256 => MarketOffering) private marketOffers;

    /**
     *@notice Emitted when a NFT is received
     */
    event NFTReceived(
        address operator,
        address from,
        uint256 tokenId,
        uint256 amount,
        string standard,
        bytes data
    );

    /**
     *@notice Emitted when
     */
    event BatchNFTReceived(
        address operator,
        address from,
        uint256[] tokenId,
        uint256[] amount,
        string standard,
        bytes data
    );

    /**
     *@notice Emitted when a new market saleis created
     */
    event SaleCreated(
        uint256 offerId,
        address from,
        uint256 tokenId,
        address contractAddress,
        string standard,
        uint256 price
    );

    /**
     *@notice Emitted when a seller cancel its sale
     */
    event SaleCanceled(uint256 marketOfferId);

    /**
     *@notice Emitted when a sale is successfully concluded
     */
    event SaleSuccessful(
        uint marketOfferId,
        address seller,
        address buyer,
        uint price
    );

    /**
     *@notice Emitted when a new offer is made
     */
    event OfferSubmitted(
        uint256 marketOfferId,
        address offerer,
        uint256 offerPrice
    );

    /**
     *@notice Emitted when a offer is cancel and refunded. cancelOffer() or makeOffer
     */
    event OfferRefunded(
        uint marketofferId,
        address previousOfferer,
        uint refundAmount
    );

    /**
     *@notice Emitted when a bidder cancel its offer
     */
    event OfferCanceled(
        uint256 marketOfferId,
        address offererAddress,
        uint canceledOffer
    );

    struct MarketOffering {
        address contractAddress; ///address of the NFT contract
        address seller; /// address that created the sale
        address buyer; /// address that bought the sale
        address offerAddress; /// address of the offerer
        uint256 price; /// price of the sale
        uint256 tokenId;
        uint256 offer; /// price of the bid
        uint256 offerTime; /// time the offer was submitted. 48h minimum before offer cancelation possible
        string standard; /// standard of the collection - only ERC721 and ERC1155 accepted
        bool closed; ///sale is on or finished
        uint offerNum;
    }

    /// ==========================================
    ///    Receive & support interfaces
    /// ==========================================

    /**
     * @notice MUST be implemented to be compatible with all ERC721 standards NFTs
     * @return bytes4 of function {onERC721Received} selector
     * @param operator address allowed to transfer NFTs on owner's behalf
     * @param from address the NFT comes from
     * @param tokenId the id of the NFT within its collection
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
        ) external override returns (bytes4) {
        emit NFTReceived(operator, from, tokenId, 1, "ERC721", data);
        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }

    /**
     * @notice MUST be implemented to be compatible with all ERC1155 standards NFTs single transfers
     * @return bytes4 of function {onERC1155Received} selector
     * @param operator address allowed to transfer NFTs on owner's behalf
     * @param from address the NFT comes from
     * @param id the id of the NFT within its collection
     * @param value quantity received. Use case for Semi Fungible Tokens
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override returns (bytes4) {
        emit NFTReceived(operator, from, id, value, "ERC1155", data);
        return
            bytes4(
                keccak256(
                    "onERC1155Received(address,address,uint256,uint256,bytes)"
                )
            );
    }

    /**
     * @notice MUST be implemented to be compatible with all ERC1155 standards NFTs batch transfers
     * @return bytes4 of function {onERC1155BatchReceived} selector
     * @param operator address allowed to transfer NFTs on owner's behalf
     * @param from address the NFT comes from
     * @param ids an array of all the ids of the tokens within their collection/type
     * @param values quantity of each received. Use case for Semi Fungible Tokens
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override returns (bytes4) {
        emit BatchNFTReceived(operator, from, ids, values, "ERC1155", data);
        return
            bytes4(
                keccak256(
                    "onER1155BatchReceived(address,address,uint256[],uint256[],bytes)"
                )
            );
    }

    /// =============================================
    ///       Marketplace functions
    /// =============================================

    /**
     *@notice set the fees. CANNOT be negative or more than 10%
     *@param _fees the fee the marketplace will receive from each sale
     */
    function setFees(uint256 _fees) external onlyOwner {
        require(_fees <= 10, "can't be more than 10%");
        marketPlaceFee = _fees;
    }

    /**
     * @notice withdraw all gains made from the sales fees all at once.
     */
    function withdrawFees() external payable onlyOwner {
        (bool sent, ) = msg.sender.call{value: fees}("");
        require(sent, "failed to send ether");
        fees = 0;
    }

    /// ==========================================
    ///      Main sale
    /// ==========================================

    /**
     * @notice opens a new sale of a single NFT. Supports {ERC721} and {ERC1155}. Compatible with {ERC721A}
     * @param _contractAddress the address of the NFT's contract
     * @param _tokenId of the token within its collection
     * @param _price defined by the creator/seller
     *
     */
    function createSale(
        address _contractAddress,
        uint256 _tokenId,
        uint256 _price
    ) external {
        _price = _price * 10e17;
        if (
            ERC721(_contractAddress).supportsInterface(
                type(IERC721).interfaceId
            )
        ) {
            ERC721 collection = ERC721(_contractAddress); ///collection address
            require(collection.ownerOf(_tokenId) == msg.sender, "not owner"); ///creator must own NFT
            marketOffers[marketOffersNonce] = MarketOffering(
                _contractAddress, /// collection address
                msg.sender, /// seller address
                address(0), /// buyer address
                address(0), /// address of the highest offerer
                _price, ///sale price
                _tokenId,
                0, ///highest offer price
                0,
                "ERC721", ///NFT's standard
                false, ///offer is closed
                marketOffersNonce
            );
            collection.safeTransferFrom(msg.sender, address(this), _tokenId); ///Transfer NFT to marketplace contract for custody
            emit SaleCreated(
                marketOffersNonce, ///id of the new offer
                msg.sender, ///seller address
                _tokenId,
                _contractAddress,
                marketOffers[marketOffersNonce].standard,
                _price
            );
            marketOffersNonce++;
        } else if (
            ERC1155(_contractAddress).supportsInterface(
                type(IERC1155).interfaceId
            )
        ) {
            ERC1155 collection = ERC1155(_contractAddress);
            require(
                collection.balanceOf(msg.sender, _tokenId) >= 1,
                "not owner"
            );
            marketOffers[marketOffersNonce] = MarketOffering(
                _contractAddress, /// collection address
                msg.sender, /// seller address
                address(0), /// buyer address
                address(0), /// address of the highest offerer
                _price, /// sale price
                _tokenId, /// id of the token (cannot be fungible in this case)
                0, /// highest offer price
                0, /// last offer submition time
                "ERC1155", /// NFT's standard
                false, /// offer is closed
                marketOffersNonce
            );
            collection.safeTransferFrom(
                msg.sender,
                address(this),
                _tokenId,
                1,
                ""
            ); /// Transfer NFT to marketplace contract for custody
            emit SaleCreated(
                marketOffersNonce,
                msg.sender,
                _tokenId,
                _contractAddress,
                marketOffers[marketOffersNonce].standard,
                _price
            );
            marketOffersNonce++;
        } else revert("not recognized");
    }

    /**
     * @notice modify the sale's price
     * @param _marketOfferId id of the sale
     * @param _newPrice the new price of the sale
     */
    function modifySale(uint256 _marketOfferId, uint256 _newPrice) external {
        require(msg.sender == marketOffers[_marketOfferId].seller, "not owner");
        marketOffers[_marketOfferId].price = _newPrice * 10e17;
    }

    /**
     * @notice cancel a sale. Will refund last offer made
     * @param _marketOfferId id of the sale
     */
    function cancelSale(uint256 _marketOfferId) external nonReentrant {
        require(!marketOffers[_marketOfferId].closed, "offer is closed"); /// offer must still be ongoing to cancel
        require(msg.sender == marketOffers[_marketOfferId].seller, "not owner");

        marketOffers[_marketOfferId].closed = true; /// sale is over
        if (marketOffers[_marketOfferId].offer != 0) {
            /// if already an offer, refund previous caller
            (bool sent, ) = marketOffers[_marketOfferId].offerAddress.call{
                value: marketOffers[_marketOfferId].offer
            }("");
            require(sent, "failed to send ether");
            emit OfferRefunded(
                _marketOfferId,
                marketOffers[_marketOfferId].offerAddress,
                marketOffers[_marketOfferId].offer
            );
        }
        if (
            ERC721(marketOffers[_marketOfferId].contractAddress)
                .supportsInterface(type(IERC721).interfaceId)
        ) {
            ERC721(marketOffers[_marketOfferId].contractAddress)
                .safeTransferFrom(
                    address(this),
                    msg.sender,
                    marketOffers[_marketOfferId].tokenId
                ); /// sale is canceled and erc721 NFt sent back to its owner
        } else if (
            ERC1155(marketOffers[_marketOfferId].contractAddress)
                .supportsInterface(type(IERC721).interfaceId)
        ) {
            ERC1155(marketOffers[_marketOfferId].contractAddress)
                .safeTransferFrom(
                    address(this),
                    msg.sender,
                    marketOffers[_marketOfferId].tokenId,
                    1,
                    ""
                ); /// sale is canceled and erc1155 NFT sent back to its owner
        }
        emit SaleCanceled(_marketOfferId);
    }

    /**
     *@notice allows anyone to buy instantly a NFT at asked price.
     *@dev fees SHOULD be automatically soustracted and made offer MUST be refunded if present
     *@param _marketOfferId id of the sale
     */
    function buySale(uint256 _marketOfferId) external payable nonReentrant {
        require(
            msg.value == marketOffers[_marketOfferId].price,
            "not the right amount"
        ); /// give the exact amount to buy

        require(!marketOffers[_marketOfferId].closed, "offer is closed");

        if (marketOffers[_marketOfferId].offer != 0) {
            /// if already an offer, refund previous caller
            (bool sent1, ) = marketOffers[_marketOfferId].offerAddress.call{
                value: marketOffers[_marketOfferId].offer
            }("");
            require(sent1, "failed to send ether");
            emit OfferRefunded(
                _marketOfferId,
                marketOffers[_marketOfferId].offerAddress,
                marketOffers[_marketOfferId].offer
            );
        }

        /// Fees of the marketplace
        uint256 afterFees = msg.value - ((msg.value * marketPlaceFee) / 100);
        fees += ((msg.value * marketPlaceFee) / 100);

        (bool sent2, ) = marketOffers[_marketOfferId].seller.call{
            value: afterFees
        }(""); /// send sale price to previous owner
        require(sent2, "failed to send ether");

        marketOffers[_marketOfferId].buyer = msg.sender; /// update buyer
        marketOffers[_marketOfferId].closed = true; /// sale is closed

        MarketOffering memory offer = marketOffers[_marketOfferId];

        if (
            ERC721(offer.contractAddress).supportsInterface(
                type(IERC721).interfaceId /// check if NFT is a erc721 standard NFT
            )
        )
            ERC721(offer.contractAddress).safeTransferFrom(
                address(this),
                msg.sender,
                offer.tokenId
            ); /// transfer NFT ERC721 to new owner
        else if (
            ERC1155(offer.contractAddress).supportsInterface(
                type(IERC1155).interfaceId /// check if NFT is a erc1155 standard NFT
            )
        )
            ERC1155(offer.contractAddress).safeTransferFrom(
                address(this),
                msg.sender,
                offer.tokenId,
                1,
                ""
            ); /// transfer NFT ERC1155 to new owner
        else revert("not supported");
        emit SaleSuccessful(_marketOfferId, marketOffers[_marketOfferId].seller, msg.sender, marketOffers[_marketOfferId].price);
    }

    // =========================================
    //      Secondary offers
    // =========================================

    /**
     * @notice make an offer most likely below asked price.
     * A new offer will be created and the previous offer will be refunded.
     * The funds must be sent in custody and CANNOT be canceled for 48h
     *
     *  // ================================================================================================ //
     *  //  WARNING: Once an offer is made it cannot be canceled for 48h.                                   //
     *  //  only the direct sale of the NFT or an higher offer will cancel the offer and refund its bider.  //
     *  // ================================================================================================ //
     */
    function makeOffer(uint256 _marketOfferId) external payable nonReentrant {
        require(
            msg.value > marketOffers[_marketOfferId].offer,
            "offer too low"
        ); /// offer should be higher than previous one
        require(!marketOffers[_marketOfferId].closed, "offer not available"); ///Only if offer is still ongoing

        if (marketOffers[_marketOfferId].offer != 0) {
            /// if already an offer, refund previous caller
            (bool sent, ) = marketOffers[_marketOfferId].offerAddress.call{
                value: marketOffers[_marketOfferId].offer
            }("");
            require(sent, "failed to send ether");
            emit OfferRefunded(
                _marketOfferId,
                marketOffers[_marketOfferId].offerAddress,
                marketOffers[_marketOfferId].offer
            );
        }

        marketOffers[_marketOfferId].offer = msg.value; ///new offer price
        marketOffers[_marketOfferId].offerAddress = msg.sender; ///new caller
        marketOffers[_marketOfferId].offerTime = block.timestamp;

        emit OfferSubmitted(
            _marketOfferId,
            marketOffers[_marketOfferId].offerAddress,
            msg.value
        );
    }

    /**
     * @notice a third party made an offer below the asked price and seller accepts
     * @dev fees SHOULD be automatically soustracted
     * @param _marketOfferId of the sale
     * Emits a {} event if follows IERC721 or {} event if it follows IERC1155
     */
    function acceptOffer(uint256 _marketOfferId) external nonReentrant {
        require(
            marketOffers[_marketOfferId].seller == msg.sender,
            "only owner"
        ); /// owner of the token - sale

        /// Fees of the marketplace
        uint256 afterFees = marketOffers[_marketOfferId].offer -
            ((marketOffers[_marketOfferId].offer * marketPlaceFee) / 100);
        fees += (marketOffers[_marketOfferId].offer * marketPlaceFee) / 100;

        (bool sent, ) = marketOffers[_marketOfferId].seller.call{
            value: afterFees
        }("");
        require(sent, "failed to send ether");

        marketOffers[_marketOfferId].buyer = marketOffers[_marketOfferId]
            .offerAddress; /// update buyer
        marketOffers[_marketOfferId].price = marketOffers[_marketOfferId].offer; /// update sell price
        marketOffers[_marketOfferId].closed = true; /// offer is now over

        MarketOffering memory offer = marketOffers[_marketOfferId];

        if (
            ERC721(offer.contractAddress).supportsInterface(
                type(IERC721).interfaceId
            )
        )
            ERC721(offer.contractAddress).safeTransferFrom(
                address(this),
                marketOffers[_marketOfferId].buyer,
                marketOffers[_marketOfferId].tokenId
            ); /// transfer NFT to new owner
        else if (
            ERC1155(offer.contractAddress).supportsInterface(
                type(IERC1155).interfaceId
            )
        )
            ERC1155(offer.contractAddress).safeTransferFrom(
                address(this),
                msg.sender,
                offer.tokenId,
                1,
                ""
            ); /// transfer NFT ERC1155 to new owner
        else revert("Not supported");
    }

    /**
     * @notice cancel an offer made. MUST be 48h minimum after submission of the offer.
     * refunds the sender of its bid
     * @param _marketOfferId id of the sale
     * Emits a {} event
     */
    function cancelOffer(uint256 _marketOfferId) external nonReentrant {
        require(
            msg.sender == marketOffers[_marketOfferId].offerAddress,
            "not the offerer"
        );
        require(
            block.timestamp >
                marketOffers[_marketOfferId].offerTime + minimumCancelTime,
            "48h minimum before cancel"
        );

        uint refund = marketOffers[_marketOfferId].offer;

        marketOffers[_marketOfferId].offer = 0;
        marketOffers[_marketOfferId].offerAddress = address(0);

        (bool sent, ) = msg.sender.call{value: refund}("");
        require(sent, "failed to send ether");

        emit OfferCanceled(_marketOfferId, msg.sender, refund);
    }

    /// ================================
    ///       Getters
    /// ================================

    /**
     * @notice get all informations of a sale order by calling its id
     * @param _marketOfferId id of the sale
     */
    function getOffer(uint256 _marketOfferId)
        external
        view
        returns (MarketOffering memory)
    {
        return marketOffers[_marketOfferId];
    }
}
