module voting_system::proposal;

use std::string::String;
use sui::clock::Clock;
use sui::table::{Self, Table};
use sui::url::{Url, new_unsafe_from_bytes};
use voting_system::dashboard::AdminCap;

const EDuplicateVote: u64 = 0;
const EProposalDelisted: u64 = 1;
const EProposalExpired: u64 = 2;

public enum ProposalStatus has drop, store {
    Active,
    Deleted,
}

public struct Proposal has key {
    id: UID,
    title: String,
    description: String,
    voted_yes_count: u64,
    voted_no_count: u64,
    expiration: u64,
    creator: address,
    status: ProposalStatus,
    voters: Table<address, bool>,
}

public struct VoteProofNFT has key {
    id: UID,
    proposal_id: ID,
    name: String,
    description: String,
    url: Url,
}

public fun vote(self: &mut Proposal, vote_yes: bool, clock: &Clock, ctx: &mut TxContext) {
    assert!(self.expiration > clock.timestamp_ms(), EProposalExpired);
    assert!(self.is_active(), EProposalDelisted);
    assert!(!self.voters.contains(ctx.sender()), EDuplicateVote);

    if (vote_yes) {
        self.voted_yes_count = self.voted_yes_count + 1;
    } else {
        self.voted_no_count = self.voted_no_count + 1;
    };

    self.voters.add(ctx.sender(), vote_yes);
    issue_vote_proof(self, vote_yes, ctx);
}

public fun vote_proof_url(self: &VoteProofNFT): Url {
    self.url
}

public fun status(self: &Proposal): &ProposalStatus {
    &self.status
}

public fun title(self: &Proposal): String {
    self.title
}

public fun description(self: &Proposal): String {
    self.description
}

public fun voted_yes_count(self: &Proposal): u64 {
    self.voted_yes_count
}

public fun voted_no_count(self: &Proposal): u64 {
    self.voted_no_count
}

public fun expiration(self: &Proposal): u64 {
    self.expiration
}

public fun creator(self: &Proposal): address {
    self.creator
}

public fun voters(self: &Proposal): &Table<address, bool> {
    &self.voters
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
        status: ProposalStatus::Active,
        voters: table::new(ctx),
    };

    let id = proposal.id.to_inner();
    transfer::share_object(proposal);

    id
}

public fun change_status(self: &mut Proposal, _admin_cap: &AdminCap, status: ProposalStatus) {
    self.status = status;
}

fun issue_vote_proof(proposal: &Proposal, vote_yes: bool, ctx: &mut TxContext) {
    let mut name = b"NFT ".to_string();
    name.append(proposal.title);

    let mut description = b"Proof of ".to_string();
    let proposal_address = object::id_address(proposal).to_string();
    description.append(proposal_address);

    let vote_yes_image = new_unsafe_from_bytes(
        b"https://evanz1215.sirv.com/Images/jellyfish_yes.jpg",
    );

    let vote_no_image = new_unsafe_from_bytes(
        b"https://evanz1215.sirv.com/Images/jellyfish_no.jpg",
    );

    let url = if (vote_yes) { vote_yes_image } else { vote_no_image };

    let proof = VoteProofNFT {
        id: object::new(ctx),
        proposal_id: proposal.id.to_inner(),
        name,
        description,
        url,
    };

    transfer::transfer(proof, ctx.sender());
}

#[test_only]
public fun is_active(self: &Proposal): bool {
    let status = self.status();

    match (status) {
        ProposalStatus::Active => true,
        _ => false,
    }
}

#[test_only]
public fun set_active_status(self: &mut Proposal, _admin_cap: &AdminCap) {
    self.change_status(_admin_cap, ProposalStatus::Active);
}

#[test_only]
public fun set_deleted_status(self: &mut Proposal, _admin_cap: &AdminCap) {
    self.change_status(_admin_cap, ProposalStatus::Deleted);
}
