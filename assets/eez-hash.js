/* eez-hash.js — self-contained Keccak-256 + EEZ protocol hash helpers.
 *
 * Zero dependencies. No fetch, no modules, no bundler. Plain browser JS
 * (var / function only) so it works from a <script src> tag, pasted inline,
 * or under `node` for tests.
 *
 * IMPORTANT: this is original Keccak (pad byte 0x01), which is what Ethereum
 * uses — NOT NIST SHA3-256 (pad byte 0x06). Test vectors in
 * assets/eez-hash.test.js pin this down.
 *
 * Exposes a single global: EEZHash
 */
(function (root) {
  "use strict";

  /* ------------------------------------------------------------------ *
   * Keccak-f[1600]
   * ------------------------------------------------------------------ */

  // Round constants, split into low/high 32-bit halves.
  var RC_LO = [
    0x00000001, 0x00008082, 0x0000808a, 0x80008000, 0x0000808b, 0x80000001,
    0x80008081, 0x00008009, 0x0000008a, 0x00000088, 0x80008009, 0x8000000a,
    0x8000808b, 0x0000008b, 0x00008089, 0x00008003, 0x00008002, 0x00000080,
    0x0000800a, 0x8000000a, 0x80008081, 0x00008080, 0x80000001, 0x80008008
  ];
  var RC_HI = [
    0x00000000, 0x00000000, 0x80000000, 0x80000000, 0x00000000, 0x00000000,
    0x80000000, 0x80000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
    0x00000000, 0x80000000, 0x80000000, 0x80000000, 0x80000000, 0x80000000,
    0x00000000, 0x80000000, 0x80000000, 0x80000000, 0x00000000, 0x80000000
  ];

  // rho rotation offsets, flat index = x + 5*y
  var RHO = [
    0, 1, 62, 28, 27,
    36, 44, 6, 55, 20,
    3, 10, 43, 25, 39,
    41, 45, 15, 21, 8,
    18, 2, 61, 56, 14
  ];

  // Precompute the pi source index for each destination index.
  // pi: A'[x][y] = A[(x + 3y) mod 5][x]
  var PI_SRC = new Array(25);
  (function () {
    for (var y = 0; y < 5; y++) {
      for (var x = 0; x < 5; x++) {
        PI_SRC[x + 5 * y] = ((x + 3 * y) % 5) + 5 * x;
      }
    }
  })();

  function keccakF(lo, hi) {
    var Clo = new Array(5), Chi = new Array(5);
    var Blo = new Array(25), Bhi = new Array(25);
    var round, x, y, i, j, n, m, sl, sh, r;

    for (round = 0; round < 24; round++) {
      /* theta */
      for (x = 0; x < 5; x++) {
        Clo[x] = lo[x] ^ lo[x + 5] ^ lo[x + 10] ^ lo[x + 15] ^ lo[x + 20];
        Chi[x] = hi[x] ^ hi[x + 5] ^ hi[x + 10] ^ hi[x + 15] ^ hi[x + 20];
      }
      for (x = 0; x < 5; x++) {
        // D[x] = C[x-1] ^ rotl(C[x+1], 1)
        var np = (x + 1) % 5;
        var rl = ((Clo[np] << 1) | (Chi[np] >>> 31)) | 0;
        var rh = ((Chi[np] << 1) | (Clo[np] >>> 31)) | 0;
        var dlo = Clo[(x + 4) % 5] ^ rl;
        var dhi = Chi[(x + 4) % 5] ^ rh;
        for (y = 0; y < 5; y++) {
          i = x + 5 * y;
          lo[i] ^= dlo;
          hi[i] ^= dhi;
        }
      }

      /* rho + pi */
      for (i = 0; i < 25; i++) {
        j = PI_SRC[i];
        n = RHO[j];
        sl = lo[j];
        sh = hi[j];
        if (n === 0) {
          Blo[i] = sl;
          Bhi[i] = sh;
        } else if (n < 32) {
          Blo[i] = ((sl << n) | (sh >>> (32 - n))) | 0;
          Bhi[i] = ((sh << n) | (sl >>> (32 - n))) | 0;
        } else if (n === 32) {
          Blo[i] = sh;
          Bhi[i] = sl;
        } else {
          m = n - 32;
          Blo[i] = ((sh << m) | (sl >>> (32 - m))) | 0;
          Bhi[i] = ((sl << m) | (sh >>> (32 - m))) | 0;
        }
      }

      /* chi */
      for (y = 0; y < 5; y++) {
        for (x = 0; x < 5; x++) {
          i = x + 5 * y;
          var i1 = ((x + 1) % 5) + 5 * y;
          var i2 = ((x + 2) % 5) + 5 * y;
          lo[i] = Blo[i] ^ (~Blo[i1] & Blo[i2]);
          hi[i] = Bhi[i] ^ (~Bhi[i1] & Bhi[i2]);
        }
      }

      /* iota */
      lo[0] ^= RC_LO[round];
      hi[0] ^= RC_HI[round];
    }
  }

  var RATE = 136; // Keccak-256: 1600 - 2*256 bits = 1088 bits = 136 bytes

  /**
   * Keccak-256 over a Uint8Array (or plain byte array).
   * @param {Uint8Array|Array} bytes
   * @returns {string} 64 lowercase hex chars, no "0x"
   */
  function keccak256(bytes) {
    if (typeof bytes === "string") {
      throw new Error(
        "keccak256 expects bytes, not a string. Use EEZHash.utf8ToBytes() or EEZHash.hexToBytes() first."
      );
    }
    if (!bytes || typeof bytes.length !== "number") {
      throw new Error("keccak256 expects a Uint8Array or byte array.");
    }

    var lo = new Array(25), hi = new Array(25);
    var i;
    for (i = 0; i < 25; i++) { lo[i] = 0; hi[i] = 0; }

    var len = bytes.length;
    var blockCount = Math.floor(len / RATE);
    var off = 0;
    var b, laneIdx, shift;

    function absorbBlock(block) {
      // little-endian lane packing, 8 bytes per lane, 17 lanes per block
      for (var k = 0; k < RATE; k++) {
        laneIdx = k >>> 3;         // k / 8
        var byteInLane = k & 7;
        var v = block[k] & 0xff;
        if (byteInLane < 4) {
          lo[laneIdx] ^= v << (8 * byteInLane);
        } else {
          hi[laneIdx] ^= v << (8 * (byteInLane - 4));
        }
      }
      keccakF(lo, hi);
    }

    var full = new Array(RATE);
    for (b = 0; b < blockCount; b++) {
      for (i = 0; i < RATE; i++) full[i] = bytes[off + i];
      absorbBlock(full);
      off += RATE;
    }

    // final (possibly empty) partial block + pad10*1 with Keccak domain 0x01
    var rem = len - off;
    var last = new Array(RATE);
    for (i = 0; i < RATE; i++) last[i] = 0;
    for (i = 0; i < rem; i++) last[i] = bytes[off + i];
    last[rem] |= 0x01;
    last[RATE - 1] |= 0x80;
    absorbBlock(last);

    // squeeze 32 bytes = lanes 0..3, little-endian
    var out = "";
    for (laneIdx = 0; laneIdx < 4; laneIdx++) {
      for (shift = 0; shift < 4; shift++) {
        out += byteHex((lo[laneIdx] >>> (8 * shift)) & 0xff);
      }
      for (shift = 0; shift < 4; shift++) {
        out += byteHex((hi[laneIdx] >>> (8 * shift)) & 0xff);
      }
    }
    return out;
  }

  var HEXC = "0123456789abcdef";
  function byteHex(v) {
    return HEXC.charAt((v >>> 4) & 0xf) + HEXC.charAt(v & 0xf);
  }

  /* ------------------------------------------------------------------ *
   * Byte / hex / number helpers — strict, throw on anything ambiguous
   * ------------------------------------------------------------------ */

  function utf8ToBytes(str) {
    if (typeof str !== "string") throw new Error("utf8ToBytes expects a string.");
    var out = [];
    for (var i = 0; i < str.length; i++) {
      var c = str.charCodeAt(i);
      if (c < 0x80) {
        out.push(c);
      } else if (c < 0x800) {
        out.push(0xc0 | (c >> 6), 0x80 | (c & 0x3f));
      } else if (c >= 0xd800 && c <= 0xdbff && i + 1 < str.length) {
        var c2 = str.charCodeAt(i + 1);
        if (c2 >= 0xdc00 && c2 <= 0xdfff) {
          var cp = 0x10000 + ((c - 0xd800) << 10) + (c2 - 0xdc00);
          out.push(
            0xf0 | (cp >> 18),
            0x80 | ((cp >> 12) & 0x3f),
            0x80 | ((cp >> 6) & 0x3f),
            0x80 | (cp & 0x3f)
          );
          i++;
        } else {
          out.push(0xef, 0xbf, 0xbd); // lone surrogate -> U+FFFD
        }
      } else {
        out.push(0xe0 | (c >> 12), 0x80 | ((c >> 6) & 0x3f), 0x80 | (c & 0x3f));
      }
    }
    return toU8(out);
  }

  function toU8(arr) {
    if (typeof Uint8Array === "function") {
      var u = new Uint8Array(arr.length);
      for (var i = 0; i < arr.length; i++) u[i] = arr[i] & 0xff;
      return u;
    }
    return arr;
  }

  function stripHexPrefix(s) {
    if (s.length >= 2 && (s.charAt(0) === "0") && (s.charAt(1) === "x" || s.charAt(1) === "X")) {
      return s.slice(2);
    }
    return s;
  }

  /**
   * Strict hex-string -> bytes. Accepts optional 0x. Requires even length and
   * only hex digits. "" / "0x" -> empty byte array.
   * @param {string} s
   * @param {string=} label used in error messages
   */
  function hexToBytes(s, label) {
    label = label || "value";
    if (typeof s !== "string") throw new Error(label + ": expected a hex string.");
    var h = stripHexPrefix(s.replace(/^\s+|\s+$/g, ""));
    if (h === "") return toU8([]);
    if (!/^[0-9a-fA-F]*$/.test(h)) {
      throw new Error(label + ': not valid hex (only 0-9 a-f allowed after "0x").');
    }
    if (h.length % 2 !== 0) {
      throw new Error(
        label + ": hex has an odd number of digits (" + h.length + "); bytes need pairs."
      );
    }
    var out = new Array(h.length / 2);
    for (var i = 0; i < out.length; i++) {
      out[i] = parseInt(h.substr(i * 2, 2), 16);
    }
    return toU8(out);
  }

  function bytesToHex(bytes) {
    var s = "";
    for (var i = 0; i < bytes.length; i++) s += byteHex(bytes[i] & 0xff);
    return s;
  }

  /**
   * Strict address validation -> 20 raw bytes.
   * Accepts with or without 0x, any case. Does NOT verify EIP-55 checksum
   * (mixed-case input is accepted as-is) but does reject wrong length.
   */
  function addressToBytes(addr, label) {
    label = label || "address";
    if (typeof addr !== "string") throw new Error(label + ": expected an address string.");
    var h = stripHexPrefix(addr.replace(/^\s+|\s+$/g, ""));
    if (!/^[0-9a-fA-F]*$/.test(h)) {
      throw new Error(label + ": contains non-hex characters.");
    }
    if (h.length !== 40) {
      throw new Error(
        label + ": must be 20 bytes (40 hex digits), got " + h.length + " hex digits."
      );
    }
    return hexToBytes(h, label);
  }

  /**
   * Parse an unsigned integer given as a decimal string, 0x-hex string, or a
   * safe JS number, into a big-endian byte array of exactly `width` bytes.
   * Throws on overflow, negatives, or non-integers. No BigInt required.
   */
  function uintToBytes(value, width, label) {
    label = label || "value";
    var out = new Array(width), i;
    for (i = 0; i < width; i++) out[i] = 0;

    var s;
    if (typeof value === "number") {
      if (!isFinite(value) || Math.floor(value) !== value) {
        throw new Error(label + ": must be a whole number.");
      }
      if (value < 0) throw new Error(label + ": must not be negative.");
      if (value > 9007199254740991) {
        throw new Error(
          label + ": number is above 2^53-1 and would lose precision. Pass it as a string."
        );
      }
      s = String(value);
    } else if (typeof value === "string") {
      s = value.replace(/^\s+|\s+$/g, "");
    } else if (typeof value === "undefined" || value === null) {
      throw new Error(label + ": missing.");
    } else if (typeof value === "boolean") {
      throw new Error(label + ": got a boolean, expected a number.");
    } else {
      throw new Error(label + ": unsupported type " + typeof value + ".");
    }

    if (s === "") throw new Error(label + ": empty.");
    if (s.charAt(0) === "-") throw new Error(label + ": must not be negative.");

    var isHex = s.length >= 2 && s.charAt(0) === "0" && (s.charAt(1) === "x" || s.charAt(1) === "X");
    if (isHex) {
      var h = stripHexPrefix(s);
      if (!/^[0-9a-fA-F]+$/.test(h)) throw new Error(label + ": not valid hex.");
      // strip leading zeros
      h = h.replace(/^0+/, "");
      if (h.length === 0) return toU8(out);
      if (h.length % 2 !== 0) h = "0" + h;
      var nb = h.length / 2;
      if (nb > width) {
        throw new Error(
          label + ": " + nb + " bytes of hex does not fit in " + width + " bytes (uint" + (width * 8) + ")."
        );
      }
      for (i = 0; i < nb; i++) out[width - nb + i] = parseInt(h.substr(i * 2, 2), 16);
      return toU8(out);
    }

    if (!/^[0-9]+$/.test(s)) {
      throw new Error(
        label + ': not a number. Use decimal digits, or a "0x"-prefixed hex string.'
      );
    }
    // decimal: out = out*10 + digit, big-endian, overflow-checked
    for (var d = 0; d < s.length; d++) {
      var carry = s.charCodeAt(d) - 48;
      for (i = width - 1; i >= 0; i--) {
        var v = out[i] * 10 + carry;
        out[i] = v & 0xff;
        carry = (v - out[i]) / 256;
      }
      if (carry !== 0) {
        throw new Error(
          label + ": " + s + " exceeds the maximum for uint" + (width * 8) + "."
        );
      }
    }
    return toU8(out);
  }

  function uint64ToBytes(v, label) { return uintToBytes(v, 8, label || "uint64"); }
  function uint256ToBytes(v, label) { return uintToBytes(v, 32, label || "uint256"); }

  function concatBytes(parts) {
    var total = 0, i, j;
    for (i = 0; i < parts.length; i++) total += parts[i].length;
    var out = new Array(total), k = 0;
    for (i = 0; i < parts.length; i++) {
      for (j = 0; j < parts[i].length; j++) out[k++] = parts[i][j] & 0xff;
    }
    return toU8(out);
  }

  function leftPad32(bytes, label) {
    if (bytes.length > 32) throw new Error((label || "word") + ": longer than 32 bytes.");
    var out = new Array(32), i;
    for (i = 0; i < 32; i++) out[i] = 0;
    for (i = 0; i < bytes.length; i++) out[32 - bytes.length + i] = bytes[i] & 0xff;
    return toU8(out);
  }

  function boolToWord(v, label) {
    label = label || "bool";
    var t;
    if (typeof v === "boolean") {
      t = v;
    } else if (typeof v === "number") {
      if (v !== 0 && v !== 1) throw new Error(label + ": expected 0 or 1.");
      t = v === 1;
    } else if (typeof v === "string") {
      var s = v.replace(/^\s+|\s+$/g, "").toLowerCase();
      if (s === "true" || s === "1") t = true;
      else if (s === "false" || s === "0") t = false;
      else throw new Error(label + ': expected true/false (got "' + v + '").');
    } else {
      throw new Error(label + ": expected a boolean.");
    }
    var out = new Array(32), i;
    for (i = 0; i < 32; i++) out[i] = 0;
    out[31] = t ? 1 : 0;
    return toU8(out);
  }

  /* ------------------------------------------------------------------ *
   * EIP-55 checksum
   * ------------------------------------------------------------------ */

  function toChecksumAddress(addr) {
    var bytes = addressToBytes(addr, "address");
    var lowerHex = bytesToHex(bytes); // 40 lowercase hex chars
    var hash = keccak256(utf8ToBytes(lowerHex));
    var out = "0x";
    for (var i = 0; i < 40; i++) {
      var c = lowerHex.charAt(i);
      if (c >= "0" && c <= "9") {
        out += c;
      } else {
        out += parseInt(hash.charAt(i), 16) >= 8 ? c.toUpperCase() : c;
      }
    }
    return out;
  }

  /* ------------------------------------------------------------------ *
   * EEZ protocol hashes
   * ------------------------------------------------------------------ */

  /**
   * keccak256(abi.encodePacked(uint64 originalRollupId, address originalAddress))
   * 8 bytes BE + 20 bytes = 28 bytes, no padding. rollupId FIRST.
   * Mirrors snippets/q1-compute-address.sol
   * @returns {string} 64 hex chars, no 0x
   */
  function proxySalt(rollupId, address) {
    var encoded = proxySaltEncoding(rollupId, address);
    return keccak256(encoded);
  }

  function proxySaltEncoding(rollupId, address) {
    return concatBytes([
      uint64ToBytes(rollupId, "rollupId"),
      addressToBytes(address, "address")
    ]);
  }

  var CALL_FIELDS = [
    "isStatic", "sourceAddress", "sourceRollupId",
    "targetAddress", "targetRollupId",
    "value", "callGas", "data"
  ];

  /**
   * abi.encode(bool, address, uint64, address, uint64, uint256, uint64, bytes)
   * 8 head slots (the 8th holds the offset 8*32 = 256 to the bytes tail),
   * then tail = 32-byte length + data right-padded to a multiple of 32.
   * Mirrors snippets/q5-content-hash.sol
   * @returns {Uint8Array}
   */
  function callHashEncoding(p) {
    if (!p || typeof p !== "object") throw new Error("callHash: expected an options object.");
    for (var i = 0; i < CALL_FIELDS.length; i++) {
      if (!(CALL_FIELDS[i] in p)) {
        throw new Error("callHash: missing field \"" + CALL_FIELDS[i] + "\".");
      }
    }

    var dataBytes = hexToBytes(
      typeof p.data === "string" ? p.data : "",
      "data"
    );
    if (typeof p.data !== "string") {
      throw new Error('data: expected a hex string (use "" or "0x" for empty calldata).');
    }

    var head = [
      boolToWord(p.isStatic, "isStatic"),
      leftPad32(addressToBytes(p.sourceAddress, "sourceAddress")),
      leftPad32(uint64ToBytes(p.sourceRollupId, "sourceRollupId")),
      leftPad32(addressToBytes(p.targetAddress, "targetAddress")),
      leftPad32(uint64ToBytes(p.targetRollupId, "targetRollupId")),
      uint256ToBytes(p.value, "value"),
      leftPad32(uint64ToBytes(p.callGas, "callGas")),
      // dynamic head slot: byte offset from the start of the encoding to the tail
      leftPad32(uintToBytes(CALL_FIELDS.length * 32, 32, "dataOffset"))
    ];

    var padLen = dataBytes.length % 32 === 0 ? 0 : 32 - (dataBytes.length % 32);
    var pad = new Array(padLen);
    for (i = 0; i < padLen; i++) pad[i] = 0;

    var tail = [
      uintToBytes(dataBytes.length, 32, "dataLength"),
      dataBytes,
      toU8(pad)
    ];

    return concatBytes(head.concat(tail));
  }

  /**
   * keccak256 of the abi.encode above.
   * @returns {string} 64 hex chars, no 0x
   */
  function callHash(p) {
    return keccak256(callHashEncoding(p));
  }

  /**
   * keccak256(abi.encodePacked(bytes1(0xff), address manager, bytes32 salt, bytes32 bytecodeHash))
   * 1 + 20 + 32 + 32 = 85 bytes; the address is the LAST 20 bytes of the hash.
   * @returns {string} EIP-55 checksummed address with 0x
   */
  function create2Address(manager, salt, bytecodeHash) {
    var saltBytes = hexToBytes(salt, "salt");
    if (saltBytes.length !== 32) {
      throw new Error("salt: must be 32 bytes (64 hex digits), got " + saltBytes.length + ".");
    }
    var codeBytes = hexToBytes(bytecodeHash, "bytecodeHash");
    if (codeBytes.length !== 32) {
      throw new Error(
        "bytecodeHash: must be 32 bytes (64 hex digits), got " + codeBytes.length + "."
      );
    }
    var encoded = concatBytes([
      toU8([0xff]),
      addressToBytes(manager, "manager"),
      saltBytes,
      codeBytes
    ]);
    if (encoded.length !== 85) {
      throw new Error("create2Address: internal encoding length " + encoded.length + " != 85.");
    }
    var hash = keccak256(encoded);
    return toChecksumAddress(hash.slice(24)); // last 20 bytes = last 40 hex chars
  }

  /* ------------------------------------------------------------------ */

  var EEZHash = {
    keccak256: keccak256,
    keccak256Hex: function (hexStr) { return keccak256(hexToBytes(hexStr, "input")); },
    keccak256Utf8: function (s) { return keccak256(utf8ToBytes(s)); },

    proxySalt: proxySalt,
    proxySaltEncoding: proxySaltEncoding,
    callHash: callHash,
    callHashEncoding: callHashEncoding,
    create2Address: create2Address,

    utf8ToBytes: utf8ToBytes,
    hexToBytes: hexToBytes,
    bytesToHex: bytesToHex,
    addressToBytes: addressToBytes,
    uint64ToBytes: uint64ToBytes,
    uint256ToBytes: uint256ToBytes,
    uintToBytes: uintToBytes,
    concatBytes: concatBytes,
    leftPad32: leftPad32,
    toChecksumAddress: toChecksumAddress,

    RATE: RATE,
    CALL_FIELDS: CALL_FIELDS
  };

  root.EEZHash = EEZHash;
  if (typeof module === "object" && module && module.exports) module.exports = EEZHash;
})(typeof globalThis !== "undefined" ? globalThis : (typeof window !== "undefined" ? window : this));
