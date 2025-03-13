module voting_system::proposal;

use std::string::String;
use voting_system::dashboard::AdminCap;

public struct Proposal has key {
    id: UID,
    title: String,
    description: String,
    voted_yes_count: u64,
    voted_no_count: u64,
    expiration: u64,
    creator: address,
    voter_registry: vector<address>,
}

public fun create(
    _admin_cap: &AdminCap,
    title: String,
    description: String,
    expiration: u64,
    ctx: &mut TxContext,
): ID {
    let proposal = Proposal {
        id: object::new(ctx),
        title,
        description,
        voted_yes_count: 0,
        voted_no_count: 0,
        expiration,
        creator: ctx.sender(),
        voter_registry: vector[],
    };

    let id = proposal.id.to_inner();
    transfer::share_object(proposal);

    id
}

public fun title(proposal: &Proposal): String {
    proposal.title
}

public fun description(proposal: &Proposal): String {
    proposal.description
}

public fun voted_yes_count(proposal: &Proposal): u64 {
    proposal.voted_yes_count
}

public fun voted_no_count(proposal: &Proposal): u64 {
    proposal.voted_no_count
}

public fun expiration(proposal: &Proposal): u64 {
    proposal.expiration
}

public fun creator(proposal: &Proposal): address {
    proposal.creator
}

public fun voter_registry(proposal: &Proposal): vector<address> {
    proposal.voter_registry
}
