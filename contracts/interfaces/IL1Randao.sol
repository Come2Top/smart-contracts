//  SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/// @notice The L1Block predeploy gives users access to information about the last known L1 block.
///         Values within this contract are updated once per epoch (every L1 block) and can only be
///         set by the "depositor" account, a special system address. Depositor account transactions
///         are created by the protocol whenever we move to a new epoch.
interface IL1Randao {
    /// @notice The latest L1 block number known by the Fraxtal L2 system.
    function number() external view returns(uint64);

    /// @notice Mapping from L1 block number to L1 block prevrandao that it written after a block hash is received from L1.
    function numberToRandao(uint64 number) external view returns (uint256);
}
