// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

contract DummyFraxStablecoin {
    bytes32 public constant PERMIT_TYPEHASH =
        keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );
    string public constant name = "Frax";
    string public constant symbol = "FRAX";
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
    uint256 public immutable MINT_CAP;
    address private immutable OWNER = msg.sender;
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

    constructor(uint256 mintCap) {
        require(mintCap != 0);

        MINT_CAP = mintCap * (10**decimals);
    }

    function internalMint(address to, uint256 amount) external {
        require(msg.sender == OWNER, "ONLY_OWNER");

        unchecked {
            balanceOf[to] += amount;
            totalSupply += amount;
        }
        emit Transfer(address(0), to, amount);
    }

    function internalBurn(address from, uint256 amount) external {
        require(msg.sender == OWNER, "ONLY_OWNER");

        unchecked {
            balanceOf[from] -= amount;
            totalSupply -= amount;
        }
        emit Transfer(from, address(0), amount);
    }

    function mint() external {
        address account = msg.sender;
        uint256 balance = balanceOf[account];

        require(
            balance < MINT_CAP,
            "ERC20: address balance reached to {MINT_CAP} or is over that"
        );

        balance = MINT_CAP - balance;

        require(
            _MAX_UINT256 - balance >= totalSupply,
            "ERC20: mint amount exceeds {_MAX_UINT256}"
        );

        balanceOf[account] = MINT_CAP;
        unchecked {
            totalSupply += balance;
        }

        require(
            totalSupply <= MAX_SUPPLY,
            "ERC20: mint amount exceeds {MAX_SUPPLY}"
        );

        emit Transfer(address(0), account, balance);
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
