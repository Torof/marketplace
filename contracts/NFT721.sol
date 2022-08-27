// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFT721 is ERC721Enumerable{

    Counters.Counter public tokenIds;

    constructor() ERC721("721test","721"){
     _safeMint(msg.sender, Counters.current(tokenIds));
     Counters.increment(tokenIds);
     _safeMint(msg.sender, Counters.current(tokenIds));
     Counters.increment(tokenIds);
     _safeMint(msg.sender, Counters.current(tokenIds));
     Counters.increment(tokenIds);
    }

    function mint(uint _amount) external {
        for(uint i = 0; i <= _amount; i++) _safeMint(msg.sender, Counters.current(tokenIds));
        Counters.increment(tokenIds);
    }
}