// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ContentHashSnippet} from "../q5-content-hash.sol";

// Runnable proof that the field order in computeCrossChainCallHash is
// load-bearing. Paste into any Foundry project and run:
//
//   forge test --match-contract Q5ContentHashTest -vv
//
// Depends on nothing but solc — no forge-std, no submodules.
//
// The expected digests below were derived OUTSIDE the EVM, with pycryptodome's
// keccak-256 and a hand-built ABI encoder, then pasted here. So these tests do
// not merely check that solc agrees with itself: they pin solc's output against
// an independent implementation. If a future refactor reorders the encode call,
// this fails even though the contract still compiles and still "hashes".

contract Q5ContentHashTest {
    ContentHashSnippet internal h;

    address internal constant SRC = 0x1111111111111111111111111111111111111111;
    address internal constant TGT = 0x2222222222222222222222222222222222222222;
    uint64 internal constant SRC_RID = 1;
    uint64 internal constant TGT_RID = 100;

    function setUp() public {
        h = new ContentHashSnippet();
    }

    function _hash(bool isStatic, address src, uint64 srid, address tgt, uint64 trid)
        internal
        view
        returns (bytes32)
    {
        return h.computeCrossChainCallHash(isStatic, src, srid, tgt, trid, 0, 0, hex"a9059cbb");
    }

    /// @dev Baseline, pinned to the externally-derived digest.
    function test_matchesIndependentlyDerivedDigest() public view {
        bytes32 got = _hash(false, SRC, SRC_RID, TGT, TGT_RID);
        require(
            got == 0x6f907866fb077719ec239f745e2de52832f0d8507473768dbaa2d3b45cf8fbe1,
            "digest drifted from the externally-derived value"
        );
    }

    /// @dev The whole lesson of the walkthrough: nothing added, nothing removed,
    ///      only source and target exchanged, and the hash is completely different.
    function test_swappingSourceAndTargetChangesTheHash() public view {
        bytes32 base = _hash(false, SRC, SRC_RID, TGT, TGT_RID);
        bytes32 swapped = _hash(false, TGT, TGT_RID, SRC, SRC_RID);
        require(base != swapped, "reordering the pairs must change the hash");
        require(
            swapped == 0x9876a218b9c58a69bb5b01481b628f13d5c2eb8d72b0f80d942e9eb0962dc19f,
            "swapped digest drifted from the externally-derived value"
        );
    }

    /// @dev isStatic is part of the preimage, so a read-only call hashes
    ///      distinctly from an otherwise-identical state-changing one.
    function test_isStaticIsPartOfTheHash() public view {
        bytes32 stateChanging = _hash(false, SRC, SRC_RID, TGT, TGT_RID);
        bytes32 readOnly = _hash(true, SRC, SRC_RID, TGT, TGT_RID);
        require(stateChanging != readOnly, "isStatic must affect the hash");
        require(
            readOnly == 0xb3d426ceaa48ca006739dd0799a05e675999732e2a63a4021089512c489daa1d,
            "isStatic digest drifted from the externally-derived value"
        );
    }

    /// @dev abi.encode is used rather than encodePacked, so `data` is length-
    ///      prefixed. Two different payloads can never collide by concatenation.
    function test_dataLengthIsEncoded() public view {
        bytes32 a = h.computeCrossChainCallHash(false, SRC, SRC_RID, TGT, TGT_RID, 0, 0, hex"1122");
        bytes32 b = h.computeCrossChainCallHash(false, SRC, SRC_RID, TGT, TGT_RID, 0, 0, hex"112200");
        require(a != b, "trailing zero byte must change the hash");
    }

    /// @dev Same inputs, same digest. Nothing in here reads state or time.
    function test_isDeterministic() public view {
        require(
            _hash(false, SRC, SRC_RID, TGT, TGT_RID) == _hash(false, SRC, SRC_RID, TGT, TGT_RID),
            "must be deterministic"
        );
    }
}
