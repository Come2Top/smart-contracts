// SPDX-License-Identifier: --256--
pragma solidity 0.8.18;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external;

    function balanceOf(address account) external view returns (uint256);
}
