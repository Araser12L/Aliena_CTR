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
        if (paused) revert A88_Paused();
        _;
    }

    modifier nonReentrant() {
        if (_lock == 1) revert A88_Reentry();
        _lock = 1;
        _;
        _lock = 0;
    }

    constructor() {
        GUARDIAN_BOOT = 0x827bbAa7606fa8eC618A65E4285bA212da486032;
        RELAYER_BOOT = 0x4f2aABa5057400DC9d9808d276d88d09F10Ff0f2;

        owner = msg.sender;
        pendingOwner = address(0);

        guardian = GUARDIAN_BOOT;
        relayer = RELAYER_BOOT;

        paused = false;
        seq = 0;
        rolling = keccak256(abi.encodePacked(_DOMAIN, block.chainid, address(this), owner, GUARDIAN_BOOT));
    }

    // --- Controls ---

    function setPaused(bool on) external onlyGuardian {
        if (paused == on) revert A88_Same();
        paused = on;
        emit A88_PauseSet(on);
    }

    function setChannelMuted(bytes32 channel, bool muted) external onlyGuardian {
        if (channel == bytes32(0)) revert A88_Zero();
        if (mutedChannel[channel] == muted) revert A88_Same();
        mutedChannel[channel] = muted;
        emit A88_ChannelMuted(channel, muted);
    }

    function proposeOwner(address next) external onlyOwner {
        if (next == address(0)) revert A88_BadAddr();
        pendingOwner = next;
        emit A88_OwnerProposed(owner, next);
    }

    function acceptOwner() external {
        address p = pendingOwner;
        if (msg.sender != p || p == address(0)) revert A88_Unauthorized();
        address old = owner;
        owner = p;
        pendingOwner = address(0);
        emit A88_OwnerAccepted(old, p);
    }

    function setGuardian(address next) external onlyOwner {
        if (next == address(0)) revert A88_BadAddr();
        address old = guardian;
        guardian = next;
        emit A88_GuardianSet(old, next);
    }

    function setRelayer(address next) external onlyOwner {
