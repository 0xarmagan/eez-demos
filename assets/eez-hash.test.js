/* eez-hash.test.js — zero-dependency test suite for assets/eez-hash.js
 *
 *   node assets/eez-hash.test.js
 *
 * Also runnable in a browser: load eez-hash.js then this file, and check the
 * console. No require(), no npm, no network.
 */
(function () {
  "use strict";

  var H = (typeof module === "object" && module && module.exports)
    ? require("./eez-hash.js")
    : (typeof window !== "undefined" ? window.EEZHash : globalThis.EEZHash);

  var passed = 0, failed = 0, log = [];
  function p(s) { log.push(s); if (typeof console !== "undefined") console.log(s); }

  function eq(name, actual, expected) {
    var a = String(actual), e = String(expected);
    if (a === e) { passed++; p("  PASS  " + name + "\n          " + a); }
    else { failed++; p("  FAIL  " + name + "\n          actual  : " + a + "\n          expected: " + e); }
  }
  function ne(name, a, b) {
    if (String(a) !== String(b)) { passed++; p("  PASS  " + name + " (differ)"); }
    else { failed++; p("  FAIL  " + name + " — values are identical: " + a); }
  }
  function throws(name, fn, needle) {
    try { fn(); failed++; p("  FAIL  " + name + " — no error thrown"); }
    catch (e) {
      if (!needle || e.message.indexOf(needle) !== -1) { passed++; p("  PASS  " + name + ' -> "' + e.message + '"'); }
      else { failed++; p("  FAIL  " + name + " — wrong error: " + e.message); }
    }
  }

  function rep(s, n) { var o = ""; for (var i = 0; i < n; i++) o += s; return o; }
  function fill(n, v) { var a = []; for (var i = 0; i < n; i++) a.push(v); return a; }

  /* ================================================================ *
   * 1. Keccak-256 known-answer vectors (original Keccak, pad 0x01)
   * ================================================================ */
  p("\n=== 1. Keccak-256 KATs (must be Keccak, NOT SHA3-256) ===");

  eq('keccak256("")',
    H.keccak256Utf8(""),
    "c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470");

  eq('keccak256("abc")',
    H.keccak256Utf8("abc"),
    "4e03657aea45a94fc7d47ba826c8d667c0d1e6e33a64a036ec44f58fa12d6c45");

  eq('keccak256("The quick brown fox jumps over the lazy dog")',
    H.keccak256Utf8("The quick brown fox jumps over the lazy dog"),
    "4d741b6f1eb29cb2a9b9911c82f56fa8d73b04959d3d9d222895df6c0b28aa15");

  // Guard against accidentally shipping NIST SHA3-256 padding (0x06).
  // SHA3-256("") is a7ffc6f8bf1ed76651c14756a061d662f580ff4de43b49fa82d80a4b80f8434a.
  ne("keccak256(\"\") is not SHA3-256(\"\")",
    H.keccak256Utf8(""),
    "a7ffc6f8bf1ed76651c14756a061d662f580ff4de43b49fa82d80a4b80f8434a");

  /* ---- multi-block absorption. Rate = 136 bytes. ---- */
  p("\n=== 2. Multi-block absorption (rate = 136 bytes) ===");
  eq("H.RATE", H.RATE, 136);

  // 135 x 'a' — one byte under the rate (padding fits in the same block)
  eq('keccak256("a" x 135)  [rate-1]',
    H.keccak256(fill(135, 0x61)),
    "34367dc248bbd832f4e3e69dfaac2f92638bd0bbd18f2912ba4ef454919cf446");

  // 136 x 'a' — exactly the rate; padding forces a WHOLE extra block.
  // This is the case a single-block implementation silently gets wrong.
  eq('keccak256("a" x 136)  [== rate, forces extra pad block]',
    H.keccak256(fill(136, 0x61)),
    "a6c4d403279fe3e0af03729caada8374b5ca54d8065329a3ebcaeb4b60aa386e");

  eq('keccak256("a" x 137)  [rate+1]',
    H.keccak256(fill(137, 0x61)),
    "d869f639c7046b4929fc92a4d988a8b22c55fbadb802c0c66ebcd484f1915f39");

  // 200 bytes of 0x00,0x01,...,0xc7 — two absorb blocks
  (function () {
    var b = [];
    for (var i = 0; i < 200; i++) b.push(i & 0xff);
    eq("keccak256(bytes 0x00..0xc7, 200 bytes)",
      H.keccak256(b),
      "bfb0aa97863e797943cf7c33bb7e880bb4543f3d2703c0923c6901c2af57b890");
  })();

  // 272 bytes = exactly 2 * rate
  eq('keccak256(0x5a x 272)  [2*rate]',
    H.keccak256(fill(272, 0x5a)),
    "55f08c872f52ae47a17f2ed98203965fe6361a0a3036291c800eaec1fefe1a7e");

  // 1000 bytes — 7 full blocks + remainder
  (function () {
    var b = [];
    for (var i = 0; i < 1000; i++) b.push((i * 7 + 3) & 0xff);
    eq("keccak256(1000 bytes)",
      H.keccak256(b),
      "80cdc8dd52cbb3dbaea8f383209893fa2bb52efbd5aedbb4b26dcfe307fcdc9b");
  })();

  /* ================================================================ *
   * 3. EIP-55 checksumming
   * ================================================================ */
  p("\n=== 3. EIP-55 checksum (vectors from the EIP itself) ===");
  eq("all-caps vector",   H.toChecksumAddress("0x52908400098527886e0f7030069857d2e4169ee7"), "0x52908400098527886E0F7030069857D2E4169EE7");
  eq("all-lower vector",  H.toChecksumAddress("0xde709f2102306220921060314715629080e2fb77"), "0xde709f2102306220921060314715629080e2fb77");
  eq("normal 1 (5aAeb605…)", H.toChecksumAddress("0x5aaeb6053f3e94c9b9a09f33669435e7ef1beaed"), "0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed");
  eq("normal 2", H.toChecksumAddress("0xfb6916095ca1df60bb79ce92ce3ea74c37c5d359"), "0xfB6916095ca1df60bB79Ce92cE3Ea74c37c5d359");
  eq("normal 3", H.toChecksumAddress("0xdbf03b407c01e7cd3cbea99509d93f8dddc8c6fb"), "0xdbF03B407c01E7cD3CBea99509d93f8DDDC8C6FB");
  eq("normal 4", H.toChecksumAddress("0xd1220a0cf47c7b9be7a2e6ba89f429762e7b9adb"), "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb");
  eq("idempotent on already-checksummed",
    H.toChecksumAddress("0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed"), "0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed");
  eq("accepts no-0x input",
    H.toChecksumAddress("5aaeb6053f3e94c9b9a09f33669435e7ef1beaed"), "0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed");

  /* ================================================================ *
   * 4. proxySalt — encodePacked(uint64 rollupId, address)
   * ================================================================ */
  p("\n=== 4. proxySalt: abi.encodePacked(uint64 rollupId, address) ===");

  // Hand-derived: 8 bytes big-endian rollupId, then 20 raw address bytes = 28 bytes.
  eq("packed length is 28 bytes, not 52",
    H.proxySaltEncoding(1, "0x1111111111111111111111111111111111111111").length, 28);

  eq("packed layout rid=1",
    H.bytesToHex(H.proxySaltEncoding(1, "0x1111111111111111111111111111111111111111")),
    "0000000000000001" + rep("11", 20));

  eq("packed layout rid=100 (0x64)",
    H.bytesToHex(H.proxySaltEncoding(100, "0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed")),
    "0000000000000064" + "5aaeb6053f3e94c9b9a09f33669435e7ef1beaed");

  eq("packed layout rid=2^64-1",
    H.bytesToHex(H.proxySaltEncoding("18446744073709551615", "0xdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef")),
    "ffffffffffffffff" + rep("deadbeef", 5));

  // hashes (cross-checked against viem — see report)
  eq("salt(0, 0x00..00)", H.proxySalt(0, "0x0000000000000000000000000000000000000000"),
    "b696031ea0505df7c7b5cc290e50cea0402d2a396b0db1c5d08155bd219cc52e");
  eq("salt(1, 0x11..11)", H.proxySalt(1, "0x1111111111111111111111111111111111111111"),
    "7ed5a58a5202829820746a19eba7a41095ea6aac78318954f72aedf48bb4ed9f");
  eq("salt(100, 0x5aAeb605…)", H.proxySalt(100, "0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed"),
    "02fd49ec7ba6d724ef92151382fa81fbd2521c70c41759cb6a9c8bd8fea5c2a8");
  eq("salt(2^64-1, 0xdeadbeef…)", H.proxySalt("18446744073709551615", "0xdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef"),
    "ac86d91c6b829ad6f10481e314261106b38b05bb1e6caece8da44786d1cc5381");

  // ORDER MATTERS: rollupId first. Swapping would produce a different 28 bytes.
  ne("salt(1, A) vs salt(2, A)",
    H.proxySalt(1, "0x1111111111111111111111111111111111111111"),
    H.proxySalt(2, "0x1111111111111111111111111111111111111111"));

  // case-insensitive address input must not change the hash
  eq("address case does not affect the salt",
    H.proxySalt(100, "0x5AAEB6053F3E94C9B9A09F33669435E7EF1BEAED"),
    H.proxySalt(100, "0x5aaeb6053f3e94c9b9a09f33669435e7ef1beaed"));

  /* ================================================================ *
   * 5. callHash — abi.encode, byte layout HAND-DERIVED
   * ================================================================ */
  p("\n=== 5. callHash: abi.encode(...) — hand-derived byte layout ===");

  var CASE = {
    isStatic: true,
    sourceAddress: "0x1111111111111111111111111111111111111111",
    sourceRollupId: 1,
    targetAddress: "0x2222222222222222222222222222222222222222",
    targetRollupId: 100,                 // 0x64
    value: "1000000000000000000",        // 1e18 = 0x0de0b6b3a7640000
    callGas: 200000,                     // 0x030d40
    data: "0xa9059cbb"                   // 4 bytes
  };

  // ---- hand-derived, word by word, from the ABI spec ----
  var W = [];
  //  0  bool isStatic = true      -> 31 zero bytes then 0x01
  W.push(rep("00", 31) + "01");
  //  1  address sourceAddress     -> left-padded to 32 (12 zero bytes + 20 addr bytes)
  W.push(rep("00", 12) + rep("11", 20));
  //  2  uint64 sourceRollupId=1   -> left-padded to 32
  W.push(rep("00", 31) + "01");
  //  3  address targetAddress
  W.push(rep("00", 12) + rep("22", 20));
  //  4  uint64 targetRollupId=100 -> 0x64
  W.push(rep("00", 31) + "64");
  //  5  uint256 value = 1e18      -> 0x0de0b6b3a7640000 in the low 8 bytes
  W.push(rep("00", 24) + "0de0b6b3a7640000");
  //  6  uint64 callGas = 200000   -> 0x030d40
  W.push(rep("00", 29) + "030d40");
  //  7  bytes data HEAD           -> offset to the tail = 8 head slots * 32 = 256 = 0x0100
  W.push(rep("00", 30) + "0100");
  //  8  bytes data TAIL: length   -> 4
  W.push(rep("00", 31) + "04");
  //  9  bytes data TAIL: content  -> right-padded to a full 32-byte word
  W.push("a9059cbb" + rep("00", 28));
  var HAND = W.join("");

  eq("hand-derived encoding is 10 words = 320 bytes", HAND.length / 2, 320);
  eq("encoded byte layout matches hand derivation", H.bytesToHex(H.callHashEncoding(CASE)), HAND);
  eq("head slot 7 holds offset 256 (0x0100), NOT 0x0120 or 0x08",
    H.bytesToHex(H.callHashEncoding(CASE)).substr(7 * 64, 64), rep("00", 30) + "0100");
  eq("callHash(CASE)", H.callHash(CASE),
    "34e7fd83c93ede5029d94ba8141512a8d67794aaec0e5878d5d747269a9439bb");

  // ---- empty data: 8 head slots + one length word = 9 words = 288 bytes ----
  var EMPTY = {
    isStatic: false,
    sourceAddress: "0x0000000000000000000000000000000000000000",
    sourceRollupId: 0,
    targetAddress: "0x0000000000000000000000000000000000000000",
    targetRollupId: 0,
    value: "0",
    callGas: 0,
    data: ""
  };
  var HAND_EMPTY = rep("00", 32 * 7) + rep("00", 30) + "0100" + rep("00", 32);
  eq("empty-data encoding is 9 words = 288 bytes", H.callHashEncoding(EMPTY).length, 288);
  eq("empty-data byte layout matches hand derivation",
    H.bytesToHex(H.callHashEncoding(EMPTY)), HAND_EMPTY);
  eq("callHash(all-zero, empty data)", H.callHash(EMPTY),
    "f037b82d836b3dbf50178bf9c657d40d233117dd1ed1981643a269babb528fdd");

  // ---- 33 bytes of data -> tail spans TWO words (66 -> 2 words, 31 bytes pad) ----
  (function () {
    var c = {
      isStatic: true, sourceAddress: "0xdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef",
      sourceRollupId: 7, targetAddress: "0xdbF03B407c01E7cD3CBea99509d93f8DDDC8C6FB",
      targetRollupId: 8, value: "1", callGas: 21000, data: "0x" + rep("cd", 33)
    };
    eq("33-byte data -> 11 words = 352 bytes", H.callHashEncoding(c).length, 352);
    eq("33-byte data tail padded right",
      H.bytesToHex(H.callHashEncoding(c)).substr(8 * 64),
      rep("00", 31) + "21" + rep("cd", 33) + rep("00", 31));
    eq("callHash(33-byte data)", H.callHash(c),
      "694a6c6751909eb3c439fc7bff7a571cb1480ac6d6e05f05d7369a6686b9b1aa");
  })();

  // ---- max-value case: uint256 max, uint64 max, exactly-32-byte data ----
  eq("callHash(max values, 32-byte data)", H.callHash({
    isStatic: false,
    sourceAddress: "0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed",
    sourceRollupId: "18446744073709551615",
    targetAddress: "0xfB6916095ca1df60bB79Ce92cE3Ea74c37c5d359",
    targetRollupId: "4294967296",
    value: "115792089237316195423570985008687907853269984665640564039457584007913129639935",
    callGas: "18446744073709551615",
    data: "0x" + rep("ab", 32)
  }), "cc72af38aa45c69af25e90d4cba28d88bd93955ddffaa99e17a3875a7e8ee0e5");

  // ---- the whole point of the walkthrough: reordering changes the hash ----
  var SWAPPED = {
    isStatic: true,
    sourceAddress: "0x2222222222222222222222222222222222222222",
    sourceRollupId: 100,
    targetAddress: "0x1111111111111111111111111111111111111111",
    targetRollupId: 1,
    value: "1000000000000000000",
    callGas: 200000,
    data: "0xa9059cbb"
  };
  ne("swapping source/target changes the hash", H.callHash(CASE), H.callHash(SWAPPED));
  eq("callHash(SWAPPED)", H.callHash(SWAPPED),
    "48b3a3115c80060bab7c49282044b9899a536b7700ff674b265853d38a4b4e02");

  // encodePacked would be 8+20+8+20+8+32+8+4 = 108 bytes; abi.encode is 320.
  // If someone wires up encodePacked by mistake, this catches it.
  ne("abi.encode is not encodePacked (320 vs 108 bytes)",
    H.callHashEncoding(CASE).length, 108);

  /* ================================================================ *
   * 6. create2Address
   * ================================================================ */
  p("\n=== 6. create2Address ===");
  eq("all-zero manager/salt/hash",
    H.create2Address("0x0000000000000000000000000000000000000000", "0x" + rep("00", 32), "0x" + rep("00", 32)),
    "0xFFc4f52f884a02bCd5716744cD622127366F2edf");
  eq("deadbeef manager",
    H.create2Address("0xdeadbeef00000000000000000000000000000000",
      "0x" + rep("00", 31) + "01",
      "0x" + H.keccak256([0x00])),
    "0xeFFE671e6241d3D9d100f1d519b44a70D9860b56");
  eq("5aAeb605 manager",
    H.create2Address("0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed",
      "0x" + H.keccak256(H.hexToBytes("0xdeadbeef")),
      "0x" + H.keccak256(H.hexToBytes("0x6080604052"))),
    "0xD02C68D1005c6CF845e0fa55147381cd77679Da3");
  eq("returns an EIP-55 checksummed 0x address (42 chars)",
    H.create2Address("0x0000000000000000000000000000000000000000", "0x" + rep("00", 32), "0x" + rep("00", 32)).length, 42);

  /* ================================================================ *
   * 7. Strict input validation — clear errors, never silent coercion
   * ================================================================ */
  p("\n=== 7. Input validation ===");
  throws("keccak256 rejects a string",              function () { H.keccak256("abc"); }, "expects bytes");
  throws("hexToBytes rejects odd-length hex",       function () { H.hexToBytes("0xabc", "data"); }, "odd number");
  throws("hexToBytes rejects non-hex",              function () { H.hexToBytes("0xzz", "data"); }, "not valid hex");
  throws("address too short",                       function () { H.addressToBytes("0x1234"); }, "must be 20 bytes");
  throws("address too long",                        function () { H.addressToBytes("0x" + rep("11", 21)); }, "must be 20 bytes");
  throws("address non-hex",                         function () { H.addressToBytes("0x" + rep("gg", 20)); }, "non-hex");
  throws("uint64 overflow (2^64)",                  function () { H.uint64ToBytes("18446744073709551616"); }, "exceeds the maximum");
  throws("uint64 negative",                         function () { H.uint64ToBytes("-1"); }, "must not be negative");
  throws("uint64 non-numeric",                      function () { H.uint64ToBytes("12a"); }, "not a number");
  throws("uint64 unsafe JS number",                 function () { H.uint64ToBytes(1e20); }, "above 2^53-1");
  throws("uint256 overflow (2^256)",                function () { H.uint256ToBytes("115792089237316195423570985008687907853269984665640564039457584007913129639936"); }, "exceeds the maximum");
  throws("callHash missing field",                  function () { H.callHash({ isStatic: true }); }, 'missing field "sourceAddress"');
  throws("callHash rejects non-string data",        function () { H.callHash({ isStatic: true, sourceAddress: "0x" + rep("11", 20), sourceRollupId: 0, targetAddress: "0x" + rep("22", 20), targetRollupId: 0, value: 0, callGas: 0, data: 123 }); }, "hex string");
  throws("callHash rejects garbage bool",           function () { H.callHash({ isStatic: "yes", sourceAddress: "0x" + rep("11", 20), sourceRollupId: 0, targetAddress: "0x" + rep("22", 20), targetRollupId: 0, value: 0, callGas: 0, data: "" }); }, "expected true/false");
  throws("create2 salt wrong length",               function () { H.create2Address("0x" + rep("11", 20), "0x1234", "0x" + rep("00", 32)); }, "must be 32 bytes");
  throws("create2 bytecodeHash wrong length",       function () { H.create2Address("0x" + rep("11", 20), "0x" + rep("00", 32), "0x1234"); }, "must be 32 bytes");

  // accepted forms
  eq("uint64 accepts decimal string == number",
    H.bytesToHex(H.uint64ToBytes("100")), H.bytesToHex(H.uint64ToBytes(100)));
  eq("uint64 accepts 0x hex",
    H.bytesToHex(H.uint64ToBytes("0x64")), "0000000000000064");
  eq("uint256 max",
    H.bytesToHex(H.uint256ToBytes("115792089237316195423570985008687907853269984665640564039457584007913129639935")),
    rep("ff", 32));
  eq('empty data accepts "" and "0x" identically',
    H.bytesToHex(H.hexToBytes("")), H.bytesToHex(H.hexToBytes("0x")));

  /* ================================================================ */
  p("\n=== " + passed + " passed, " + failed + " failed ===");
  if (typeof process !== "undefined" && process.exit && failed > 0) process.exit(1);
})();
