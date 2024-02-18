// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {EscrowFactory} from "../src/EscrowFactory.sol";
import {Escrow} from "../src/Escrow.sol";

contract EscrowFactoryTest is Test {
    EscrowFactory public escrowFactory;

    event EscrowDeployed(address indexed buyer, address indexed seller, address indexed token, address escrow);

    function setUp() public {
        escrowFactory = new EscrowFactory();
    }

    function test_DeployEscrow() public {
        address buyer = address(0x1);
        address seller = address(0x2);
        address token = address(0x3);
        uint256 price = 100;

        Escrow escrow = escrowFactory.deployEscrow(buyer, seller, token, price);

        assertEq(address(escrow.TOKEN()), token);
        assertEq(escrow.BUYER(), buyer);
        assertEq(escrow.SELLER(), seller);
        assertEq(escrow.PRICE(), price);
    }

    function test_DeployEscrowEvent() public {
        address buyer = address(0x1);
        address seller = address(0x2);
        address token = address(0x3);
        uint256 price = 100;

        vm.expectEmit(true, true, true, false);
        emit EscrowDeployed(buyer, seller, token, address(0));

        escrowFactory.deployEscrow(buyer, seller, token, price);
    }
}
