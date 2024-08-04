// SPDX-License-Identifier: -- Come2Top --
pragma solidity 0.8.20;

import {GameConstantsLib} from "./GameConstantsLib.sol";

library GameUintCheckersLib {
    error VALUE_CANT_BE_LOWER_THAN(uint256 givenValue);
    error VALUE_CANT_BE_GREATER_THAN(uint256 givenValue);
    error ZERO_UINT_PROVIDED();

    /**
        @dev It verifies that the value is not zero
            and not greater than the maximum limit predefined as {8}.
        @param value The value to be checked for maximum tickets per game.
    */
    function checkMTPG(uint8 value) internal pure {
        revertOnZeroUint(value);

        // if (value > 8) revert VALUE_CANT_BE_GREATER_THAN(8);
    }

    /**
        @dev It verifies that the value is not zero
            and not lower than the minimum limit predefined as {MIN_PRNG_PERIOD}.
        @param value The value to be checked for maximum tickets per game.
    */
    function checkPRNGP(uint256 value) internal pure {
        revertOnZeroUint(value);

        if (value < GameConstantsLib.MIN_PRNG_PERIOD())
            revert VALUE_CANT_BE_LOWER_THAN(GameConstantsLib.MIN_PRNG_PERIOD());
    }

    /**
        @dev It verifies that the value is not zero
            and not lower than the minimum limit predefined as {MIN_TICKET_PRICE}.
        @param value The ticket price value to be checked
    */
    function checkTP(uint80 value) internal pure {
        revertOnZeroUint(value);

        if (value < GameConstantsLib.MIN_TICKET_PRICE())
            revert VALUE_CANT_BE_LOWER_THAN(
                GameConstantsLib.MIN_TICKET_PRICE()
            );
    }

    /**
        @dev It verifies that the value is not zero
            and not greater than the maximum limit predefined as {6}.
        @param value The value to be checked for game strategy.
    */
    function checkGS(uint8 value) internal pure {
        if (value > 6) revert VALUE_CANT_BE_GREATER_THAN(6);
    }

    /**
        @dev Checks if the provided uint value is zero and reverts the transaction if it is.
        @param uInt The uint value to be checked.
    */
    function revertOnZeroUint(uint256 uInt) internal pure {
        if (uInt == 0) revert ZERO_UINT_PROVIDED();
    }
}
