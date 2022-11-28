/**
 *@author Torof
 *@title A custodial NFT MarketPlace
 *@notice This marketplace allows the listing and selling of {ERC721} and {ERC1155} Non Fungible & Semi Fungible Tokens
 *@dev The marketplace MUST hold the NFT and the offer funds in custody.
 */

/// TODO: security
/// TODO: gas opti
/// TODO: time to start batchoffers and batch buying of erc1155 tokens
/// TODO: change offerModel
///TODO: add WETH transfers

/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
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
    uint256 private wethFees;
    uint256 public marketPlaceFee; /// percentage of the fee. starts at 0, cannot be more than 10
    uint256 public minimumCancelTime = 2 days; /// 48h
    ERC20 public immutable WETH;
    mapping(uint256 => SaleOrder) private marketOffers;

    error offerClosed();

    error failedToSendEther();

    error notOwner();

    error standardNotRecognized();

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

    //TODO:  to allow  batch transfer, needs uint[]  tokenIds and uint[] amounts
    struct SaleOrder {
        address contractAddress; ///address of the NFT contract
        address seller; /// address that created the sale
        address buyer; /// address that bought the sale
        // address offerAddress;     /// address of the offerer
        uint256 price; /// price of the sale
        uint256 tokenId;
        // uint256 offer;            /// price of the bid
        Offer[] offers; /// an array of all the offers
        // uint256 offerTime;        /// time the offer was submitted. 48h minimum before offer cancelation possible
        string standard; /// standard of the collection - only ERC721 and ERC1155 accepted
        bool closed; ///sale is on or finished
    }

    struct Offer {
        address sender;
        uint amount;
        uint duration;
        uint offerTime;
    }

    constructor(address _WETH) {
        WETH = ERC20(_WETH);
    }

    /// ==========================================
    ///    Receive & support interfaces
    /// ==========================================

    fallback() external {
        revert("not allowed");
    }

    /**
     * @notice         MUST be implemented to be compatible with all ERC721 standards NFTs
     * @return bytes4  function {onERC721Received} selector
     * @param operator address allowed to transfer NFTs on owner's behalf
     * @param from     address the NFT comes from
     * @param tokenId  id of the NFT within its collection
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        if (msg.sender != address(this) && tx.origin == operator)
            revert("direct transfer not allowed"); //disallow direct transfers
        emit NFTReceived(operator, from, tokenId, 1, "ERC721", data);
        return IERC721Receiver.onERC721Received.selector;
    }

    //CHECK: security issues with direct transfer revert ?
    /**
     * @notice         MUST be implemented to be compatible with all ERC1155 standards NFTs single transfers
     * @return bytes4  of function {onERC1155Received} selector
     * @param operator address allowed to transfer NFTs on owner's behalf
     * @param from     address the NFT comes from
     * @param id       the id of the NFT within its collection
     * @param value    quantity received. Use case for Semi Fungible Tokens
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override returns (bytes4) {
        if (msg.sender != address(this) && tx.origin == operator)
            revert("direct transfer not allowed"); //disallow direct transfers
        emit NFTReceived(operator, from, id, value, "ERC1155", data);
        return IERC1155Receiver.onERC1155Received.selector;
    }

    /**
     * @notice         MUST be implemented to be compatible with all ERC1155 standards NFTs batch transfers
     * @return bytes4  of function {onERC1155BatchReceived} selector
     * @param operator address allowed to transfer NFTs on owner's behalf
     * @param from     address the NFT comes from
     * @param ids      an array of all the ids of the tokens within their collection/type
     * @param values   quantity of each received. Use case for Semi Fungible Tokens
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override returns (bytes4) {
        if (tx.origin != address(this) && tx.origin == operator)
            revert("direct transfer not allowed"); //disallow direct transfers
        emit BatchNFTReceived(operator, from, ids, values, "ERC1155", data);
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }

    /// =============================================
    ///       Marketplace functions
    /// =============================================

    /**
     *@notice      set the fees. CANNOT be negative or more than 10%
     *@param _fees the fee the marketplace will receive from each sale
     */
    function setFees(uint256 _fees) external onlyOwner {
        require(_fees <= 10, "can't be more than 10%");
        marketPlaceFee = _fees;
    }

    /**
     * @notice withdraw all gains in ETH made from the sales fees all at once.
     */
    function withdrawEthFees() external payable onlyOwner {
        (bool sent, ) = msg.sender.call{value: fees}("");
        if (!sent) revert failedToSendEther();
        fees = 0;
    }

    /**
     * @notice withdraw all gains made in WETH from the sales fees all at once.
     */
    function withdrawFees() external payable onlyOwner {
        bool sent = ERC20(WETH).transferFrom(
            address(this),
            msg.sender,
            wethFees
        );
        if (!sent) revert failedToSendEther();
        wethFees = 0;
    }

    /// ==========================================
    ///      Main sale
    /// ==========================================

    //TODO: to allow  batch transfer needs  uint[] tokenIds and uint[]amounts. Makesure for ERC721 lengths are equal to 1;
    ///CHECK: one function createSaleor several ? => createSaleERC721, createSaleERC1155, createSaleBatch1155
    /**
     * @notice                 opens a new sale of a single NFT. Supports {ERC721} and {ERC1155}. Compatible with {ERC721A}
     * @param _contractAddress the address of the NFT's contract
     * @param _tokenId         id of the token within its collection
     * @param _price           price defined by the creator/seller
     *
     */
    function createSale(
        address _contractAddress,
        uint256 _tokenId,
        uint256 _price
    ) external {
        if (
            ERC721(_contractAddress).supportsInterface(
                type(IERC721).interfaceId
            )
        ) {
            (bool success1, bytes memory data) = _contractAddress.staticcall(
                abi.encodeWithSignature("ownerOf(uint256)", _tokenId)
            );
            if (!success1) revert("non view detected");
            address owner = abi.decode(data, (address));

            if (owner != msg.sender) revert notOwner(); ///creator must own NFT

            ERC721 collection = ERC721(_contractAddress); ///collection address

            marketOffers[marketOffersNonce].contractAddress = _contractAddress; /// collection address
            marketOffers[marketOffersNonce].seller = msg.sender; /// seller address
            marketOffers[marketOffersNonce].price = _price; ///sale price
            marketOffers[marketOffersNonce].tokenId = _tokenId;
            marketOffers[marketOffersNonce].standard = "ERC721"; ///NFT's standard

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
            if (collection.balanceOf(msg.sender, _tokenId) < 1)
                revert notOwner();

            marketOffers[marketOffersNonce].contractAddress = _contractAddress; /// collection address
            marketOffers[marketOffersNonce].seller = msg.sender; /// seller address
            marketOffers[marketOffersNonce].price = _price; /// sale price
            marketOffers[marketOffersNonce].tokenId = _tokenId; /// id of the token (cannot be fungible in this case)
            marketOffers[marketOffersNonce].standard = "ERC1155"; /// NFT's standard
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
        } else revert standardNotRecognized();
    }

    /**
     * @notice               modify the sale's price
     * @param _marketOfferId id of the sale
     * @param _newPrice      the new price of the sale
     */
    function modifySale(uint256 _marketOfferId, uint256 _newPrice) external {
        if (msg.sender != marketOffers[_marketOfferId].seller)
            revert notOwner();
        marketOffers[_marketOfferId].price = _newPrice * 1 ether;
    }

    /**
     * @notice               cancel a sale. Will refund last offer made
     * @param _marketOfferId id of the sale
     */
    function cancelSale(uint256 _marketOfferId) external nonReentrant {
        if (marketOffers[_marketOfferId].closed) revert offerClosed(); /// offer must still be ongoing to cancel
        if (msg.sender != marketOffers[_marketOfferId].seller)
            revert notOwner();

        marketOffers[_marketOfferId].closed = true; /// sale is over

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
        } else revert standardNotRecognized();
        emit SaleCanceled(_marketOfferId);
    }

    /**
     *@notice               allows anyone to buy instantly a NFT at asked price.
     *@dev                  fees SHOULD be automatically soustracted and made offer MUST be refunded if present
     *@param _marketOfferId id of the sale
     */
    function buySale(uint256 _marketOfferId) external payable nonReentrant {
        require(
            msg.value == marketOffers[_marketOfferId].price,
            "not the right amount"
        ); /// give the exact amount to buy

        if (marketOffers[_marketOfferId].closed) revert offerClosed();

        /// Fees of the marketplace
        uint256 afterFees = msg.value - ((msg.value * marketPlaceFee) / 100);
        fees += ((msg.value * marketPlaceFee) / 100);

        (bool sent2, ) = marketOffers[_marketOfferId].seller.call{
            value: afterFees
        }(""); /// send sale price to previous owner
        if (!sent2) revert failedToSendEther();

        marketOffers[_marketOfferId].buyer = msg.sender; /// update buyer
        marketOffers[_marketOfferId].closed = true; /// sale is closed

        SaleOrder memory offer = marketOffers[_marketOfferId];

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
        else revert standardNotRecognized();
        emit SaleSuccessful(
            _marketOfferId,
            marketOffers[_marketOfferId].seller,
            msg.sender,
            marketOffers[_marketOfferId].price
        );
    }

    // =========================================
    //      Secondary offers
    // =========================================

    /**
     * @notice make an offer. Offer is made and sent in WETH.
     *
     *  // ================================================================================================ //
     *  //  WARNING: Once an offer is made it cannot be canceled for 48h.                                   //
     *  //  only the direct sale of the NFT or an higher offer will cancel the offer and refund its bider.  //
     *  // ================================================================================================ //
     */
    function makeOffer(uint256 _marketOfferId, uint _amount, uint _duration)
        external
        nonReentrant
    {
        require(_amount > 0, "amount can't be zero");
        if (marketOffers[_marketOfferId].closed) revert offerClosed(); ///Only if offer is still ongoing
        require(
            WETH.allowance(msg.sender, address(this)) >= _amount,
            "not enough balance allowed"
        );

        Offer memory temp; ///new offer price
        temp.sender = msg.sender; ///new caller
        temp.offerTime = block.timestamp;
        temp.amount = _amount;
        temp.duration = _duration;
        marketOffers[_marketOfferId].offers.push(temp);
        emit OfferSubmitted(_marketOfferId, msg.sender, _amount);
    }

    /**
     * @notice               a third party made an offer below the asked price and seller accepts
     * @dev                  fees SHOULD be automatically soustracted
     * @param _marketOfferId id of the sale
     *
     * Emits a {} event if follows IERC721 or {} event if it follows IERC1155
     */
    function acceptOffer(uint256 _marketOfferId, uint _index)
        external
        nonReentrant
    {
        Offer memory offer = marketOffers[_marketOfferId].offers[_index];

        if (marketOffers[_marketOfferId].seller != msg.sender)
            revert notOwner(); /// owner of the token - sale
        //TODO: _index is not out of bound
        require(_index < marketOffers[_marketOfferId].offers.length, "index out of bound");
        //TODO: require offerNotexpired 
        //TODO: require balance of caller is enough
        require(
            WETH.allowance(offer.sender, address(this)) >=
                marketOffers[_marketOfferId].offers[_index].amount,
            "not enough allowance"
        );

        marketOffers[_marketOfferId].buyer = offer.sender; /// update buyer
        marketOffers[_marketOfferId].price = offer.amount; /// update sell price
        marketOffers[_marketOfferId].closed = true; /// offer is now over

        SaleOrder memory marketOrder = marketOffers[_marketOfferId];

        if (
            ERC721(marketOrder.contractAddress).supportsInterface(
                type(IERC721).interfaceId
            )
        )
            ERC721(marketOrder.contractAddress).safeTransferFrom(
                address(this),
                marketOrder.buyer,
                marketOrder.tokenId
            ); /// transfer NFT to new owner
        else if (
            ERC1155(marketOrder.contractAddress).supportsInterface(
                type(IERC1155).interfaceId
            )
        )
            ERC1155(marketOrder.contractAddress).safeTransferFrom(
                address(this),
                msg.sender,
                marketOrder.tokenId,
                1,
                ""
            ); /// transfer NFT ERC1155 to new owner
        else revert standardNotRecognized();

        /// Fees of the marketplace
        uint256 afterFees = offer.amount -
            ((offer.amount * marketPlaceFee) / 100);
        fees += (offer.amount * marketPlaceFee) / 100;

        bool sent1 = ERC20(WETH).transferFrom(
            msg.sender,
            marketOffers[_marketOfferId].seller,
            afterFees
        );
        if (!sent1) revert failedToSendEther();

        bool sent2 = ERC20(WETH).transferFrom(
            msg.sender,
            address(this),
            (offer.amount * marketPlaceFee) / 100
        );
        if (!sent2) revert failedToSendEther();
    }

    /**
     * @notice               cancel an offer made.
     * @param _marketOfferId id of the sale
     *
     * Emits a {} event
     */
    function cancelOffer(uint256 _marketOfferId, uint _index)
        external
        nonReentrant
    {
        require(
            msg.sender == marketOffers[_marketOfferId].offers[_index].sender,
            "not the offerer"
        );

        marketOffers[_marketOfferId].offers[_index] = marketOffers[
            _marketOfferId
        ].offers[marketOffers[_marketOfferId].offers.length - 1];
        marketOffers[_marketOfferId].offers.pop();
        
        emit OfferCanceled(_marketOfferId, msg.sender, 0);
    }

    /// ================================
    ///       Getters
    /// ================================

    /**
     * @notice               get all informations of a sale order by calling its id
     * @param _marketOfferId id of the sale
     */
    function getSaleOrder(uint256 _marketOfferId)
        external
        view
        returns (SaleOrder memory)
    {
        return marketOffers[_marketOfferId];
    }

    function getFees() external view onlyOwner returns (uint) {
        return fees;
    }
}
