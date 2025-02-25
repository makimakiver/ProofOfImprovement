module movement::PoILiquidityPool{
    use std::debug::print;
    use std::signer;
    use std::string::{Self, utf8, String};
    use std::option;
    use std::vector;
    use std::bcs;
    use aptos_framework::event;
    use aptos_framework::account::{Self, SignerCapability};
    use aptos_framework::fungible_asset::{Self, Metadata, MintRef, TransferRef, BurnRef};
    use aptos_framework::object::{Self, Object};
    use aptos_framework::coin::{Self};
    use aptos_framework::aptos_coin::{Self, AptosCoin};
    use aptos_framework::primary_fungible_store;

    const DECIMAL: u8 = 8;
    const FEE: u64 = 10_000_000;
    const MAX_SUPPLY: u64 = 100_000_000_000_000_000;
    const MOVE_AMOUNT: u64 = 100_000_000;
    const INITIAL_TOKEN_PER_APT: u64 = 5_000_000_000_000_000;
    const TOKEN_AMOUNT: u64 = 1_000;
    const APT_MULTIPLIER: u64 = 100_000_000;
    const E: u64 = 271_828;

    // Error codes
    const INSUFFICIENT_LIQUIDITY: u64 = 1;
    const INVALID_AMOUNT: u64 = 2;
    const ERR_NOT_OWNER: u64 = 3;
    const ERR_ZERO_AMOUNT: u64 = 4;
    const ERR_MAX_SUPPLY_EXCEEDED: u64 = 5;

    // create a pool for the prediction market
    struct PredictionMarketPool has key, store, drop {
        title: String,
        tokens: vector<u64>, //total supply of yes ticket
        tokens_metadata: vector<Object<Metadata>>, //metadata of yes ticket 
        owner: address, //owner of the pool
        signer_cap: SignerCapability,
        move_reserve: u64, //reserve of move
    }

    struct MarketCreationReceipt has key {
        fees: u64, //fees for creating the market
        admin: address, //admin of the market
    }

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct PredictionMarketControl has key {
        admin_address: address, //admin of the market
        mint_ref: MintRef, //mint reference for the market
        burn_ref: BurnRef, //burn reference for the market
        transfer_ref: TransferRef, //transfer reference for the market
    }
    // publish receipt when initializing the market
 
    fun init_module(owner: &signer){
        let admin = signer::address_of(owner);
        if(!exists<MarketCreationReceipt>(admin)){
            print(&utf8(b"the market creation receipt does not exist."));
            print(&utf8(b"thus executed"));
            move_to(
                owner,
                MarketCreationReceipt{
                    fees: FEE,
                    admin: admin,
                }
            );
        }
        else{
            print(&utf8(b"not executed"));
        }
    }

    // create a tickets for the prediction market
    public fun create_ticket_and_buy(sender: &signer, title_arg: String, names: vector<String>, symbols: vector<String>) acquires MarketCreationReceipt, PredictionMarketControl{
        // symbols and names can be immutable reference to the variable(can be "&vector<String>")
        let receipt = borrow_global<MarketCreationReceipt>(@movement);
        let admin_addr = receipt.admin;
        let sender_addr = signer::address_of(sender);
        // charge fees
        let fees_coin = coin::withdraw<AptosCoin>(sender, receipt.fees);
        coin::deposit<AptosCoin>(admin_addr, fees_coin);
        // create a new set of yes tickets
        assert!(vector::length(&names) > 1, 0);
        assert!(vector::length(&names) == vector::length(&symbols), 0);
        let (pool_signer, signer_cap) = account::create_resource_account(sender, bcs::to_bytes(&title_arg));
        let num_of_token = vector::length<String>(&names);
        let pos = 0;
        let yes_constructor_ref = object::create_named_object(
            &pool_signer,
            *string::bytes(vector::borrow(&names, 0)) //changed
        );
        let yes_object_signer = object::generate_signer(&yes_constructor_ref);
        // create a new pool for the prediction market
        primary_fungible_store::create_primary_store_enabled_fungible_asset(
            &yes_constructor_ref,
            option::some((MAX_SUPPLY as u128)),
            *vector::borrow(&names, 0), //changed
            *vector::borrow(&symbols, 0), //changed
            DECIMAL, //changed
            utf8(b" "), //changed
            utf8(b" ") //changed
        );
        let yes_ticket_object = object::object_from_constructor_ref<Metadata>(&yes_constructor_ref);
        let token_metadata_vector: vector<Object<Metadata>> = vector::singleton<Object<Metadata>>(yes_ticket_object);
        // Setup token controller
        move_to(&yes_object_signer, PredictionMarketControl {
            admin_address: sender_addr,
            mint_ref: fungible_asset::generate_mint_ref(&yes_constructor_ref),
            burn_ref: fungible_asset::generate_burn_ref(&yes_constructor_ref),
            transfer_ref: fungible_asset::generate_transfer_ref(&yes_constructor_ref),
        });

        let user_token_amount = (MOVE_AMOUNT as u128)*(INITIAL_TOKEN_PER_APT as u128)/(APT_MULTIPLIER as u128);
        assert!((user_token_amount * 2) <= (MAX_SUPPLY as u128), 0);
        let token_amount = user_token_amount / (num_of_token as u128);
        let token_amount_vector = vector::singleton<u64>((token_amount as u64));
        // assert!((user_token_amount * 2) <= (MAX_SUPPLY as u128), 0);
        // minting both tokens to users
        mint_tokens(sender, *vector::borrow(&token_metadata_vector, 0), (*vector::borrow(&token_amount_vector, 0) as u64));
        pos = pos + 1;
        while (pos < vector::length<String>(&names)){
            yes_constructor_ref = object::create_named_object(
                &pool_signer,
                *string::bytes(vector::borrow(&names, pos)) //changed
            );
            yes_object_signer = object::generate_signer(&yes_constructor_ref);
            // create a new pool for the prediction market
            primary_fungible_store::create_primary_store_enabled_fungible_asset(
                &yes_constructor_ref,
                option::some((MAX_SUPPLY as u128)),
                *vector::borrow(&names, pos), //changed
                *vector::borrow(&symbols, pos), //changed
                DECIMAL, //changed
                utf8(b" "), //changed
                utf8(b" ") //changed
            );
            yes_ticket_object = object::object_from_constructor_ref<Metadata>(&yes_constructor_ref);
            vector::push_back(&mut token_metadata_vector, (yes_ticket_object));
            // Setup token controller
            move_to(&yes_object_signer, PredictionMarketControl {
                admin_address: sender_addr,
                mint_ref: fungible_asset::generate_mint_ref(&yes_constructor_ref),
                burn_ref: fungible_asset::generate_burn_ref(&yes_constructor_ref),
                transfer_ref: fungible_asset::generate_transfer_ref(&yes_constructor_ref),
            });

            user_token_amount = (MOVE_AMOUNT as u128)*(INITIAL_TOKEN_PER_APT as u128)/(APT_MULTIPLIER as u128);
            assert!((user_token_amount * 2) <= (MAX_SUPPLY as u128), 0);
            token_amount = user_token_amount / (num_of_token as u128);
            vector::push_back(&mut token_amount_vector, ((token_amount as u64)));
            // assert!((user_token_amount * 2) <= (MAX_SUPPLY as u128), 0);
            // minting both tokens to users
            mint_tokens(sender, *vector::borrow(&token_metadata_vector, pos), 100_000_000);
            pos = pos + 1;

        };
        // initialize the liquidity pool
        initialize_liquidity_pool(sender, title_arg, token_metadata_vector, token_amount_vector, MOVE_AMOUNT, pool_signer, signer_cap)
        
        // Object has been cloned and the error occured
    }

    fun mint_tokens(sender: &signer, token: Object<Metadata>, amount: u64) acquires PredictionMarketControl{
        let token_addr = object::object_address(&token);
        let control = borrow_global<PredictionMarketControl>(token_addr);
        let fa = fungible_asset::mint(&control.mint_ref, amount);
        primary_fungible_store::deposit(signer::address_of(sender), fa);
    }

    fun initialize_liquidity_pool(sender: &signer, title: String, token_vector: vector<Object<Metadata>>, token_amount_vector: vector<u64>, move_amount: u64, pool_signer: signer, signer_cap: SignerCapability) acquires PredictionMarketControl{
        // Register the APT coin store for pool
        let pos = 0;
        let token = *vector::borrow<Object<Metadata>>(&token_vector, pos);
        let token_amount = *vector::borrow<u64>(&token_amount_vector, pos);
        if(!coin::is_account_registered<AptosCoin>(signer::address_of(&pool_signer))){
            coin::register<AptosCoin>(&pool_signer);
        };
        mint_tokens(&pool_signer, token, token_amount);
        // Transfer aptos to the pool
        let aptos_coin = coin::withdraw<AptosCoin>(sender, move_amount);
        coin::deposit<AptosCoin>(signer::address_of(&pool_signer), aptos_coin);
        pos = pos + 1;
        let length = vector::length<Object<Metadata>>(&token_vector);
        while (pos < length){
            token = *vector::borrow<Object<Metadata>>(&token_vector, pos);
            token_amount = *vector::borrow<u64>(&token_amount_vector, pos);
            mint_tokens(&pool_signer, token, token_amount);
            // Transfer aptos to the pool
            pos = pos + 1;
            length = vector::length<Object<Metadata>>(&token_vector);
        };
        // Initialize the pool
        move_to(&pool_signer,
            PredictionMarketPool{
                tokens: token_amount_vector,
                tokens_metadata: token_vector,
                owner: signer::address_of(sender),
                signer_cap: signer_cap,
                move_reserve: move_amount,
                title: title,
            }
        );
        // return PredictionMarketPool {
        //     tokens: token_amount_vector,
        //     tokens_metadata: token_vector,
        //     owner: signer::address_of(sender),
        //     signer_cap: signer_cap,
        //     move_reserve: move_amount,
        //     title: title,
        // }
        
    }
    public entry fun buy_ticket(
        sender: &signer,
        pool_addr: address,
        token_idx: u64,
        ticket_amount: u64,
        market_addr: address,
    )acquires PredictionMarketPool{
        assert!(ticket_amount > 0, ERR_ZERO_AMOUNT);
        let move_amount = total_cost_calculator_in_move_when_swapping_move_to_token_and_change_reserve(ticket_amount, token_idx, market_addr);
        swap_move_to_token(sender, market_addr, token_idx, move_amount, ticket_amount);
    }
    // Swap MOVE for tokens
    fun swap_move_to_token(
        sender: &signer,
        pool_addr: address,
        token_idx: u64,
        move_amount: u64,
        token_out: u64,
    ) acquires PredictionMarketPool {
        assert!(move_amount > 0, ERR_ZERO_AMOUNT);
        let lp = borrow_global_mut<PredictionMarketPool>(pool_addr);
        let token_reserve = vector::borrow_mut(&mut lp.tokens, token_idx);
        let token_address = vector::borrow(&lp.tokens_metadata, token_idx);

        // Calculate output tokens
        // let token_out = get_output_amount(
        //     move_amount,
        //     lp.move_reserve,
        //     *token_reserve
        // );

        assert!(token_out > 0, INSUFFICIENT_LIQUIDITY);

        // Transfer MOVE to pool
        let move_coins = coin::withdraw<AptosCoin>(sender, move_amount);
        coin::deposit(pool_addr, move_coins);

        let pool_signer = account::create_signer_with_capability(&lp.signer_cap);

        // Transfer tokens to user
        primary_fungible_store::transfer(
            &pool_signer,
            *token_address,
            signer::address_of(sender),
            token_out*100_000_000,
        );
        // Update reserves

        lp.move_reserve = lp.move_reserve + move_amount;
        // *token_reserve = *token_reserve - token_out;
    }

    // Swap tokens for MOVE
    public entry fun swap_token_to_move(
        sender: &signer,
        pool_addr: address,
        token_idx: u64,
        token_amount: u64
    ) acquires PredictionMarketPool {
        assert!(token_amount > 0, ERR_ZERO_AMOUNT);

        let lp = borrow_global_mut<PredictionMarketPool>(pool_addr);
        let token_reserve = vector::borrow_mut(&mut lp.tokens, token_idx);
        let token_address = vector::borrow(&lp.tokens_metadata, token_idx);
        // // Calculate MOVE output
        // let move_out = get_output_amount(
        //     token_amount,
        //     *token_reserve,
        //     lp.move_reserve
        // );

        let cost_of_ticket = 100_000_000 / vector::length<u64>(&lp.tokens);
        let move_out = cost_of_ticket * token_amount;
        let token_reserve = vector::borrow_mut(&mut lp.tokens, token_idx);
        
        assert!(move_out > 0, INSUFFICIENT_LIQUIDITY);

        // Transfer tokens to pool
        primary_fungible_store::transfer(
            sender,
            *token_address,
            pool_addr,
            token_amount*100_000_000
        );

        let pool_signer = account::create_signer_with_capability(&lp.signer_cap);

        // Transfer MOVE to user
        coin::transfer<AptosCoin>(&pool_signer, signer::address_of(sender), move_out);

        // Update reserves

        *token_reserve = *token_reserve + token_amount;
        lp.move_reserve = lp.move_reserve - move_out;
    }
    // Calculate output amount based on AMM formula
    fun get_output_amount(
        input_amount: u64,
        input_reserve: u64,
        output_reserve: u64
    ): u64 {
        let input_amount_with_fee = (input_amount as u128) * 997; // 0.3% fee
        let numerator = input_amount_with_fee * (output_reserve as u128);
        let denominator = (input_reserve as u128) * 1000 + input_amount_with_fee;
        ((numerator / denominator) as u64)
    }

    fun total_cost_calculator_in_move_when_swapping_move_to_token_and_change_reserve(
        desired_output_amount: u64,
        token_idx: u64,
        market_addr: address,
    ): u64 acquires PredictionMarketPool{
        let lp = borrow_global_mut<PredictionMarketPool>(market_addr);
        let cost_of_ticket = 100_000_000 / vector::length<u64>(&lp.tokens);
        let total_cost = cost_of_ticket * desired_output_amount;
        let token_reserve = vector::borrow_mut(&mut lp.tokens, token_idx);
        *token_reserve = *token_reserve - desired_output_amount;
        return total_cost
    }

    #[view]
    fun total_cost_calculator_in_move_when_swapping_move_to_token(
        desired_output_amount: u64,
        market_addr: address,
    ): u64 acquires PredictionMarketPool {
        let lp = borrow_global_mut<PredictionMarketPool>(market_addr);
        let cost_of_ticket = 100_000_000 / vector::length<u64>(&lp.tokens);
        let total_cost = cost_of_ticket * desired_output_amount;
        return total_cost
    }

    #[test (account=@movement)]
    fun test_initialisation(account: &signer) acquires MarketCreationReceipt, PredictionMarketControl{
        init_module(account);
        let title = utf8(b"Test1");
        let title_2 = utf8(b"Test2");
        let grades_symbol = vector::empty<String>();
        vector::push_back(&mut grades_symbol, utf8(b"A*"));
        vector::push_back(&mut grades_symbol, utf8(b"A"));
        vector::push_back(&mut grades_symbol, utf8(b"B"));
        vector::push_back(&mut grades_symbol, utf8(b"C"));
        vector::push_back(&mut grades_symbol, utf8(b"D"));
        let grades = vector::empty<String>();
        vector::push_back(&mut grades, utf8(b"getting_A*"));
        vector::push_back(&mut grades, utf8(b"getting_A"));
        vector::push_back(&mut grades, utf8(b"getting_B"));
        vector::push_back(&mut grades, utf8(b"getting_C"));
        vector::push_back(&mut grades, utf8(b"getting_D"));
        create_ticket_and_buy(account, title, grades, grades_symbol);
        create_ticket_and_buy(account, title_2, grades, grades_symbol);
    }

}
//      [title].        "Hello world"
// [name of the ticket] ["getting_A*", "getting_A", "getting_B", "getting_C", "getting_D", "getting_E"]
//      [symbol]        ["A*", "A", "B", "C", "D", "E"]





//      [title].        "Hello world"
// [name of the ticket] ["getting_A*", "getting_A", "getting_B", "getting_C", "getting_D", "getting_E"]
//      [symbol]        ["A*", "A", "B", "C", "D", "E"]

