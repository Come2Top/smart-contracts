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
    uint256 public supplyWatcher;
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

        if (totalSupply == 0) supplyWatcher = block.timestamp;
        uint256 bal = balance();
        CurveStableSwapNG.transferFrom(sender, address(this), amount);

        uint256 shares;
        totalSupply == 0 ? shares = amount : shares =
            (amount * totalSupply) /
            bal;

        totalSupply += shares;
        balanceOf[sender] += shares;
    }

    function withdraw(uint256 shares) external {
        address sender = msg.sender;
        uint256 asset = (balance() * shares) / totalSupply;

        CurveStableSwapNG.internalBurn(shares);

        balanceOf[sender] -= shares;
        totalSupply -= shares;

        if (totalSupply == 0) delete supplyWatcher;

        CurveStableSwapNG.transfer(sender, asset);
    }

    function getPricePerFullShare() external view returns (uint256) {
        return totalSupply == 0 ? 1e18 : (balance() * 1e18) / totalSupply;
    }

    function balance() public view returns (uint256) {
        if (totalSupply == 0) return 0;

        uint256 bal = CurveStableSwapNG.balanceOf(address(this));

        // using simple interest for test
        uint256 n = block.timestamp - supplyWatcher;
        if (n == 0) n = 1;

        // interest rate = 2777777777777/s (1e18 base -> 1% every hour == 1e16 of balance)
        return bal + ((bal * n * 2777777777777) / 1e18);
    }
}
