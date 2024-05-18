// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
}

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

contract KungFuK9 is Context, IERC20, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    string public constant url = "https://kfk9-coin.io";

    string private _name = "KungFuK9";
    string private _symbol = "KFK9";
    uint8 private _decimals = 18;
    uint256 private _totalSupply = 314159265358979323846264338327 * (10 ** uint256(_decimals));
    uint256 public taxFee = 2; // 2% tax fee
    address public taxRecipient; // Address to receive tax fees
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    constructor() {
        taxRecipient = owner();
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override nonReentrant returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override nonReentrant returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override nonReentrant returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        _approve(sender, _msgSender(), currentAllowance.sub(amount));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 fee = amount.mul(taxFee).div(100);
        uint256 amountAfterFee = amount.sub(fee);

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amountAfterFee);
        _balances[taxRecipient] = _balances[taxRecipient].add(fee);

        emit Transfer(sender, recipient, amountAfterFee);
        emit Transfer(sender, taxRecipient, fee);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function setTaxFee(uint256 fee) external onlyOwner {
        require(fee >= 0 && fee <= 100, "Tax fee must be between 0 and 100");
        taxFee = fee;
    }

    function setTaxRecipient(address recipient) external onlyOwner {
        require(recipient != address(0), "Tax recipient cannot be the zero address");
        taxRecipient = recipient;
    }

    // Function to check balance of any address
    function checkBalance(address account) external view returns (uint256) {
        return _balances[account];
    }

    // Function to transfer tokens to an external address, only callable by the owner
    function transferToAddress(address recipient, uint256 amount) external onlyOwner nonReentrant {
        require(recipient != address(0), "Cannot transfer to the zero address");
        require(amount <= _balances[owner()], "Transfer amount exceeds balance");

        _balances[owner()] = _balances[owner()].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);

        emit Transfer(owner(), recipient, amount);
    }

    // Function to burn tokens, only callable by the owner
    function burn(uint256 amount) external onlyOwner nonReentrant {
        require(amount <= _balances[owner()], "Burn amount exceeds balance");

        _balances[owner()] = _balances[owner()].sub(amount);
        _totalSupply = _totalSupply.sub(amount);

        emit Transfer(owner(), address(0), amount);
    }
}
