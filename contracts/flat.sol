/*===============================
       __
      / /___ _____  __  _______
 __  / / __ `/ __ \/ / / / ___/
/ /_/ / /_/ / / / / /_/ (__  )
\____/\__,_/_/ /_/\__,_/____/

===============================*/

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.4 <0.9.0;

// File @chainlink/contracts/src/v0.8/vendor/BufferChainlink.sol@v0.2.1

/**
* @dev A library for working with mutable byte buffers in Solidity.
*
* Byte buffers are mutable and expandable, and provide a variety of primitives
* for writing to them. At any time you can fetch a bytes object containing the
* current contents of the buffer. The bytes object should not be stored between
* operations, as it may change due to resizing of the buffer.
*/
library BufferChainlink {
  /**
  * @dev Represents a mutable buffer. Buffers have a current value (buf) and
  *      a capacity. The capacity may be longer than the current value, in
  *      which case it can be extended without the need to allocate more memory.
  */
  struct buffer {
    bytes buf;
    uint capacity;
  }

  /**
  * @dev Initializes a buffer with an initial capacity.
  * @param buf The buffer to initialize.
  * @param capacity The number of bytes of space to allocate the buffer.
  * @return The buffer, for chaining.
  */
  function init(
    buffer memory buf,
    uint capacity
  )
    internal
    pure
    returns(
      buffer memory
    )
  {
    if (capacity % 32 != 0) {
      capacity += 32 - (capacity % 32);
    }
    // Allocate space for the buffer data
    buf.capacity = capacity;
    assembly {
      let ptr := mload(0x40)
      mstore(buf, ptr)
      mstore(ptr, 0)
      mstore(0x40, add(32, add(ptr, capacity)))
    }
    return buf;
  }

  /**
  * @dev Initializes a new buffer from an existing bytes object.
  *      Changes to the buffer may mutate the original value.
  * @param b The bytes object to initialize the buffer with.
  * @return A new buffer.
  */
  function fromBytes(
    bytes memory b
  )
    internal
    pure
    returns(
      buffer memory
    )
  {
    buffer memory buf;
    buf.buf = b;
    buf.capacity = b.length;
    return buf;
  }

  function resize(
    buffer memory buf,
    uint capacity
  )
    private
    pure
  {
    bytes memory oldbuf = buf.buf;
    init(buf, capacity);
    append(buf, oldbuf);
  }

  function max(
    uint a,
    uint b
  )
    private
    pure
    returns(
      uint
    )
  {
    if (a > b) {
      return a;
    }
    return b;
  }

  /**
  * @dev Sets buffer length to 0.
  * @param buf The buffer to truncate.
  * @return The original buffer, for chaining..
  */
  function truncate(
    buffer memory buf
  )
    internal
    pure
    returns (
      buffer memory
    )
  {
    assembly {
      let bufptr := mload(buf)
      mstore(bufptr, 0)
    }
    return buf;
  }

  /**
  * @dev Writes a byte string to a buffer. Resizes if doing so would exceed
  *      the capacity of the buffer.
  * @param buf The buffer to append to.
  * @param off The start offset to write to.
  * @param data The data to append.
  * @param len The number of bytes to copy.
  * @return The original buffer, for chaining.
  */
  function write(
    buffer memory buf,
    uint off,
    bytes memory data,
    uint len
  )
    internal
    pure
    returns(
      buffer memory
    )
  {
    require(len <= data.length);

    if (off + len > buf.capacity) {
      resize(buf, max(buf.capacity, len + off) * 2);
    }

    uint dest;
    uint src;
    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Length of existing buffer data
      let buflen := mload(bufptr)
      // Start address = buffer address + offset + sizeof(buffer length)
      dest := add(add(bufptr, 32), off)
      // Update buffer length if we're extending it
      if gt(add(len, off), buflen) {
        mstore(bufptr, add(len, off))
      }
      src := add(data, 32)
    }

    // Copy word-length chunks while possible
    for (; len >= 32; len -= 32) {
      assembly {
        mstore(dest, mload(src))
      }
      dest += 32;
      src += 32;
    }

    // Copy remaining bytes
    uint mask = 256 ** (32 - len) - 1;
    assembly {
      let srcpart := and(mload(src), not(mask))
      let destpart := and(mload(dest), mask)
      mstore(dest, or(destpart, srcpart))
    }

    return buf;
  }

  /**
  * @dev Appends a byte string to a buffer. Resizes if doing so would exceed
  *      the capacity of the buffer.
  * @param buf The buffer to append to.
  * @param data The data to append.
  * @param len The number of bytes to copy.
  * @return The original buffer, for chaining.
  */
  function append(
    buffer memory buf,
    bytes memory data,
    uint len
  )
    internal
    pure
    returns (
      buffer memory
    )
  {
    return write(buf, buf.buf.length, data, len);
  }

  /**
  * @dev Appends a byte string to a buffer. Resizes if doing so would exceed
  *      the capacity of the buffer.
  * @param buf The buffer to append to.
  * @param data The data to append.
  * @return The original buffer, for chaining.
  */
  function append(
    buffer memory buf,
    bytes memory data
  )
    internal
    pure
    returns (
      buffer memory
    )
  {
    return write(buf, buf.buf.length, data, data.length);
  }

  /**
  * @dev Writes a byte to the buffer. Resizes if doing so would exceed the
  *      capacity of the buffer.
  * @param buf The buffer to append to.
  * @param off The offset to write the byte at.
  * @param data The data to append.
  * @return The original buffer, for chaining.
  */
  function writeUint8(
    buffer memory buf,
    uint off,
    uint8 data
  )
    internal
    pure
    returns(
      buffer memory
    )
  {
    if (off >= buf.capacity) {
      resize(buf, buf.capacity * 2);
    }

    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Length of existing buffer data
      let buflen := mload(bufptr)
      // Address = buffer address + sizeof(buffer length) + off
      let dest := add(add(bufptr, off), 32)
      mstore8(dest, data)
      // Update buffer length if we extended it
      if eq(off, buflen) {
        mstore(bufptr, add(buflen, 1))
      }
    }
    return buf;
  }

  /**
  * @dev Appends a byte to the buffer. Resizes if doing so would exceed the
  *      capacity of the buffer.
  * @param buf The buffer to append to.
  * @param data The data to append.
  * @return The original buffer, for chaining.
  */
  function appendUint8(
    buffer memory buf,
    uint8 data
  )
    internal
    pure
    returns(
      buffer memory
    )
  {
    return writeUint8(buf, buf.buf.length, data);
  }

  /**
  * @dev Writes up to 32 bytes to the buffer. Resizes if doing so would
  *      exceed the capacity of the buffer.
  * @param buf The buffer to append to.
  * @param off The offset to write at.
  * @param data The data to append.
  * @param len The number of bytes to write (left-aligned).
  * @return The original buffer, for chaining.
  */
  function write(
    buffer memory buf,
    uint off,
    bytes32 data,
    uint len
  )
    private
    pure
    returns(
      buffer memory
    )
  {
    if (len + off > buf.capacity) {
      resize(buf, (len + off) * 2);
    }

    uint mask = 256 ** len - 1;
    // Right-align data
    data = data >> (8 * (32 - len));
    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Address = buffer address + sizeof(buffer length) + off + len
      let dest := add(add(bufptr, off), len)
      mstore(dest, or(and(mload(dest), not(mask)), data))
      // Update buffer length if we extended it
      if gt(add(off, len), mload(bufptr)) {
        mstore(bufptr, add(off, len))
      }
    }
    return buf;
  }

  /**
  * @dev Writes a bytes20 to the buffer. Resizes if doing so would exceed the
  *      capacity of the buffer.
  * @param buf The buffer to append to.
  * @param off The offset to write at.
  * @param data The data to append.
  * @return The original buffer, for chaining.
  */
  function writeBytes20(
    buffer memory buf,
    uint off,
    bytes20 data
  )
    internal
    pure
    returns (
      buffer memory
    )
  {
    return write(buf, off, bytes32(data), 20);
  }

  /**
  * @dev Appends a bytes20 to the buffer. Resizes if doing so would exceed
  *      the capacity of the buffer.
  * @param buf The buffer to append to.
  * @param data The data to append.
  * @return The original buffer, for chhaining.
  */
  function appendBytes20(
    buffer memory buf,
    bytes20 data
  )
    internal
    pure
    returns (
      buffer memory
    )
  {
    return write(buf, buf.buf.length, bytes32(data), 20);
  }

  /**
  * @dev Appends a bytes32 to the buffer. Resizes if doing so would exceed
  *      the capacity of the buffer.
  * @param buf The buffer to append to.
  * @param data The data to append.
  * @return The original buffer, for chaining.
  */
  function appendBytes32(
    buffer memory buf,
    bytes32 data
  )
    internal
    pure
    returns (
      buffer memory
    )
  {
    return write(buf, buf.buf.length, data, 32);
  }

  /**
  * @dev Writes an integer to the buffer. Resizes if doing so would exceed
  *      the capacity of the buffer.
  * @param buf The buffer to append to.
  * @param off The offset to write at.
  * @param data The data to append.
  * @param len The number of bytes to write (right-aligned).
  * @return The original buffer, for chaining.
  */
  function writeInt(
    buffer memory buf,
    uint off,
    uint data,
    uint len
  )
    private
    pure
    returns(
      buffer memory
    )
  {
    if (len + off > buf.capacity) {
      resize(buf, (len + off) * 2);
    }

    uint mask = 256 ** len - 1;
    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Address = buffer address + off + sizeof(buffer length) + len
      let dest := add(add(bufptr, off), len)
      mstore(dest, or(and(mload(dest), not(mask)), data))
      // Update buffer length if we extended it
      if gt(add(off, len), mload(bufptr)) {
        mstore(bufptr, add(off, len))
      }
    }
    return buf;
  }

  /**
    * @dev Appends a byte to the end of the buffer. Resizes if doing so would
    * exceed the capacity of the buffer.
    * @param buf The buffer to append to.
    * @param data The data to append.
    * @return The original buffer.
    */
  function appendInt(
    buffer memory buf,
    uint data,
    uint len
  )
    internal
    pure
    returns(
      buffer memory
    )
  {
    return writeInt(buf, buf.buf.length, data, len);
  }
}


// File @chainlink/contracts/src/v0.8/vendor/CBORChainlink.sol@v0.2.1

library CBORChainlink {
  using BufferChainlink for BufferChainlink.buffer;

  uint8 private constant MAJOR_TYPE_INT = 0;
  uint8 private constant MAJOR_TYPE_NEGATIVE_INT = 1;
  uint8 private constant MAJOR_TYPE_BYTES = 2;
  uint8 private constant MAJOR_TYPE_STRING = 3;
  uint8 private constant MAJOR_TYPE_ARRAY = 4;
  uint8 private constant MAJOR_TYPE_MAP = 5;
  uint8 private constant MAJOR_TYPE_TAG = 6;
  uint8 private constant MAJOR_TYPE_CONTENT_FREE = 7;

  uint8 private constant TAG_TYPE_BIGNUM = 2;
  uint8 private constant TAG_TYPE_NEGATIVE_BIGNUM = 3;

  function encodeType(
    BufferChainlink.buffer memory buf,
    uint8 major,
    uint value
  )
    private
    pure
  {
    if(value <= 23) {
      buf.appendUint8(uint8((major << 5) | value));
    } else if(value <= 0xFF) {
      buf.appendUint8(uint8((major << 5) | 24));
      buf.appendInt(value, 1);
    } else if(value <= 0xFFFF) {
      buf.appendUint8(uint8((major << 5) | 25));
      buf.appendInt(value, 2);
    } else if(value <= 0xFFFFFFFF) {
      buf.appendUint8(uint8((major << 5) | 26));
      buf.appendInt(value, 4);
    } else if(value <= 0xFFFFFFFFFFFFFFFF) {
      buf.appendUint8(uint8((major << 5) | 27));
      buf.appendInt(value, 8);
    }
  }

  function encodeIndefiniteLengthType(
    BufferChainlink.buffer memory buf,
    uint8 major
  )
    private
    pure
  {
    buf.appendUint8(uint8((major << 5) | 31));
  }

  function encodeUInt(
    BufferChainlink.buffer memory buf,
    uint value
  )
    internal
    pure
  {
    encodeType(buf, MAJOR_TYPE_INT, value);
  }

  function encodeInt(
    BufferChainlink.buffer memory buf,
    int value
  )
    internal
    pure
  {
    if(value < -0x10000000000000000) {
      encodeSignedBigNum(buf, value);
    } else if(value > 0xFFFFFFFFFFFFFFFF) {
      encodeBigNum(buf, value);
    } else if(value >= 0) {
      encodeType(buf, MAJOR_TYPE_INT, uint(value));
    } else {
      encodeType(buf, MAJOR_TYPE_NEGATIVE_INT, uint(-1 - value));
    }
  }

  function encodeBytes(
    BufferChainlink.buffer memory buf,
    bytes memory value
  )
    internal
    pure
  {
    encodeType(buf, MAJOR_TYPE_BYTES, value.length);
    buf.append(value);
  }

  function encodeBigNum(
    BufferChainlink.buffer memory buf,
    int value
  )
    internal
    pure
  {
    buf.appendUint8(uint8((MAJOR_TYPE_TAG << 5) | TAG_TYPE_BIGNUM));
    encodeBytes(buf, abi.encode(uint(value)));
  }

  function encodeSignedBigNum(
    BufferChainlink.buffer memory buf,
    int input
  )
    internal
    pure
  {
    buf.appendUint8(uint8((MAJOR_TYPE_TAG << 5) | TAG_TYPE_NEGATIVE_BIGNUM));
    encodeBytes(buf, abi.encode(uint(-1 - input)));
  }

  function encodeString(
    BufferChainlink.buffer memory buf,
    string memory value
  )
    internal
    pure
  {
    encodeType(buf, MAJOR_TYPE_STRING, bytes(value).length);
    buf.append(bytes(value));
  }

  function startArray(
    BufferChainlink.buffer memory buf
  )
    internal
    pure
  {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_ARRAY);
  }

  function startMap(
    BufferChainlink.buffer memory buf
  )
    internal
    pure
  {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_MAP);
  }

  function endSequence(
    BufferChainlink.buffer memory buf
  )
    internal
    pure
  {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_CONTENT_FREE);
  }
}


// File @chainlink/contracts/src/v0.8/Chainlink.sol@v0.2.1


/**
 * @title Library for common Chainlink functions
 * @dev Uses imported CBOR library for encoding to buffer
 */
library Chainlink {
  uint256 internal constant defaultBufferSize = 256; // solhint-disable-line const-name-snakecase

  using CBORChainlink for BufferChainlink.buffer;

  struct Request {
    bytes32 id;
    address callbackAddress;
    bytes4 callbackFunctionId;
    uint256 nonce;
    BufferChainlink.buffer buf;
  }

  /**
   * @notice Initializes a Chainlink request
   * @dev Sets the ID, callback address, and callback function signature on the request
   * @param self The uninitialized request
   * @param jobId The Job Specification ID
   * @param callbackAddr The callback address
   * @param callbackFunc The callback function signature
   * @return The initialized request
   */
  function initialize(
    Request memory self,
    bytes32 jobId,
    address callbackAddr,
    bytes4 callbackFunc
  )
    internal
    pure
    returns (
      Chainlink.Request memory
    )
  {
    BufferChainlink.init(self.buf, defaultBufferSize);
    self.id = jobId;
    self.callbackAddress = callbackAddr;
    self.callbackFunctionId = callbackFunc;
    return self;
  }

  /**
   * @notice Sets the data for the buffer without encoding CBOR on-chain
   * @dev CBOR can be closed with curly-brackets {} or they can be left off
   * @param self The initialized request
   * @param data The CBOR data
   */
  function setBuffer(
    Request memory self,
    bytes memory data
  )
    internal
    pure
  {
    BufferChainlink.init(self.buf, data.length);
    BufferChainlink.append(self.buf, data);
  }

  /**
   * @notice Adds a string value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The string value to add
   */
  function add(
    Request memory self,
    string memory key,
    string memory value
  )
    internal
    pure
  {
    self.buf.encodeString(key);
    self.buf.encodeString(value);
  }

  /**
   * @notice Adds a bytes value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The bytes value to add
   */
  function addBytes(
    Request memory self,
    string memory key,
    bytes memory value
  )
    internal
    pure
  {
    self.buf.encodeString(key);
    self.buf.encodeBytes(value);
  }

  /**
   * @notice Adds a int256 value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The int256 value to add
   */
  function addInt(
    Request memory self,
    string memory key,
    int256 value
  )
    internal
    pure
  {
    self.buf.encodeString(key);
    self.buf.encodeInt(value);
  }

  /**
   * @notice Adds a uint256 value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The uint256 value to add
   */
  function addUint(
    Request memory self,
    string memory key,
    uint256 value
  )
    internal
    pure
  {
    self.buf.encodeString(key);
    self.buf.encodeUInt(value);
  }

  /**
   * @notice Adds an array of strings to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param values The array of string values to add
   */
  function addStringArray(
    Request memory self,
    string memory key,
    string[] memory values
  )
    internal
    pure
  {
    self.buf.encodeString(key);
    self.buf.startArray();
    for (uint256 i = 0; i < values.length; i++) {
      self.buf.encodeString(values[i]);
    }
    self.buf.endSequence();
  }
}


// File @chainlink/contracts/src/v0.8/interfaces/ENSInterface.sol@v0.2.1

interface ENSInterface {

  // Logged when the owner of a node assigns a new owner to a subnode.
  event NewOwner(
    bytes32 indexed node,
    bytes32 indexed label,
    address owner
  );

  // Logged when the owner of a node transfers ownership to a new account.
  event Transfer(
    bytes32 indexed node,
    address owner
  );

  // Logged when the resolver for a node changes.
  event NewResolver(
    bytes32 indexed node,
    address resolver
  );

  // Logged when the TTL of a node changes
  event NewTTL(
    bytes32 indexed node,
    uint64 ttl
  );


  function setSubnodeOwner(
    bytes32 node,
    bytes32 label,
    address owner
  ) external;

  function setResolver(
    bytes32 node,
    address resolver
  ) external;

  function setOwner(
    bytes32 node,
    address owner
  ) external;

  function setTTL(
    bytes32 node,
    uint64 ttl
  ) external;

  function owner(
    bytes32 node
  )
    external
    view
    returns (
      address
    );

  function resolver(
    bytes32 node
  )
    external
    view
    returns (
      address
    );

  function ttl(
    bytes32 node
  )
    external
    view
    returns (
      uint64
    );

}


// File @chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol@v0.2.1

interface LinkTokenInterface {

  function allowance(
    address owner,
    address spender
  )
    external
    view
    returns (
      uint256 remaining
    );

  function approve(
    address spender,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function balanceOf(
    address owner
  )
    external
    view
    returns (
      uint256 balance
    );

  function decimals()
    external
    view
    returns (
      uint8 decimalPlaces
    );

  function decreaseApproval(
    address spender,
    uint256 addedValue
  )
    external
    returns (
      bool success
    );

  function increaseApproval(
    address spender,
    uint256 subtractedValue
  ) external;

  function name()
    external
    view
    returns (
      string memory tokenName
    );

  function symbol()
    external
    view
    returns (
      string memory tokenSymbol
    );

  function totalSupply()
    external
    view
    returns (
      uint256 totalTokensIssued
    );

  function transfer(
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  )
    external
    returns (
      bool success
    );

  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

}


// File @chainlink/contracts/src/v0.8/interfaces/OracleInterface.sol@v0.2.1

interface OracleInterface {
  function fulfillOracleRequest(
    bytes32 requestId,
    uint256 payment,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 expiration,
    bytes32 data
  )
    external
    returns (
      bool
    );

  function isAuthorizedSender(
    address node
  )
    external
    view
    returns (
      bool
    );

  function withdraw(
    address recipient,
    uint256 amount
  ) external;

  function withdrawable()
    external
    view
    returns (
      uint256
    );
}


// File @chainlink/contracts/src/v0.8/interfaces/ChainlinkRequestInterface.sol@v0.2.1

interface ChainlinkRequestInterface {
  function oracleRequest(
    address sender,
    uint256 requestPrice,
    bytes32 serviceAgreementID,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 nonce,
    uint256 dataVersion,
    bytes calldata data
  ) external;

  function cancelOracleRequest(
    bytes32 requestId,
    uint256 payment,
    bytes4 callbackFunctionId,
    uint256 expiration
  ) external;
}


// File @chainlink/contracts/src/v0.8/interfaces/OperatorInterface.sol@v0.2.1


interface OperatorInterface is OracleInterface, ChainlinkRequestInterface {

  function requestOracleData(
    address sender,
    uint256 payment,
    bytes32 specId,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 nonce,
    uint256 dataVersion,
    bytes calldata data
  )
    external;

  function fulfillOracleRequest2(
    bytes32 requestId,
    uint256 payment,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 expiration,
    bytes calldata data
  )
    external
    returns (
      bool
    );

  function ownerTransferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  )
    external
    returns (
      bool success
    );

  function distributeFunds(
    address payable[] calldata receivers,
    uint[] calldata amounts
  )
    external
    payable;

  function getAuthorizedSenders()
    external
    returns (
      address[] memory
    );

  function setAuthorizedSenders(
    address[] calldata senders
  ) external;

  function getForwarder()
    external
    returns (
      address
    );
}


// File @chainlink/contracts/src/v0.8/interfaces/PointerInterface.sol@v0.2.1

interface PointerInterface {

  function getAddress()
    external
    view
    returns (
      address
    );
}


// File @chainlink/contracts/src/v0.8/vendor/ENSResolver.sol@v0.2.1

abstract contract ENSResolver {
  function addr(
    bytes32 node
  )
    public
    view
    virtual
    returns (
      address
    );
}


// File @chainlink/contracts/src/v0.8/ChainlinkClient.sol@v0.2.1






/**
 * @title The ChainlinkClient contract
 * @notice Contract writers can inherit this contract in order to create requests for the
 * Chainlink network
 */
contract ChainlinkClient {
  using Chainlink for Chainlink.Request;

  uint256 constant internal LINK_DIVISIBILITY = 10**18;
  uint256 constant private AMOUNT_OVERRIDE = 0;
  address constant private SENDER_OVERRIDE = address(0);
  uint256 constant private ORACLE_ARGS_VERSION = 1;
  uint256 constant private OPERATOR_ARGS_VERSION = 2;
  bytes32 constant private ENS_TOKEN_SUBNAME = keccak256("link");
  bytes32 constant private ENS_ORACLE_SUBNAME = keccak256("oracle");
  address constant private LINK_TOKEN_POINTER = 0xC89bD4E1632D3A43CB03AAAd5262cbe4038Bc571;

  ENSInterface private ens;
  bytes32 private ensNode;
  LinkTokenInterface private link;
  OperatorInterface private oracle;
  uint256 private requestCount = 1;
  mapping(bytes32 => address) private pendingRequests;

  event ChainlinkRequested(
    bytes32 indexed id
  );
  event ChainlinkFulfilled(
    bytes32 indexed id
  );
  event ChainlinkCancelled(
    bytes32 indexed id
  );

  /**
   * @notice Creates a request that can hold additional parameters
   * @param specId The Job Specification ID that the request will be created for
   * @param callbackAddress The callback address that the response will be sent to
   * @param callbackFunctionSignature The callback function signature to use for the callback address
   * @return A Chainlink Request struct in memory
   */
  function buildChainlinkRequest(
    bytes32 specId,
    address callbackAddress,
    bytes4 callbackFunctionSignature
  )
    internal
    pure
    returns (
      Chainlink.Request memory
    )
  {
    Chainlink.Request memory req;
    return req.initialize(specId, callbackAddress, callbackFunctionSignature);
  }

  /**
   * @notice Creates a Chainlink request to the stored oracle address
   * @dev Calls `chainlinkRequestTo` with the stored oracle address
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendChainlinkRequest(
    Chainlink.Request memory req,
    uint256 payment
  )
    internal
    returns (
      bytes32
    )
  {
    return sendChainlinkRequestTo(address(oracle), req, payment);
  }

  /**
   * @notice Creates a Chainlink request to the specified oracle address
   * @dev Generates and stores a request ID, increments the local nonce, and uses `transferAndCall` to
   * send LINK which creates a request on the target oracle contract.
   * Emits ChainlinkRequested event.
   * @param oracleAddress The address of the oracle for the request
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendChainlinkRequestTo(
    address oracleAddress,
    Chainlink.Request memory req,
    uint256 payment
  )
    internal
    returns (
      bytes32 requestId
    )
  {
    return rawRequest(oracleAddress, req, payment, ORACLE_ARGS_VERSION, oracle.oracleRequest.selector);
  }

  /**
   * @notice Creates a Chainlink request to the stored oracle address
   * @dev This function supports multi-word response
   * @dev Calls `requestOracleDataFrom` with the stored oracle address
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function requestOracleData(
    Chainlink.Request memory req,
    uint256 payment
  )
    internal
    returns (
      bytes32
    )
  {
    return requestOracleDataFrom(address(oracle), req, payment);
  }

  /**
   * @notice Creates a Chainlink request to the specified oracle address
   * @dev This function supports multi-word response
   * @dev Generates and stores a request ID, increments the local nonce, and uses `transferAndCall` to
   * send LINK which creates a request on the target oracle contract.
   * Emits ChainlinkRequested event.
   * @param oracleAddress The address of the oracle for the request
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function requestOracleDataFrom(
    address oracleAddress,
    Chainlink.Request memory req,
    uint256 payment
  )
    internal
    returns (
      bytes32 requestId
    )
  {
    return rawRequest(oracleAddress, req, payment, OPERATOR_ARGS_VERSION, oracle.requestOracleData.selector);
  }

  /**
   * @notice Make a request to an oracle
   * @param oracleAddress The address of the oracle for the request
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @param argsVersion The version of data support (single word, multi word)
   * @return requestId The request ID
   */
  function rawRequest(
    address oracleAddress,
    Chainlink.Request memory req,
    uint256 payment,
    uint256 argsVersion,
    bytes4 funcSelector
  )
    private
    returns (
      bytes32 requestId
    )
  {
    requestId = keccak256(abi.encodePacked(this, requestCount));
    req.nonce = requestCount;
    pendingRequests[requestId] = oracleAddress;
    emit ChainlinkRequested(requestId);
    bytes memory encodedData = abi.encodeWithSelector(
      funcSelector,
      SENDER_OVERRIDE, // Sender value - overridden by onTokenTransfer by the requesting contract's address
      AMOUNT_OVERRIDE, // Amount value - overridden by onTokenTransfer by the actual amount of LINK sent
      req.id,
      req.callbackAddress,
      req.callbackFunctionId,
      req.nonce,
      argsVersion,
      req.buf.buf);
    require(link.transferAndCall(oracleAddress, payment, encodedData), "unable to transferAndCall to oracle");
    requestCount += 1;
  }

  /**
   * @notice Allows a request to be cancelled if it has not been fulfilled
   * @dev Requires keeping track of the expiration value emitted from the oracle contract.
   * Deletes the request from the `pendingRequests` mapping.
   * Emits ChainlinkCancelled event.
   * @param requestId The request ID
   * @param payment The amount of LINK sent for the request
   * @param callbackFunc The callback function specified for the request
   * @param expiration The time of the expiration for the request
   */
  function cancelChainlinkRequest(
    bytes32 requestId,
    uint256 payment,
    bytes4 callbackFunc,
    uint256 expiration
  )
    internal
  {
    OperatorInterface requested = OperatorInterface(pendingRequests[requestId]);
    delete pendingRequests[requestId];
    emit ChainlinkCancelled(requestId);
    requested.cancelOracleRequest(requestId, payment, callbackFunc, expiration);
  }

  /**
   * @notice Sets the stored oracle address
   * @param oracleAddress The address of the oracle contract
   */
  function setChainlinkOracle(
    address oracleAddress
  )
    internal
  {
    oracle = OperatorInterface(oracleAddress);
  }

  /**
   * @notice Sets the LINK token address
   * @param linkAddress The address of the LINK token contract
   */
  function setChainlinkToken(
    address linkAddress
  )
    internal
  {
    link = LinkTokenInterface(linkAddress);
  }

  /**
   * @notice Sets the Chainlink token address for the public
   * network as given by the Pointer contract
   */
  function setPublicChainlinkToken()
    internal
  {
    setChainlinkToken(PointerInterface(LINK_TOKEN_POINTER).getAddress());
  }

  /**
   * @notice Retrieves the stored address of the LINK token
   * @return The address of the LINK token
   */
  function chainlinkTokenAddress()
    internal
    view
    returns (
      address
    )
  {
    return address(link);
  }

  /**
   * @notice Retrieves the stored address of the oracle contract
   * @return The address of the oracle contract
   */
  function chainlinkOracleAddress()
    internal
    view
    returns (
      address
    )
  {
    return address(oracle);
  }

  /**
   * @notice Allows for a request which was created on another contract to be fulfilled
   * on this contract
   * @param oracleAddress The address of the oracle contract that will fulfill the request
   * @param requestId The request ID used for the response
   */
  function addChainlinkExternalRequest(
    address oracleAddress,
    bytes32 requestId
  )
    internal
    notPendingRequest(requestId)
  {
    pendingRequests[requestId] = oracleAddress;
  }

  /**
   * @notice Sets the stored oracle and LINK token contracts with the addresses resolved by ENS
   * @dev Accounts for subnodes having different resolvers
   * @param ensAddress The address of the ENS contract
   * @param node The ENS node hash
   */
  // function useChainlinkWithENS(
  //   address ensAddress,
  //   bytes32 node
  // )
  //   internal
  // {
  //   ens = ENSInterface(ensAddress);
  //   ensNode = node;
  //   bytes32 linkSubnode = keccak256(abi.encodePacked(ensNode, ENS_TOKEN_SUBNAME));
  //   ENSResolver_Chainlink resolver = ENSResolver_Chainlink(ens.resolver(linkSubnode));
  //   setChainlinkToken(resolver.addr(linkSubnode));
  //   updateChainlinkOracleWithENS();
  // }

  // /**
  //  * @notice Sets the stored oracle contract with the address resolved by ENS
  //  * @dev This may be called on its own as long as `useChainlinkWithENS` has been called previously
  //  */
  // function updateChainlinkOracleWithENS()
  //   internal
  // {
  //   bytes32 oracleSubnode = keccak256(abi.encodePacked(ensNode, ENS_ORACLE_SUBNAME));
  //   ENSResolver_Chainlink resolver = ENSResolver_Chainlink(ens.resolver(oracleSubnode));
  //   setChainlinkOracle(resolver.addr(oracleSubnode));
  // }

  /**
   * @notice Ensures that the fulfillment is valid for this contract
   * @dev Use if the contract developer prefers methods instead of modifiers for validation
   * @param requestId The request ID for fulfillment
   */
  function validateChainlinkCallback(
    bytes32 requestId
  )
    internal
    recordChainlinkFulfillment(requestId)
    // solhint-disable-next-line no-empty-blocks
  {}

  /**
   * @dev Reverts if the sender is not the oracle of the request.
   * Emits ChainlinkFulfilled event.
   * @param requestId The request ID for fulfillment
   */
  modifier recordChainlinkFulfillment(
    bytes32 requestId
  )
  {
    require(msg.sender == pendingRequests[requestId],
            "Source must be the oracle of the request");
    delete pendingRequests[requestId];
    emit ChainlinkFulfilled(requestId);
    _;
  }

  /**
   * @dev Reverts if the request is already pending
   * @param requestId The request ID for fulfillment
   */
  modifier notPendingRequest(
    bytes32 requestId
  )
  {
    require(pendingRequests[requestId] == address(0), "Request is already pending");
    _;
  }
}


// File contracts/Janus.sol

/*===============================
       __
      / /___ _____  __  _______
 __  / / __ `/ __ \/ / / / ___/
/ /_/ / /_/ / / / / /_/ (__  )
\____/\__,_/_/ /_/\__,_/____/

===============================*/
contract Janus is ChainlinkClient {

    address owner;

    //===================================
    // Chainlink Stuff
    //===================================

    using Chainlink for Chainlink.Request;

    bytes32 private jobId;
    uint256 private fee;

    mapping(bytes32 => address) public requestIdToAddress;
    mapping(bytes32 => bool) public requestIdFulfilled;

    event RequestFulfilled(bytes32 indexed requestId, uint256 indexed score);

    //===================================
    // Janus Stuff
    //===================================

    mapping(address => IdentityData) public identityData;
    mapping(uint256 => mapping(address => bool) ) public _postLikedByAddress;

    struct IdentityData {
        uint256 score;
        string metaData;
        uint256 lastUpdated;
    }

    event DataUpdated (
        address indexed _address,
        uint256 _score,
        string _metaData,
        uint256 _lastUpdated
    );

    constructor() {
        owner = msg.sender;
        setChainlinkOracle(0xb33D8A4e62236eA91F3a8fD7ab15A95B9B7eEc7D);
        setChainlinkToken(0x326C977E6efc84E512bB9C30f76E30c160eD06FB);
        jobId = "da20aae0e4c843f6949e5cb3f7cfe8c4";
        fee = 0.01 * (10 ** 18); // 0.01 LINK
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Janus:OnlyOwner");
        _;
    }

    function withdrawLink() public onlyOwner {
        LinkTokenInterface _link = LinkTokenInterface(chainlinkTokenAddress());
        require(_link.transfer(msg.sender, _link.balanceOf(address(this))), "Unable to transfer");
    }

    function updateScore( address add, uint256 score, string memory metaData )
        public onlyOwner
    {
        identityData[add] = IdentityData(score, metaData, block.timestamp);

        emit DataUpdated(add, score, metaData, block.timestamp);
    }

    function updateScoreManual(address _add)
        external payable
    {
        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);

        string memory reqApiAddress = string(abi.encodePacked(
            "https://janus.anudit.dev/api?address=",
            toAsciiString(_add),
            "&apikey=CONVO"
        ));

        request.add("get", reqApiAddress);

        string[] memory path = new string[](1);
        path[0] = "score";
        request.addStringArray("path", path);

        bytes32 requestId = sendChainlinkRequest(request, fee);
        requestIdToAddress[requestId] = _add;
    }

    function fulfill(bytes32 _requestId, uint256 _score) public recordChainlinkFulfillment(_requestId) {
        require(requestIdFulfilled[_requestId] == false, "Janus:Request already Fulfilled");
        emit RequestFulfilled(_requestId, _score);
        address _add = requestIdToAddress[_requestId];
        identityData[_add] = IdentityData(_score, "", block.timestamp);
        emit DataUpdated(_add, _score, "", block.timestamp);
    }

    function toAsciiString(address x) internal pure returns (string memory) {
      bytes memory s = new bytes(40);
      for (uint i = 0; i < 20; i++) {
          bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
          bytes1 hi = bytes1(uint8(b) / 16);
          bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
          s[2*i] = char(hi);
          s[2*i+1] = char(lo);
      }
      return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
      if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
      else return bytes1(uint8(b) + 0x57);
    }

}