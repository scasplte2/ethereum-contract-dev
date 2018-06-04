const HDWalletProvider = require('truffle-hdwallet-provider');
const Web3 = require('web3');
const { interface, bytecode } = require('./compile');

// Setup the provider to get to Rinkeby
const provider = new HDWalletProvider(
    'loud claim fork hole survey crane flower december trend pond liberty venture',
    'https://rinkeby.infura.io/4iAt9KN5ezUZsGOVW48T'
);
const web3 = new Web3(provider);

const deploy = async () => {
    const accounts = await web3.eth.getAccounts();

    console.log('Attempting to deploy from account', accounts[0])

    const result = await new web3.eth.Contract(JSON.parse(interface))
        .deploy({
            data: bytecode
        })
        .send({
            gas: '1000000',
            from: accounts[0]
        });

        console.log(interface);
        console.log('Contract deployed to', result.options.address);
};
deploy();