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

contract TRSupervise is TRToken {
	address generator;
	address supervisor;	
	mapping (address => uint256) creditToPay;
	modifier mustGenerator {
	   assert(msg.sender==generator); 
	   _;
	}
	modifier mustSupervisor {
	    assert(msg.sender==supervisor);
	    _;
	}
	modifier mustPay {
	   assert(creditToPay[msg.sender]>0); 
	   assert(creditToPay[msg.sender]<=balances[msg.sender]); 
	   _;
	}

	constructor() public {
	    generator=msg.sender;
	}
	function setSupervisor( address who ) public mustGenerator returns (bool) {
	    supervisor = who;
	    return true;
	}
	function setCreditToPay( address who, uint credit ) public mustSupervisor returns (bool) {
	    creditToPay[who] = credit;
	    return true;
	}
	function sendCredit( address who, uint credit ) public mustSupervisor returns (bool) {
	    balances[who] += credit;
		supply += credit;
	}
	
}

contract TR is TRSupervise {
    struct Object {
        address owner;
        address[] preOwners;
        uint256[] materials;
        mapping (address=>uint256) credits;
        address receiver;
        bool valid;
    }
    mapping (uint256=>Object) objects;
    
    modifier mustPay {
        assert( creditToPay[msg.sender] > 0 );
        assert( balances[msg.sender] >= creditToPay[msg.sender] );
        _;
    }
    function mustOwner(uint256[] ids) private constant {
        uint256 i;
        for(i=0;i<ids.length;i++) {
            assert(objects[ids[i]].valid);
			assert(msg.sender==objects[ids[i]].owner);
        }
    }
    function pay(Object obj) private {
 		balances[msg.sender] -= creditToPay[msg.sender];	
		obj.credits[msg.sender] += creditToPay[msg.sender];
    }
    function create(uint256[] _materials) public returns (uint256 id) {
        Object obj = Object({
            owner: msg.sender,
            preOwners: new address[](0),
            materials: _materials,
            valid: true
        });
        id = keccak256(msg.sender, _materials, block.timestamp);
		objects[id] = obj;
		return id;
    }
    function push(uint256 id, address to) public mustPay {
        Object obj = objects[id];
        pay(obj);
    }
}