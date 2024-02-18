// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Escrow} from "../src/Escrow.sol";

contract Token is ERC20 {
    constructor() ERC20("Test token", "TKN") {
        _mint(msg.sender, 100_000);
    }
}

contract EscrowTest is Test {
    Escrow public escrow;
    Token public token;

    address buyer = address(this);
    address seller = address(0x2);
    address stranger = address(0x3);
    uint256 price = 10_000;

    event Deposit(address indexed buyer, uint256 amount);
    event Withdraw(address indexed seller, uint256 amount);

    function setUp() public {
        token = new Token();
        escrow = new Escrow(buyer, seller, address(token), price);
    }

    function test_Constructor() public {
        assertEq(address(escrow.TOKEN()), address(token));
        assertEq(escrow.BUYER(), buyer);
        assertEq(escrow.SELLER(), seller);
        assertEq(escrow.PRICE(), price);
    }

    function test_Constnat() public {
        assertEq(escrow.TIMELOCK(), 3 days);
    }

    // Deposits

    function test_Deposit() public {
        token.approve(address(escrow), price);
        escrow.deposit(price);

        assertEq(token.balanceOf(address(escrow)), price);
    }

    function test_InsufficientDeposit() public {
        uint256 deposit = price - 1;
        token.approve(address(escrow), deposit);

        vm.expectRevert(abi.encodeWithSelector(Escrow.DepositLessThanPrice.selector, deposit, price));
        escrow.deposit(deposit);
    }

    function test_ExtraDeposit() public {
        uint256 deposit = price + 1;
        token.approve(address(escrow), deposit);
        escrow.deposit(deposit);

        assertEq(token.balanceOf(address(escrow)), deposit);
    }

    function test_DepositFromNonBuyer() public {
        token.approve(address(escrow), price);

        vm.prank(stranger);
        vm.expectRevert(abi.encodeWithSelector(Escrow.NotBuyer.selector, stranger));
        escrow.deposit(price);
    }

    function test_DepositTwice() public {
        token.approve(address(escrow), price);
        escrow.deposit(price);

        vm.expectRevert(abi.encodeWithSelector(Escrow.AlreadyDeposited.selector, escrow.depositTimestamp()));
        escrow.deposit(price);
    }

    function test_DepositTimestamp() public {
        token.approve(address(escrow), price);
        escrow.deposit(price);

        assertEq(escrow.depositTimestamp(), block.timestamp);
    }

    function test_DepositEmitsEvent() public {
        token.approve(address(escrow), price);

        vm.expectEmit(true, true, true, true, address(escrow));
        emit Deposit(buyer, price);

        escrow.deposit(price);
    }

    // Withdrawals

    function test_Withdraw() public {
        depositAndWarp(price, 0);

        vm.prank(seller);
        escrow.withdraw();

        assertEq(token.balanceOf(address(escrow)), 0);
    }

    function test_WithdrawExtra() public {
        depositAndWarp(price + 1, 0);

        vm.prank(seller);
        escrow.withdraw();

        assertEq(token.balanceOf(seller), price + 1);
    }

    function test_WithdrawFromNonSeller() public {
        depositAndWarp(price, 0);

        vm.expectRevert(abi.encodeWithSelector(Escrow.NotSeller.selector, stranger));
        vm.prank(stranger);
        escrow.withdraw();
    }

    function test_WithdrawBeforeTimelock() public {
        depositAndWarp(price, -1);

        vm.expectRevert(abi.encodeWithSelector(Escrow.TimeLockNotExpired.selector, timelockExpiration()));
        vm.prank(seller);
        escrow.withdraw();
    }

    function test_WithdrawBeforeDeposit() public {
        vm.expectRevert(abi.encodeWithSelector(Escrow.NotDeposited.selector));
        vm.prank(seller);
        escrow.withdraw();
    }

    function test_WithdrawEmitsEvent() public {
        depositAndWarp(price, 0);

        vm.expectEmit(true, true, true, true, address(escrow));
        emit Withdraw(seller, price);

        vm.prank(seller);
        escrow.withdraw();
    }

    // Direct transfers

    function test_DirectTransfer() public {
        token.transfer(address(escrow), 10);

        vm.expectRevert(abi.encodeWithSelector(Escrow.NotDeposited.selector));
        vm.prank(seller);
        escrow.withdraw();
    }

    function test_DirectTransferAndDeposit() public {
        token.transfer(address(escrow), 10);
        depositAndWarp(price, 0);

        vm.prank(seller);
        escrow.withdraw();

        assertEq(token.balanceOf(seller), price + 10);
    }

    // Helpers

    function depositAndWarp(uint256 amount, int256 extraTime) public {
        token.approve(address(escrow), amount);
        escrow.deposit(amount);
        vm.warp(uint256(extraTime + int256(timelockExpiration())));
    }

    function timelockExpiration() public view returns (uint256) {
        return escrow.depositTimestamp() + escrow.TIMELOCK();
    }
}
