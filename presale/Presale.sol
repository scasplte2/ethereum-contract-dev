// TO DO
// - Safe Math
// - Dutch Auction
// - whitelist functionality
// - helpers
// - events

pragma solidity ^0.4.23;

import "./Owned.sol";
import "./SafeMath.sol";

contract Presale is owned {

    // no overflows
    using SafeMath for uint256;

    // state stuff
    struct participant {
        uint256 eth_contributed;
        uint256 token_amount;
        address payout_address;
    }
    mapping(address => participant) public participants;
    mapping(address => bool) public whitelist;
    bool dutch_auction_on = false;
    bool presale_open = false;
    uint256 initial_tokens_per_ether = 2;
    uint256 initial_price_tick = 1;
    uint256 total_presale_tokens = 9000;
    uint256 sold_presale_tokens = 0;

    // constructor
    constructor(uint256 _initial_tokens_per_ether, uint256 _initial_price_tick, uint256 _total_presale_tokens,
                uint256 _sold_presale_tokens, bool _dutch_auction_on, bool _presale_open) public {

        /////                                                       /////
        // Adds owner to the whitelist, sets initial values, and       //
        // toggles if the dutch auction is on. Also, sets owner via    //
        // Owned contract inheritance.                                 //
        /////                                                       /////

        whitelist[msg.sender] = true; // whitelist owner
        initial_tokens_per_ether = _initial_tokens_per_ether;
        initial_price_tick = _initial_price_tick;
        total_presale_tokens = _total_presale_tokens;
        sold_presale_tokens = _sold_presale_tokens;
        dutch_auction_on = _dutch_auction_on;
        presale_open = _presale_open;
    }

    // participant functions
    function Participate(address _payout_address) public payable Whitelisted ValidPurchase(CalcTokenAmount(msg.value)) PresaleOpen {

        /////                                                       /////
        // Used to participate in the pre-sale with Ether.             //
        // Participants must be added to the pre-sale whitelist prior  //
        // to using this method or they will be denied. Participants   //
        // paying via a fiat currency or other medium must be added    //
        // via an owner's call to the AddParticipant method.           //
        /////                                                       /////

        participant cur_participant = participants[msg.sender]; // get participant struct mapped to the given payout_address
        cur_participant.eth_contribution = cur_participant.eth_contributed.add(msg.value); // add eth contributed to current amount
        cur_participant.token_amount =  cur_participant.token_amount.add(CalcTokenAmount(msg.value)); // add tokens to the current tokens amount
        cur_participant.payout_address = _payout_address; // set payout address
        sold_presale_tokens = sold_presale_tokens.add(cur_participant.token_amount);

    }

    function ChangePayoutAddress(address _payout_address) public Whitelisted PresaleOpen {

        /////                                                       /////
        // Used to change a participant's payout address.              //
        // NOTE: This may not always work. If you try to changes your  //
        // payout address, but a tx asking for your payout address is  //
        // first it will return your 'old' payout address despite your //
        // tx being broadcast first.                                   //
        /////                                                       /////

        participant cur_participant = participants[msg.sender]; // get participant struct mapped to the given payout_address
        cur_participant.payout_address = _payout_address; // change payout address
    }

    // tick function
    function Tick() public OnlyOwner DutchAuctionOn PresaleOpen {
        /////                                                       /////
        // Used for dutch auction as the downward price pressure.      //
        // Meant to be triggered by an owner's web3 script a constant  //
        // rate. The rate determines the strength of the downward      //
        // price pressure. Additionally, the owner can adjust the tick //
        // amount to tune granularity.                                 //
        /////                                                       /////
    }

    // owner functions
    function AddParticipant(uint256 _eth_contributed, uint256 _token_amount, address _payout_address) public Whitelisted ValidPurchase(_token_amount) {

        /////                                                       /////
        // Used by an owner to manually add a participant to the       //
        // pre-sale. General use would be for fiat participants and/or //
        // technologically distant participants.                       //
        /////                                                       /////

        participant cur_participant = participants[_payout_address]; // get participant struct mapped to the given payout_address
        cur_participant.eth_contributed =cur_participant.eth_contributed.add(_eth_contributed); // add eth contributed to current amount (for fiat a conversion is done off-chain)
        cur_participant.token_amount = cur_participant.token_amount.add(_token_amount); // add tokens to the current tokens amount (this is an arg rather calculated value allowing for custom prices)
        cur_participant.payout_address = _payout_address; // set payout address
        sold_presale_tokens = sold_presale_tokens.add(_token_amount); // update sold amount counter
    }

    // modifiers
    modifier Whitelisted(address check) {

        /////                                                       /////
        // Checks if the message sender is on the whitelist or owner   //
        /////                                                       /////

        if (check == owner || whitelist[check]) { // owner check prevents owner changes from locking themselves out
            _;
        } else {
            throw;
        }
    }

    modifier ValidPurchase(uint256 purchase) {

        /////                                                       /////
        // checks that a purchase won't breach the sale token # cap    //
        /////                                                       /////

        if (total_presale_tokens.add(purchase) > total_presale_tokens) {
            throw;
        } else {
            _;
        }
    }

    modifier DutchAuctionOn() {

        /////                                                       /////
        // checks if thw dutch auction logic is active                 //
        /////                                                       /////

        if (dutch_auction_on) {
            _;
        } else {
            throw;
        }
    }

    modifier PresaleOpen() {
        if (presale_open) {
            _;
        } else {
            throw;
        }
    }

}
