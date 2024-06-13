//  SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/// @notice ERC20 interface, which is used for easier interactions with ERC20 contracts.
interface IERC20 {
    /**
        @notice Allows the contract to transfer Deft tokens to a specified address.
        @dev Allows the contract to transfer Deft tokens to a specified address.
        @param to The address to which the Deft tokens will be transferred.
        @param amount The amount of Deft tokens to be transferred.
    */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
        @notice Allows the contract to transfer Deft tokens from one address to another.
        @dev Allows the contract to transfer Deft tokens from one address to another.
        @param from The address from which the Deft tokens will be transferred.
        @param to The address to which the Deft tokens will be transferred.
        @param amount The amount of Deft tokens to be transferred.
        @return bool indicating if the transfer was successful or not.
    */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}
