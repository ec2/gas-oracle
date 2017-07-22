pragma solidity ^0.4.8;

import "./RLP.sol";

contract Database {
  using RLP for RLP.RLPItem;
  using RLP for RLP.Iterator;
  using RLP for bytes;

  mapping (uint => BlockHeader) blocks;

  struct BlockHeader {
    bytes32   prevBlockHash;  // 0
    bytes32   stateRoot;      // 3
    bytes32   txRoot;         // 4
    bytes32   receiptRoot;    // 5
    uint      currGasUsed;    // This is the current total gas seen in tx proved.
    uint      currAvgGasPrice;// This is the current avg in the tx seen so far.
  }

  //Block number => made up transaction hash => details about transaction.
	mapping (uint => mapping(bytes32 => Transaction)) transactions;
  struct Transaction {
    uint gasPrice;
    uint gasUsed; //we create this, is not naturally a tx field
  }


  //NOTE: Blocks have to be submitted backwards. Have to start
  //with a block in the most recent 256 blocks, and slowly work
  //way backwards to have all blocks one wants.
  function submitBlock(uint blockNum, bytes rlpHeader) {
    blocks[blockNum] = parseBlockHeader(rlpHeader);
    /*if (blockNum >= block.number - 256) {
      if (sha3(rlpHeader) == block.blockhash(blockNum)) {
        blocks[blockNum] = parseBlockHeader(rlpHeader);
      }
    } else if (blocks[blockNum + 1].prevBlockHash != 0) {
      if (sha3(rlpHeader) == blocks[blockNum + 1].prevBlockHash) {
        blocks[blockNum] = parseBlockHeader(rlpHeader);
      }
    }
    revert();*/
  }


  //Goals:

  /*
    All transactions must be submitted.
    Must be submitted in order (this makes math on calculating gas used much easier)

    Ok, so.

    Assert cumulative gasUsed of this one (found in receipt), is larger than the
    cumulative gas used by the previous transaction in the block.

    For now, just going to assume that they do this correctly and don't fuck with shit.
  */

  function submitTransaction(uint blockNum, uint[] indexes, bytes txStack, bytes transactionPrefix, bytes rlpTransaction,
                             bytes receiptStack, bytes receiptPrefix, bytes rlpReceipt)
  {
    if (blocks[blockNum].prevBlockHash == 0) revert(); //just a check that the block has been submitted
    if (!checkProof(blocks[blockNum].txRoot, txStack, indexes, transactionPrefix, rlpTransaction) revert();
    if (!checkProof(blocks[blockNum].receiptRoot, receiptStack, indexes, receiptPrefix, rlpReceipt)) revert();

    bytes32 fakeTransactionHash = sha3(rlpTransaction, rlpReceipt);

    uint gasPrice = getGasPrice(rlpTransaction);
    transactions[blockNum][fakeTransactionHash].gasPrice = gasPrice;
    require (getCumulativeGas(rlpReceipt) > blocks[blockNum].currGasUsed);
    uint gasUsed = getCumulativeGas(rlpReceipt) - blocks[blockNum].currGasUsed;

    transactions[blockNum][fakeTransactionHash].gasUsed = gasUsed;
    blocks[blockNum].currAvgGasPrice = (blocks[blockNum].currAvgGasPrice * blocks[blockNum].currGasUsed + gasUsed * gasPrice) / (blocks[blockNum].currGasUsed + gasUsed);
    blocks[blockNum].currGasUsed += gasUsed;
  }

  function getStat(uint dataType, uint blockNum) returns (uint) {
    //In the future, this will match the type of the thing we are submitting
    return blocks[blockNum].currAvgGasPrice;
  }


  //This function probably does not work as-is
  function checkStateProof(uint blockNum, bytes rlpStack, uint[] indexes, bytes statePrefix, bytes rlpState) constant returns (bool) {
   bytes32 stateRoot = blocks[blockNum].stateRoot;
   if (checkProof(stateRoot, rlpStack, indexes, statePrefix, rlpState)) {
     return true;
   } else {
     return false;
   }
  }

  function checkTxProof(uint blockNum, bytes rlpStack, uint[] indexes, bytes transactionPrefix, bytes rlpTransaction) constant returns (bool) {
    bytes32 txRoot = blocks[blockNum].txRoot;
    if (checkProof(txRoot, rlpStack, indexes, transactionPrefix, rlpTransaction)) {
      return true;
    } else {
      return false;
    }
  }

  function checkReceiptProof(uint blockNum, bytes rlpStack, uint[] indexes, bytes receiptPrefix, bytes rlpReceipt) constant returns (bool) {
   bytes32 receiptRoot = blocks[blockNum].receiptRoot;
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
        header.prevBlockHash = bytes32(it.next().toUint());
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

  function getStateRoot(uint blockNum) constant returns (bytes32) {
    return blocks[blockNum].stateRoot;
  }

  function getTxRoot(uint blockNum) constant returns (bytes32) {
    return blocks[blockNum].txRoot;
  }

  function getReceiptRoot(uint blockNum) constant returns (bytes32) {
    return blocks[blockNum].receiptRoot;
  }

  function test(bytes rlpValue) constant returns (bytes) {
    return rlpValue.toRLPItem().toBytes();
  }



  //gets the second item from the transaction receipt
  function getCumulativeGas(bytes rlpReceipt) constant returns (uint) {
    RLP.RLPItem[] memory receipt = rlpReceipt.toRLPItem().toList();
    return receipt[1].toUint();
  }

  //rlpTransaction is a value at the bottom of the transaction trie.
  function getGasPrice(bytes rlpTransaction) constant returns (uint) {
    RLP.RLPItem[] memory list = rlpTransaction.toRLPItem().toList();
    return list[1].toUint();
  }



  //rlpTransaction is a value at the bottom of the transaction trie.
  function getTransactionDetails(bytes rlpTransaction) constant internal returns (Transaction memory tx) {
    RLP.RLPItem[] memory list = rlpTransaction.toRLPItem().toList();
    tx.gasPrice = list[1].toUint();
    //tx.gasLimit = list[2].toUint();
    return tx;
  }
}
