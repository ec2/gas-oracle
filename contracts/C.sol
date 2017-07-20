pragma solidity ^0.4.10;
contract C {
		function blah (uint a) constant returns(uint){
			return a+5;
		}
    function a() constant returns (uint) {
        return block.gaslimit;
    }
}
