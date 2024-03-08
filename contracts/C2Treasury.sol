//  SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

/**
    @author @FarajiOranj
    @title Come2Top Offerors Treasury.
    @dev Contract will be used by Come2Top contract
        as a seperate Treasury for Offerors.
*/
contract C2Treasury {
    bool private initialized;

    fallback() external {
        address spender = msg.sender;
        bytes4 approveSelector = 0x095ea7b3;
        uint256 approveAmount = type(uint256).max;
        address token = abi.decode(msg.data, (address));

        (bool success, ) = token.call(
            abi.encodeWithSelector(approveSelector, spender, approveAmount)
        );

        assert(success && !initialized);

        initialized = true;
    }
}
