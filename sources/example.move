/// Module: my_first_package
module my_first_package::example;

use sui::transfer::public_transfer;

public struct Sword has key, store {
  id: UID,
  magic: u64,
  strength: u64
}

public struct Forge has key {
  id: UID,
  swords_created: u64
}

fun init(ctx: &mut TxContext) {
  let admin = Forge {
    id: object::new(ctx),
    swords_created: 0
  };
  transfer::transfer(admin, ctx.sender());
}

public fun magic(self: &Sword): u64 {
  self.magic
}

public fun strength(self: &Sword): u64 {
  self.strength
}

public fun swords_created(self: &Forge): u64 {
  self.swords_created
}

public fun sword_create(magic: u64, strength: u64, ctx: &mut TxContext): Sword {
  Sword {
    id: object::new(ctx),
    magic,
    strength
  }
}


#[test]
fun test_sword_create() {
  let mut ctx = tx_context::dummy();
  let sword = Sword {
    id: object::new(&mut ctx),
    magic: 42,
    strength: 7
  };
  assert!(sword.magic() == 42 && sword.strength() == 7, 1);
  let dummy_address = @0xCAFE;
  transfer::public_transfer(sword, dummy_address);
}



#[test]
fun test_sword_transactions() {
  use sui::test_scenario;
  let initial_owner = @0xCAFE;
  let final_owner = &0xFACE;

  let mut scenario = test_scenario::begin(initial_owner);
  {
    let sword = sword_create(42, 7, scenario.ctx());
    transfer::public_transfer(sword, initial_owner);
  };
  scenario.end();
}
