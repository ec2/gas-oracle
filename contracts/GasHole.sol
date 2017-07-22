pragma solidity ^0.4.10;
contract GasHole {
	
	uint constant MIN_DEPOSIT = 0.1 ether;
	
	struct Register {
		uint deposit;
		uint lastBlock;
	}

	mapping(address => Register) reg;

	modifier onlyRegistered () {
		if(escrow[msg.sender] == 0) revert();
		_;
	}

	enum StatState{ 
		Null,
		Requested,
		Fulfilled,
		Challenged	
	}

	struct Stat {
		address cbAdd;
		bytes4 funID;
		StatState state;	
		uint dataType;
		uint blockNum;
		address servedBy;
	}

	mapping (uint => Stat) stats;
	uint currStat;

	function GasHole() {
		
	}

	function register () payable returns (bool) {
		if(msg.value <= MIN_DEPOSIT || escrow[msg.sender] != 0) revert();
		reg[msg.sender].deposit = msg.value;
	}

	function withdraw () onlyRegistered returns (bool) {
		if (reg[msg.sender].lastBlock > block.number - 256) revert();
		msg.sender.transfer(reg[msg.sender].deposit);
		delete reg[msg.sender];
	}

	function requestStat (bytes4 _funID, uint _dataType, uint _blockNumber) payable returns (bool) {
		currStat++;
		stats[currStat] = Stat({cbAdd: msg.sender, funID: _funID, state: Requested, dataType: _dataType, blockNum: _blockNum});
	}

	function submitStat (uint statNum, bytes _inputStat, uint _dataType) onlyRegistered returns (bool) {
		reg[msg.sender].lastBlock = block.number;
		Stat memory s = stats[statNum];
		//concat data shit
		s.cbAdd.call(data);
		s.done = true;
		s.servedBy = msg.sender;
	}


	function challengeStat(uint statNum) payable returns (bool) {
		//call the correct function depending on the data type
	}
	
}
