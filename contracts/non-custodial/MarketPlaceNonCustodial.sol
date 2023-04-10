// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

contract MarketPlaceNonCustodial {

    uint256 public marketOffersNonce = 1; /// sale id - all sales ongoing and closed
    uint256 private ethFees; /// All the fees gathered by the markeplace
    uint256 private wethFees;
    uint256 public marketPlaceFee; /// percentage of the fee. starts at 0, cannot be more than 10
    //ERC20 public constant WETH = ERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    mapping(uint256 => Order) public marketOrders;
    mapping(address => uint256) public balanceOfEth;

    struct Order {
        uint salePrice;
        uint tokenId;
        address contractAddress;
        address seller;
        address buyer;
        bytes4 standard;
        bool closed;
        Offer[] offers;
    }

    struct Offer {
        uint offerPrice;
        uint duration;
        uint offerTime;
        address sender;
    }


    function setFees() external {}

    function withdrawEthFees() external {}

    function withdrawWethFees() external {}

    function createSale() external {}

    function buySale() external {}

    function modifySale() external {}

    function cancelSale() external {}

    function createOffer() external {}

    function acceptOffer() external {}

    function modifyOffer() external {}

    function cancelOffer() external {}

    function getSaleOrder() public view returns (bool){}

    // function _hasExistingSale(
    //     address _contractAddress,
    //     uint256 _tokenId
    // ) internal view returns (bool) {
    //     for (uint256 i = 1; i <= marketOffersNonce; i++) {
    //         SaleOrder storage saleOrder = marketOffers[i];
    //         if (
    //             saleOrder.contractAddress == _contractAddress &&
    //             saleOrder.tokenId == _tokenId &&
    //             !saleOrder.closed
    //         ) {
    //             return true;
    //         }
    //     }
    //     return false;
    // }

    // //CHECK: if SaleOrder.seller is not owner anymore change SaleOrder.closed to true ?
    // function _sellerIsOwner(
    //     SaleOrder memory _order
    // ) internal view returns (bool) {
    //     if (_order.standard == type(IERC721).interfaceId) {
    //         if (
    //             _order.seller ==
    //             IERC721(_order.contractAddress).ownerOf(_order.tokenId)
    //         ) return true;
    //         else return false;
    //     } else if (_order.standard == type(IERC1155).interfaceId) {
    //         if (
    //             IERC1155(_order.contractAddress).balanceOf(
    //                 _order.seller,
    //                 _order.tokenId
    //             ) > 0
    //         ) return true;
    //         else return false;
    //     } else return false;
    // }

}