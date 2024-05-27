//  SPDX-License-Identifier: -- Come2Top --
pragma solidity 0.8.20;

/**
    @author @4bit-lab
    @title Come2Top Offerors Treasury.
    @dev Contract will be used by Come2Top contract
        as a seperate Treasury for Offerors.
*/
contract Treasury {
    bool public LOCKED;
    address public FRAX;
    address public COME2TOP;

    fallback() external {
        COME2TOP = msg.sender;
        FRAX = abi.decode(msg.data, (address));

        (bool OK, ) = FRAX.call(
            abi.encodeWithSelector(0x095ea7b3, COME2TOP, type(uint256).max)
        );

        require(OK && !LOCKED);

        LOCKED = true;
    }
}
