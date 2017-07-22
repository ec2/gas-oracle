var Database = artifacts.require("./Database.sol");
var GasHole = artifacts.require("./GasHole.sol");

contract('Database', function(accounts) {
  it("should deploy contracts", function () {
    var db
    var gasHole
    Database.new().then(instance => {
      db = instance
      return GasHole.new(db.address)
    }).then(instance => {
      gasHole = instance
      //do shit
    })
  })
})
