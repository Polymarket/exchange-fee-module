// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { TestHelper } from "./TestHelper.sol";
import { Deployer } from "./Deployer.sol"; 

import { IConditionalTokens } from "src/interfaces/IConditionalTokens.sol";

import { ERC20 } from "solmate/tokens/ERC20.sol";

contract FeeModuleTest is TestHelper {
    address public admin = alice;

    address public usdc;
    address public ctf;
    address public exchange;

    bytes32 public constant questionID = hex"1234";
    bytes32 public conditionId;
    uint256 public yes;
    uint256 public no;

    function setUp() public virtual {
        
        usdc = new ERC20("USD Coin", "USDC", 6);
        vm.label(usdc, "USDC");

        ctf = Deployer.ConditionalTokens();

        vm.startPrank(admin);
        exchange = Deployer.Exchange(usdc, ctf);

        conditionId = _prepareCondition(admin, questionID);
        yes = _getPositionId(2);
        no = _getPositionId(1);


    }

    function _prepareCondition(address oracle, bytes32 _questionId) internal returns (bytes32) {
        ctf.prepareCondition(oracle, _questionId, 2);
        return ctf.getConditionId(oracle, _questionId, 2);
    }

    function _getPositionId(uint256 indexSet) internal view returns (uint256) {
        return ctf.getPositionId(IERC20(address(usdc)), ctf.getCollectionId(bytes32(0), conditionId, indexSet));
    }



}

