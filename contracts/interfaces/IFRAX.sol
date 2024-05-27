//  SPDX-License-Identifier: MIT
pragma solidity 0.8.20;


/// @notice FRAX interface, which is used for easier interactions with FRAX contracts.
interface IFRAX {
    /**
        @notice Allows the contract to transfer FRAX tokens to a specified address.
        @dev Allows the contract to transfer FRAX tokens to a specified address.
        @param to The address to which the FRAX tokens will be transferred.
        @param amount The amount of FRAX tokens to be transferred.
    */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
        @notice Allows the contract to transfer FRAX tokens from one address to another.
        @dev Allows the contract to transfer FRAX tokens from one address to another.
        @param from The address from which the FRAX tokens will be transferred.
        @param to The address to which the FRAX tokens will be transferred.
        @param amount The amount of FRAX tokens to be transferred.
        @return bool indicating if the transfer was successful or not.
    */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}