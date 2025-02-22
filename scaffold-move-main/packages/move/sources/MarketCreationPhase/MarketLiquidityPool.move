module movement::PoILiquidityPool{
    use std::debug::print;
    use std::signer;
    use std::string::{Self, utf8, String};
    use std::option;
    use std::vector;
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
    const INITIAL_TOKEN_PER_APT: u64 = 5_000_000_000_000;
    const APT_MULTIPLIER: u64 = 100_000_000;
    // create a pool for the prediction market
    struct PredictionMarketPool has key, store,drop {
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
        move_to(
            owner,
            MarketCreationReceipt{
                fees: FEE,
                admin: admin,
            }
        );
    }
    // create a tickets for the prediction market
    public entry fun create_ticket_and_buy(sender: &signer, names: vector<String>, symbols: vector<String>) acquires MarketCreationReceipt, PredictionMarketControl{
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
        let num_of_token = vector::length<String>(&names);
        let pos = 0;
        let yes_constructor_ref = object::create_named_object(
            sender,
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
                sender,
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
            mint_tokens(sender, *vector::borrow(&token_metadata_vector, pos), (*vector::borrow(&token_amount_vector, pos) as u64));
            pos = pos + 1;

        };
        // initialize the liquidity pool
        initialize_liquidity_pool(sender, token_metadata_vector, token_amount_vector, MOVE_AMOUNT);
        
        // Object has been cloned and the error occured
    }
    fun mint_tokens(sender: &signer, token: Object<Metadata>, amount: u64) acquires PredictionMarketControl{
        let token_addr = object::object_address(&token);
        let control = borrow_global<PredictionMarketControl>(token_addr);
        let fa = fungible_asset::mint(&control.mint_ref, amount);
        primary_fungible_store::deposit(signer::address_of(sender), fa);
    }
    fun initialize_liquidity_pool(sender: &signer, token_vector: vector<Object<Metadata>>, token_amount_vector: vector<u64>, move_amount: u64) acquires PredictionMarketControl{
        let (pool_signer, signer_cap) = account::create_resource_account(sender, b"Liquidity pool");
        // Register the APT coin store for pool
        let token = *vector::borrow<Object<Metadata>>(&token_vector, 0);
        let token_amount = *vector::borrow<u64>(&token_amount_vector, 0);
        if(!coin::is_account_registered<AptosCoin>(signer::address_of(&pool_signer))){
            coin::register<AptosCoin>(&pool_signer);
        };
        mint_tokens(&pool_signer, token, token_amount);
        // Transfer aptos to the pool
        let aptos_coin = coin::withdraw<AptosCoin>(sender, move_amount);
        coin::deposit<AptosCoin>(signer::address_of(&pool_signer), aptos_coin);
        // Initialize the pool
        move_to(&pool_signer,
            PredictionMarketPool{
                tokens: token_amount_vector,
                tokens_metadata: token_vector,
                owner: signer::address_of(sender),
                signer_cap: signer_cap,
                move_reserve: move_amount,
            }
        );
    }

}
