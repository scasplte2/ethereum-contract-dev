import Web3 from 'web3';

// Takes provider from Metamask web3 instance
const web3 = new Web3(window.web3.currentProvider);

export default web3;