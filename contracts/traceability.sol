pragma solidity ^0.4.24;

contract ERC20 {
    function totalSupply() public constant returns (uint supply);
    function balanceOf( address who ) public constant returns (uint value);
    function allowance( address owner, address spender ) public constant returns (uint _allowance);

    function transfer( address to, uint value) public returns (bool ok);
    function transferFrom( address from, address to, uint value) public returns (bool ok);
    function approve( address spender, uint value ) public returns (bool ok);

    event Transfer( address indexed from, address indexed to, uint value);
    event Approval( address indexed owner, address indexed spender, uint value);
}

contract TRToken is ERC20 {
	string public constant name = "Credit";
	string public constant symbol = "PTR";
	uint8 public constant decimals = 0;
	uint256 supply;
	mapping (address => uint256) balances;
	mapping (address => mapping (address => uint256)) approvals;

    function totalSupply() public constant returns (uint) {
    	return supply;
    }
    function balanceOf( address who ) public constant returns (uint) {
    	return balances[who];
    }
    function allowance( address owner, address spender ) public constant returns (uint) {
    	return approvals[owner][spender];
    }

    function transfer( address to, uint value) public returns (bool ok) {
    	assert(balances[msg.sender] >= value);
    	balances[msg.sender] -= value;
    	balances[to] += value;
    	emit Transfer(msg.sender, to, value);
    	return true;
    }
    function transferFrom( address from, address to, uint value) public returns (bool) {
    	assert(balances[from]>=value);
    	assert(approvals[from][msg.sender]>=value);
    	approvals[from][msg.sender] -= value;
    	balances[from] -= value;
    	emit Transfer(from, to, value);
    	return true;
    }
    function approve( address spender, uint value ) public returns (bool) {
	    approvals[msg.sender][spender] = value;
		emit Approval(msg.sender, spender, value);
		return true;
    }
}