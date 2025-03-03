# ZenTrek
A decentralized mindfulness app that pairs nature sounds with daily breathing exercises, built on the Stacks blockchain.

## Features
- Create and manage breathing exercise sessions
- Store and access nature sound collections
- Track user participation and progress
- Reward system for consistent practice

## Setup and Installation
1. Clone the repository
2. Install Clarinet (if not already installed)
3. Run `clarinet check` to verify the contract
4. Run `clarinet test` to run the test suite

## Usage Examples
```clarity
;; Create a new breathing session
(contract-call? .zentrek create-session 'morning-meditation u300 u10)

;; Start a session
(contract-call? .zentrek start-session u1)

;; Complete a session
(contract-call? .zentrek complete-session u1)

;; Get user stats
(contract-call? .zentrek get-user-stats tx-sender)
```

## Dependencies
- Clarity language
- Clarinet for testing and deployment
