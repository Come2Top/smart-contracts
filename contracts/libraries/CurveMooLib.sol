//  SPDX-License-Identifier: -- Come2Top --
pragma solidity 0.8.20;

import {ICurveStableSwapNG} from "../interfaces/ICurveStableSwapNG.sol";
import {IBeefyVaultV7} from "../interfaces/IBeefyVaultV7.sol";

library CurveMooLib {
    uint256 private constant $_I = 1;
    ICurveStableSwapNG private constant CurveStableSwapNG =
        ICurveStableSwapNG(0x63Eb7846642630456707C3efBb50A03c79B89D81);
    IBeefyVaultV7 private constant BeefyVaultV7 =
        IBeefyVaultV7(0x01Fbf9B624a6133Ab04Fc4000ae513AC97e4d114);

    function mintLPT(uint256 depositAmount) internal returns (uint256) {
        uint256[8] memory depositAmounts;
        depositAmounts[$_I] = depositAmount;

        return
            CurveStableSwapNG.add_liquidity(depositAmounts, $_I, address(this));
    }

    function burnLPT(uint256 withdrawAmount, address receiver)
        internal
        returns (uint256)
    {
        return
            CurveStableSwapNG.remove_liquidity_one_coin(
                withdrawAmount,
                int128(uint128($_I)),
                $_I,
                receiver
            );
    }

    function depositLPT(uint256 amount) internal {
        BeefyVaultV7.deposit(amount);
    }

    function withdrawLPT(uint256 share) internal {
        BeefyVaultV7.withdraw(share);
    }
}
