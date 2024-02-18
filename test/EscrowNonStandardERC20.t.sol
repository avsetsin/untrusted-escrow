// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Escrow} from "../src/Escrow.sol";

contract TokenWithFee is ERC20 {
    address feeRecipient = address(0xfee);
    uint256 feeBasisPoints = 5_000;

    constructor() ERC20("Test token", "TKN") {
        _mint(msg.sender, 100_000);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        uint256 fee = amount * feeBasisPoints / 10_000;
        uint256 netAmount = amount - fee;

        super.transferFrom(sender, recipient, netAmount);
        super.transferFrom(sender, feeRecipient, fee);

        return true;
    }
}

contract EscrowTest is Test {
    Escrow public escrow;
    TokenWithFee public token;

    address buyer = address(this);
    address seller = address(0x2);
    address stranger = address(0x3);
    uint256 price = 10_000;

    event Deposit(address indexed buyer, uint256 amount);
    event Withdraw(address indexed seller, uint256 amount);

    function setUp() public {
        token = new TokenWithFee();
        escrow = new Escrow(buyer, seller, address(token), price);
    }

    // Deposits

    function test_DepositOnlyPrice() public {
        token.approve(address(escrow), price);

        vm.expectRevert(abi.encodeWithSelector(Escrow.DepositLessThanPrice.selector, price / 2, price));
        escrow.deposit(price);
    }

    function test_DepositPriceWithFee() public {
        uint256 priceWithFee = price * 2;
        token.approve(address(escrow), priceWithFee);
        escrow.deposit(priceWithFee);

        assertEq(token.balanceOf(address(escrow)), price);
    }
}
