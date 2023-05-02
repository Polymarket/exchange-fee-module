// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { ERC20 } from "solmate/tokens/ERC20.sol";
import { ERC1155 } from "solmate/tokens/ERC1155.sol";
import { IERC20 } from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import { IERC1155 } from "openzeppelin-contracts/token/ERC1155/IERC1155.sol";

import { TestHelper } from "./TestHelper.sol";
import { Deployer } from "./Deployer.sol";
import { OrderLib } from "./OrderLib.sol";

import { IConditionalTokens } from "../interfaces/IConditionalTokens.sol";
import { IExchangeEE, IExchange } from "../interfaces/IExchange.sol";

import { FeeModule } from "src/FeeModule.sol";
import { Order, Side, OrderStatus } from "src/libraries/Structs.sol";
import { CalculatorHelper } from "src/libraries/CalculatorHelper.sol";

import { IAuthEE } from "src/interfaces/IAuth.sol";
import { IFeeModuleEE } from "src/interfaces/IFeeModule.sol";

contract Token is ERC20 {
    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol, 6) { }
}

contract FeeModuleTestHelper is TestHelper, IAuthEE, IExchangeEE, IFeeModuleEE {
    address public admin = alice;

    // Order Signers
    uint256 internal bobPK = 0xB0B;
    uint256 internal carlaPK = 0xCA414;
    address public bob;
    address public carla;

    // Tokens
    address public usdc;
    address public ctf;

    // Contracts
    address public exchange;

    // Fee Module
    FeeModule public feeModule;

    bytes32 public constant questionID = hex"1234";
    bytes32 public conditionId;
    uint256 public yes;
    uint256 public no;

    function setUp() public virtual {
        bob = vm.addr(bobPK);
        vm.label(bob, "bob");
        carla = vm.addr(carlaPK);
        vm.label(carla, "carla");

        usdc = address(new Token("USD Coin", "USDC"));
        vm.label(usdc, "USDC");

        ctf = Deployer.ConditionalTokens();

        // Deploy Exchange
        exchange = Deployer.Exchange(usdc, ctf);
        IExchange(exchange).addAdmin(admin);
        IExchange(exchange).addOperator(admin);

        conditionId = _prepareCondition(admin, questionID);
        yes = _getPositionId(2);
        no = _getPositionId(1);

        vm.startPrank(admin);
        // Register tokens
        IExchange(exchange).registerToken(yes, no, conditionId);

        // Deploy FeeModule
        feeModule = new FeeModule(exchange);

        // Add FeeModule as operator to Exchange
        IExchange(exchange).addOperator(address(feeModule));
        vm.stopPrank();

        // Deal and approve tokens to traders, bob and carla
        // NOTE: The FeeModule is NOT approved by traders
        dealAndMint(bob, exchange, 20_000_000_000);
        dealAndMint(carla, exchange, 20_000_000_000);
    }

    function hashOrder(Order memory order) internal view returns (bytes32) {
        return IExchange(exchange).hashOrder(order);
    }

    function getOrderStatus(bytes32 orderHash) internal view returns (OrderStatus memory) {
        return IExchange(exchange).getOrderStatus(orderHash);
    }

    function getMaxFeeRate() internal view returns (uint256) {
        return IExchange(exchange).getMaxFeeRate();
    }

    function createAndSignOrder(
        uint256 pk,
        uint256 tokenId,
        uint256 makerAmount,
        uint256 takerAmount,
        Side side,
        uint256 feeRateBps
    ) internal view returns (Order memory order) {
        address maker = vm.addr(pk);
        order = OrderLib._createOrder(maker, tokenId, makerAmount, takerAmount, side, feeRateBps);
        order = OrderLib._signOrder(pk, IExchange(exchange).hashOrder(order), order);
    }

    function getExpectedFee(Order memory order, uint256 making) internal pure returns (uint256) {
        uint256 taking = CalculatorHelper.calculateTakingAmount(making, order.makerAmount, order.takerAmount);
        return CalculatorHelper.calculateFee(
            order.feeRateBps, order.side == Side.BUY ? taking : making, order.makerAmount, order.takerAmount, order.side
        );
    }

    function getRefund(Order memory order, uint256 making, uint256 operatorFeeRateBps) internal pure returns (uint256) {
        uint256 taking = CalculatorHelper.calculateTakingAmount(making, order.makerAmount, order.takerAmount);
        return CalculatorHelper.calcRefund(
            order.feeRateBps,
            operatorFeeRateBps, 
            order.side == Side.BUY ? taking : making,
            order.makerAmount,
            order.takerAmount,
            order.side
        );
    }

    function dealAndMint(address to, address spender, uint256 amount) internal {
        uint256[] memory partition = new uint256[](2);
        partition[0] = 1;
        partition[1] = 2;

        vm.startPrank(to);
        approve(address(usdc), address(ctf), type(uint256).max);

        dealAndApprove(address(usdc), to, spender, amount);
        IERC1155(address(ctf)).setApprovalForAll(spender, true);

        uint256 splitAmount = amount / 2;
        IConditionalTokens(ctf).splitPosition(IERC20(address(usdc)), bytes32(0), conditionId, partition, splitAmount);
        vm.stopPrank();
    }

    function _transfer(address token, address from, address to, uint256 id, uint256 amount) internal {
        vm.startPrank(from);
        if (id == 0) ERC20(token).transfer(to, amount);
        else ERC1155(token).safeTransferFrom(from, to, id, amount, "");
        vm.stopPrank();
    }

    function _prepareCondition(address oracle, bytes32 _questionId) internal returns (bytes32) {
        IConditionalTokens ictf = IConditionalTokens(ctf);
        ictf.prepareCondition(oracle, _questionId, 2);
        return ictf.getConditionId(oracle, _questionId, 2);
    }

    function _getPositionId(uint256 indexSet) internal view returns (uint256) {
        IConditionalTokens ictf = IConditionalTokens(ctf);
        return ictf.getPositionId(IERC20(address(usdc)), ictf.getCollectionId(bytes32(0), conditionId, indexSet));
    }
}
