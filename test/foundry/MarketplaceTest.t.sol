//SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "forge-std/Test.sol";
import "../../contracts/Marketplace.sol";
import "../../contracts/WETH.sol";
import "../../contracts/NFT721.sol";
import "../../contracts/NFT1155.sol";
import "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";
import "@openzeppelin/contracts/interfaces/IERC1155Receiver.sol";

contract MarketplaceTest is Test {
    Marketplace public marketplace;
    WETH public weth;
    NFT721 public nft721;
    NFT1155 public nft1155;

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

    function setUp() public {
        weth = new WETH();
        marketplace = new Marketplace(address(weth));
        nft721 = new NFT721();
        nft1155 = new NFT1155(50);
    }

    function testNFT721() public {
        assertEq(nft721.balanceOf(address(this)),3);
    }

        function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        if (msg.sender != address(this) && tx.origin == operator)
            revert("direct transfer not allowed"); //disallow direct transfers with safeTransferFrom()
        emit NFTReceived(operator, from, tokenId, 1, "ERC721", data);
        return IERC721Receiver.onERC721Received.selector;
    }

        function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4) {
        if (msg.sender != address(this) && tx.origin == operator)
            revert("direct transfer not allowed"); //disallow direct transfers
        emit NFTReceived(operator, from, id, value, "ERC1155", data);
        return IERC1155Receiver.onERC1155Received.selector;
    }

}
