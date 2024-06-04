//  SPDX-License-Identifier: -- MIT --
pragma solidity 0.8.20;

interface IERC20 {
    function approve(address spender, uint256 amount) external returns(bool);

    function allowance(address owner, address spender) external returns(uint256);
}