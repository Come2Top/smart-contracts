// SPDX-License-Identifier: --256--
pragma solidity 0.8.18;

import {IUSDC} from "./interfaces/IUSDC.sol";

contract OfferorsTreasury {
    IUSDC immutable public USDC;
    address immutable public GAME;

    uint256 constant public GAME_COMMISSION = 50000;
    uint256 constant public BASIS = 1000000;

    constructor(IUSDC usdc) {
        GAME = msg.sender;
        USDC = usdc;
    }

    function transferUSDC(address to, uint256 amount) external {
        require(msg.sender == GAME, "ONLY_GAME_FUNCTION");

        USDC.transfer(to, amount);
    }
}
