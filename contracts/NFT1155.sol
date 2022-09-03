// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

contract NFT1155 is ERC1155Supply{


constructor(uint256 _amount) ERC1155("https://ipfs.io/ipfs/") {
 _mint(msg.sender, 0, _amount, "");
}

function mint(uint _id, uint _amount) external {
    _mint(msg.sender, _id, _amount, "");
}

}