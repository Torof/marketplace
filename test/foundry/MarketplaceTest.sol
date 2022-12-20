//SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "forge-std/Test.sol";
import "../../contracts/Marketplace.sol";
import "../../contracts/WETH.sol";

contract MarketplaceTest is Test {
    uint256 testNumber;
    Marketplace public marketplace;
    WETH public weth;

    function setUp() public {
        weth = new WETH();
        marketplace = new Marketplace(address(weth));
        testNumber = 42;
    }

    function testNumberIs42() public {
        assertEq(testNumber, 42);
    }

    function testFailSubtract43() public {
        testNumber -= 43;
    }
}
