// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

contract NFT1155 is ERC1155Supply{

uint public constant POTIONS = 1;
uint public constant SWORDS = 2;
uint public constant SHIELD = 3;
uint public constant BOOTS = 4;
uint public constant HELMET = 5;

constructor(uint256 _amount) ERC1155("https://ipfs.io/ipfs/") {
    _mint(msg.sender, 1, _amount, "potions");
}

function mint(uint _id, uint _amount) external {
    _mint(msg.sender, _id, _amount, "potions");
}

function mintSword(uint _amount) external {
    _mint(msg.sender, 2, _amount, "sword");
}

function mintShield(uint _amount) external {
    _mint(msg.sender, 3, _amount, "shield");
}

function mintBoots(uint _amount) external {
    _mint(msg.sender, 4, _amount, "boots");
}

function mintHelmet(uint _amount) external {
    _mint(msg.sender, 5, _amount, "helmet");
}

}