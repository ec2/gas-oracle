pragma solidity ^0.4.7;
contract GasHole {

	uint constant MIN_DEPOSIT = 0.1 ether;

	struct Register {
		uint deposit;
		uint lastBlock;
	}

	mapping(address => Register) reg;

	modifier onlyRegistered () {
		if(reg[msg.sender].deposit == 0) {
			revert();
		}
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
		uint challengeNum;
	}



	struct Challenge {
		//type of challenge
		//when ti expires.
		//the person that is challenging
		//status
		//etc.

		uint challengeNum;
		address challenger;
		// if challenge is wrong, we must penalize
		uint escrow;
		//1 for being Challenged
		uint challengeStatus;


	}
	mapping (uint => Stat) stats;
	mapping(uint => mapping (uint => Challenge)) challenges;

	uint currStat;

	/*function GasHole() {

	}*/

	function register () payable returns (bool) {
		if(msg.value <= MIN_DEPOSIT || reg[msg.sender].deposit != 0) revert();
		reg[msg.sender].deposit = msg.value;
	}

	function withdraw () onlyRegistered returns (bool) {
		if (reg[msg.sender].lastBlock > block.number - 256) revert();
		msg.sender.transfer(reg[msg.sender].deposit);
		delete reg[msg.sender];
	}

	function requestStat (bytes4 _funID, uint _dataType, uint _blockNumber) payable returns (bool) {
		currStat++;
		stats[currStat] = Stat({cbAdd: msg.sender, funID: _funID, state: StatState.Requested, dataType: _dataType, blockNum: _blockNumber, servedBy: address(0), challengeNum: 0});
	}

	function submitStat (uint statNum, bytes _inputStat, uint _dataType) onlyRegistered returns (bool) {
		reg[msg.sender].lastBlock = block.number;
		Stat memory s = stats[statNum];
		_inputStat;
		_dataType;
		//concat data shit
		//s.cbAdd.call(data);
		s.state = StatState.Fulfilled;
		s.servedBy = msg.sender;
	}

	function verifyChallenge (uint _statNum, uint _challengeNumber, bytes _inputChallenge) returns (bool){
		Stat memory s = stats[_statNum];

		if(challenges[_statNum][_challengeNumber].challenger != msg.sender) revert();

		//database.getStat(type, block) returns

		//if proof == true {give back deposit, and send this user the escrow, update our data}
		//if proof == false

		return true;
	}


	function challengeStat(uint _statNum) payable returns (uint challengeNumber) {
		//call the correct function depending on the data type
		if(msg.value != 0.1 ether) revert();
		Stat memory s = stats[_statNum];
		s.state = StatState.Challenged;
		challenges[_statNum][s.challengeNum] = Challenge({challengeNum: s.challengeNum, challenger: msg.sender, challengeStatus: 1, escrow: msg.value});
		s.challengeNum ++;

		//timer starts for 100 blocks

		return s.challengeNum - 1 ;
	}

}
