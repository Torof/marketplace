// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../node_modules/erc721a/contracts/ERC721A.sol";

contract NFT721A is ERC721A("721Atest","721a"){


constructor (uint _amount) {
    _mintERC2309(msg.sender, _amount);
}

function mint(uint _amount) external {
    _mint(msg.sender, _amount);
}
}