// SPDX-License-Identifier: --256--
pragma solidity 0.8.18;

import {IERC20} from "./IERC20.sol";

/// @notice Interface of the ERC20 standard as defined in the EIP.
interface IUSDC is IERC20 {
    /**
        @dev Checks if account is blacklisted

        @param _account The address to check
    */
    function isBlacklisted(address _account) external view returns (bool);
}
