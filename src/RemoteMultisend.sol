// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MessageDependencyChecker} from "./MessageDependencyChecker.sol";
import {PredeployAddresses} from "@interop-lib/libraries/PredeployAddresses.sol";
import {IL2ToL2CrossDomainMessenger} from "@interop-lib/interfaces/IL2ToL2CrossDomainMessenger.sol";
import {ISuperchainWETH} from "@interop-lib/interfaces/ISuperchainWETH.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

error Unauthorized();
error IncorrectValue();
error CallerNotL2ToL2CrossDomainMessenger();
error InvalidCrossDomainSender();

contract RemoteMultisend {
    struct Send {
        address to;
        uint256 amount;
    }

    ISuperchainWETH internal immutable superchainWeth = ISuperchainWETH(payable(PredeployAddresses.SUPERCHAIN_WETH));
    IL2ToL2CrossDomainMessenger internal immutable l2ToL2CrossDomainMessenger =
        IL2ToL2CrossDomainMessenger(PredeployAddresses.L2_TO_L2_CROSS_DOMAIN_MESSENGER);

    function send(uint256 _destinationChainId, Send[] calldata _sends) public payable returns (bytes32) {
        uint256 totalAmount;
        for (uint256 i; i < _sends.length; i++) {
            totalAmount += _sends[i].amount;
        }

        if (msg.value != totalAmount) revert IncorrectValue();

        bytes32 sendWethMsgHash = superchainWeth.sendETH{value: totalAmount}(address(this), _destinationChainId);

        return l2ToL2CrossDomainMessenger.sendMessage(
            _destinationChainId, address(this), abi.encodeCall(this.relay, (sendWethMsgHash, _sends))
        );
    }

    function relay(bytes32 _sendWethMsgHash, Send[] calldata _sends) public onlyCrossDomainCallback {
        MessageDependencyChecker.requireMsgSuccess(_sendWethMsgHash);

        for (uint256 i; i < _sends.length; i++) {
            Address.sendValue(payable(_sends[i].to), _sends[i].amount);
        }
    }

    modifier onlyCrossDomainCallback() {
        if (msg.sender != address(l2ToL2CrossDomainMessenger)) revert CallerNotL2ToL2CrossDomainMessenger();
        if (l2ToL2CrossDomainMessenger.crossDomainMessageSender() != address(this)) revert InvalidCrossDomainSender();

        _;
    }
}
