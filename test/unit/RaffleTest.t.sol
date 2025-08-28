//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig, CodeConstants} from "script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract RaffleTest is Test, CodeConstants {
    Raffle raffle;
    HelperConfig helperConfig;
    uint256 constant STARTING_PLAYER_BALANCE = 10 ether;

    //Events
    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);

    uint256 entryFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint256 subId;
    uint32 callbackGasLimit;

    address PLAYER = makeAddr("player");

    function setUp() public {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        entryFee = config.raffleEntranceFee;
        interval = config.automationUpdateInterval;
        vrfCoordinator = config.vrfCoordinatorV2_5;
        gasLane = config.gasLane;
        subId = config.subscriptionId;
        callbackGasLimit = config.callbackGasLimit;

        vm.deal(PLAYER, STARTING_PLAYER_BALANCE);
    }

    modifier raffleEntered() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entryFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
    }

    function testRaffleInitializesInOpenState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    function testRaffleRevertsWhenYouDontPayEnough() public {
        vm.prank(PLAYER);
        vm.expectRevert(Raffle.Raffle__SendMoreToEnterRaffle.selector);
        raffle.enterRaffle();
    }

    function testRaffleEntersPlayer() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entryFee}();
        address playerRecorded = raffle.getPlayer(0);
        assert(playerRecorded == PLAYER);
    }

    function testEnterRaffleEmitsEventOnEntrance() public {
        vm.prank(PLAYER);
        vm.expectEmit(true, false, false, false, address(raffle));
        emit RaffleEntered(PLAYER);
        raffle.enterRaffle{value: entryFee}();
    }

    function testDontAllowEntranceWhenRaffleIsCalculating()
        public
        raffleEntered
    {
        raffle.performUpKeep("");

        vm.prank(PLAYER);
        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        raffle.enterRaffle{value: entryFee}();
    }

    function testCheckUpkeepReturnsFalseIfNoBalance() public {
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsFalseIfRaffleNotOpen() public raffleEntered {
        raffle.performUpKeep("");

        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(!upkeepNeeded);
    }

    function testPerformUpkeepCanOnlyRunIfCheckUpkeepIsTrue()
        public
        raffleEntered
    {
        raffle.performUpKeep("");
    }

    function testPerformUpkeepRevertsIfCheckUpkeepIsFalse() public {
        uint256 currentBalance = 0;
        uint256 currentPlayers = 0;
        Raffle.RaffleState currentState = raffle.getRaffleState();

        vm.expectRevert(
            abi.encode(
                Raffle.Raffle__UpkeepNotNeeded.selector,
                currentBalance,
                currentPlayers,
                currentState
            )
        );
        raffle.performUpKeep("");
    }

    function testPerformUpkeepUpdatesRaffleStateAndEmitsRequestId()
        public
        raffleEntered
    {
        vm.recordLogs();
        raffle.performUpKeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();

        bytes32 requestIdTopic = entries[1].topics[1];
        assert(uint256(requestIdTopic) > 0);
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        assert(uint256(raffleState) == 1);
    }

    modifier skipFork() {
        if (block.chainid != LOCAL_CHAIN_ID) {
            return;
        }
        _;
    }

    function testFulfillRandomWordsCanOnlyBeCalledAfterPerformUpkeep(
        uint256 randomRequestId
    ) public skipFork {
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(
            randomRequestId,
            address(raffle)
        );
    }

    function testFulfillRandomWordsPicksAWinnerResetsAndSendsMoney()
        public
        raffleEntered
        skipFork
    {
        uint256 additionalEntrants = 3;
        uint256 startingIndex = 1;
        address expectedWinner = address(1);

        for (
            uint256 i = startingIndex;
            i < startingIndex + additionalEntrants;
            i++
        ) {
            address newPlayer = address(uint160(i));
            hoax(newPlayer, 1 ether);
            raffle.enterRaffle{value: entryFee}();
        }

        uint256 startingTimestamp = raffle.getLastTimestamp();
        uint256 winnerStartingBalance = expectedWinner.balance;

        vm.recordLogs();
        raffle.performUpKeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestIdTopic = entries[1].topics[1];
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(
            uint256(requestIdTopic),
            address(raffle)
        );

        address recentWinner = raffle.getRecentWinner();
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        uint256 winnerEndingBalance = recentWinner.balance;
        uint256 endingTimeStamp = raffle.getLastTimestamp();
        uint256 prize = entryFee * (additionalEntrants + 1);

        assert(recentWinner == expectedWinner);
        assert(raffleState == Raffle.RaffleState.OPEN);
        assert(winnerEndingBalance == winnerStartingBalance + prize);
        assert(endingTimeStamp > startingTimestamp);
    }
}
