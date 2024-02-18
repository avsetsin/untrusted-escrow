// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title Escrow Contract
 * @dev A smart contract for handling escrow transactions between a buyer and a seller
 */
contract Escrow {
    using SafeERC20 for IERC20;

    IERC20 public immutable TOKEN;
    address public immutable BUYER;
    address public immutable SELLER;
    uint256 public immutable PRICE;

    uint256 public constant TIMELOCK = 3 days;

    uint256 public depositTimestamp;

    event Deposit(address indexed buyer, uint256 amount);
    event Withdraw(address indexed seller, uint256 amount);

    error NotBuyer(address account);
    error NotSeller(address account);
    error NotDeposited();
    error AlreadyDeposited(uint256 timestamp);
    error TimeLockNotExpired(uint256 expirationTime);
    error DepositLessThanPrice(uint256 deposit, uint256 price);

    /**
     * @dev Constructor function
     * @param buyer The address of the buyer
     * @param seller The address of the seller
     * @param token The address of the ERC20 token used for the escrow
     * @param price The price of the item being sold
     */
    constructor(address buyer, address seller, address token, uint256 price) {
        TOKEN = IERC20(token);
        BUYER = buyer;
        SELLER = seller;
        PRICE = price;
    }

    /**
     * @dev Deposits funds into the escrow
     * @param amount The amount of tokens to deposit
     */
    function deposit(uint256 amount) public {
        if (msg.sender != BUYER) revert NotBuyer(msg.sender);
        if (_isDepositDone()) revert AlreadyDeposited(depositTimestamp);

        depositTimestamp = block.timestamp;

        uint256 balanceBefore = TOKEN.balanceOf(address(this));
        TOKEN.safeTransferFrom(msg.sender, address(this), amount);
        uint256 balanceAfter = TOKEN.balanceOf(address(this));
        uint256 deposited = balanceAfter - balanceBefore;

        if (deposited < PRICE) revert DepositLessThanPrice(deposited, PRICE);

        emit Deposit(msg.sender, deposited);
    }

    /**
     * @dev Withdraws funds from the escrow
     */
    function withdraw() public {
        if (msg.sender != SELLER) revert NotSeller(msg.sender);
        if (!_isDepositDone()) revert NotDeposited();
        if (!_isTimeLockExpired()) revert TimeLockNotExpired(depositTimestamp + TIMELOCK);

        uint256 withdrawn = TOKEN.balanceOf(address(this));
        TOKEN.safeTransfer(msg.sender, withdrawn);

        emit Withdraw(msg.sender, withdrawn);
    }

    /**
     * @dev Checks if the timelock has expired
     * @return result A boolean indicating whether the timelock has expired
     */
    function _isTimeLockExpired() internal view returns (bool) {
        return block.timestamp >= depositTimestamp + TIMELOCK;
    }

    /**
     * @dev Checks if a deposit has been made
     * @return result A boolean indicating whether a deposit has been made
     */
    function _isDepositDone() internal view returns (bool) {
        return depositTimestamp != 0;
    }
}
