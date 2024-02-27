//  SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

interface IUSDT {
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}
