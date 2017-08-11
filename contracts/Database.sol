pragma solidity ^0.4.8;

import "./RLP.sol";

contract Database {
  using RLP for RLP.RLPItem;
  using RLP for RLP.Iterator;
  using RLP for bytes;

  mapping (uint => BlockHeader) blocks;
  mapping (uint => uint) pendingPayments;

  struct BlockHeader {
    bytes32   prevBlockHash;  // 0
    uint      gasLimit;       // 9
    uint      gasUsed;        // 1
    uint      freeGas;        // gasLimit - gasUsed
    address   servedBy;       // blockPoster
  }

  function submitBlock(uint blockNum, bytes rlpHeader) {
    blocks[blockNum] = parseBlockHeader(rlpHeader);
    require(blockNum > block.number - 256);
    if (sha3(rlpHeader) == block.blockhash(blockNum)) {
      blocks[blockNum] = parseBlockHeader(rlpHeader);
      blocks[blockNum].servedBy = msg.sender;
      blocks[blockNum].freeGas = blocks[blockNum].gasLimit - blocks[blockNum].gasUsed;
    } else {
      revert();
    }
  }

  function requestBlock(uint blockNum) payable {
    pendingPayments[blockNum] += msg.value;
  }

  function getGasLimit(uint blockNum) returns (uint) {
    if (checkBlock(blockNum)) revert();

    return blocks[blockNum].gasLimit;
  }

  function getGasUsed(uint blockNum) returns (uint) {
    if (!checkBlock(blockNum)) revert();

    return blocks[blockNum].gasUsed;
  }

  function getFreeGas(uint blockNum) returns (uint) {
    if (!checkBlock(blockNum)) revert();

    return blocks[blockNum].freeGas;
  }

  /* HELPER FUNCTIONS */

  function checkBlock(uint blockNum) constant returns (bool) {
    return blocks[blockNum].prevBlockHash != bytes32(0);
  }

  function parseBlockHeader(bytes rlpHeader) constant internal returns (BlockHeader) {
     BlockHeader memory header;
     var it = rlpHeader.toRLPItem().iterator();

     uint idx;
     while(it.hasNext()) {
      if (idx == 0) {
        header.prevBlockHash = bytes32(it.next().toUint());
      } else if (idx == 9) {
        header.gasLimit = it.next().toUint();
      } else if (idx == 10) {
        header.gasUsed = it.next().toUint();
      } else {
        it.next();
      }
      idx++;
     }
     return header;
  }
}
