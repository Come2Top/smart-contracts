//  SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

/**
    @author @FarajiOranj
    @custom:auditor @MatinR1

    @title Come2Top Offerors Treasury.
    @dev Contract will be used by Come2Top contract
        as a seperate Treasury for Offerors.
*/
contract C2Treasury {
    bool private _$;

    fallback() external {
        (bool $, ) = abi.decode(msg.data, (address)).call(
            abi.encodeWithSelector(0x095ea7b3, msg.sender, type(uint256).max)
        );

        assert($ && !_$);

        _$ = true;
    }
}