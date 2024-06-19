//  SPDX-License-Identifier: -- Come2Top --
pragma solidity 0.8.20;

import {ICurveStableSwapNG} from "../interfaces/ICurveStableSwapNG.sol";
import {IBeefyVaultV7} from "../interfaces/IBeefyVaultV7.sol";

// ONLY USABLE for CURVE STABLESWAP NG
library CurveMooLib {
    uint256 private constant $_I = 1;

    function mintLPT(uint256 depositAmount, ICurveStableSwapNG curveStableswapNG) internal returns (uint256) {
        uint256[8] memory depositAmounts;
        depositAmounts[$_I] = depositAmount;

        return
            curveStableswapNG.add_liquidity(depositAmounts, $_I, address(this));
    }

    function burnLPT(uint256 withdrawAmount, address receiver, ICurveStableSwapNG curveStableswapNG)
        internal
        returns (uint256)
    {
        return
            curveStableswapNG.remove_liquidity_one_coin(
                withdrawAmount,
                int128(uint128($_I)),
                $_I,
                receiver
            );
    }

    function depositLPT(uint256 amount, IBeefyVaultV7 beefyVault) internal {
        beefyVault.deposit(amount);
    }

    function withdrawLPT(uint256 share, IBeefyVaultV7 beefyVault) internal {
        beefyVault.withdraw(share);
    }
}
