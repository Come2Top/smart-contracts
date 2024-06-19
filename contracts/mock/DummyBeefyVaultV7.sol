//  SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {DummyCurveStableSwapNG} from "./DummyCurveStableSwapNG.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DummyBeefyVaultV7 {
    string public constant name = "Moo Curve crvUSD-FRAX";
    string public constant symbol = "mooCurveCrvUSD-FRAX";
    uint8 public constant decimals = 18;
    DummyCurveStableSwapNG public immutable CurveStableSwapNG;

    address public come2Top;
    uint256 public totalSupply;
    uint256 private lastUpdatedTime;
    mapping(address => uint256) public balanceOf;

    constructor() {
        CurveStableSwapNG = new DummyCurveStableSwapNG();
    }

    function setCome2Top(address come2Top_) external {
        require(come2Top == address(0) && come2Top_ != address(0));

        come2Top = come2Top_;
    }

    function deposit(uint256 amount) external {
        address sender = msg.sender;
        require(sender == come2Top);

        CurveStableSwapNG.transferFrom(sender, address(this), amount);

        uint256 shares;
        totalSupply == 0 ? shares = amount : shares =
            (amount * totalSupply) /
            balance();

        lastUpdatedTime = block.timestamp;
        totalSupply += shares;
        balanceOf[sender] += shares;
    }

    function withdraw(uint256 shares) external {
        address sender = msg.sender;
        uint256 asset = (balance() * shares) / totalSupply;

        CurveStableSwapNG.internalBurn(shares);

        lastUpdatedTime = block.timestamp;
        balanceOf[sender] -= shares;
        totalSupply -= shares;

        CurveStableSwapNG.transfer(sender, asset);
    }

    function getPricePerFullShare() external view returns (uint256) {
        return
            totalSupply == 0
                ? 1e18
                : 1e18 +
                    (balance() *
                        (100 +
                            ((block.timestamp - lastUpdatedTime) /
                                8 minutes))) /
                    (totalSupply * 100);
    }

    function balance() public view returns (uint256) {
        return
            CurveStableSwapNG.balanceOf(address(this)) +
            ((1e18 * (block.timestamp - lastUpdatedTime)) / 8 minutes);
    }
}
