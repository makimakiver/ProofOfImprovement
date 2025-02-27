module movement::TestMarketAbstraction {
    use std::debug::print;
    use std::vector;
    use std::signer;
    use std::bcs;
    use std::randomness;
    use std::string::{Self, String, utf8};
    use aptos_framework::event;
    use aptos_framework::account;
    use aptos_framework::table;
    // use aptos_framework::randomness;
    use movement::PoILiquidityPool;


    #[event]
    struct MarketCreation has drop, store {
        market_addr: address,
        owner: address,
    }

////////Market Opening structs start////////////


    // store an object which will store a mapping between the invitation and the participant
    struct InvitationRegistry has key{
        // from address of the recepient to the list of InvitationObject
        invitations: table::Table<address, vector<InvitationObject>>,
    }
    struct ValidationProof has key{
        photo: String,
    }
    struct PMPRegistry has key {
        market_address: address,
        user_to_LP: table::Table<address, address>
    }

    struct UserDataRegistry has key{
        markets_available: table::Table<address, vector<address>>,
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
    struct MarketContainer has key, drop, copy{
        owner: address,
        title: String, //title of the market
        markets: vector<address>, //containing the list of the market pools
        pre_participant: vector<address>, //list of users whom the invitation will be received
        participants: vector<address>, //participants of the market
        options: vector<String>, //name of each shares
        symbols: vector<String>,
        market_validating: bool,
        market_end: bool,
    }

    struct LPMarketTable has key{
        lp_mapping: table::Table<address, address>,
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
        lp_address: address,
        created_at: u64,
        participant: vector<address>, //receiver of the invitation
        // picture: String,
        seen: bool, //check if the invitation has been seen
        is_valid: vector<bool>, //check if the participant has accepted the invitation
        reason: vector<String>, //In worst case scenario, I'll use the reason attributes to explain why the user is putting invalid answer
    }

    struct ValidationAttachment has key, drop, copy{
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
        move_to(admin, UserDataRegistry {
            markets_available: table::new(),
        });
        move_to(admin, ValidationRegistry {
            validations: table::new(),
        });
        // move_to(admin, ValidationRegistry {
        //     validations: table::new(),
        // });
    }
    // fun init_module_2(admin: &signer) {
    //     let admin_addr = signer::address_of(admin); 
    //     // transfer the ownership of Registry to the admin and let the object to be stored in the admin's account
    //     move_to(admin, AddressMarketConnection {
    //         address_to_market_place: table::new(),
    //     });
    // }
    public entry fun new_create_market_place(owner: &signer, title_arg: String, pre_participant_arg: vector<address>, symbols: vector<String>, names: vector<String>, registry_addr: address) acquires InvitationObject, InvitationRegistry, UserDataRegistry{
        assert!(vector::length<address>(&pre_participant_arg) > 0, 0); //check if the User is not sending the invitation to anyone
        assert!(vector::length<String>(&symbols) > 0, 0);
        if (vector::contains<address>(&pre_participant_arg, &signer::address_of(owner))){
            abort 2
        };
        let (market_place_signer, _signer_cap) = account::create_resource_account(owner, *string::bytes(&title_arg)); //create a resource account for the invitation to be stored
        // assert!(exists<InvitationRegistry>(registry_addr), 404);
        let pools = vector::empty<address>(); //create an empty vector of PredictionMarketPool
        let host_lp = PoILiquidityPool::create_ticket_and_buy(owner, title_arg, names, symbols);
        vector::push_back(&mut pools, host_lp);

        let registry = borrow_global_mut<UserDataRegistry>(registry_addr);
        if (table::contains(&registry.markets_available, signer::address_of(owner))){ // if the participant already has received an invitation before
            let inv_vec = table::borrow_mut(&mut registry.markets_available, signer::address_of(owner));
            vector::push_back<address>(inv_vec, signer::address_of(&market_place_signer)); //add the invitation to the list of the invitation
        }else{
            let inv_vec = vector::singleton<address>(signer::address_of(&market_place_signer));
            table::add(&mut registry.markets_available, signer::address_of(owner), inv_vec); //add the new mapping between the participant and the invitation
        };

        let user_LP_table = table::new();
        table::add(&mut user_LP_table, signer::address_of(owner), host_lp);
        let pmp_reg = PMPRegistry{
            market_address: signer::address_of(&market_place_signer),
            user_to_LP: user_LP_table,
        };
        move_to(
            &market_place_signer,
            pmp_reg
        );
        let participants_arg = vector::empty<address>(); 
        vector::push_back<address>(&mut participants_arg, signer::address_of(owner)); //add the owner to the participants list
        let market_cont_1 = MarketContainer{
            owner: signer::address_of(owner),
            title: title_arg,
            markets: pools,
            pre_participant: pre_participant_arg, // list of users whom the invitation will be received
            participants: participants_arg,
            options: names, // name of each shares. (e.g. getA*, A, B, C)
            symbols: symbols,
            market_validating: false,
            market_end: false,
        };
        move_to(
            &market_place_signer,
            market_cont_1
        );
        event::emit(
            MarketCreation{
                market_addr: signer::address_of(&market_place_signer),
                owner: signer::address_of(owner),
        });
        let pos = 0;
        while (pos < vector::length(&pre_participant_arg)){
            new_send_invitation(&market_place_signer, &market_cont_1, *vector::borrow<address>(&pre_participant_arg, pos), registry_addr, signer::address_of(owner));
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
    }


    fun create_market_place(owner: &signer, title_arg: String, pre_participant_arg: vector<address>, symbols: vector<String>, names: vector<String>, registry_addr: address): address acquires InvitationObject, InvitationRegistry{
        assert!(vector::length<address>(&pre_participant_arg) > 0, 0); //check if the User is not sending the invitation to anyone
        assert!(vector::length<String>(&symbols) > 0, 0);
        let (market_place_signer, _signer_cap) = account::create_resource_account(owner, *string::bytes(&title_arg)); //create a resource account for the invitation to be stored
        // assert!(exists<InvitationRegistry>(registry_addr), 404);
        let pools = vector::empty<address>(); //create an empty vector of PredictionMarketPool
        let host_lp = PoILiquidityPool::create_ticket_and_buy(owner, title_arg, names, symbols);
        vector::push_back(&mut pools, host_lp);

        // changes
        // let lp_market = borrow_global_mut<LPMarketTable>
        // table::add(&mut lp_)

        let participants_arg = vector::empty<address>(); 
        vector::push_back<address>(&mut participants_arg, signer::address_of(owner)); //add the owner to the participants list
        let market_cont_1 = MarketContainer{
            owner: signer::address_of(owner),
            title: title_arg,
            markets: pools,
            pre_participant: pre_participant_arg, // list of users whom the invitation will be received
            participants: participants_arg,
            options: names, // name of each shares. (e.g. getA*, A, B, C)
            symbols: symbols,
            market_validating: false,
            market_end: false,
        };
        move_to(
            &market_place_signer,
            market_cont_1
        );
        let pos = 0;
        while (pos < vector::length(&pre_participant_arg)){
            let market_cont_2 = MarketContainer{
                owner: signer::address_of(owner),
                title: title_arg,
                markets: pools,
                pre_participant: pre_participant_arg, // list of users whom the invitation will be received
                participants: participants_arg,
                options: names, // name of each shares. (e.g. A*, A, B, C)
                symbols: symbols,
                market_validating: false,
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
        let title_vec = *string::bytes(&market.title);
        let val_par_vec = bcs::to_bytes(&participant);
        let result = vector::empty<u8>();
        vector::append(&mut result, title_vec);
        vector::append(&mut result, val_par_vec);
        let (invitation_signer, _signer_cap) = account::create_resource_account(owner, result); //create a resource account for the invitation to be stored
        move_to<InvitationObject>(
            &invitation_signer,
            InvitationObject{
                sender: sender,
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

    // will pass the index of the index stored
    public entry fun new_respond_invitation(sender: &signer, registry_addr: address, is_participant: bool, is_listed: bool, res_idx: u64) acquires MarketContainer, InvitationRegistry, UserDataRegistry, PMPRegistry{
        let invitation_registry = borrow_global_mut<InvitationRegistry>(registry_addr);
        //assert!(table::contains(&invitation_registry.invitations, signer::address_of(sender)) == false, 1);
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
            let registry = borrow_global_mut<UserDataRegistry>(registry_addr);
            if (table::contains(&registry.markets_available, signer::address_of(sender))){ // if the participant already has received an invitation before
                let inv_vec = table::borrow_mut(&mut registry.markets_available, signer::address_of(sender));
                vector::push_back<address>(inv_vec, respond_invitation.market_address); //add the invitation to the list of the invitation
            }else{
                let inv_vec = vector::singleton<address>(respond_invitation.market_address);
                table::add(&mut registry.markets_available, signer::address_of(sender), inv_vec); //add the new mapping between the participant and the invitation
            };
            if(is_listed){
                let market_container = borrow_global_mut<MarketContainer>(respond_invitation.market_address);
                let market = market_container.markets;
                let title = market_container.title;
                let names = market_container.options;
                let symbols = market_container.symbols;
                let user_lp = PoILiquidityPool::create_ticket_and_buy(sender, title, names, symbols);
                let user_LP_table = borrow_global_mut<PMPRegistry>(respond_invitation.market_address);
                //assert!(table::contains(&user_LP_table.user_to_LP, signer::address_of(sender)) == false, 1);
                table::add(&mut user_LP_table.user_to_LP, signer::address_of(sender), user_lp);
            };
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

    #[view]
    public fun view_invitation(sender: address, reg_addr: address): vector<address> acquires InvitationRegistry{
        let inv_data = borrow_global<InvitationRegistry>(reg_addr);
        let inv_obj_vec = table::borrow(&inv_data.invitations, sender);
        let inv_vec = vector::empty<address>();
        let pos = 0;
        while (pos < vector::length<InvitationObject>(inv_obj_vec)){
            let data = vector::borrow<InvitationObject>(inv_obj_vec, pos);
            vector::push_back<address>(&mut inv_vec, data.market_address);
            pos = pos + 1;
        };
        inv_vec
    }

    #[view]
    public fun view_participant(market_addr: address): vector<address> acquires MarketContainer{
        let market_container = borrow_global<MarketContainer>(market_addr);
        market_container.participants
    }

    #[view]
    public fun view_owner(market_addr: address): address acquires MarketContainer{
        let market_container = borrow_global<MarketContainer>(market_addr);
        market_container.owner
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

    #[view]
    public fun view_markets(viewer: address, registry_addr: address): vector<address> acquires UserDataRegistry{
        let user_data = borrow_global_mut<UserDataRegistry>(registry_addr);
        let user_vec = table::borrow(&user_data.markets_available, viewer);
        *user_vec
    }
////////Market Validation start////////////


    // Initializing the invitation registry and only admin can call as all the invitations will be stored in the registry
    // fun initialise_validation_reg_mod(admin: &signer) {
    //     let admin_addr = signer::address_of(admin); 
    //     // transfer the ownership of Registry to the admin and let the object to be stored in the admin's account

    // }

    public entry fun finish_market(owner: &signer, market_addr: address)acquires MarketContainer{
        let market = borrow_global_mut<MarketContainer>(market_addr);
        assert!(market.owner == signer::address_of(owner), 0);
        market.market_validating = true
    }

    // the owner of each LP will execute the SC to validate their result
    public entry fun create_validation(owner: &signer, result_idx: u64, poc: String, registry_addr: address, market_addr: address) acquires ValidationObject, MarketContainer, ValidationAttachment, PMPRegistry, ValidationRegistry{
    //public entry fun create_validation(owner: &signer, result_idx: u64, poc: String, registry_addr: address, market_addr: address) acquires MarketContainer, PMPRegistry{
        // assert!(market_validating)
        // should restrict people from validating the market
        // If the market ends the validation stage
        let market_place = borrow_global<MarketContainer>(market_addr);//getter
        let pmp_reg = borrow_global<PMPRegistry>(market_addr);
        let validation_flag = market_place.market_validating;
        assert!(validation_flag, 1);
        assert!(vector::contains<address>(&market_place.participants, &signer::address_of(owner)), 0);
        if(table::contains(&pmp_reg.user_to_LP, signer::address_of(owner)) == false){
            abort 2
        };
        // assert!(vector::length<address>(&participant_arg) > 0, 0); //check if the User is not sending the invitation to anyone
        // assert!(vector::length<String>(&symbols) > 0, 0);
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
        let is_valid_vec = vector::empty<bool>();
        let reason_vec = vector::empty<String>();
        let user_LP_reg = borrow_global<PMPRegistry>(market_addr);
        let lp_address = table::borrow(&user_LP_reg.user_to_LP, signer::address_of(owner));
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
        let proof = ValidationProof{
            photo: poc,
        };
        move_to(
            &validation_signer,
            proof
        );
        let validation_Object = ValidationObject {
            sender: signer::address_of(owner), 
            market_address: market_addr,
            lp_address: *lp_address,
            created_at: 0,
            participant: pre_validators, //receiver of the invitation
            seen: false, //check if the invitation has been seen
            is_valid: is_valid_vec, //check if the participant has accepted the invitation
            reason: reason_vec, //In worst case scenario, I'll use the reason attributes to explain why the user is putting invalid answer
        };
        let validation_info_1 = borrow_global_mut<ValidationAttachment>(market_addr);
        // errorrrrrr
        while (pos < vector::length(&pre_validators)){
            new_send_validation(&validation_signer, validation_Object, *vector::borrow<address>(&pre_validators, pos), registry_addr, signer::address_of(owner), market_addr, *lp_address, title_vec);  
            validation_Object = ValidationObject {
                sender: signer::address_of(owner), 
                market_address: market_addr,
                lp_address: *lp_address,
                created_at: 0,
                participant: pre_validators, //receiver of the invitation
                seen: false, //check if the invitation has been seen
                is_valid: is_valid_vec, //check if the participant has accepted the invitation
                reason: reason_vec, //In worst case scenario, I'll use the reason attributes to explain why the user is putting invalid answer
            };
            pos = pos + 1;
        };
    }
    fun new_send_validation(validation_signer: &signer, validation_Object: ValidationObject, participant: address, registry_addr: address, sender: address, market_address: address, lp_address: address, title_vec: vector<u8>) acquires ValidationObject, MarketContainer, ValidationRegistry{
        let val_par_vec = bcs::to_bytes(&participant);
        let result = vector::empty<u8>();
        vector::append(&mut result, title_vec);
        vector::append(&mut result, val_par_vec);
        let (validation_per_person_signer, _signer_cap) = account::create_resource_account(validation_signer, result); //change should be made(the resource account address will be just identical as the )
        let market_place = borrow_global<MarketContainer>(market_address);
        assert!(vector::contains<address>(&market_place.markets, &lp_address), 0);
        // let title_vec = *string::bytes(&market_place.title);
        // let par_vec = bcs::to_bytes(&participant);
        // let val_str_vec = b"validation";
        // let result = vector::empty<u8>();
        // vector::append(&mut result, title_vec);
        // vector::append(&mut result, par_vec);
        // vector::append(&mut result, val_str_vec);
        // let (validation_signer, _signer_cap) = account::create_resource_account(owner, result); //create a resource account for the invitation to be stored
        move_to<ValidationObject>(
            &validation_per_person_signer,
            validation_Object
        );
        let validation_obj = move_from<ValidationObject>(signer::address_of(&validation_per_person_signer)); //delete the ownership of the invitation from the owner temporarily
        let registry = borrow_global_mut<ValidationRegistry>(registry_addr);
        if (table::contains(&registry.validations, participant)){ // if the participant already has received an invitation before
            let validation_vec = table::borrow_mut(&mut registry.validations, participant);
            vector::push_back<ValidationObject>(validation_vec, validation_obj); //add the invitation to the list of the invitation
        }else{
            let validation_vec = vector::singleton<ValidationObject>(validation_obj);
            table::add(&mut registry.validations, participant, validation_vec); //add the new mapping between the participant and the invitation
        };
        move_to(&validation_per_person_signer, validation_obj); //return the ownership of the invitation to the owner(resource account)
    }


    public entry fun new_respond_validation(sender: &signer, registry_addr: address, is_valid: bool, reason: String, res_idx: u64) acquires ValidationRegistry{
        let validation_registry = borrow_global_mut<ValidationRegistry>(registry_addr);
        assert!(table::contains(&validation_registry.validations, signer::address_of(sender)), 1);
        let validation_vector = table::borrow_mut(&mut validation_registry.validations, signer::address_of(sender));
        // Ensure there is at least one validation request.
        assert!(vector::length<ValidationObject>(validation_vector) > 0, 2);
        // Obtain a mutable reference to the first validation.
        let respond_validation = vector::borrow_mut<ValidationObject>(validation_vector, res_idx);
        // Check that the invitation belongs to the sender.
        assert!(vector::contains(&respond_validation.participant, &signer::address_of(sender)), 0);
        if (vector::length<bool>(&respond_validation.is_valid) == vector::length<address>(&respond_validation.participant) - 1){
            respond_validation.seen = true;
        };
        vector::push_back<bool>(&mut respond_validation.is_valid, is_valid);
        vector::push_back<String>(&mut respond_validation.reason, reason);
        // enter_validation_response(sender, respond_validation.market_address);
        let validation_registry_2 = borrow_global_mut<ValidationRegistry>(registry_addr);
        assert!(table::contains(&validation_registry_2.validations, signer::address_of(sender)), 1);

        // the code is complex due to the lifetime of each variable
        let validation_vec = table::borrow_mut(&mut validation_registry_2.validations, signer::address_of(sender));
        let respond_validation_2 = vector::borrow<ValidationObject>(validation_vec, 0);
        let validation_vec2 = table::borrow(&validation_registry_2.validations, signer::address_of(sender));
        let respond_validation_3 = vector::borrow<ValidationObject>(validation_vec2, 0);
        let validation_registry_3 = borrow_global<ValidationRegistry>(registry_addr);
        let validation_vec3 = table::borrow(&validation_registry_3.validations, signer::address_of(sender));
        
        // take an index of where the validation is stored in the vector
        let (existence, index) = vector::index_of<ValidationObject>(validation_vec3, respond_validation_3);

        let validation_registry_4 = borrow_global_mut<ValidationRegistry>(registry_addr);
        let validation_vec_4 = table::borrow_mut(&mut validation_registry_4.validations, signer::address_of(sender));
        // as soon as the response is sent, the invitation should be removed from the registry
        if (existence){
            vector::remove<ValidationObject>(validation_vec_4, index);
        }
    }

    // fun enter_validation_response(sender: &signer, market_container_addr: address) acquires ValidationAttachment{
    //     // the function will audit the participants array and pre_participants array
    //     let validation_attachment = borrow_global_mut<ValidationAttachment>(market_container_addr);
    //     let (existence, index) = vector::index_of(&validation_attachment.pre_validators, &signer::address_of(sender));
    //     assert!(existence, 0);
    //     if (existence){
    //         vector::remove<address>(&mut validation_attachment.pre_validators, index);
    //         vector::push_back<address>(&mut validation_attachment.validators, signer::address_of(sender));
    //     };
    // }

    public entry fun distribute_reward_or_stay_same(owner: &signer, market_address: address, lp_address: address, registry_address: address, validation_obj_address: address) acquires ValidationObject, PMPRegistry{
        let validate_lp = borrow_global<PMPRegistry>(market_address);
        // assert!(lp_address = table::borrow<address>(&validate_lp.user_to_LP, &signer::address_of(signer)), 0);
        let validation_obj = borrow_global<ValidationObject>(validation_obj_address);
        assert!(validation_obj.seen, 2);
        let turns = vector::length<address>(&validation_obj.participant);
        let count = 0;
        let penalty = 0;
        while (count < turns){
            let response = vector::borrow(&validation_obj.is_valid, count);
            if (!*response) {
                penalty = penalty + 1;
            };
            count = count + 1;
        };
        if (penalty > 0){
            // createValidation
        }else{
          
            // distribute reward
        };
    }
////////Market Validation end ////////////

////////Market Opening Test ////////////
    #[test(account0 = @bocchi, account1 = @kita, account2 = @nijika, account3 = @ryo)]
    fun check_mailbox_5(account0: &signer, account1: &signer, account2: &signer, account3: &signer) acquires InvitationObject, InvitationRegistry, MarketContainer, UserDataRegistry{
        init_module(account0);
        let participants = vector::empty<address>();
        vector::push_back<address>(&mut participants, @nijika);
        vector::push_back<address>(&mut participants, @ryo);
        let shares = vector::empty<String>();
        vector::push_back<String>(&mut shares, utf8(b"A*"));
        vector::push_back<String>(&mut shares, utf8(b"A"));
        let options = vector::empty<String>();
        vector::push_back<String>(&mut shares, utf8(b"getA*"));
        vector::push_back<String>(&mut shares, utf8(b"getA"));
        print(&utf8(b"hello_from_check_mailbox2"));
        let kita_virtual = create_market_place(account1, utf8(b"Test"), participants, shares, options, @bocchi);
        assert!(vector::length<address>(&borrow_global<MarketContainer>(kita_virtual).participants) == 1, 0);
        assert!(vector::length<address>(&borrow_global<MarketContainer>(kita_virtual).pre_participant) == 2, 0);
        // when user sent the invitation the length should be incremented by 1
        assert!(table::contains(&borrow_global<InvitationRegistry>(@bocchi).invitations, @nijika), 0);
        let inv_vec = table::borrow(&borrow_global<InvitationRegistry>(@bocchi).invitations, @nijika);
        assert!(vector::length<InvitationObject>(inv_vec) == 1, 0);
        new_respond_invitation(account2, @bocchi, true, true, 0);
        assert!(vector::length<address>(&borrow_global<MarketContainer>(kita_virtual).participants) == 2, 0);
        assert!(vector::length<address>(&borrow_global<MarketContainer>(kita_virtual).pre_participant) == 1, 0);
        let inv_vec_2 = table::borrow(&borrow_global<InvitationRegistry>(@bocchi).invitations, @nijika);
        assert!(vector::length<InvitationObject>(inv_vec_2) == 0, 0);
    }
    
////////Market Opening Test end ////////////

////////Market Validation Test ////////////
    // #[test(account0 = @bocchi, account1 = @kita, account2 = @nijika, account3 = @ryo)]
    // fun test_send_validation(account0: &signer, account1: &signer, account2: &signer, account3: &signer) acquires InvitationObject, InvitationRegistry, ValidationObject, ValidationRegistry, MarketContainer, ValidationAttachment, UserDataRegistry{
    //     init_module(account0);
    //     initialise_validation_reg_mod(account0);
    //     let participants = vector::empty<address>();
    //     vector::push_back<address>(&mut participants, @nijika);
    //     vector::push_back<address>(&mut participants, @ryo);
    //     let shares = vector::empty<String>();
    //     vector::push_back<String>(&mut shares, utf8(b"A*"));
    //     vector::push_back<String>(&mut shares, utf8(b"A"));
    //     let options = vector::empty<String>();
    //     vector::push_back<String>(&mut shares, utf8(b"getA*"));
    //     vector::push_back<String>(&mut shares, utf8(b"getA"));
    //     print(&utf8(b"hello_from_check_mailbox2"));
    //     let kita_virtual = create_market_place(account1, utf8(b"Test"), participants, shares, options, @bocchi);
    //     new_respond_invitation(account2, @bocchi, true, true, 0);
    //     new_respond_invitation(account3, @bocchi, true, true, 0);
    //     assert!(vector::length<address>(&borrow_global<MarketContainer>(kita_virtual).participants) == 3, 0);
    //     new_validate_market_place(account1, @bocchi, kita_virtual);
    //     assert!(vector::length<address>(&borrow_global<ValidationAttachment>(kita_virtual).pre_validators) == 2, 0);
    // }

    // #[test(account0 = @bocchi, account1 = @kita, account2 = @nijika, account3 = @ryo)]
    // #[expected_failure(abort_code = 0)]
    // fun test_send_validation_2(account0: &signer, account1: &signer, account2: &signer, account3: &signer) acquires InvitationObject, InvitationRegistry, ValidationObject, ValidationRegistry, MarketContainer, ValidationAttachment, UserDataRegistry{
    //     init_module(account0);
    //     initialise_validation_reg_mod(account0);
    //     let participants = vector::empty<address>();
    //     vector::push_back<address>(&mut participants, @nijika);
    //     vector::push_back<address>(&mut participants, @ryo);
    //     let shares = vector::empty<String>();
    //     vector::push_back<String>(&mut shares, utf8(b"A*"));
    //     vector::push_back<String>(&mut shares, utf8(b"A"));
    //     print(&utf8(b"hello_from_check_mailbox2"));
    //     let kita_virtual = create_market_place(account1, utf8(b"Test"), participants, shares,  @bocchi);
    //     new_respond_invitation(account2, @bocchi, true, true, 0);
    //     new_respond_invitation(account3, @bocchi, true, true, 0);
    //     assert!(vector::length<address>(&borrow_global<MarketContainer>(kita_virtual).participants) == 3, 0);
    //     new_validate_market_place(account0, @bocchi, kita_virtual);
    // }

}