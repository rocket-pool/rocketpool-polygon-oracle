// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "@fx-portal/tunnel/FxBaseChildTunnel.sol";

contract PolygonStateSenderMock {
    function sendMessageToChild(address _receiver, bytes calldata _data) external {
        IFxMessageProcessor(_receiver).processMessageFromRoot(0, msg.sender, _data);
    }
}
