//SPDX-License-Identifier: MIT

pragma solidity ^0.8.6; 

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract WETH is ERC20("Wrapped Ethereum", "WETH"){

function mint(address _to, uint _amount) external {
    _mint(_to, _amount);
}

}