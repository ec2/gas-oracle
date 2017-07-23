var Database = artifacts.require("./Database.sol");
var GasHole = artifacts.require("./GasHole.sol");
var TestRequest = artifacts.require("./TestRequest.sol");
const fs = require("fs");

const proofData  = JSON.parse(fs.readFileSync('/Users/narush/gas-oracle-folders/gas-oracle/duck.json').toString());
//console.log(proofData[0].txproof)

contract('Database', function(accounts) {
  it("should allow a person to register", function () {
    var db;
    var gasHole;
    return Database.new().then(instance => {
      db = instance;
      return GasHole.new(db.address);
    }).then(instance => {
      gasHole = instance;
      return gasHole.register({value: 100});
    }).then(tx => {
      assert.equal(tx.logs[0].event, "Registered", "wrong event");
      assert.equal(tx.logs[0].args.person, accounts[0], "wrong person");
    });
  });
  it("should not allow a person to register twice", function () {
    let db;
    let gasHole;
    let thrown = false;
    return Database.new().then(instance => {
      db = instance;
      return GasHole.new(db.address);
    }).then(instance => {
      gasHole = instance;
      return gasHole.register({value: 100});
    }).then(tx => {
      assert.equal(tx.logs[0].event, "Registered", "wrong event");
      assert.equal(tx.logs[0].args.person, accounts[0], "wrong person");
      return gasHole.register({value: 100});
    }).catch(e => {
      thrown = true;
      assert.match(e, /invalid opcode/, 'should have thrown');
    }).then(() => {
      assert.isTrue(thrown, "should have thrown");
    })
  });
  it("should  allow a person to unregister after registering", function () {
    let db;
    let gasHole;
    let thrown = false;
    return Database.new().then(instance => {
      db = instance;
      return GasHole.new(db.address);
    }).then(instance => {
      gasHole = instance;
      return gasHole.register({value: 100});
    })
    .then(t =>{
      return gasHole.withdraw();
    })
    .then(tx => {
      assert.equal(tx.logs[0].event, "Withdraw", "wrong event");
      assert.equal(tx.logs[0].args.person, accounts[0], "wrong person");
    });
  });
  it("should not allow a person to unregister twice", function () {
    let db;
    let gasHole;
    let thrown = false;
    return Database.new().then(instance => {
      db = instance;
      return GasHole.new(db.address);
    }).then(instance => {
      gasHole = instance;
      return gasHole.register({value: 100});
    })
    .then(t =>{
      return gasHole.withdraw();
    })
    .then( () => {
      return gasHole.withdraw();
    })
    .catch(e => {
      thrown = true;
      assert.match(e, /invalid opcode/, 'should have thrown');
    })
    .then(() => {
      assert.isTrue(thrown, "should have thrown");
    });
  });
  it("should callback", function () {
    let db;
    let gasHole;
    let testrequester;
    let thrown = false;
    return Database.new().then(instance => {
      db = instance;
      return GasHole.new(db.address);
    })
    .then(instance => {
      gasHole = instance;
      return gasHole.register({value: 100});
    })
    .then(() => {
      return TestRequest.new(gasHole.address);
    })
    .then((testRequestInstance) =>{
      testrequester = testRequestInstance;
      return testrequester.makeRequest();
    })
    .then((txhash) => {
      return testrequester.x.call();
    })
    .then((beforereq) => {
      assert.equal(beforereq.toString(16), 'deadbeef');
      return gasHole.submitStat(0, 123);
    })
    .then(txhash2 => {
      return testrequester.x.call();
    })
    .then(afterreq => {
      assert.equal(afterreq.toString(10), '123', 'what');
    })
  });


  it("should allow challenge", function () {
    let db;
    let gasHole;
    let testrequester;
    let thrown = false;
    return Database.new().then(instance => {
      db = instance;
      return GasHole.new(db.address);
    })
    .then(instance => {
      gasHole = instance;
      return gasHole.register({value: 100});
    })
    .then(() => {
      return TestRequest.new(gasHole.address);
    })
    .then((testRequestInstance) =>{
      testrequester = testRequestInstance;
      return testrequester.makeRequest();
    })
    .then((txhash) => {
      return testrequester.x.call();
    })
    .then((beforereq) => {
      assert.equal(beforereq.toString(16), 'deadbeef');
      return gasHole.submitStat(0, 123);
    })
    .then(txhash2 => {
      return gasHole.challengeStat.call(0, {value: 100})
    }).then(challengeNum => {
      assert.equal(challengeNum.toString(), "0", "Should have successful first challenge")
    })
  })

  it("should calculate", function () {
    let db;
    let gasHole;
    let blockNum = 4059939;
    let tx = proofData[0].txproof;
    let rec = proofData[0].receiptproof;
    return Database.new().then(instance => {
      db = instance;
      return GasHole.new(db.address);
    })
    .then(instance => {
      gasHole = instance;
      //console.log(tx.rlpHeader)
      return db.submitBlock(blockNum, tx.header)
    }).then(() => {
      return db.getReceiptRoot(blockNum)
    }).then(root => {
      assert.equal(root, tx.receiptRoot, "wrong root")
      return db.getTxRoot(blockNum)
    }).then(root => {
      assert.equal(root, tx.txRoot, "wrong root")
      return db.getStateRoot(blockNum)
    }).then(async (root) => {
      assert.equal(root, tx.stateRoot, "wrong root")
      //console.log(tx.path, tx.stack, tx.prefix, tx.value, rec.stack, rec.prefix, rec.value)
      let totalGas = 0;
      let res;
      for(let i = 0 ; i < proofData.length ; i++){
        tx = proofData[i].txproof;
        rec = proofData[i].receiptproof;
        res = await db.submitTransaction(blockNum, tx.path, tx.stack, tx.prefix, tx.value, rec.stack, rec.prefix, rec.value)
        totalGas += res.receipt.gasUsed;
      }
      //console.log(totalGas)
    }).then(() => {
      return db.getUsed.call(blockNum)
    }).then(gasUsed => {
      console.log("Total Gas Used in Block:", gasUsed.toString('10'))
      return db.getPrice.call(blockNum)
    }).then(price => {
      console.log("Average Gas Price in Block:", price.toString('10'))
    }).then(async()=>{
      await db.getMaxGas.call(blockNum).then((max)=> {console.log("Max Gas Used", max.toString('10'))});
      await db.getMinGas.call(blockNum).then((min)=> {console.log("Min Gas Used", min.toString('10'))});
      return db.getMaxFee.call(blockNum).then((fee)=> {console.log("Max Fee Paid ", fee.toString('10'))});
    })
  })

  it('should allow for valid challenges', function () {
    let db;
    let gasHole;
    let testrequester;
    let thrown = false;
    let tx = proofData[0].txproof;
    let rec = proofData[0].receiptproof;
    let blockNum = 4059939;
    return Database.new().then(instance => {
      db = instance;
      return GasHole.new(db.address);
    })
    .then(instance => {
      gasHole = instance;
      return gasHole.register({value: 100});
    })
    .then(() => {
      return db.getPrice.call(blockNum)
    }).then(res => {
      //console.log(res.toString('10'))
      return TestRequest.new(gasHole.address);
    })
    .then((testRequestInstance) =>{
      testrequester = testRequestInstance;
      return testrequester.makeRequest();
    })
    .then((txhash) => {
      return testrequester.x.call();
    })
    .then((beforereq) => {
      assert.equal(beforereq.toString(16), 'deadbeef');
      return gasHole.submitStat(0, 123);
    })
    .then(txhash2 => {
      return testrequester.x.call();
    })
    .then(afterreq => {
      assert.equal(afterreq.toString(10), '123', 'what');
      return gasHole.challengeStat(0, {value: 2})
    }).then(() => {
      return db.submitBlock(blockNum, tx.header)
    }).then(async () => {
      for(let i = 0 ; i < proofData.length ; i++){
        tx = proofData[i].txproof;
        rec = proofData[i].receiptproof;
        await db.submitTransaction(blockNum, tx.path, tx.stack, tx.prefix, tx.value, rec.stack, rec.prefix, rec.value)
      }
    }).then(() => {
      return db.getPrice.call(blockNum)
    }).then(res => {
      //console.log(res.toString('10'))
      return gasHole.verifyChallenge(0, 0)
    }).then(tx => {
      assert.equal(tx.logs[0].event, "GoodChallenge", "should have been a valid challenge")
    })
  })

  it('should reject invalid challenges', function () {
    let db;
    let gasHole;
    let testrequester;
    let thrown = false;
    let tx = proofData[0].txproof;
    let rec = proofData[0].receiptproof;
    let blockNum = 4059939;
    return Database.new().then(instance => {
      db = instance;
      return GasHole.new(db.address);
    })
    .then(instance => {
      gasHole = instance;
      return gasHole.register({value: 100});
    })
    .then(() => {
      return TestRequest.new(gasHole.address);
    })
    .then((testRequestInstance) =>{
      testrequester = testRequestInstance;
      return testrequester.makeRequest();
    })
    .then((txhash) => {
      return testrequester.x.call();
    })
    .then((beforereq) => {
      assert.equal(beforereq.toString(16), 'deadbeef');
      return gasHole.submitStat(0, 31066306691);
    })
    .then(txhash2 => {
      return testrequester.x.call();
    })
    .then(afterreq => {
      assert.equal(afterreq.toString(10), '31066306691', 'what');
      return gasHole.challengeStat(0, {value: 2})
    }).then(() => {
      return gasHole.statCheck(0)
    }).then(res => {
      //console.log("THING EHRE", res)
      return db.submitBlock(blockNum, tx.header)
    }).then(async () => {

      for (let i = 0 ; i < proofData.length ; i++){
        tx = proofData[i].txproof;
        rec = proofData[i].receiptproof;
        await db.submitTransaction(blockNum, tx.path, tx.stack, tx.prefix, tx.value, rec.stack, rec.prefix, rec.value)
      }
    //}).then(async()=>{
    //  await db.getMaxGas.call(blockNum).then((max)=> {console.log("Max Gas Used", max)});
    //  await db.getMinGas.call(blockNum).then((min)=> {console.log("Min Gas Used", min)});
    //  return db.getMaxFee.call(blockNum).then((fee)=> {console.log("Max Fee Paid ", fee)});
    }).then(() => {
      return db.getPrice.call(blockNum)
    }).then(res => {
      console.log(res.toString('10'))
      assert.equal(res.toString('10'), '31066306691', "wrong value")
      return gasHole.verifyChallenge(0, 0)
    }).then(tx => {
      assert.equal(tx.logs[0].event, "BadChallenge", "should have been a valid challenge")
    })
  })

});
