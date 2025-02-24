module movement::TestMarketAbstraction {
    use std::debug::print;
    use std::vector;
    use std::signer;
    use std::bcs;
    use std::randomness;
    use std::string::{Self, String, utf8, };
    use aptos_framework::event;
    use aptos_framework::account;
    use aptos_framework::table;
    // use aptos_framework::randomness;
    use movement::PoILiquidityPool;


////////Market Opening structs start////////////


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
        market_end: bool,
    }

//////Market Opening Structs end//////

/////Market Validation structs start//////
    // store an object which will store a mapping between the invitation and the participant
    struct ValidationRegistry has key{
        // from address of the recepient to the list of InvitationObject
        validations: table::Table<address, vector<ValidationObject>>,
    }

    struct ValidationObject has copy, drop, store, key{
        sender: address, 
        market_address: address,
        created_at: u64,
        participant: address, //receiver of the invitation
        seen: bool, //check if the invitation has been seen
        is_valid: bool, //check if the participant has accepted the invitation
        reason: String, //In worst case scenario, I'll use the reason attributes to explain why the user is putting invalid answer
    }

    struct ValidationAttachment has key, drop{
        market_address: address, //address of the market
        pre_validators: vector<address>, //list of users whom the invitation will be received
        validators: vector<address>, //participants of the market
    }


/////Market Validation structs finish//////

/////Market Opening starts//////////
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
                market_end: false,
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
                    market_end: false,
                };
            new_send_invitation(&market_place_signer, &market_cont_2, *vector::borrow<address>(&pre_participant_arg, pos), registry_addr, signer::address_of(owner));
            pos = pos + 1;
        };

    /// Validation is assigned when the market is created ///
        let validators = vector::empty<address>(); 
        let pre_validators = vector::empty<address>(); 
        let validation_info = ValidationAttachment{
            market_address: signer::address_of(&market_place_signer), //address of the market
            pre_validators: pre_validators, //list of users whom the invitation will be received
            validators: validators, //participants of the market
        };
        move_to(
            &market_place_signer,
            validation_info
        );
    /// the validation info will be stored the same place as the market cont
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

    fun send_invitation(owner: &signer, market_addr: address, participant: address, registry_addr: address)acquires MarketContainer, InvitationObject, InvitationRegistry{
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


    public fun get_participants(pool: &MarketContainer): vector<address>{
        pool.participants
    }

    fun get_market_title(pool: &MarketContainer): vector<u8>{
        *string::bytes(&pool.title)
    }

    // public fun get_market(addr: address): &MarketContainer acquires MarketContainer{
    //     let market = borrow_global<MarketContainer>(addr);
    //     market
    // }

    // public fun get_pool(market: &MarketContainer): vector<PoILiquidityPool::PredictionMarketPool>{
    //     market.markets
    // }

////////Market Opening end////////////

////////Market Validation start////////////


    // Initializing the invitation registry and only admin can call as all the invitations will be stored in the registry
    fun initialise_validation_reg_mod(admin: &signer) {
        let admin_addr = signer::address_of(admin); 
        // transfer the ownership of Registry to the admin and let the object to be stored in the admin's account
        move_to(admin, ValidationRegistry {
            validations: table::new(),
        });
    }

    fun new_validate_market_place(owner: &signer, registry_addr: address, market_addr: address) acquires ValidationObject, ValidationRegistry, MarketContainer, ValidationAttachment{


        // should restrict people from validating the market

        // If the market ends the validation stage
        let market_place = borrow_global<MarketContainer>(market_addr);//getter

        assert!(vector::contains<address>(&market_place.participants, &signer::address_of(owner)), 0);
        // assert!(vector::length<address>(&participant_arg) > 0, 0); //check if the User is not sending the invitation to anyone
        // assert!(vector::length<String>(&options_arg) > 0, 0);
        let title_vec = *string::bytes(&market_place.title);
        let val_str_vec = b"validation";
        let result = vector::empty<u8>();
        vector::append(&mut result, title_vec);
        vector::append(&mut result, val_str_vec);
        let (validation_signer, _signer_cap) = account::create_resource_account(owner, result); //change should be made(the resource account address will be just identical as the )
        // assert!(exists<InvitationRegistry>(registry_addr), 404);
        // let pools = TestMarketAbstraction::get_pool(market_place); //use get function
        let validators = vector::empty<address>(); 
        let pre_validators = vector::empty<address>(); 
        let len = 2;
        let count = 0;
        while (count < len){
            let participants = get_participants(market_place);
            let num_of_participants = vector::length<address>(&participants) - 2;
            let pre_validator_idx = 1;
            let pre_validator_addr = vector::borrow<address>(&participants, pre_validator_idx);
            while(vector::contains((&pre_validators), pre_validator_addr)){
                print(&utf8(b"containing same objects..."));
                pre_validator_idx = pre_validator_idx + 1;
                pre_validator_addr = vector::borrow<address>(&participants, pre_validator_idx);        
            };
            vector::push_back(&mut pre_validators, *pre_validator_addr);
            count = count + 1
        };
        let pos = 0;
        let validation_info_1 = borrow_global_mut<ValidationAttachment>(market_addr);
        validation_info_1.pre_validators = pre_validators;
        while (pos < vector::length(&pre_validators)){
            let validation_info_2 = ValidationAttachment{
                market_address: market_addr, //address of the market
                pre_validators: pre_validators, //list of users whom the invitation will be received
                validators: validators, //participants of the market
            };
            new_send_validation(&validation_signer, &validation_info_2, *vector::borrow<address>(&pre_validators, pos), registry_addr, signer::address_of(owner), market_addr);
            pos = pos + 1;
        };
    }

    fun new_send_validation(owner: &signer, market: &ValidationAttachment, participant: address, registry_addr: address, sender: address, market_address: address) acquires ValidationObject, ValidationRegistry{
        let (validation_signer, _signer_cap) = account::create_resource_account(owner, bcs::to_bytes(&participant)); //create a resource account for the invitation to be stored
        move_to<ValidationObject>(
            &validation_signer,
            ValidationObject{
                sender: sender, 
                market_address: market_address,
                created_at: 0,
                participant: participant, //receiver of the invitation
                seen: false, //check if the invitation has been seen
                is_valid: false, //check if the participant has accepted the invitation
                reason: utf8(b""), //In worst case scenario, I'll use the reason attributes to explain why the user is putting invalid answer
            }
        );
        let validation_obj = move_from<ValidationObject>(signer::address_of(&validation_signer)); //delete the ownership of the invitation from the owner temporarily
        let registry = borrow_global_mut<ValidationRegistry>(registry_addr);
        if (table::contains(&registry.validations, participant)){ // if the participant already has received an invitation before
            let validation_vec = table::borrow_mut(&mut registry.validations, participant);
            vector::push_back<ValidationObject>(validation_vec, validation_obj); //add the invitation to the list of the invitation
        }else{
            let validation_vec = vector::singleton<ValidationObject>(validation_obj);
            table::add(&mut registry.validations, participant, validation_vec); //add the new mapping between the participant and the invitation
        };
        move_to(&validation_signer, validation_obj); //return the ownership of the invitation to the owner(resource account)
    }

    fun new_respond_validation(sender: &signer, registry_addr: address, is_valid: bool, reason: String) acquires ValidationAttachment, ValidationRegistry{
        let validation_registry = borrow_global_mut<ValidationRegistry>(registry_addr);
        assert!(table::contains(&validation_registry.validations, signer::address_of(sender)), 1);
        let validation_vector = table::borrow_mut(&mut validation_registry.validations, signer::address_of(sender));
        // Ensure there is at least one validation request.
        assert!(vector::length<ValidationObject>(validation_vector) > 0, 2);
        // Obtain a mutable reference to the first validation.
        let respond_validation = vector::borrow_mut<ValidationObject>(validation_vector, 0);
        // Check that the invitation belongs to the sender.
        assert!(respond_validation.participant == signer::address_of(sender), 0);
        respond_validation.seen = true;
        respond_validation.is_valid = is_valid;
        respond_validation.reason = reason;
        enter_validation_response(sender, respond_validation.market_address);
        let validation_registry_2 = borrow_global_mut<ValidationRegistry>(registry_addr);
        assert!(table::contains(&validation_registry_2.validations, signer::address_of(sender)), 1);

        // the code is complex due to the lifetime of each variable
        let validation_vec = table::borrow_mut(&mut validation_registry_2.validations, signer::address_of(sender));
        let respond_validation_2 = vector::borrow<ValidationObject>(validation_vec, 0);
        let validation_vec2 = table::borrow(&validation_registry_2.validations, respond_validation_2.participant);
        let respond_validation_3 = vector::borrow<ValidationObject>(validation_vec2, 0);
        let validation_registry_3 = borrow_global<ValidationRegistry>(registry_addr);
        let validation_vec3 = table::borrow(&validation_registry_3.validations, signer::address_of(sender));
        
        // take an index of where the invitation is stored in the vector
        let (existence, index) = vector::index_of<ValidationObject>(validation_vec3, respond_validation_3);

        let validation_registry_4 = borrow_global_mut<ValidationRegistry>(registry_addr);
        let validation_vec_4 = table::borrow_mut(&mut validation_registry_4.validations, signer::address_of(sender));
        // as soon as the response is sent, the invitation should be removed from the registry
        if (existence){
            vector::remove<ValidationObject>(validation_vec_4, index);
        }
    }

    fun enter_validation_response(sender: &signer, market_container_addr: address) acquires ValidationAttachment{
        // the function will audit the participants array and pre_participants array
        let validation_attachment = borrow_global_mut<ValidationAttachment>(market_container_addr);
        let (existence, index) = vector::index_of(&validation_attachment.pre_validators, &signer::address_of(sender));
        assert!(existence, 0);
        if (existence){
            vector::remove<address>(&mut validation_attachment.pre_validators, index);
            vector::push_back<address>(&mut validation_attachment.validators, signer::address_of(sender));
        };
    }
////////Market Validation end ////////////

////////Market Opening Test ////////////
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
    
////////Market Opening Test end ////////////

////////Market Validation Test ////////////
    #[test(account0 = @bocchi, account1 = @kita, account2 = @nijika, account3 = @ryo)]
    fun test_send_validation(account0: &signer, account1: &signer, account2: &signer, account3: &signer) acquires InvitationObject, InvitationRegistry, ValidationObject, ValidationRegistry, MarketContainer, ValidationAttachment{
        init_module(account0);
        initialise_validation_reg_mod(account0);
        let participants = vector::empty<address>();
        vector::push_back<address>(&mut participants, @nijika);
        vector::push_back<address>(&mut participants, @ryo);
        let shares = vector::empty<String>();
        vector::push_back<String>(&mut shares, utf8(b"A*"));
        vector::push_back<String>(&mut shares, utf8(b"A"));
        print(&utf8(b"hello_from_check_mailbox2"));
        let kita_virtual = create_market_place(account1, utf8(b"Test"), participants, shares, @bocchi);
        new_respond_invitation(account2, @bocchi, true, true);
        new_respond_invitation(account3, @bocchi, true, true);
        assert!(vector::length<address>(&borrow_global<MarketContainer>(kita_virtual).participants) == 3, 0);
        new_validate_market_place(account1, @bocchi, kita_virtual);
        assert!(vector::length<address>(&borrow_global<ValidationAttachment>(kita_virtual).pre_validators) == 2, 0);
    }

    #[test(account0 = @bocchi, account1 = @kita, account2 = @nijika, account3 = @ryo)]
    #[expected_failure(abort_code = 0)]
    fun test_send_validation_2(account0: &signer, account1: &signer, account2: &signer, account3: &signer) acquires InvitationObject, InvitationRegistry, ValidationObject, ValidationRegistry, MarketContainer, ValidationAttachment{
        init_module(account0);
        initialise_validation_reg_mod(account0);
        let participants = vector::empty<address>();
        vector::push_back<address>(&mut participants, @nijika);
        vector::push_back<address>(&mut participants, @ryo);
        let shares = vector::empty<String>();
        vector::push_back<String>(&mut shares, utf8(b"A*"));
        vector::push_back<String>(&mut shares, utf8(b"A"));
        print(&utf8(b"hello_from_check_mailbox2"));
        let kita_virtual = create_market_place(account1, utf8(b"Test"), participants, shares, @bocchi);
        new_respond_invitation(account2, @bocchi, true, true);
        new_respond_invitation(account3, @bocchi, true, true);
        assert!(vector::length<address>(&borrow_global<MarketContainer>(kita_virtual).participants) == 3, 0);
        new_validate_market_place(account0, @bocchi, kita_virtual);
    }

}