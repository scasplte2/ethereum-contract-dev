pragma solidity ^0.4.23;

import "./Owned.sol";

contract Presale is owned{
    // state stuff
    struct participant {
        uint256 eth_contributed;
        uint256 token_amount;
        address payout_address;
    }
    mapping(address => participant) public participants;
    mapping(address => bool) public whitelist;
    bool dutch_auction_on;
    uint256 initial_tokens_per_ether = 2;
    uint256 initial_price_tick = 1;
    uint256 total_presale_tokens = 9000;
    uint256 sold_presale_tokens = 0;

    // constructor
    constructor(uint256 _initial_tokens_per_ether, uint256 _total_presale_tokens, uint256 _initial_price_tick) public {
        /////                                                       /////
        // Adds owner to the whitelist, sets initial values, and       //
        // toggles if the dutch auction is on. Also, sets owner via    //
        // Owned contract.                                             //
        /////                                                       /////
        whitelist[msg.sender] =  true; // whitelist owner
    }

    // participant functions
    function Participate(address _payout_address) public payable Whitelisted {
        participant cur_participant = participants[msg.sender];
        cur_participant.eth_contribution = msg.value;
        cur_participant.token_amount = CalcTokenAmount(msg.value);
        cur_participant.payout_address = _payout_address;
    }

    function ChangePayoutAddress(address _payout_address) public Whitelisted {
        participant cur_participant = participants[msg.sender];
        cur_participant.payou_address = _payout_address;
    }

    // tick function
    function Tick() public OnlyOwner {
        /////                                                       /////
        // Used for dutch auction as the downward price pressure.      //
        // Meant to be triggered by an owner's web3 script a constant  //
        // rate. The rate determines the strength of the downward      //
        // price pressure. Additionally, the owner can adjust the tick //
        // amount to tune granularity.                                 //
        /////                                                       /////
    }

    // owner functions
    function AddParticipant(uint256 _eth_contributed, uint256 _token_amount, address _payout_address) public Whitelisted(msg.sender) ValidPurchase(_token_amount){
        participant cur_participant = participants[_payout_address];
        cur_participant.eth_contributed = _eth_contributed;
        cur_participant.token_amount = _token_amount;
        cur_participant.payout_address = _payout_address;
        sold_presale_tokens = sold_presale_tokens + _token_amount; // update sold amount counter
    }

    // modifiers
    modifier Whitelisted(address check) {
        if (whitelist[check]) {
            _;
        } else {
            throw;
        }
    }

    modifier ValidPurchase(uint256 purchase) {
        if (total_presale_tokens)
    }

}
