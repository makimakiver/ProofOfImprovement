module movement::TestMarketAbstraction {
    use std::debug::print;
    use std::vector;
    use std::signer;
    use std::bcs;
    use std::string::{Self, String, utf8};
    use aptos_framework::event;
    use aptos_framework::account;
    use aptos_framework::table;
    use movement::PoILiquidityPool;

    struct UserData has key{
        username: String,
        invitation_sent: vector<InvitationObject>,
    }
    // store an object which will store a mapping between the invitation and the participant
    struct InvitationRegistry has key{
        // from address of the recepient to the list of InvitationObject
        invitations: table::Table<address, vector<InvitationObject>>,
    }

    // // store an object which will store a mapping between the invitation and the participant
    // struct AddressMarketConnection has key{
    //     // from address of the recepient to the list of InvitationObject
    //     address_to_market_place: table::Table<address, vector<address>>,
    // }
    // the struct is like a letter which will be sent to the participant and the participant will respond to the letter
    struct InvitationObject has copy, drop, store, key{
        sender: address, 
        market_address: address,
        created_at: u64,
        participant: address, //receiver of the invitation
        seen: bool, //check if the invitation has been seen
        is_participant: bool, //check if the participant has accepted the invitation
        is_listed: bool, //check if the participant is listed in the market
    }

    struct MarketContainer has key, drop{
        title: String, //title of the market
        markets: vector<PoILiquidityPool::PredictionMarketPool>, //containing the list of the market pools
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
    // fun init_module_2(admin: &signer) {
    //     let admin_addr = signer::address_of(admin); 
    //     // transfer the ownership of Registry to the admin and let the object to be stored in the admin's account
    //     move_to(admin, AddressMarketConnection {
    //         address_to_market_place: table::new(),
    //     });
    // }
    public entry fun neo_create_market_place(owner: &signer, title_arg: String, pre_participant_arg: vector<address>, options_arg: vector<String>, registry_addr: address) acquires InvitationObject, InvitationRegistry{
        assert!(vector::length<address>(&pre_participant_arg) > 0, 0); //check if the User is not sending the invitation to anyone
        assert!(vector::length<String>(&options_arg) > 0, 0);
        let (market_place_signer, _signer_cap) = account::create_resource_account(owner, *string::bytes(&title_arg)); //create a resource account for the invitation to be stored
        // assert!(exists<InvitationRegistry>(registry_addr), 404);
        let pools = vector::empty<PoILiquidityPool::PredictionMarketPool>(); //create an empty vector of PredictionMarketPool
        let participants_arg = vector::empty<address>(); 
        vector::push_back<address>(&mut participants_arg, signer::address_of(owner)); //add the owner to the participants list
        let market_cont_1 = MarketContainer{
                title: title_arg,
                markets: pools,
                pre_participant: pre_participant_arg, // list of users whom the invitation will be received
                participants: participants_arg,
                options: options_arg, // name of each shares. (e.g. A*, A, B, C)
            };
        move_to(
            &market_place_signer,
            market_cont_1
        );
        let pos = 0;
        while (pos < vector::length(&pre_participant_arg)){
            let market_cont_2 = MarketContainer{
                    title: title_arg,
                    markets: vector::empty<PoILiquidityPool::PredictionMarketPool>(),
                    pre_participant: pre_participant_arg, // list of users whom the invitation will be received
                    participants: participants_arg,
                    options: options_arg, // name of each shares. (e.g. A*, A, B, C)
                };
            new_send_invitation(&market_place_signer, &market_cont_2, *vector::borrow<address>(&pre_participant_arg, pos), registry_addr, signer::address_of(owner));
            pos = pos + 1;
        };
    }
    fun create_market_place(owner: &signer, title_arg: String, pre_participant_arg: vector<address>, options_arg: vector<String>, registry_addr: address): address acquires InvitationObject, InvitationRegistry{
        assert!(vector::length<address>(&pre_participant_arg) > 0, 0); //check if the User is not sending the invitation to anyone
        assert!(vector::length<String>(&options_arg) > 0, 0);
        let (market_place_signer, _signer_cap) = account::create_resource_account(owner, *string::bytes(&title_arg)); //create a resource account for the invitation to be stored
        // assert!(exists<InvitationRegistry>(registry_addr), 404);
        let pools = vector::empty<PoILiquidityPool::PredictionMarketPool>(); //create an empty vector of PredictionMarketPool
        let participants_arg = vector::empty<address>(); 
        vector::push_back<address>(&mut participants_arg, signer::address_of(owner)); //add the owner to the participants list
        let market_cont_1 = MarketContainer{
                title: title_arg,
                markets: pools,
                pre_participant: pre_participant_arg, // list of users whom the invitation will be received
                participants: participants_arg,
                options: options_arg, // name of each shares. (e.g. A*, A, B, C)
            };
        move_to(
            &market_place_signer,
            market_cont_1
        );
        let pos = 0;
        while (pos < vector::length(&pre_participant_arg)){
            let market_cont_2 = MarketContainer{
                    title: title_arg,
                    markets: vector::empty<PoILiquidityPool::PredictionMarketPool>(),
                    pre_participant: pre_participant_arg, // list of users whom the invitation will be received
                    participants: participants_arg,
                    options: options_arg, // name of each shares. (e.g. A*, A, B, C)
                };
            new_send_invitation(&market_place_signer, &market_cont_2, *vector::borrow<address>(&pre_participant_arg, pos), registry_addr, signer::address_of(owner));
            pos = pos + 1;
        };
        return signer::address_of(&market_place_signer)
    }


    fun new_send_invitation(owner: &signer, market: &MarketContainer, participant: address, registry_addr: address, sender: address) acquires InvitationObject, InvitationRegistry{
        let participants = get_participants(market); 
        let owner_addr = signer::address_of(owner);
        assert!(vector::contains<address>(&participants, &sender), 0);
        let (invitation_signer, _signer_cap) = account::create_resource_account(owner, bcs::to_bytes(&participant)); //create a resource account for the invitation to be stored
        move_to<InvitationObject>(
            &invitation_signer,
            InvitationObject{
                sender: signer::address_of(owner),
                market_address: signer::address_of(owner),
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

    public entry fun send_invitation(owner: &signer, market_addr: address, participant: address, registry_addr: address)acquires MarketContainer, InvitationObject, InvitationRegistry{
        let owner_addr = signer::address_of(owner);
        let market = borrow_global<MarketContainer>(market_addr);
        let participants = market.participants;
        assert!(vector::contains<address>(&participants, &owner_addr), 0);
        let (invitation_signer, _signer_cap) = account::create_resource_account(owner, bcs::to_bytes(&participant));
        move_to<InvitationObject>(
            &invitation_signer,
            InvitationObject{
                sender: signer::address_of(owner),
                market_address: market_addr,
                created_at: 0,
                participant: participant,
                seen: false,
                is_participant: false,
                is_listed: false,
            }
        );
        enter_invitation_request(owner, market_addr, participant);
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
    fun new_respond_invitation(sender: &signer, registry_addr: address, is_participant: bool, is_listed: bool) acquires MarketContainer, InvitationRegistry{
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
            enter_invitation_response(sender, respond_invitation.market_address);
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
    fun enter_invitation_request(sender: &signer, market_container_addr: address, participant:address) acquires MarketContainer{
        // the function will audit the participants array and pre_participants array
        let private_group = borrow_global_mut<MarketContainer>(market_container_addr);
        let (existence, index) = vector::index_of(&private_group.pre_participant, &signer::address_of(sender));
        if (!existence){
            vector::push_back<address>(&mut private_group.pre_participant, participant);
        };
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

    fun get_market_title(pool: &MarketContainer): vector<u8>{
        *string::bytes(&pool.title)
    }

    #[test(account = @movement)]
    #[expected_failure(abort_code = 0)]
    public fun test_create_market_place_1(account: &signer) acquires InvitationObject, InvitationRegistry{
        create_market_place(account, utf8(b"Test"), vector::empty<address>(), vector::empty<String>(), @bocchi);
    }
    #[test(account = @kita)]
    #[expected_failure(abort_code = 0)]
    public fun test_create_market_place_2(account: &signer) acquires InvitationObject, InvitationRegistry{
        let participants = vector::empty<address>();
        vector::push_back<address>(&mut participants, @nijika);
        create_market_place(account, utf8(b"Test"), participants, vector::empty<String>(), @bocchi);
    }
    #[test(account0 = @bocchi, account1 = @kita, account2 = @nijika, account3 = @ryo)]
    // test fails as there is no init function
    fun test_create_market_place_3(account0: &signer) acquires InvitationObject, InvitationRegistry{
        let participants = vector::empty<address>();
        vector::push_back<address>(&mut participants, @nijika);
        let shares = vector::empty<String>();
        vector::push_back<String>(&mut shares, utf8(b"A*"));
        vector::push_back<String>(&mut shares, utf8(b"A"));
        create_market_place(account0, utf8(b"Test"), participants, shares, @bocchi);
    }

    #[test(account0 = @bocchi, account1 = @kita, account2 = @nijika, account3 = @ryo)]
    fun test_create_market_place_4(account0: &signer, account1: &signer) acquires InvitationObject, InvitationRegistry{
        init_module(account0);
        let participants = vector::empty<address>();
        vector::push_back<address>(&mut participants, @nijika);
        let shares = vector::empty<String>();
        vector::push_back<String>(&mut shares, utf8(b"A*"));
        vector::push_back<String>(&mut shares, utf8(b"A"));
        create_market_place(account1, utf8(b"Test"), participants, shares, @bocchi);
    }
    #[test(account0 = @bocchi, account1 = @kita, account2 = @nijika, account3 = @ryo)]
    fun test_create_market_place_5(account0: &signer, account1: &signer) acquires InvitationObject, InvitationRegistry{
        init_module(account0);
        let participants = vector::empty<address>();
        vector::push_back<address>(&mut participants, @nijika);
        let shares = vector::empty<String>();
        vector::push_back<String>(&mut shares, utf8(b"A*"));
        vector::push_back<String>(&mut shares, utf8(b"A"));
        create_market_place(account1, utf8(b"Test"), participants, shares, @bocchi);
        create_market_place(account1, utf8(b"Test2"), participants, shares, @bocchi);
    }
    #[test(account0 = @bocchi, account1 = @kita, account2 = @nijika, account3 = @ryo)]
    fun check_mailbox_2(account0: &signer, account1: &signer, account2: &signer, account3: &signer) acquires InvitationObject, InvitationRegistry, MarketContainer{
        init_module(account0);
        let participants = vector::empty<address>();
        vector::push_back<address>(&mut participants, @nijika);
        let shares = vector::empty<String>();
        vector::push_back<String>(&mut shares, utf8(b"A*"));
        vector::push_back<String>(&mut shares, utf8(b"A"));
        print(&utf8(b"hello_from_check_mailbox2"));
        let kita_virtual = create_market_place(account1, utf8(b"Test"), participants, shares, @bocchi);
        assert!(vector::length<address>(&borrow_global<MarketContainer>(kita_virtual).participants) == 1, 0);
        assert!(vector::length<address>(&borrow_global<MarketContainer>(kita_virtual).pre_participant) == 1, 0);
        // when user sent the invitation the length should be incremented by 1
        assert!(table::contains(&borrow_global<InvitationRegistry>(@bocchi).invitations, @nijika), 0);
        let inv_vec = table::borrow(&borrow_global<InvitationRegistry>(@bocchi).invitations, @nijika);
        assert!(vector::length<InvitationObject>(inv_vec) == 1, 0);
        new_respond_invitation(account2, @bocchi, true, true);
        assert!(vector::length<address>(&borrow_global<MarketContainer>(kita_virtual).participants) == 2, 0);
        assert!(vector::length<address>(&borrow_global<MarketContainer>(kita_virtual).pre_participant) == 0, 0);
        let inv_vec_2 = table::borrow(&borrow_global<InvitationRegistry>(@bocchi).invitations, @nijika);
        assert!(vector::length<InvitationObject>(inv_vec_2) == 0, 0);
    }
    #[test(account0 = @bocchi, account1 = @kita, account2 = @nijika, account3 = @ryo)]
    fun check_mailbox_3(account0: &signer, account1: &signer, account2: &signer, account3: &signer) acquires InvitationObject, InvitationRegistry, MarketContainer{
        init_module(account0);
        let participants = vector::empty<address>();
        vector::push_back<address>(&mut participants, @nijika);
        let shares = vector::empty<String>();
        vector::push_back<String>(&mut shares, utf8(b"A*"));
        vector::push_back<String>(&mut shares, utf8(b"A"));
        print(&utf8(b"hello_from_check_mailbox2"));
        let kita_virtual = create_market_place(account1, utf8(b"Test"), participants, shares, @bocchi);
        assert!(vector::length<address>(&borrow_global<MarketContainer>(kita_virtual).participants) == 1, 0);
        assert!(vector::length<address>(&borrow_global<MarketContainer>(kita_virtual).pre_participant) == 1, 0);
        // when user sent the invitation the length should be incremented by 1
        assert!(table::contains(&borrow_global<InvitationRegistry>(@bocchi).invitations, @nijika), 0);
        let inv_vec = table::borrow(&borrow_global<InvitationRegistry>(@bocchi).invitations, @nijika);
        assert!(vector::length<InvitationObject>(inv_vec) == 1, 0);
        new_respond_invitation(account2, @bocchi, true, true);
        assert!(vector::length<address>(&borrow_global<MarketContainer>(kita_virtual).participants) == 2, 0);
        assert!(vector::length<address>(&borrow_global<MarketContainer>(kita_virtual).pre_participant) == 0, 0);
        let inv_vec_2 = table::borrow(&borrow_global<InvitationRegistry>(@bocchi).invitations, @nijika);
        assert!(vector::length<InvitationObject>(inv_vec_2) == 0, 0);
        send_invitation(account2, kita_virtual, @ryo, @bocchi);
        assert!(vector::length<address>(&borrow_global<MarketContainer>(kita_virtual).participants) == 2, 0);
        assert!(vector::length<address>(&borrow_global<MarketContainer>(kita_virtual).pre_participant) == 1, 0);
        new_respond_invitation(account3, @bocchi, true, true);
        assert!(vector::length<address>(&borrow_global<MarketContainer>(kita_virtual).participants) == 3, 0);
        assert!(vector::length<address>(&borrow_global<MarketContainer>(kita_virtual).pre_participant) == 0, 0);
    }
    #[test(account0 = @bocchi, account1 = @kita, account2 = @nijika, account3 = @ryo)]
    #[expected_failure(abort_code = 0)]
    fun check_mailbox_4(account0: &signer, account1: &signer, account2: &signer, account3: &signer) acquires InvitationObject, InvitationRegistry, MarketContainer{
        init_module(account0);
        let participants = vector::empty<address>();
        vector::push_back<address>(&mut participants, @nijika);
        let shares = vector::empty<String>();
        vector::push_back<String>(&mut shares, utf8(b"A*"));
        vector::push_back<String>(&mut shares, utf8(b"A"));
        print(&utf8(b"hello_from_check_mailbox2"));
        let kita_virtual = create_market_place(account1, utf8(b"Test"), participants, shares, @bocchi);
        assert!(vector::length<address>(&borrow_global<MarketContainer>(kita_virtual).participants) == 1, 0);
        assert!(vector::length<address>(&borrow_global<MarketContainer>(kita_virtual).pre_participant) == 1, 0);
        // when user sent the invitation the length should be incremented by 1
        assert!(table::contains(&borrow_global<InvitationRegistry>(@bocchi).invitations, @nijika), 0);
        let inv_vec = table::borrow(&borrow_global<InvitationRegistry>(@bocchi).invitations, @nijika);
        assert!(vector::length<InvitationObject>(inv_vec) == 1, 0);
        new_respond_invitation(account2, @bocchi, true, true);
        assert!(vector::length<address>(&borrow_global<MarketContainer>(kita_virtual).participants) == 2, 0);
        assert!(vector::length<address>(&borrow_global<MarketContainer>(kita_virtual).pre_participant) == 0, 0);
        let inv_vec_2 = table::borrow(&borrow_global<InvitationRegistry>(@bocchi).invitations, @nijika);
        assert!(vector::length<InvitationObject>(inv_vec_2) == 0, 0);
        send_invitation(account3, kita_virtual, @ryo, @bocchi);
    }
  #[test(account0 = @bocchi, account1 = @kita, account2 = @nijika, account3 = @ryo)]
    fun check_mailbox_5(account0: &signer, account1: &signer, account2: &signer, account3: &signer) acquires InvitationObject, InvitationRegistry, MarketContainer{
        init_module(account0);
        let participants = vector::empty<address>();
        vector::push_back<address>(&mut participants, @nijika);
        vector::push_back<address>(&mut participants, @ryo);
        let shares = vector::empty<String>();
        vector::push_back<String>(&mut shares, utf8(b"A*"));
        vector::push_back<String>(&mut shares, utf8(b"A"));
        print(&utf8(b"hello_from_check_mailbox2"));
        let kita_virtual = create_market_place(account1, utf8(b"Test"), participants, shares, @bocchi);
        assert!(vector::length<address>(&borrow_global<MarketContainer>(kita_virtual).participants) == 1, 0);
        assert!(vector::length<address>(&borrow_global<MarketContainer>(kita_virtual).pre_participant) == 2, 0);
        // when user sent the invitation the length should be incremented by 1
        assert!(table::contains(&borrow_global<InvitationRegistry>(@bocchi).invitations, @nijika), 0);
        let inv_vec = table::borrow(&borrow_global<InvitationRegistry>(@bocchi).invitations, @nijika);
        assert!(vector::length<InvitationObject>(inv_vec) == 1, 0);
        new_respond_invitation(account2, @bocchi, true, true);
        assert!(vector::length<address>(&borrow_global<MarketContainer>(kita_virtual).participants) == 2, 0);
        assert!(vector::length<address>(&borrow_global<MarketContainer>(kita_virtual).pre_participant) == 1, 0);
        let inv_vec_2 = table::borrow(&borrow_global<InvitationRegistry>(@bocchi).invitations, @nijika);
        assert!(vector::length<InvitationObject>(inv_vec_2) == 0, 0);
    }
}