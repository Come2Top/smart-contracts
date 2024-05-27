//  SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IL1Randao {
    function number() external view returns(uint64);
    function numberToRandao(uint64 number) external view returns (uint256);
}
