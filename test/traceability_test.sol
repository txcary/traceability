pragma solidity ^0.4.24;
import "./traceability.sol";

contract test is TR {
    uint256 credit = 100;
    uint256 creditToPay = 1;
    uint256 expireDays = 1;
    address supervisor;
    address vendor;
    address manufactor;
    address consumer;
    
    uint256 material_id; 
    uint256 production_id;

    function testSupervisor(address _vendor, address _manufactor, address _consumer) public returns(bool ok) {
        ok = false;
        setSupervisor(msg.sender);
        vendor = _vendor;
        manufactor = _manufactor;
        consumer = _consumer;
        setCreditToPay(vendor, creditToPay, expireDays);
        setCreditToPay(manufactor, creditToPay, expireDays);
        setCreditToPay(consumer, creditToPay, expireDays);
        sendCredit(vendor, credit);
        sendCredit(manufactor, credit);
        sendCredit(consumer, credit);
        assert(balanceOf(vendor)==credit);
        assert(balanceOf(manufactor)==credit);
        assert(balanceOf(consumer)==credit);
        assert(totalSupply()==credit*3);
        ok = true;
    }
    function testVendor() public returns (bool ok) {
        ok = false;
        assert(msg.sender==vendor);
        uint256 creditBefore = balanceOf(vendor);
        uint256[] memory emptyArray = new uint256[](0);
        material_id = produce(emptyArray);
        assert(push(material_id, manufactor)==true);
        uint256 creditAfter = balanceOf(vendor);
        assert(creditToPay==(creditBefore-creditAfter));
        ok = true;
    }
    function testManufactor() public returns (bool ok) {
        ok = false;
        uint256 creditBefore = balanceOf(vendor);
        assert(msg.sender==manufactor);
        assert(isPushedToMe(material_id));
        assert(pull(material_id));
        uint256 creditAfter = balanceOf(vendor);
        assert(creditToPay==(creditAfter-creditBefore));
        uint256[] memory source = new uint256[](1);
        source[0] = material_id;
		production_id = produce(source);
		creditBefore = balanceOf(manufactor);
		assert(push(production_id, consumer));
		creditAfter = balanceOf(manufactor);
        assert(creditToPay==(creditBefore-creditAfter));
        ok = true;
    }
    function testArbitrate() public mustSupervisor returns (bool ok) {
        ok = false;
        uint256 supplyBefore = totalSupply();
        uint256 creditBefore = balanceOf(manufactor);
        arbitrate(production_id, "Test For Arbitrate"); 
        uint256 creditAfter = balanceOf(manufactor);
        uint256 supplyAfter = totalSupply();
        assert(creditToPay==(supplyBefore-supplyAfter));
        assert(creditBefore==creditAfter);
        ok = true;
    }
}