// TO DO
// - Dutch Auction
// - whitelist functionality
// - helpers
// - events

pragma solidity ^0.4.23;

import "./Owned.sol";
import "./SafeMath.sol";

contract Presale is Owned {

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

        participant cur_participant = participants[msg.sender]; // get participant struct mapped to the sender
        cur_participant.payout_address = _payout_address; // change payout address
    }

    function GetInfo() public view Whitelisted PresaleOpen returns(uint256 eth, uint256 tokens, address payout_address) {

        /////                                                       /////
        // Let's users check that their info is correct. Also, allows  //
        // fiat participants to check that we, Topl, input their       //
        // purchase correctly.                                         //
        /////                                                       /////

        participant cur_participant = participants[msg.sender]; // get participant struct mapped to the sender
        return (cur_participant.eth_contributed, cur_participant.token_amount, cur_participant.payout_address); // return all participant data-points
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

        ///////// NOT DONE

    }

    // owner functions
    function GetParticipant(address subject) public view OnlyOwner returns(uint256 eth, uint256 tokens, address payout_address) {

        /////                                                       /////
        // Let's the owner get info on a participant. NOTE: This info  //
        // is technically publicly available, but requires a decent    //
        // amount of technical skill to access. This gives the owner   //
        // an easy way to look around the database.                    //
        /////                                                       /////

        participant cur_participant = participants[subject]; // get participant struct mapped to the sender
        return (cur_participant.eth_contributed, cur_participant.token_amount, cur_participant.payout_address); // return all participant data-points
    }

    function AddParticipant(uint256 _eth_contributed, uint256 _token_amount, address _payout_address) public OnlyOwner Whitelisted ValidPurchase(_token_amount) {

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

    function RemoveParticipant(address subject) public OnlyOwner {

        /////                                                       /////
        // Used by an owner to erase a participant's existence. It     //
        // resets their struct and undoes their tokens from the sold   //
        // tokens counter.                                             //
        /////                                                       /////

        participant cur_participant = participants[subject]; // get participant struct mapped to the given subject
        sold_presale_tokens = sold_presale_tokens.sub(cur_participant.token_amount); // undo his tokens from the sold count
        cur_participant.eth_contributed = 0; // 0
        cur_participant.token_amount = 0; // 0
        cur_participant.payout_address = 0x0; // 0
    }

    function EditParticipant(address subject, uint256 _new_eth, uint256 _new_tokens, address _new_payout_address) public OnlyOwner {

        /////                                                       /////
        // Used by an owner to adjust a participant's account. Can be  //
        // used to remove a participant completely though              //
        // RemoveParticipant if more efficient. Edits token count.     //
        /////                                                       /////

        participant cur_participant = participants[subject]; // get participant struct mapped to the given subject
        sold_presale_tokens = sold_presale_tokens.sub(cur_participant.token_amount); // undo his tokens from the sold count
        cur_participant.eth_contributed = _new_eth; // set to arg
        cur_participant.token_amount = _new_tokens; // set to arg
        cur_participant.payout_address = _new_payout_address; // set to arg
        sold_presale_tokens = sold_presale_tokens.add(cur_participant.token_amount); // add his tokens to the sold count
    }

    function ToggleDutchAuction() public OnlyOwner {

        /////                                                       /////
        // turn the dutch auction on and off if you're an owner        //
        /////                                                       /////

        if (dutch_auction_on) { // if on turn off
            dutch_auction_on = false;
        } else { // if off turn on
            dutch_auction_on = true;
        }
    }

    function AddWhitelister(address _new_whitelister) public OnlyOwner {

        /////                                                       /////
        // adds an address to the whitelist                            //
        /////                                                       /////

        whitelist[_new_whitelister] = true; // welcome
    }

    function RemoveWhitelister(address _whitelister) public OnlyOwner {

        /////                                                       /////
        // removes an address to the whitelist                         //
        /////                                                       /////

        whitelist[_whitelister] = false; //  get out
    }

    // helper functions
    function IsWhitelisted(address subject) public PresaleOpen returns(bool) {

        /////                                                       /////
        // checks an address's status                                  //
        /////                                                       /////

        return whitelist[subject]; // returns bool
    }

    function IsDutchAuction() public PresaleOpen returns(bool) {

        /////                                                       /////
        // checks if dutch auction logic is active                     //
        /////                                                       /////

        return dutch_auction_on; // returns bool
    }

    function IsPresaleOpen() public returns(bool) {

        /////                                                       /////
        // checks if presale is open                                   //
        /////                                                       /////

        return presale_open; // returns bool
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

    // events
    event e_Participate(address, uint256, uint256, address);
    event e_ChangePayoutAddress(address, uint256, uint256, address, address);
    event e_GetInfo(address, uint256, uint256, address);
    event e_Tick(uint256);
    event e_GetParticipant(address, uint256, uint256, address);
    event e_AddParticipant(address, uint256, uint256, address, uint256);
    event e_RemoveParticipant(address, uint256, uint256, address, uint256);
    event e_EditParticipant(address, uint256, uint256, address, uint256, uint256, address, uint256);
    event e_ToggleDutchAuction(bool);
    event e_AddWhitelister(address, bool);
    event e_RemoveWhitelister(address, bool);
    event e_IsWhiteListed(address, address, bool);
    event e_IsDutchAuction(address, address, bool);
    event e_IsPresaleOpen(address, bool);
}
