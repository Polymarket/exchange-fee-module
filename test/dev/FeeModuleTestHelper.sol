// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { ERC20 } from "solmate/tokens/ERC20.sol";
import { IERC20 } from "openzeppelin-contracts/token/ERC20/IERC20.sol";

import { TestHelper } from "./TestHelper.sol";
import { Deployer } from "./Deployer.sol"; 

import { IConditionalTokens } from "../interfaces/IConditionalTokens.sol";
import { IExchange } from "../interfaces/IExchange.sol";

import { FeeModule } from "src/FeeModule.sol";
import { IAuthEE } from "src/interfaces/IAuth.sol";

import { console } from "forge-std/console.sol";

contract Token is ERC20 {
    constructor(string memory _name,string memory _symbol) ERC20(_name, _symbol, 6) {}
}

contract FeeModuleTestHelper is TestHelper, IAuthEE {
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

