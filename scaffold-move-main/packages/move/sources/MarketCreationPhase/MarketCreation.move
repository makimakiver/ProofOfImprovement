module movement::TestMarketAbstraction {
    use std::debug::print;
    use std::vector;
    use std::signer;
    use std::string::{Self, String, utf8};
    use aptos_framework::event;
    use aptos_framework::account;
    use aptos_framework::table;
    use movement::TestPool2;

    // store an object which will store a mapping between the invitation and the participant
    struct InvitationRegistry has key {
        // from address of the recepient to the list of InvitationObject
        invitations: table::Table<address, vector<InvitationObject>>,
    }

    // the struct is like a letter which will be sent to the participant and the participant will respond to the letter
    struct InvitationObject has copy, drop, store, key{
        sender: address, 
        created_at: u64,
        participant: address, //receiver of the invitation
        seen: bool, //check if the invitation has been seen
        is_participant: bool, //check if the participant has accepted the invitation
        is_listed: bool, //check if the participant is listed in the market
    }

    struct MarketContainer has key {
        title: String, //title of the market
        markets: vector<TestPool2::PredictionMarketPool>, //containing the list of the market pools
        pre_participant: vector<address>, //list of users whom the invitation will be received
        participants: vector<address>, //participants of the market
        options: vector<String>, //name of each shares
    }
    // Initializing the invitation registry and only admin can call as all the invitations will be stored in the registry
    fun init_module(admin: &signer) {
        let admin_addr = signer::address_of(admin); 
        // transfer the ownership of Registry to the admin and let the object to be stored in the admin's account
        move_to(admin, InvitationRegistry {
            invitations: table::new(),
        });
    }

    fun create_market_place(owner: &signer, title_arg: String, pre_participant_arg: vector<address>, options_arg: vector<String>){
        let pools = vector::empty<TestPool2::PredictionMarketPool>(); //create an empty vector of PredictionMarketPool
        assert!(vector::length<address>(&pre_participant_arg) > 0, 0); //check if the User is not sending the invitation to anyone
        let participants_arg = vector::empty<address>(); 
        vector::push_back<address>(&mut participants_arg, signer::address_of(owner)); //add the owner to the participants list
        assert!(vector::length<String>(&options_arg) > 0, 0);
        move_to(
            owner,
            MarketContainer{
                title: title_arg,
                markets: pools,
                pre_participant: pre_participant_arg, // list of users whom the invitation will be received
                participants: participants_arg,
                options: options_arg, // name of each shares. (e.g. A*, A, B, C)
            }
        );
        
    }


    fun new_send_invitation(owner: &signer, market: &MarketContainer, participant: address, registry_addr: address) acquires InvitationObject, InvitationRegistry{
        let participants = get_participants(market); 
        let owner_addr = signer::address_of(owner);
        assert!(vector::contains<address>(&participants, &owner_addr), 0);
        let (invitation_signer, _signer_cap) = account::create_resource_account(owner, b"Invitation Letter"); //create a resource account for the invitation to be stored
        move_to<InvitationObject>(
            &invitation_signer,
            InvitationObject{
                sender: signer::address_of(owner),
                created_at: 0,
                participant: participant,
                seen: false,
                is_participant: false,
                is_listed: false,
            }
        );
        let invitation = move_from<InvitationObject>(signer::address_of(&invitation_signer)); //delete the ownership of the invitation from the owner temporarily
        let registry = borrow_global_mut<InvitationRegistry>(registry_addr);
        if (table::contains(&registry.invitations, participant)){ // if the participant already has received an invitation before
            let inv_vec = table::borrow_mut(&mut registry.invitations, participant);
            vector::push_back<InvitationObject>(inv_vec, invitation); //add the invitation to the list of the invitation
        }else{
            let inv_vec = vector::singleton<InvitationObject>(invitation);
            table::add(&mut registry.invitations, participant, inv_vec); //add the new mapping between the participant and the invitation
        };
        move_to(&invitation_signer, invitation); //return the ownership of the invitation to the owner(resource account)
    }

    fun send_invitation(owner: &signer, market: &MarketContainer, participant: address): address{
        let participants = market.participants;
        let owner_addr = signer::address_of(owner);
        let (invitation_signer, _signer_cap) = account::create_resource_account(owner, b"Invitation Letter");
        assert!(vector::contains<address>(&participants, &owner_addr), 0);
        move_to<InvitationObject>(
            &invitation_signer,
            InvitationObject{
                sender: signer::address_of(owner),
                created_at: 0,
                participant: participant,
                seen: false,
                is_participant: false,
                is_listed: false,
            }
        );
        return signer::address_of(&invitation_signer)
    }
    fun new_respond_invitation(sender: &signer, registry_addr: address, is_participant: bool, is_listed: bool) acquires InvitationRegistry, MarketContainer{
        let invitation_registry = borrow_global_mut<InvitationRegistry>(registry_addr);
        assert!(table::contains(&invitation_registry.invitations, signer::address_of(sender)), 1);
        let invitation_vector = table::borrow_mut(&mut invitation_registry.invitations, signer::address_of(sender));
        // Ensure there is at least one invitation.
        assert!(vector::length<InvitationObject>(invitation_vector) > 0, 2);
        // Obtain a mutable reference to the first invitation.
        let respond_invitation = vector::borrow_mut<InvitationObject>(invitation_vector, 0);
        // Check that the invitation belongs to the sender.
        assert!(respond_invitation.participant == signer::address_of(sender), 0);


        respond_invitation.seen = true;
        respond_invitation.is_participant = is_participant;
        respond_invitation.is_listed = is_listed;
        if (is_participant){
            enter_invitation_response(sender, respond_invitation.sender);
        };
        let invitation_registry_2 = borrow_global_mut<InvitationRegistry>(registry_addr);
        assert!(table::contains(&invitation_registry_2.invitations, signer::address_of(sender)), 1);

        // the code is complex due to the lifetime of each variable
        let invitation_vec = table::borrow_mut(&mut invitation_registry_2.invitations, signer::address_of(sender));
        let respond_invitation_2 = vector::borrow<InvitationObject>(invitation_vec, 0);
        let invitation_vec_2 = table::borrow(&invitation_registry_2.invitations, respond_invitation_2.participant);
        let respond_invitation_3 = vector::borrow<InvitationObject>(invitation_vec_2, 0);
        let invitation_registry_3 = borrow_global<InvitationRegistry>(registry_addr);
        let invitation_vec_3 = table::borrow(&invitation_registry_3.invitations, signer::address_of(sender));
        
        // take an index of where the invitation is stored in the vector
        let (existence, index) = vector::index_of<InvitationObject>(invitation_vec_3, respond_invitation_3);

        let invitation_registry_4 = borrow_global_mut<InvitationRegistry>(registry_addr);
        let invitation_vec_4 = table::borrow_mut(&mut invitation_registry_4.invitations, signer::address_of(sender));
        // as soon as the response is sent, the invitation should be removed from the registry
        if (existence){
            vector::remove<InvitationObject>(invitation_vec_4, index);
        }
    }

    fun enter_invitation_response(sender: &signer, market_container_addr: address) acquires MarketContainer{
        // the function will audit the participants array and pre_participants array
        let private_group = borrow_global_mut<MarketContainer>(market_container_addr);
        let (existence, index) = vector::index_of(&private_group.pre_participant, &signer::address_of(sender));
        if (existence){
            vector::remove<address>(&mut private_group.pre_participant, index);
            vector::push_back<address>(&mut private_group.participants, signer::address_of(sender));
        };
    }

    fun get_participants(pool: &MarketContainer): vector<address>{
        pool.participants
    }

    
    #[test(account = @movement)]
    #[expected_failure(abort_code = 0)]
    public fun test_create_market_place_1(account: &signer){
        create_market_place(account, utf8(b"Test"), vector::empty<address>(), vector::empty<String>());
    }
    #[test(account = @movement)]
    #[expected_failure(abort_code = 0)]
    public fun test_create_market_place_2(account: &signer){
        let participants = vector::empty<address>();
        vector::push_back<address>(&mut participants, @default);
        create_market_place(account, utf8(b"Test"), participants, vector::empty<String>());
    }
    #[test(account = @movement)]
    fun test_create_market_place_3(account: &signer){
        let participants = vector::empty<address>();
        vector::push_back<address>(&mut participants, @default);
        let shares = vector::empty<String>();
        vector::push_back<String>(&mut shares, utf8(b"A*"));
        vector::push_back<String>(&mut shares, utf8(b"A"));
        create_market_place(account, utf8(b"Test"), participants, shares);
    }
    #[test(account0 = @bocchi, account1 = @kita, account2 = @nijika, account3 = @ryo)]
    fun check_mailbox_2(account0: &signer, account1: &signer, account2: &signer, account3: &signer) acquires InvitationObject, InvitationRegistry, MarketContainer{
        init_module(account0);
        let participants = vector::empty<address>();
        vector::push_back<address>(&mut participants, @nijika);
        let shares = vector::empty<String>();
        vector::push_back<String>(&mut shares, utf8(b"A*"));
        vector::push_back<String>(&mut shares, utf8(b"A"));
        create_market_place(account1, utf8(b"Test"), participants, shares);
        assert!(vector::length<address>(&borrow_global<MarketContainer>(@kita).participants) == 1, 0);
        assert!(vector::length<address>(&borrow_global<MarketContainer>(@kita).pre_participant) == 1, 0);
        // when user sent the invitation the length should be incremented by 1
        new_send_invitation(account1, borrow_global<MarketContainer>(@kita), @nijika, @bocchi);
        assert!(table::contains(&borrow_global<InvitationRegistry>(@bocchi).invitations, @nijika), 0);
        let inv_vec = table::borrow(&borrow_global<InvitationRegistry>(@bocchi).invitations, @nijika);
        assert!(vector::length<InvitationObject>(inv_vec) == 1, 0);
        new_respond_invitation(account2, @bocchi, true, true);
        assert!(vector::length<address>(&borrow_global<MarketContainer>(@kita).participants) == 2, 0);
        assert!(vector::length<address>(&borrow_global<MarketContainer>(@kita).pre_participant) == 0, 0);
        let inv_vec_2 = table::borrow(&borrow_global<InvitationRegistry>(@bocchi).invitations, @nijika);
        assert!(vector::length<InvitationObject>(inv_vec_2) == 0, 0);
    }

}