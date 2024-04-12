//  SPDX-License-Identifier: -- Come2Top --
pragma solidity 0.8.18;

interface IERC20 {
    function approve(address spender, uint256 amount) external returns(bool);

    function allowance(address owner, address spender) external returns(uint256);
}