//  SPDX-License-Identifier: -- DeftGame --
pragma solidity 0.8.20;

/**
    @author @4bit-lab
    @title DeftGame Offerors Treasury.
    @dev Contract will be used by DeftGame contract
        as a seperate Treasury for Offerors.
*/
contract Treasury {
    bool public LOCKED;
    address public DEFT;
    address public DEFT_GAME;

    fallback() external {
        DEFT_GAME = msg.sender;
        DEFT = abi.decode(msg.data, (address));

        (bool OK, ) = DEFT.call(
            abi.encodeWithSelector(0x095ea7b3, DEFT_GAME, type(uint256).max)
        );

        require(OK && !LOCKED);

        LOCKED = true;
    }
}
