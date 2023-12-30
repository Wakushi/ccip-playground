// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {OwnerIsCreator} from "@chainlink/contracts-ccip/src/v0.8/shared/access/OwnerIsCreator.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {IERC20} from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";

contract CCIPTokenSender is OwnerIsCreator {
    IRouterClient immutable i_router;
    LinkTokenInterface immutable i_linkToken;

    mapping(uint64 chainSelector => bool whitelisted)
        public s_whitelistedChains;

    error NotEnoughBalance(uint256 _currentBalance, uint256 _requiredFees);
    error ChainNotWhitelisted(uint64 _destinationChainSelector);
    error NothingToWithdraw(address _token);

    event TokensTransferred(
        bytes32 indexed messageId, // The unique ID of the message.
        uint64 indexed destinationChainSelector, // The chain selector of the destination chain.
        address receiver, // The address of the receiver on the destination chain.
        address token, // The token address that was transferred.
        uint256 tokenAmount, // The token amount that was transferred.
        address feeToken, // the token address used to pay CCIP fees.
        uint256 fees // The fees paid for sending the message.
    );

    modifier onlyWhitelistedChain(uint64 _destinationChainSelector) {
        if (!s_whitelistedChains[_destinationChainSelector]) {
            revert ChainNotWhitelisted(_destinationChainSelector);
        }
        _;
    }

    constructor(address _link, address _router) {
        i_router = IRouterClient(_router);
        i_linkToken = LinkTokenInterface(_link);
    }

    function whitelistChain(
        uint64 _destinationChainSelector
    ) external onlyOwner {
        s_whitelistedChains[_destinationChainSelector] = true;
    }

    function denylistChain(
        uint64 _destinationChainSelector
    ) external onlyOwner {
        s_whitelistedChains[_destinationChainSelector] = false;
    }

    // @notice The user should first send the tokens to this contract
    function transferTokens(
        uint64 _destinationChainSelector,
        address _receiver,
        address _token,
        uint256 _amount
    )
        external
        onlyOwner
        onlyWhitelistedChain(_destinationChainSelector)
        returns (bytes32 messageId)
    {
        Client.EVMTokenAmount[]
            memory tokenAmounts = new Client.EVMTokenAmount[](1);
        Client.EVMTokenAmount memory tokenAmount = Client.EVMTokenAmount({
            token: _token,
            amount: _amount
        });
        tokenAmounts[0] = tokenAmount;

        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(_receiver),
            data: "", // Only tokens are being sent
            tokenAmounts: tokenAmounts,
            extraArgs: Client._argsToBytes(
                Client.EVMExtraArgsV1({gasLimit: 0})
            ),
            feeToken: address(i_linkToken)
        });

        uint256 fees = i_router.getFee(_destinationChainSelector, message);
        if (fees > i_linkToken.balanceOf(address(this))) {
            revert NotEnoughBalance(i_linkToken.balanceOf(address(this)), fees);
        }

        i_linkToken.approve(address(i_router), fees);
        IERC20(_token).approve(address(i_router), _amount);

        messageId = i_router.ccipSend(_destinationChainSelector, message);

        emit TokensTransferred(
            messageId,
            _destinationChainSelector,
            _receiver,
            _token,
            _amount,
            address(i_linkToken),
            fees
        );
    }

    function withdrawTokens(
        address _token,
        address _beneficiary
    ) public onlyOwner {
        uint256 amount = IERC20(_token).balanceOf(address(this));
        if (amount == 0) {
            revert NothingToWithdraw(_token);
        }
        IERC20(_token).transfer(_beneficiary, amount);
    }
}
