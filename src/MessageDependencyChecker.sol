// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PredeployAddresses} from "@interop-lib/libraries/PredeployAddresses.sol";
import {IL2ToL2CrossDomainMessenger} from "@interop-lib/interfaces/IL2ToL2CrossDomainMessenger.sol";

error DependentMessageNotSuccessful(bytes32 msgHash);

library MessageDependencyChecker {
    function requireMsgSuccess(bytes32 msgHash) internal view {
        if (
            !IL2ToL2CrossDomainMessenger(PredeployAddresses.L2_TO_L2_CROSS_DOMAIN_MESSENGER).successfulMessages(msgHash)
        ) {
            revert DependentMessageNotSuccessful(msgHash);
        }
    }
}
