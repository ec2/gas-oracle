App = {
  web3Provider: null,
  contracts: {},

  init: function() {
    // Load pets.
    // $.getJSON('../pets.json', function(data) {
    //   var petsRow = $('#petsRow');    //from index.html div id
    //   var petTemplate = $('#petTemplate');    //petTemplate is also div id
    //
    //   for (i = 0; i < data.length; i ++) {
    //     petTemplate.find('.panel-title').text(data[i].name);    //.panel-title is div class    .name is in JSON file
    //     petTemplate.find('img').attr('src', data[i].picture);
    //     petTemplate.find('.pet-breed').text(data[i].breed);
    //     petTemplate.find('.pet-age').text(data[i].age);
    //     petTemplate.find('.pet-location').text(data[i].location);
    //     petTemplate.find('.btn-adopt').attr('data-id', data[i].id);
    //
    //     petsRow.append(petTemplate.html());
    //   }
    // });

    return App.initWeb3();
  },

  initWeb3: function() {
    // Initialize web3 and set the provider to the testRPC.
    if (typeof web3 !== 'undefined') {
      App.web3Provider = web3.currentProvider;
      web3 = new Web3(web3.currentProvider);
    } else {
      // set the provider you want from Web3.providers
      App.web3Provider = new web3.providers.HttpProvider('http://localhost:8545');
      web3 = new Web3(App.web3Provider);
    }

    return App.initGasholeContract();
  },

  initGasholeContract: function() {
    $.getJSON('Gashole.json', function(data) {
      // Get the necessary contract artifact file and instantiate it with truffle-contract.

      var GasholeArtifact = data;
      App.contracts.Gashole = TruffleContract(GasholeArtifact);

      // Set the provider for our contract.
      App.contracts.Gashole.setProvider(App.web3Provider);
      console.log('initGasholeContract complete')

      // Use our contract to retieve and mark the adopted pets.
      //return App.markAdopted();
      return App.addRow();
      });

    //return App.initAdoptionContract();
  },

  // initAdoptionContract: function() {
  //   $.getJSON('Adoption.json', function(data) {
  //     // Get the necessary contract artifact file and instantiate it with truffle-contract.
  //
  //     var AdoptionArtifact = data;
  //     App.contracts.Adoption = TruffleContract(AdoptionArtifact);
  //
  //     // Set the provider for our contract.
  //     App.contracts.Adoption.setProvider(App.web3Provider);
  //
  //     // Use our contract to retieve and mark the adopted pets.
  //     return App.markAdopted();
  //     });
  //
  //   return App.bindEvents();
  // },

 addRow: function() {
   var i=2;

  $("#add_row").click(function(){
    console.log('add row');
    var inputtype = document.getElementById('inputType').value;
    console.log(inputtype);
    var blocknumber = document.getElementById('inputBlocknumber').value;
    console.log(blocknumber);
    if(inputtype != "" && blocknumber != ""){
     $('#tab_logic').append('<tr id="addr'+(i)+'"></tr>');
     $('#addr'+i).html("<td>"+ (i) +"</td><td>" + inputtype + "</td><td>"+ blocknumber +"</td><td id='submission"+i+"'></td><td id='challenge"+i+"'></td><td id='verified"+i+"'></td>");
     i++;
    }
  });
    return App.updateSubmission();
  },

 updateSubmission: function() {
    $("#update_submission").click(function(){
      console.log('update submission');
      var submission_index = document.getElementById('inputIndex').value;
      console.log(submission_index);
      var submission = document.getElementById('submission').value;
      console.log(submission);
      j = submission_index;

      if(submission_challenge_array[j] == 0) {
        $('#submission'+j).replaceWith("<td id='submission" + j + "''>" + submission + "</td>");
        $('#verified'+j).replaceWith("<td id='verified" + j + "''><span class='glyphicon glyphicon-remove'></td>");
        submission_challenge_array[j] = 1;
      }
      else{
        //alert that someone already submitted
      }
    });
    return App.challengeSubmission();
  },

 challengeSubmission: function() {
    $("#challenge_submission").click(function(){
      console.log('challenge submission');
      var challenge_index = document.getElementById('challengeIndex').value;
      console.log(challenge_index);
      var challenge = document.getElementById('challenge').value;
      console.log(challenge);
      j = challenge_index;
      $('#challenge'+j).replaceWith("<td id='challenge" + j + "''>" + challenge + "</td>");
      $('#verified'+j).replaceWith("<td id='verified" + j + "''>Pending...</td>");
    });
  },

 bindEvents: function() {
    $(document).on('click', '.btn-adopt', App.handleAdopt);
  },

 handleAdopt: function() {
    event.preventDefault();

    var petId = parseInt($(event.target).data('id'));

    var adoptionInstance;

    web3.eth.getAccounts(function(error, accounts) {
      if (error) {
        console.log(error);
      }

      var account = accounts[0];

      App.contracts.Adoption.deployed().then(function(instance) {
        adoptionInstance = instance;

        return adoptionInstance.adopt(petId, {from: account});
      }).then(function(result) {
        return App.markAdopted();
      }).catch(function(err) {
        console.log(err.message);
      });
    });
  },

 markAdopted: function(adopters, account) {
    var adoptionInstance;

    App.contracts.Adoption.deployed().then(function(instance) {
      adoptionInstance = instance;

      return adoptionInstance.getAdopters.call();
    }).then(function(adopters) {
      for (i = 0; i < adopters.length; i++) {
        if (adopters[i] !== '0x0000000000000000000000000000000000000000') {
          $('.panel-pet').eq(i).find('button').text('Pending...').attr('disabled', true);
        }
      }
    }).catch(function(err) {
      console.log(err.message);
    });
  }

};

$(function() {
  $(window).load(function() {
    submission_challenge_array = new Array(1000);
    submission_challenge_array.fill(0);
    App.init();
  });
});
