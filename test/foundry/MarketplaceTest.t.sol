//SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "forge-std/Test.sol";
import "contracts/Marketplace.sol";
import "contracts/WETH.sol";
import "contracts/NFT721.sol";
import "contracts/NFT1155.sol";
import "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";
import "@openzeppelin/contracts/interfaces/IERC1155Receiver.sol";

contract MarketplaceTest is Test {
    Marketplace public marketplace;
    WETH public weth;
    NFT721 public nft721;
    NFT1155 public nft1155;
    address bob = vm.addr(1);
    address alice = vm.addr(2);
    address matt = vm.addr(3);

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
        vm.startPrank(bob,bob);
        weth = new WETH();
        marketplace = new Marketplace(address(weth));
        nft721 = new NFT721();
        nft1155 = new NFT1155(50);
    }

    function testNFT721() public {
        assertEq(nft721.balanceOf(bob),3);
        assertEq(nft721.name(), "721test");
        assertEq(nft721.symbol(), "721");
        assertEq(nft721.ownerOf(1), bob);
    }

    function testNFT1155() public {
        assertEq(nft1155.balanceOf(bob, 1),50);
        assertEq(nft1155.totalSupply(1), 50);
        nft1155.mint(1, 10);
        assertEq(nft1155.totalSupply(1), 60);   
    }

    function testNoOrderYet() public{
        assertEq(marketplace.getSaleOrder(1).seller, address(0));
        assertEq(marketplace.getSaleOrder(1).tokenId, 0);
        assertEq(marketplace.getSaleOrder(1).contractAddress, address(0));
    }

    function testFailOnDirectTransferFromOwner() public {
        nft721.safeTransferFrom(bob, address(marketplace), 1);
    }

    function testFailOnDirectTransferFromApproved() public {
        nft721.setApprovalForAll(alice,true);
        vm.stopPrank();
        vm.prank(alice,alice);
        nft721.safeTransferFrom(bob, address(marketplace), 2);
    }

    function testCreateOrder() public {
        nft721.setApprovalForAll(address(marketplace), true);
        marketplace.createSale(address(nft721), 1, 1);
        assertEq(marketplace.getSaleOrder(1).contractAddress, address(nft721));
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
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
