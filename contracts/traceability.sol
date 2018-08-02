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
	mapping (address => uint256) creditExpire;
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
	function setCreditToPay( address who, uint credit, uint expireDay ) public mustSupervisor returns (bool) {
	    creditToPay[who] = credit;
	    creditExpire[who] = expireDay;
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
        address[] exOwners;
        uint256[] materials;
        uint256 credit;
        address receiver;
        uint256 pushTime;
        bool valid;
    }
    mapping (uint256=>Object) objects;
    mapping (address=>uint256) objectCount;
    event noteArbitration(
        address indexed addr, 
        uint256 indexed credit, 
        string message
    ); 
    
    modifier mustPay {
        assert( creditToPay[msg.sender] > 0 );
        assert( balances[msg.sender] >= creditToPay[msg.sender] );
        _;
    }
    function getObjectById(uint256 id) private constant returns (Object storage) {
        Object storage obj = objects[id];
        assert(obj.valid);
        return obj;
    }
    function checkOwnerOfObject(uint256 id) private constant {
        Object storage obj = getObjectById(id);
		assert(msg.sender==obj.owner);
    }
    function checkOwnerOfMaterials(uint256[] ids) private constant {
        uint256 i;
        for(i=0;i<ids.length;i++) {
            checkOwnerOfObject(ids[i]);
        }
    }
    function payCredit(Object obj) private {
 		balances[msg.sender] -= creditToPay[msg.sender];	
		obj.credit += creditToPay[msg.sender];
    }
    function returnCreditToOwner(Object obj) private {
		uint256 creditToReturn = obj.credit;
        obj.credit = 0;
      	balances[obj.owner] = creditToReturn;
    }
	/*    
    function returnCreditToLastOwner(Object obj) private {
		if(obj.exOwners.length>0) {
	        address lastOwner = obj.exOwners[obj.exOwners.length-1];
			uint256 creditToReturn = obj.credit;
    	    obj.credit = 0;
        	balances[lastOwner] = creditToReturn;
		}
    }
    function returnCreditToVendors(Object obj) private {
		uint256 i;
		for(i=0;i<obj.materials.length;i++) {
		    Object obj = getObjectById(obj.materials[i]);
		    returnCreditToOwner(obj);
		}
    }
    */
    function createObjectId() private returns (uint256 id) {
        bytes memory b = new bytes(64);
        bytes32 addr32 = bytes32(msg.sender);
        bytes32 count32 = bytes32( objectCount[msg.sender] );
        objectCount[msg.sender]++;
        for (uint i=0; i<32; i++) {
            b[i] = addr32[i];
            b[32+i] = count32[i];
        }
        id = uint256(keccak256(b));
    }
    function produce(uint256[] _materials) public returns (uint256 id) {
        checkOwnerOfMaterials(_materials);
        Object memory obj = Object ({
            owner: msg.sender,
            exOwners: new address[](0),
            materials: _materials,
            receiver: 0,
            pushTime: 0,
            credit: 0,
            valid: true
        });
        id = createObjectId();
		objects[id] = obj;
		return id;
    }
    function push(uint256 id, address to) public mustPay returns (bool) {
        checkOwnerOfObject(id);
        Object storage obj = getObjectById(id);
        payCredit(obj);
        obj.receiver = to;
        obj.pushTime = now;
        return true;
    }
    function pull(uint256 id) public returns (bool) {
        Object storage obj = getObjectById(id);
        assert(obj.receiver==msg.sender);
		returnCreditToOwner(obj);
        obj.receiver = 0;
        obj.exOwners.push(obj.owner);
        obj.pushTime = 0;
		obj.owner = msg.sender;
        return true;
    }
    function arbitrate(uint256 id, string message) public mustSupervisor returns (bool) {
        Object storage obj = getObjectById(id);
        obj.credit = 0;
        supply -= obj.credit;
		emit noteArbitration(obj.owner, obj.credit, message);
        return true;
    }
	function refund(uint256 id) public returns (bool) {
        checkOwnerOfObject(id);
        Object storage obj = getObjectById(id);
        assert(obj.owner==msg.sender);
        if(now > obj.pushTime + creditExpire[msg.sender]* 1 days) {
			returnCreditToOwner(obj);
        }
        return true;
	}
	function isPushedToMe(uint256 id) public constant returns (bool) {
	    Object storage obj = getObjectById(id);
	    if(obj.receiver==msg.sender) {
	        return true;
	    }
	    return false;
	}
}