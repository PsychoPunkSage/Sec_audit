---
title: Protocol Audit Report
author: PsychoPunkSage
date: December 22, 2023
header-includes:
  - \usepackage{titling}
  - \usepackage{graphicx}
---

\begin{titlepage}
    \centering
    \begin{figure}[h]
        \centering
        \includegraphics[width=0.5\textwidth]{logo.pdf} 
    \end{figure}
    \vspace*{2cm}
    {\Huge\bfseries Protocol Audit Report\par}
    \vspace{1cm}
    {\Large Version 1.0\par}
    \vspace{2cm}
    {\Large\itshape PsychoPunkSage\par}
    \vfill
    {\large \today\par}
\end{titlepage}

\maketitle

<!-- Your report starts here! -->

Prepared by: [PsychoPunkSage](https://helloabhinav.vercel.app/)


# Table of Contents
- [Table of Contents](#table-of-contents)
- [Protocol Summary](#protocol-summary)
- [Disclaimer](#disclaimer)
- [Risk Classification](#risk-classification)
- [Audit Details](#audit-details)
  - [Scope](#scope)
  - [Roles](#roles)
- [Executive Summary](#executive-summary)
  - [Issues found](#issues-found)
- [Findings](#findings)
- [High](#high)
  - [\[H-1\] Anything stored on-chain can be accessed by anyone, solidity access control (i.e. private, public etc) is only applicable for contracts.](#h-1-anything-stored-on-chain-can-be-accessed-by-anyone-solidity-access-control-ie-private-public-etc-is-only-applicable-for-contracts)
    - [Description:](#description)
    - [Impact:](#impact)
    - [Proof of Concept:](#proof-of-concept)
    - [Recommended Mitigation:](#recommended-mitigation)
  - [\[H-2\] `PasswordStore::setpassword()` don't have any "Access Control", so even a "non-owner" can change/set the password](#h-2-passwordstoresetpassword-dont-have-any-access-control-so-even-a-non-owner-can-changeset-the-password)
    - [Description:](#description-1)
    - [Impact:](#impact-1)
    - [Proof of Concept:](#proof-of-concept-1)
    - [Recommended Mitigation:](#recommended-mitigation-1)
- [Informational](#informational)
  - [\[I-1\] `PasswordStore::getPassword()` doesn't use any parameters, but the documentation mentions about `newPassword`](#i-1-passwordstoregetpassword-doesnt-use-any-parameters-but-the-documentation-mentions-about-newpassword)
    - [Description:](#description-2)
    - [Impact:](#impact-2)
    - [Recommended Mitigation:](#recommended-mitigation-2)

# Protocol Summary

PasswordStore is a protocol that focuses on storage and retrieval of user's passwords. The protocol is meant to be used by single user only. It only allows owners to set and retrieve password.

# Disclaimer

I make all effort to find as many vulnerabilities in the code in the given time period, but holds no responsibilities for the findings provided in this document. A security audit is not an endorsement of the underlying business or product. The audit was time-boxed and the review of the code was solely on the security aspects of the Solidity implementation of the contracts.

# Risk Classification

|            |        | Impact |        |     |
| ---------- | ------ | ------ | ------ | --- |
|            |        | High   | Medium | Low |
|            | High   | H      | H/M    | M   |
| Likelihood | Medium | H/M    | M      | M/L |
|            | Low    | M      | M/L    | L   |

We use the [CodeHawks](https://docs.codehawks.com/hawks-auditors/how-to-evaluate-a-finding-severity) severity matrix to determine severity. See the documentation for more details.

# Audit Details 

**The findings described below in this doc is base on following commit hash:**
```7d55682ddc4301a7b13ae9413095feffd9924566```

## Scope 
```
./src/
    |__ PasswordStore.sol
```

## Roles

- Owner: The user who can set the password and read the password.
- Outsides: No one else should be able to set or read the password.

# Executive Summary
## Issues found
| Severity | Number of issues found |
| -------- | ---------------------- |
| High     | 2                      |
| Medium   | 0                      |
| Low      | 0                      |
| Info     | 1                      |
| Total    | 3                      |



# Findings
# High

## [H-1] Anything stored on-chain can be accessed by anyone, solidity access control (i.e. private, public etc) is only applicable for contracts.

### Description:
> **`PasswordStore::s_password`** is accessible to anyone which defeats the protocol ideal `This contract allows you to store a private password that others won't be able to see.`. Solidity keywords is only applicable on contracts. But you are storing **s_password** on-chain, so, anyone can see it.

### Impact: 
> **s_password** is no more safe or private.

### Proof of Concept:
> Here is how one can attack your system.

1. Run **anvil**:
```bash
anvil
```

2. Deploy the Contract
```bash
make deploy
```

3. Read the Storage slot of **s_password** (i.e. 1) using *cast*
```bash
cast storage <CONTRACT_ADDRESS> 1
```
Output (on success) : `0x6d7950617373776f726400000000000000000000000000000000000000000014`

4. Decode the data obtained from step:3
```bash
cast parse-bytes32-string 0x6d7950617373776f726400000000000000000000000000000000000000000014
```
Output (on success) : `myPassword`

### Recommended Mitigation:
>Due to this, the overall architecture of the contract should be rethought. One could encrypt the password off-chain, and then store the encrypted password on-chain. This would require the user to remember another password off-chain to decrypt the password. However, you'd also likely want to remove the view function as you wouldn't want the user to accidentally send a transaction with the password that decrypts your password.  


## [H-2] `PasswordStore::setpassword()` don't have any "Access Control", so even a "non-owner" can change/set the password

### Description:
> According to natspec of **`PasswordStore::setpassword()`** i.e. `@notice This function allows only the owner to set a new password.` but the function don't have any access restriction/control. So, anyone can call this function and Change Password. this defeats the intention of the protocol.

```javascript
    function setPassword(string memory newPassword) external {
@>>        // @Audit No access control
           s_password = newPassword;
           emit SetNetPassword();
       }
```

### Impact: 
> Anyone can change the **s_password**.

### Proof of Concept:
> Please paste *Test Code* attached below to `test/PasswordStore.t.sol` for checking....

<details>
<summary>Test Code</summary>

```javascript
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
```

</details>

### Recommended Mitigation:
> You can add following Lines of code to `PasswordStore::setpassword()`

```javascript
if (msg.sender != s_owner) {
    revert PasswordStore__NotOwner;
}
```


# Informational

## [I-1] `PasswordStore::getPassword()` doesn't use any parameters, but the documentation mentions about `newPassword`

### Description:
> Since `PasswordStore::getPassword()` don't require any parameters, but the documentation mentions about a paramater `newPassword`. This suggests the signature of this function is `getPassword(string)` which is not true.

```
    /*
     * @notice This allows only the owner to retrieve the password.
@>   * @param newPassword The new password to set.
     */
    function getPassword() external view returns (string memory) {
```

### Impact: 
> Can be misleading for future reference.

### Recommended Mitigation:
> Remove the line from *natspec*:

```diff
+
-      * @param newPassword The new password to set.
```