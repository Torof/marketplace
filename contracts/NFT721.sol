// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract NFT721 is ERC721Enumerable{


    constructor() ERC721("721test","721"){
     _safeMint(msg.sender, totalSupply());
     _safeMint(msg.sender, totalSupply());
     _safeMint(msg.sender, totalSupply());
    }

    function mint(uint _amount) external {
        for(uint i = 0; i < _amount; i++) _safeMint(msg.sender, totalSupply());
    }
}