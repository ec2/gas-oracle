pragma solidity ^0.4.7;
import "./Database.sol";

contract GasHole {

	event Registered(address person);
	event Withdraw(address person);
	event GoodChallenge();
	event BadChallenge();

	uint constant MIN_DEPOSIT = 1 wei;

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
		uint data;
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
		//2 for unsuccessful
		//3 for successful challenge
		uint challengeStatus;


	}
	mapping (uint => Stat) stats;
	mapping(uint => mapping (uint => Challenge)) challenges;

	uint currStat;
	Database db;

	function GasHole(address _database) {
		db = Database(_database);
	}

	function register () payable returns (bool) {
		if(msg.value <= MIN_DEPOSIT || reg[msg.sender].deposit != 0) revert();
		reg[msg.sender].deposit = msg.value;
		Registered(msg.sender);
		return true;
	}

	function withdraw () onlyRegistered returns (bool) {
		if (reg[msg.sender].lastBlock > block.number - 256 && reg[msg.sender].lastBlock != 0) revert();
		msg.sender.transfer(reg[msg.sender].deposit);
		Withdraw(msg.sender);
		delete reg[msg.sender];
	}

	function requestStat (bytes4 _funID, uint _dataType, uint _blockNumber) payable returns (bool) {
		stats[currStat] = Stat({cbAdd: msg.sender, funID: _funID, state: StatState.Requested, dataType: _dataType, blockNum: _blockNumber, servedBy: address(0), challengeNum: 0, data: 0});
		currStat++;
	}

	function submitStat (uint statNum, uint _inputStat) onlyRegistered returns (bool) {
		reg[msg.sender].lastBlock = block.number;
		Stat s = stats[statNum];
		s.data = _inputStat;
		bytes memory concat = new bytes(36);
		bytes32 temp = bytes32(s.data);
		for(uint i = 0 ; i < 36 ; i++){
			if (i < 4) {
				concat[i] = s.funID[i];
			}
			else {
				concat[i] = temp[i-4];
			}
		}
		s.cbAdd.call(concat);
		s.state = StatState.Fulfilled;
		s.servedBy = msg.sender;
	}

	function verifyChallenge (uint _statNum, uint _challengeNumber) returns (bool){
		Stat s = stats[_statNum];

		if(challenges[_statNum][_challengeNumber].challenger != msg.sender) revert();

		uint result = db.getStat(s.dataType, s.blockNum);
		//challenger not successful
		if(result == s.data) {
			//payoput escrow of challenger
			s.servedBy.transfer(challenges[_statNum][_challengeNumber].escrow);
			s.state = StatState.Fulfilled;
			challenges[_statNum][_challengeNumber].challengeStatus = 2;
			BadChallenge();
			return false;
		}
		//challenger successful
		else {

			challenges[_statNum][_challengeNumber].challenger.transfer(reg[s.servedBy].deposit);
			delete reg[s.servedBy];
			s.state = StatState.Fulfilled;
			s.data = result;
			challenges[_statNum][_challengeNumber].challengeStatus = 3;
			GoodChallenge();
		}
		return true;
	}

	function statCheck(uint _statNum) constant returns (uint) {
		return stats[_statNum].data;
	}


	function challengeStat(uint _statNum) payable returns (uint challengeNumber) {
		//call the correct function depending on the data type
		if (msg.value <= 1 wei) revert();
		Stat memory s = stats[_statNum];
		s.state = StatState.Challenged;
		challenges[_statNum][s.challengeNum] = Challenge({challengeNum: s.challengeNum, challenger: msg.sender, challengeStatus: 1, escrow: msg.value});
		s.challengeNum ++;

		//timer starts for 100 blocks
		//return 100;
		return s.challengeNum - 1 ;
	}

}
