// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract NFT721 is ERC721Enumerable{
    bool revealed;

    constructor() ERC721("721test","721"){
    _safeMint(msg.sender, totalSupply());
    _safeMint(msg.sender, totalSupply());
    _safeMint(msg.sender, totalSupply());
    }

    function mint(uint _amount) external {
        for(uint i = 0; i < _amount; i++) _safeMint(msg.sender, totalSupply());
    }

    function reveal() external {
        revealed = true;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory tier;

        if(revealed) tier = "test_metadata.json";
        else tier = "unrevealed.json";

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tier)) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return "https://ipfs.io/ipfs/QmWRVVr8jZEJnvFXuADH5QkMMPiSBVAongdVXLrMSbqBN3";
    }
}