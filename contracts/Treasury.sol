//  SPDX-License-Identifier: -- Come2Top --
pragma solidity 0.8.20;

/**
    @author @4bit-lab
    @title Come2Top Offerors Treasury.
    @dev Contract will be used by Come2Top contract
        as a seperate Treasury for Offerors.
*/
contract Treasury {
    bool public INIT;
    address public TOKEN;
    address public COME2TOP;

    fallback() external {
        COME2TOP = msg.sender;
        TOKEN = abi.decode(msg.data, (address));

        (bool OK, ) = TOKEN.call(
            abi.encodeWithSelector(0x095ea7b3, COME2TOP, type(uint256).max)
        );

        require(OK && !INIT);

        INIT = true;
    }
}
