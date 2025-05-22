// Copyright (c), Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

module app::sentinel;

use enclave::enclave::{Self, Enclave};
use std::string::String;
use sui::coin::{Self, Coin};
use sui::sui::SUI;
use sui::balance::{Self, Balance};
use sui::table::{Self, Table};
use sui::event;

/// ====
/// Constants and errors
/// ====

const SENTINEL_INTENT: u8 = 1;


const EInvalidSignature: u64 = 1;
const EAgentNotFound: u64 = 2;
const EInsufficientBalance: u64 = 3;
const EInvalidAmount: u64 = 4;

/// ====
/// Structs
/// ====

/// Agent object - stores the agent's identity, prompt, and financial details
public struct Agent has key, store {
    id: UID,
    agent_id: String,
    prompt: String,
    creator: address,
    cost_per_message: u64,
    balance: Balance<SUI>,  // Funds available for rewards
}

/// The global registry that manages all agents
public struct AgentRegistry has key {
    id: UID,
    agents: Table<String, ID>, // Maps agent_id to Agent object ID
}

/// Module identifier for enclave operations
public struct SENTINEL has drop {}

/// Agent capability to control agent settings
public struct AgentCap has key, store {
    id: UID,
    agent_id: String,
}

/// ====
/// Verification Response Structs
/// ====

/// Response struct for registering an agent
public struct RegisterAgentResponse has copy, drop {
    agent_id: String,
    prompt: String,
    creator: address,
    cost_per_message: u64,
}

/// Response struct for consuming a prompt
public struct ConsumePromptResponse has copy, drop {
    agent_id: String,
    prompt: String,
    success: bool,
}

/// ====
/// Events
/// ====

public struct AgentRegistered has copy, drop {
    agent_id: String,
    prompt: String,
    creator: address,
    cost_per_message: u64,
    initial_balance: u64,
    agent_object_id: ID,
}

public struct PromptConsumed has copy, drop {
    agent_id: String,
    prompt: String,
    success: bool,
    amount: u64,
    sender: address,
}

public struct FeeTransferred has copy, drop {
    agent_id: String,
    creator: address,
    amount: u64,
}

public struct AgentFunded has copy, drop {
    agent_id: String,
    amount: u64,
}

/// ====
/// Functions
/// ====

fun init(otw: SENTINEL, ctx: &mut TxContext) {
    // Initialize enclave configuration
    let cap = enclave::new_cap(otw, ctx);
    cap.create_enclave_config(
        b"agent challenge enclave".to_string(),
        x"000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000", // pcr0
        x"000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000", // pcr1
        x"000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000", // pcr2
        ctx,
    );

    // Create and share agent registry
    let registry = AgentRegistry {
        id: object::new(ctx),
        agents: table::new(ctx),
    };
    
    // Transfer capability to sender
    transfer::public_transfer(cap, tx_context::sender(ctx));
    
    // Share registry
    transfer::share_object(registry);
}

/// Register a new agent with its prompt, cost per message, and initial funds
#[allow(lint(self_transfer))]
public fun register_agent<T>(
    agent_id: String,
    prompt: String,
    cost_per_message: u64,
    initial_funds: Coin<SUI>,
    sig: &vector<u8>,
    enclave: &Enclave<T>,
    registry: &mut AgentRegistry,
    ctx: &mut TxContext,
) {
    let creator = tx_context::sender(ctx);
    
    // Verify signature from the enclave
    let res = enclave.verify_signature(
        SENTINEL_INTENT,
        tx_context::epoch(ctx),
        RegisterAgentResponse { 
            agent_id, 
            prompt, 
            creator,
            cost_per_message
        },
        sig,
    );
    assert!(res, EInvalidSignature);
    
    // Get initial funds
    let initial_balance = coin::into_balance(initial_funds);
    let initial_amount = balance::value(&initial_balance);
    
    // Create new agent
    let agent = Agent {
        id: object::new(ctx),
        agent_id,
        prompt,
        creator,
        cost_per_message,
        balance: initial_balance,
    };
    
    let agent_object_id = object::id(&agent);
    
    // Add agent to registry
    table::add(&mut registry.agents, agent_id, agent_object_id);
    
    // Create and transfer agent capability to sender
    let cap = AgentCap {
        id: object::new(ctx),
        agent_id,
    };
    transfer::public_transfer(cap, creator);
    
    // Share agent object
    transfer::share_object(agent);
    
    // Emit event
    event::emit(AgentRegistered {
        agent_id,
        prompt,
        creator,
        cost_per_message,
        initial_balance: initial_amount,
        agent_object_id,
    });
}

/// Consume a prompt and handle rewards based on success
#[allow(lint(self_transfer))]
public fun consume_prompt<T>(
    agent_id: String,
    prompt: String,
    success: bool,
    payment: Coin<SUI>,
    reward_amount: u64,
    sig: &vector<u8>,
    enclave: &Enclave<T>,
    registry: &AgentRegistry,
    agent: &mut Agent,
    ctx: &mut TxContext,
) {
    // Verify signature from enclave
    let res = enclave.verify_signature(
        SENTINEL_INTENT,
        tx_context::epoch(ctx),
        ConsumePromptResponse { agent_id, prompt, success },
        sig,
    );
    assert!(res, EInvalidSignature);
    
    // Verify agent exists and matches
    assert!(table::contains(&registry.agents, agent_id), EAgentNotFound);
    assert!(agent.agent_id == agent_id, EAgentNotFound);
    
    // Verify payment covers cost per message
    let payment_amount = coin::value(&payment);
    assert!(payment_amount >= agent.cost_per_message, EInvalidAmount);
    
    // Process payment
    let mut payment_balance = coin::into_balance(payment);
    
    // Extract fee for agent creator
    let creator_fee = balance::split(&mut payment_balance, agent.cost_per_message);
    let creator_coin = coin::from_balance(creator_fee, ctx);
    
    // Send fee to agent creator
    transfer::public_transfer(creator_coin, agent.creator);
    
    // Add remaining payment (if any) to agent balance
    if (balance::value(&payment_balance) > 0) {
        balance::join(&mut agent.balance, payment_balance);
    } else {
        balance::destroy_zero(payment_balance);
    };
    
    // Emit fee transfer event
    event::emit(FeeTransferred {
        agent_id,
        creator: agent.creator,
        amount: agent.cost_per_message,
    });
    
    if (success) {
        // User succeeded in fooling the agent, pay them the reward
        assert!(balance::value(&agent.balance) >= reward_amount, EInsufficientBalance);
        
        // Send reward to user
        let reward = coin::from_balance(balance::split(&mut agent.balance, reward_amount), ctx);
        transfer::public_transfer(reward, tx_context::sender(ctx));
    };
    let amount = if (success) { reward_amount } else { 0 };
    
    // Emit event
    event::emit(PromptConsumed {
        agent_id,
        prompt,
        success,
        amount ,
        sender: tx_context::sender(ctx),
    });
}

/// Add funds to an agent's balance
public entry fun add_funds_to_agent(
    agent: &mut Agent,
    funds: Coin<SUI>,
    _cap: &AgentCap,
) {
    // Verify cap matches agent
    assert!(_cap.agent_id == agent.agent_id, EAgentNotFound);
    
    let amount = coin::value(&funds);
    let funds_balance = coin::into_balance(funds);
    
    // Add funds to agent balance
    balance::join(&mut agent.balance, funds_balance);
    
    // Emit event
    event::emit(AgentFunded {
        agent_id: agent.agent_id,
        amount,
    });
}

/// Update cost per message
public entry fun update_cost_per_message(
    agent: &mut Agent,
    new_cost: u64,
    _cap: &AgentCap,
) {
    // Verify cap matches agent
    assert!(_cap.agent_id == agent.agent_id, EAgentNotFound);
    
    // Update cost
    agent.cost_per_message = new_cost;
}

/// Get agent ID by agent_id string
public fun fetch_agent_by_id(
    agent_id: String,
    registry: &AgentRegistry,
): Option<ID> {
    if (table::contains(&registry.agents, agent_id)) {
        option::some(*table::borrow(&registry.agents, agent_id))
    } else {
        option::none()
    }
}

/// Get cost per message for an agent
public fun get_cost_per_message(agent: &Agent): u64 {
    agent.cost_per_message
}

/// Get agent balance
public fun get_agent_balance(agent: &Agent): u64 {
    balance::value(&agent.balance)
}

/// Get agent creator
public fun get_agent_creator(agent: &Agent): address {
    agent.creator
}

// #[test]
// fun test_agent_challenge_flow() {
//     use sui::test_scenario;
//     use sui::nitro_attestation;
//     use sui::test_utils::destroy;
//     use sui::clock;
//     use enclave::enclave::{register_enclave, create_enclave_config, update_pcrs, EnclaveConfig};

//     let creator = @0x1;
//     let user = @0x2;
    
//     let scenario = test_scenario::begin(creator);
    
//     // Initialize the clock for testing
//     let clock = clock::create_for_testing(test_scenario::ctx(&scenario));
//     clock.set_for_testing(1744684007462);

//     // Initialize our agent challenge system
//     let cap = enclave::new_cap(AGENT_CHALLENGE {}, test_scenario::ctx(&scenario));
//     cap.create_enclave_config(
//         b"agent challenge enclave".to_string(),
//         x"000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
//         x"000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
//         x"000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
//         test_scenario::ctx(&scenario),
//     );

//     test_scenario::next_tx(&scenario, creator);
    
//     let config = test_scenario::take_shared<EnclaveConfig<AGENT_CHALLENGE>>(&scenario);
    
//     // Update PCRs to match the enclave's measurements
//     config.update_pcrs(
//         &cap,
//         x"cbe1afb6ed0ff89f10295af0b802247ec5670da8f886e71a4226373b032c322f4e42c9c98288e7211682b258684505a2",
//         x"cbe1afb6ed0ff89f10295af0b802247ec5670da8f886e71a4226373b032c322f4e42c9c98288e7211682b258684505a2",
//         x"21b9efbc184807662e966d34f390821309eeac6802309798826296bf3e8bec7c10edb30948c90ba67310f7b964fc500a",
//     );
    
//     // Test implementation would continue here with registering agents and consuming prompts
    
//     test_scenario::return_shared(config);
//     clock.destroy_for_testing();
//     destroy(cap);
//     test_scenario::end(scenario);
// }
