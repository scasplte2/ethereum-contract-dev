pragma solidity ^0.4.23;

contract Owned {

    address owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier OnlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function newOwner(address _newOwner) OnlyOwner public {
        owner = _newOwner;
    }

    /// upgrades require you to call terminate on the old bifrost contract
    /// this sends the ether to the owner
    /// the owner has to then send the ether to the new contract
    /// preferably via the constructor
    /// if you have a better idea i'm all ears
    function terminate() OwnerOnly external {
        selfdestruct(owner);
    }
}
