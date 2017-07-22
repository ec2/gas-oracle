var Database = artifacts.require("./Database.sol");
var GasHole = artifacts.require("./GasHole.sol");

contract('Database', function(accounts) {
  it("should allow a person to register", function () {
    var db
    var gasHole
    Database.new().then(instance => {
      db = instance
      return GasHole.new(db.address)
    }).then(instance => {
      gasHole = instance
      return gasHole.register({value: 100})
    }).then(tx => {
      assert.equal(tx.logs[0].event, "Registered", "wrong event")
      assert.equal(tx.logs[0].args.person, accounts[0], "wrong person")
      //do shit
    })
  })
})
