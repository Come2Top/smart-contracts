//  SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface ICurveStableNG {
    function add_liquidity(
        uint256[8] memory deposit_amounts,
        uint256 min_mint_amount,
        address receiver
    ) external returns (uint256);

    function remove_liquidity_one_coin(
        uint256 burn_amount,
        int128 i,
        uint256 min_received,
        address receiver
    ) external returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function N_COINS() external view returns (uint256);

    function coins(uint256 arg0) external view returns (address);
}
