// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Escrow} from "./Escrow.sol";

/**
 * @title Escrow Factory
 * @notice This contract is used to create new Escrow contracts
 */
contract EscrowFactory {
    event EscrowDeployed(address indexed buyer, address indexed seller, address indexed token, address escrow);

    /**
     * @notice Deploys a new Escrow contract
     * @dev Emits an EscrowDeployed event upon successful deployment
     * @param buyer The address of the buyer
     * @param seller The address of the seller
     * @param token The address of the token to be transacted
     * @param price The price to be paid by the buyer
     * @return escrow The newly deployed Escrow contract
     */
    function deployEscrow(address buyer, address seller, address token, uint256 price) public returns (Escrow escrow) {
        escrow = new Escrow(buyer, seller, token, price);
        emit EscrowDeployed(buyer, seller, token, address(escrow));
    }
}
