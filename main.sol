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

    // ≤3 embedded addresses. Not a vault; no sink address pattern.
    address public immutable GUARDIAN_BOOT;
    address public immutable RELAYER_BOOT;

    address public owner;
    address public pendingOwner;
    address public guardian;
    address public relayer;

    bool public paused;

    uint64 public seq;
    bytes32 public rolling;

    uint256 private _lock;

    mapping(bytes32 receipt => bool) public usedReceipt;
    mapping(bytes32 channel => bool) public mutedChannel;

    bytes4 private constant _DOMAIN = 0x41383831; // "A881"

    modifier onlyOwner() {
        if (msg.sender != owner) revert A88_Unauthorized();
        _;
    }

    modifier onlyGuardian() {
        if (msg.sender != guardian) revert A88_NotGuardian();
        _;
    }

    modifier whenActive() {
