//  SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ICurveStableSwapNG} from "../interfaces/ICurveStableSwapNG.sol";
import {DummyFraxStablecoin} from "./DummyFraxStablecoin.sol";

interface IOwner {
    function come2Top() external view returns (address);
}

contract DummyCurveStableSwapNG is ICurveStableSwapNG {
    bytes32 public constant PERMIT_TYPEHASH =
        keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );
    string public constant name = "crvUSD/Frax";
    string public constant symbol = "crvUSDFRAX";
    uint8 public constant decimals = 18;
    uint256 private constant _MAX_UINT256 = type(uint256).max;
    bytes32 public immutable DOMAIN_SEPARATOR =
        keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    uint256 private immutable MAX_SUPPLY = _MAX_UINT256;
    IOwner private immutable OWNER = IOwner(msg.sender);
    DummyFraxStablecoin private immutable FRAX;
    uint256 public totalSupply;
    mapping(address => uint256) public nonces;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    constructor() {
        FRAX = new DummyFraxStablecoin(1e4);

        balanceOf[msg.sender] = _MAX_UINT256;
        totalSupply = _MAX_UINT256;
    }

    function add_liquidity(
        uint256[8] memory deposit_amounts,
        uint256 min_mint_amount,
        address receiver
    ) external returns (uint256) {
        min_mint_amount;
        receiver;

        require(msg.sender == OWNER.come2Top());
        FRAX.transfer(address(this), deposit_amounts[1]);
        FRAX.internalBurn(address(this),deposit_amounts[1]);
        return deposit_amounts[1];
    }

    function remove_liquidity_one_coin(
        uint256 burn_amount,
        int128 i,
        uint256 min_received,
        address receiver
    ) external returns (uint256) {
        i;
        min_received;

        require(msg.sender == OWNER.come2Top());
        FRAX.internalMint(receiver, burn_amount);
        return burn_amount;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        address owner = msg.sender;

        _transfer(owner, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {
        address spender = msg.sender;

        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);

        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        address owner = msg.sender;

        _approve(owner, spender, amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool)
    {
        address owner = msg.sender;

        _approve(owner, spender, allowance[owner][spender] + addedValue);

        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool)
    {
        address owner = msg.sender;
        uint256 currentAllowance = allowance[owner][spender];

        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );

        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(
            block.timestamp <= deadline,
            "TokenWrapped::permit: Expired permit"
        );

        bytes32 hashStruct = keccak256(
            abi.encode(
                PERMIT_TYPEHASH,
                owner,
                spender,
                value,
                nonces[owner]++,
                deadline
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, hashStruct)
        );

        address signer = ecrecover(digest, v, r, s);
        require(
            signer != address(0) && signer == owner,
            "TokenWrapped::permit: Invalid signature"
        );

        _approve(owner, spender, value);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        uint256 fromBalance = balanceOf[from];

        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );

        unchecked {
            balanceOf[from] = fromBalance - amount;
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        allowance[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) private {
        uint256 currentAllowance = allowance[owner][spender];

        if (currentAllowance != _MAX_UINT256) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );

            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }
}
