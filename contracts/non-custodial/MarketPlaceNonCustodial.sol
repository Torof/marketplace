// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

contract MarketPlaceNonCustodial {


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