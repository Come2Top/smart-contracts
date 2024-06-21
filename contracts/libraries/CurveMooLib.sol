//  SPDX-License-Identifier: -- Come2Top --
pragma solidity 0.8.20;

import {ICurveStableNG} from "../interfaces/ICurveStableNG.sol";
import {IBeefyVault} from "../interfaces/IBeefyVault.sol";

// ONLY USABLE for CURVE STABLESWAP NG
library CurveMooLib {
    function mintLPT(uint256 depositAmount, uint256 fraxTokenPosition, ICurveStableNG curveStableNG) internal returns (uint256) {
        uint256[8] memory depositAmounts;
        depositAmounts[fraxTokenPosition] = depositAmount;

        return
            curveStableNG.add_liquidity(depositAmounts, 0, address(this));
    }

    function burnLPT(uint256 withdrawAmount, address receiver, uint256 fraxTokenPosition, ICurveStableNG curveStableNG)
        internal
        returns (uint256)
    {
        return
            curveStableNG.remove_liquidity_one_coin(
                withdrawAmount,
                int128(uint128(fraxTokenPosition)),
                0,
                receiver
            );
    }

    function depositLPT(uint256 amount, IBeefyVault beefyVault) internal {
        beefyVault.deposit(amount);
    }

    function withdrawLPT(uint256 share, IBeefyVault beefyVault) internal {
        beefyVault.withdraw(share);
    }
}
