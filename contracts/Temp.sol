pragma solidity ^0.4.11;

import "./RLP.sol";

contract Temp {
  using RLP for RLP.RLPItem;
  using RLP for RLP.Iterator;
  using RLP for bytes;

  mapping (uint => BlockHeader) blocks;

  struct BlockHeader {
    uint      prevBlockHash;// 0
    bytes32   stateRoot;    // 3
    bytes32   txRoot;       // 4
    bytes32   receiptRoot;  // 5
  }


	mapping (bytes32 => Transaction) transactions;
  struct Transaction {
    //data
  }

	//can get the block hash of the last 256 blocks.
	//have to start at the last 256 blocks.

	//do we need a seperate method of storing blocks depending on proof? No.
	//Blocks should be stored all in a single mapping.

	//Then, anyone can refer to them. Should they use mulitple things?



  function submitBlock(uint blockNum, bytes32 blockHash, bytes rlpHeader) {
		if (blockNum >= block.number - 256) {
			if (blockHash != block.blockhash(blockNum) && blockHash != sha3(rlpHeader)) {
				throw;
			} else {
				blocks[blockHash] = parseBlockHeader(rlpHeader);
			}
		}
		//Can just let people build back to real block hashes. Maybe let them encode
		//rlp encoding of lists of headers.
		//
    BlockHeader memory header = parseBlockHeader(rlpHeader);
    blocks[blockHash] = header;
    //TO DO: pass in cmix, check PoW
  }

  //This function probably does not work as-is
  function checkStateProof(bytes32 blockHash, bytes rlpStack, uint[] indexes, bytes statePrefix, bytes rlpState) constant returns (bool) {
   bytes32 stateRoot = blocks[blockHash].stateRoot;
   if (checkProof(stateRoot, rlpStack, indexes, statePrefix, rlpState)) {
     return true;
   } else {
     return false;
   }
  }

  function checkTxProof(bytes32 blockHash, bytes rlpStack, uint[] indexes, bytes transactionPrefix, bytes rlpTransaction) constant returns (bool) {
    bytes32 txRoot = blocks[blockHash].txRoot;
    if (checkProof(txRoot, rlpStack, indexes, transactionPrefix, rlpTransaction)) {
      return true;
    } else {
      return false;
    }
  }

  function checkReceiptProof(bytes32 blockHash, bytes rlpStack, uint[] indexes, bytes receiptPrefix, bytes rlpReceipt) constant returns (bool) {
   bytes32 receiptRoot = blocks[blockHash].receiptRoot;
   if (checkProof(receiptRoot, rlpStack, indexes, receiptPrefix, rlpReceipt)) {
     return true;
   } else {
     return false;
   }
  }

  // HELPER FUNCTIONS
  function parseBlockHeader(bytes rlpHeader) constant internal returns (BlockHeader) {
     BlockHeader memory header;
     var it = rlpHeader.toRLPItem().iterator();

     uint idx;
     while(it.hasNext()) {
      if (idx == 0) {
        header.prevBlockHash = it.next().toUint();
      } else if (idx == 3) {
        header.stateRoot = bytes32(it.next().toUint());
      } else if (idx == 4) {
        header.txRoot = bytes32(it.next().toUint());
      } else if (idx == 5) {
        header.receiptRoot = bytes32(it.next().toUint());
      } else {
        it.next();
      }
      idx++;
     }
     return header;
  }

  function checkProof(bytes32 rootHash, bytes rlpStack, uint[] indexes, bytes valuePrefix, bytes rlpValue) constant returns (bool) {
   RLP.RLPItem[] memory stack = rlpStack.toRLPItem().toList();
   bytes32 hashOfNode = rootHash;
   bytes memory currNode;
   RLP.RLPItem[] memory currNodeList;

   for (uint i = 0; i < stack.length; i++) {
     if (i == stack.length - 1) {
       currNode = stack[i].toBytes();
       if (hashOfNode != sha3(currNode)) {return false;}
       currNodeList = stack[i].toList();
       RLP.RLPItem memory value = currNodeList[currNodeList.length - 1];
       if (sha3(valuePrefix, rlpValue) == sha3(value.toBytes())) {
         return true;
       } else {
         return false;
       }
     }
     currNode = stack[i].toBytes();
     if (hashOfNode != sha3(currNode)) {return false;}
     currNodeList = stack[i].toList();
     hashOfNode = currNodeList[indexes[i]].toBytes32();
   }
  }

  function getStateRoot(bytes32 blockHash) constant returns (bytes32) {
    return blocks[blockHash].stateRoot;
  }

  function getTxRoot(bytes32 blockHash) constant returns (bytes32) {
    return blocks[blockHash].txRoot;
  }

  function getReceiptRoot(bytes32 blockHash) constant returns (bytes32) {
    return blocks[blockHash].receiptRoot;
  }

  function test(bytes rlpValue) constant returns (bytes) {
    return rlpValue.toRLPItem().toBytes();
  }

  //rlpTransaction is a value at the bottom of the transaction trie. This, however,
  //has the first few bytes chopped off.
  function getTransactionDetails(bytes rlpTransaction) constant returns (uint) {
  	RLP.RLPItem[] memory list = rlpTransaction.toRLPItem().toList();
    return list[2].toUint();
    /*
    uint idx = 0;
  	while(it.hasNext()) {
  		if (idx == 0) {
  		  tx.nonce = it.next().toUint();
  		} else if (idx == 1) {
  			tx.gasPrice = it.next().toUint();
  		} else if (idx == 2) {
        tx.gasLimit = it.next().toUint();
  		} else if (idx == 3) {
  			tx.to = it.next().toAddress();
  		} else if (idx == 4) {
  			tx.value = it.next().toUint(); // amount of etc sent
  		} else if (idx == 5) {
        	tx.data = it.next().toBytes();
      	}
  		idx++;
  	}
    return tx;
    */

  }

}
