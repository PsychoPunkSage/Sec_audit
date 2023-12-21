// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {PasswordStore} from "../src/PasswordStore.sol";
import {DeployPasswordStore} from "../script/DeployPasswordStore.s.sol";

contract PasswordStoreTest is Test {
    PasswordStore public passwordStore;
    DeployPasswordStore public deployer;
    address public owner;

    function setUp() public {
        deployer = new DeployPasswordStore();
        passwordStore = deployer.run();
        owner = msg.sender;
    }

    function test_owner_can_set_password() public {
        vm.startPrank(owner);
        string memory expectedPassword = "myNewPassword";
        passwordStore.setPassword(expectedPassword);
        string memory actualPassword = passwordStore.getPassword();
        assertEq(actualPassword, expectedPassword);
    }

    function test_non_owner_reading_password_reverts() public {
        vm.startPrank(address(1));

        vm.expectRevert(PasswordStore.PasswordStore__NotOwner.selector);
        passwordStore.getPassword();
    }

    // @Audit what about non_owner_can_set_password
    function test_nan_owner_can_set_password(address randomAddress) public {
        vm.prank(owner);
        string memory owner_pass = passwordStore.getPassword();

        string memory hackedPassword = "HackedPassword";
        vm.prank(randomAddress);
        passwordStore.setPassword(hackedPassword);

        vm.prank(owner);
        string memory owner_pass_now = passwordStore.getPassword();

        // To prove:: owner_pass_now != Password set by owner (i.e. owner_pass) + owner_pass_now == HackedPassword
        assert(keccak256(abi.encodePacked(owner_pass)) != keccak256(abi.encodePacked(owner_pass_now)));
        assert(keccak256(abi.encodePacked(hackedPassword)) == keccak256(abi.encodePacked(owner_pass_now)));
    }
}
