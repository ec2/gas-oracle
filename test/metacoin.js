var Database = artifacts.require("./Database.sol");
var GasHole = artifacts.require("./GasHole.sol");
var TestRequest = artifacts.require("./TestRequest.sol");

contract('Database', function(accounts) {
  it("should allow a person to register", function () {
    var db;
    var gasHole;
    Database.new().then(instance => {
      db = instance;
      return GasHole.new(db.address);
    }).then(instance => {
      gasHole = instance;
      return gasHole.register({value: 100});
    }).then(tx => {
      assert.equal(tx.logs[0].event, "Registered", "wrong event");
      assert.equal(tx.logs[0].args.person, accounts[0], "wrong person");
      //do shit
    });
  });
  it("should not allow a person to register twice", function () {
    let db;
    let gasHole;
    let thrown = false;
    Database.new().then(instance => {
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
    Database.new().then(instance => {
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
    Database.new().then(instance => {
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
    Database.new().then(instance => {
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
    Database.new().then(instance => {
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

});
