pragma solidity ^0.8.13;

import "./ERC20.sol";

contract ubst is IERC20 {
    uint public extendNo = 0;
    uint public totalSupply = 90000000;
    uint public depositFee = 9000000 gwei;
    uint public returnFee = 7000000 gwei;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
    string public name = "20182011 IE421Assignment 1";
    string public symbol = "IEA1";
    uint8 public decimals = 5;
    bool public isInitialized = false;
    
    constructor() public {
        require(msg.sender == 0xfb67ff7969C5F9261Abd9E498b5Fa71B70BF39E5, "Only Venus can initialize this token!!");
        require(!isInitialized, "token already initialized!!");
        isInitialized = true;
        totalSupply = 90000000;
        balanceOf[0xfb67ff7969C5F9261Abd9E498b5Fa71B70BF39E5] = 30000000;
        balanceOf[0xb89F66a4639E1Bd668A67e8C7F2f556f2e90645d] = 30000000;
        balanceOf[0x74565507439a899daEc1D7a285a3E39924E88Eeb] = 30000000;
    }

    function transfer(address recipient, uint amount) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool) {
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function extendSupply() public payable {
        require(msg.sender == 0xfb67ff7969C5F9261Abd9E498b5Fa71B70BF39E5, "The token supply is not extended!!");
        require(msg.value == depositFee, "The amount must be equal to the deposit fee");
        totalSupply += 10000000;
        balanceOf[0xfb67ff7969C5F9261Abd9E498b5Fa71B70BF39E5] += 10000000;
        extendNo += 1;
    }

    function reduceSupply() public payable {
        require(msg.sender == 0xfb67ff7969C5F9261Abd9E498b5Fa71B70BF39E5, "The token supply is not extended!!");
        require(extendNo >= 1, "The token supply cannot be reduced");
        (bool sent, bytes memory data) = payable(msg.sender).call{value: returnFee}("");
        require(sent, "Failed to send deposit");
        require(balanceOf[0xfb67ff7969C5F9261Abd9E498b5Fa71B70BF39E5] >= 10000000, "The amount of tokens is not enough");
        balanceOf[0xfb67ff7969C5F9261Abd9E498b5Fa71B70BF39E5] -= 10000000;
        totalSupply -= 10000000;
        extendNo -= 1;
    }

}

