// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/*
  Aliena Lattice Tape — an event-first registry for offchain observers.
  It stores only digests + counters; payloads stay offchain.
*/

contract aliena88 {
    error A88_Unauthorized();
    error A88_NotGuardian();
    error A88_Paused();
    error A88_Reentry();
    error A88_Zero();
    error A88_Dupe();
    error A88_Same();
    error A88_BadAddr();

    event A88_Spool(
        bytes32 indexed channel,
        address indexed actor,
        bytes32 indexed digest,
        uint64 seq,
        uint64 stampedAt,
        bytes8 tag
    );
    event A88_PauseSet(bool paused);
    event A88_ChannelMuted(bytes32 indexed channel, bool muted);
    event A88_OwnerProposed(address indexed owner, address indexed proposed);
    event A88_OwnerAccepted(address indexed oldOwner, address indexed newOwner);
    event A88_GuardianSet(address indexed oldGuardian, address indexed newGuardian);

