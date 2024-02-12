// SPDX-License-Identifier: --256--
pragma solidity 0.8.18;

import {IUSDC} from "./interfaces/IUSDC.sol";

contract OfferorsTreasury {
    IUSDC immutable public USDC;
    address immutable public GAME;

    constructor(IUSDC usdc) {
        GAME = msg.sender;
        USDC = usdc;
    }

    function transferUSDC(address to, uint256 amount) external {
        require(msg.sender == GAME, "ONLY_GAME_FUNCTION");

        USDC.transfer(to, amount);
    }
}
