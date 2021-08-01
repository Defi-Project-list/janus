/*===============================
       __
      / /___ _____  __  _______
 __  / / __ `/ __ \/ / / / ___/
/ /_/ / /_/ / / / / /_/ (__  )
\____/\__,_/_/ /_/\__,_/____/

===============================*/

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.4 <0.9.0;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

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
