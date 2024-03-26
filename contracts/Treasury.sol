//  SPDX-License-Identifier: -- Risk-Labs --
pragma solidity 0.8.18;

/**
    @author @Risk-Labs
    @title Come2Top Offerors Treasury.
    @dev Contract will be used by Come2Top contract
        as a seperate Treasury for Offerors.
*/
contract Treasury {
    bool public LOCKED;
    address public USDT;
    address public SPENDER;
    bytes4 public constant USDT_APPROVE_SELECTOR = 0x095ea7b3;
    uint256 public constant MAX_APPROVE_AMOUNT = type(uint256).max;

    fallback() external {
        SPENDER = msg.sender;
        USDT = abi.decode(msg.data, (address));

        (bool OK, ) = USDT.call(
            abi.encodeWithSelector(
                USDT_APPROVE_SELECTOR,
                SPENDER,
                MAX_APPROVE_AMOUNT
            )
        );

        require(OK && !LOCKED);

        LOCKED = true;
    }
}
