// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console2.sol";

import "../src/mock/RocketStorageMock.sol";
import "../src/mock/RocketNetworkBalancesMock.sol";
import "../src/mock/PolygonStateSenderMock.sol";

import "../src/RocketPolygonPriceOracle.sol";
import "../src/RocketPolygonPriceMessenger.sol";

/// @author Kane Wallmann (Rocket Pool)
contract RocketPolygonPriceOracleTest is Test {
    RocketStorageMock rocketStorage;
    RocketNetworkBalancesMock rocketNetworkBalances;
    PolygonStateSenderMock polygonStateSenderMock;

    RocketPolygonPriceOracle priceOracle;
    RocketPolygonPriceMessenger priceMessenger;

    // Events
    event RateUpdated(uint256 rate);

    function setUp() public {
        // Create mocks
        rocketStorage = new RocketStorageMock();
        rocketNetworkBalances = new RocketNetworkBalancesMock();
        polygonStateSenderMock = new PolygonStateSenderMock();
        // Set rocketNetworkBalances address to mock
        rocketStorage.setAddress(
            keccak256(abi.encodePacked("contract.address", "rocketNetworkBalances")),
            address(rocketNetworkBalances)
        );
        // Set starting rate to 1:1
        rocketNetworkBalances.setTotalETHBalance(1 ether);
        rocketNetworkBalances.setTotalRETHSupply(1 ether);
        // Create the price oracle (on L2)
        priceOracle = new RocketPolygonPriceOracle(address(polygonStateSenderMock));
        // Create the messenger
        priceMessenger = new RocketPolygonPriceMessenger(
            RocketStorageInterface(address(rocketStorage)),
            address(0), // Unused
            address(polygonStateSenderMock)
        );
        // Setup tunnel
        priceMessenger.setFxChildTunnel(address(priceOracle));
        priceOracle.setFxRootTunnel(address(priceMessenger));
        // Rate and last updated should be 0
        uint256 rate = priceOracle.rate();
        uint256 updated = priceOracle.lastUpdated();
        assertEq(updated, 0);
        assertEq(rate, 0);
    }

    function testResetTunnel() public {
        vm.expectRevert("FxBaseRootTunnel: CHILD_TUNNEL_ALREADY_SET");
        priceMessenger.setFxChildTunnel(address(priceOracle));
        vm.expectRevert("FxBaseChildTunnel: ROOT_TUNNEL_ALREADY_SET");
        priceOracle.setFxRootTunnel(address(priceOracle));
    }

    function testRates(uint256 ethTotal, uint256 rethSupply) public {
        vm.assume(ethTotal < 1_000_000 ether);
        vm.assume(rethSupply < 1_000_000 ether);
        // Set the rate
        rocketNetworkBalances.setTotalETHBalance(ethTotal);
        rocketNetworkBalances.setTotalRETHSupply(rethSupply);
        // Calculate expected rate
        uint256 expectedRate;
        if (rethSupply == 0) {
            expectedRate = 0;
        } else {
            expectedRate = 1 ether * ethTotal / rethSupply;
        }
        // Expect event
        vm.expectEmit(false, false, false, true);
        emit RateUpdated(expectedRate);
        // Send the updated rate
        priceMessenger.submitRate();
        // Check rate and lastUpdated were updated
        uint256 rate = priceOracle.rate();
        assertEq(rate, expectedRate);
    }

    function testRateStale() public {
        // Rate should be stale
        assertTrue(priceMessenger.rateStale());
        // Send the updated rate
        priceMessenger.submitRate();
        // Rate should no longer be stale
        assertFalse(priceMessenger.rateStale());
        // Change rate again
        rocketNetworkBalances.setTotalETHBalance(1.5 ether);
        // Rate should be stale
        assertTrue(priceMessenger.rateStale());
    }

    function testCanSendRate() public {
        // Expect event
        vm.expectEmit(false, false, false, true);
        emit RateUpdated(1 ether);
        // Anyone can call submitRate
        vm.prank(address(0));
        // Send the updated rate
        priceMessenger.submitRate();
        // Check rate and lastUpdated were updated
        uint256 rate = priceOracle.rate();
        uint256 updated = priceOracle.lastUpdated();
        assertGt(updated, 0);
        assertEq(rate, 1 ether);
    }

    function testDirectUpdateRate() public {
        vm.expectRevert();
        priceOracle.updateRate(1.4 ether);
    }
}
