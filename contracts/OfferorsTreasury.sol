// SPDX-License-Identifier: --256--
pragma solidity 0.8.18;

import {IUSDT} from "./interfaces/IUSDT.sol";

contract OfferorsTreasury {
    IUSDT immutable public USDC;
    address immutable public GAME;

    constructor(IUSDT usdt) {
        GAME = msg.sender;
        USDC = usdt;
    }

    function transferUSDT(address to, uint256 amount) external {
        require(msg.sender == GAME, "ONLY_GAME_FUNCTION");

        USDC.transfer(to, amount);
    }
}
