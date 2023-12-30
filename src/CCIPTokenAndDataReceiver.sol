// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {ERC721URIStorage, ERC721} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {OwnerIsCreator} from "@chainlink/contracts-ccip/src/v0.8/shared/access/OwnerIsCreator.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {IERC20} from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";

contract MyNFT is ERC721URIStorage, OwnerIsCreator {
    string constant TOKEN_URI =
        "https://ipfs.io/ipfs/QmYuKY45Aq87LeL1R5dhb1hqHLp6ZFbJaCP8jxqKM1MX6y/babe_ruth_1.json";
    uint256 internal tokenId;

    constructor() ERC721("MyNFT", "MNFT") {}

    function mint(address to) public onlyOwner {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, TOKEN_URI);
        unchecked {
            tokenId++;
        }
    }
}

contract CCIPTokenAndDataReceiver is CCIPReceiver, OwnerIsCreator {
    MyNFT public s_nft;
    uint256 public s_mintPrice;
    mapping(uint64 chainSelector => bool whitelisted)
        public s_whitelistedSourceChains;
    mapping(address sender => bool whitelisted) public s_whitelistedSenders;

    event MintCallSuccessfull();

    error CCIPTokenAndDataReceiver_NotEnoughFunds();
    error CCIPTokenAndDataReceiver_ExternalMintCallFailed();
    error ChainNotWhitelisted(uint64 _destinationChainSelector);
    error SenderNotWhitelisted(address _sender);

    modifier onlyWhitelistedChain(uint64 _destinationChainSelector) {
        if (!s_whitelistedSourceChains[_destinationChainSelector]) {
            revert ChainNotWhitelisted(_destinationChainSelector);
        }
        _;
    }

    modifier onlyWhitelistedSender(address _sender) {
        if (!s_whitelistedSenders[_sender]) {
            revert SenderNotWhitelisted(_sender);
        }
        _;
    }

    constructor(address _router, uint256 _price) CCIPReceiver(_router) {
        s_mintPrice = _price;
        s_nft = new MyNFT();
    }

    function whitelistChain(
        uint64 _destinationChainSelector
    ) external onlyOwner {
        s_whitelistedSourceChains[_destinationChainSelector] = true;
    }

    function denylistChain(
        uint64 _destinationChainSelector
    ) external onlyOwner {
        s_whitelistedSourceChains[_destinationChainSelector] = false;
    }

    function whitelistSender(address _sender) external onlyOwner {
        s_whitelistedSenders[_sender] = true;
    }

    function denylistSender(address _sender) external onlyOwner {
        s_whitelistedSenders[_sender] = false;
    }

    function _ccipReceive(
        Client.Any2EVMMessage memory message
    )
        internal
        override
        onlyWhitelistedSender(abi.decode(message.sender, (address)))
        onlyWhitelistedChain(message.sourceChainSelector)
    {
        if (message.destTokenAmounts[0].amount < s_mintPrice) {
            revert CCIPTokenAndDataReceiver_NotEnoughFunds();
        }
        (bool success, ) = address(s_nft).call(message.data);
        if (!success) {
            revert CCIPTokenAndDataReceiver_ExternalMintCallFailed();
        }
        emit MintCallSuccessfull();
    }
}
