# Skill Exchange Smart Contract

This project is a smart contract that enables users to offer their skills for exchange, where users can list their available skill hours, set rates for their skills, and exchange skills for Stacks (STX) tokens. The contract allows the owner to configure the skill exchange rate, service fee, and skill reserve limit. It is written for the Clarinet 2.0 platform and is designed to interact with the Stacks blockchain.

## Overview

The Skill Exchange contract enables the following key features:

- **Set Skill Exchange Rate**: The contract owner can set the rate for skill exchanges (in microstacks).
- **Set Service Fee**: The contract owner can set a service fee (as a percentage of the transaction).
- **Skill Exchange**: Users can offer their skills for exchange by listing their skill hours and rates. Other users can then exchange their STX for the offered skills.
- **Skill Reserve Management**: The contract manages a global skill reserve, ensuring there is a cap on the total skill hours available for exchange.
- **User Skill and STX Balances**: Users maintain balances for both their available skill hours and STX tokens.
- **Owner Only Functions**: Some contract functions (such as setting rates or limits) are restricted to the contract owner.

## Features

### 1. **Skill Rate Management**
   - The contract owner can set and adjust the skill exchange rate.
   - Users are required to pay for the skill exchange in STX tokens, with the exchange rate set by the owner.

### 2. **Skill Offering**
   - Users can offer their skills by specifying the number of hours they are willing to trade and the rate they will charge.
   - Skill offerings are tracked in the contract, and users can update or remove their offers.

### 3. **Skill Exchange**
   - Users can exchange their STX for skills offered by other users.
   - The exchange cost includes the skill rate plus a service fee, which is also set by the contract owner.

### 4. **Skill Reserve Management**
   - The contract has a limit on the total skill reserve to prevent the market from being flooded with too many skills.
   - The owner can update the reserve limit, and the contract ensures the reserve does not exceed the limit.

### 5. **Transaction Fees**
   - A service fee (percentage) is applied to every skill exchange transaction.
   - The fee is deducted from the transaction amount and sent to the contract owner.

### 6. **Security**
   - Only the contract owner can update rates, service fees, and reserve limits.
   - Only users can cancel or adjust their own skill offers.
   - Proper checks are in place to ensure users have enough skills and STX balance before performing exchanges.

## Contract Functions

### Public Functions

- **set-skill-rate**: Allows the contract owner to set the rate for skill exchange (in microstacks).
- **set-service-fee**: Allows the contract owner to set the service fee percentage for transactions.
- **set-skill-reserve-limit**: Allows the contract owner to set the global limit for available skill hours.
- **offer-skills-for-exchange**: Users can offer their skills for exchange by specifying the number of hours and the exchange rate.
- **remove-skills-from-exchange**: Users can remove their skills from the exchange by specifying the number of hours.
- **exchange-skills**: Allows a user to exchange their STX for the skills offered by another user.
- **set-max-skills-per-user**: Allows the contract owner to set the maximum number of skill hours a user can offer.
- **cancel-skill-offer**: Allows users to cancel their skill offering.
- **view-activity-page**: Allows users to view their activity page (e.g., balance and skills for exchange).

### Read-Only Functions

- **get-skill-rate**: Retrieves the current skill exchange rate.
- **get-service-fee**: Retrieves the current service fee percentage.
- **get-skill-balance**: Retrieves the skill balance of a specified user.
- **get-stx-balance**: Retrieves the STX balance of a specified user.
- **get-skills-for-exchange**: Retrieves the skills currently available for exchange by a specified user.
- **get-max-skills-per-user**: Retrieves the maximum skills a user can offer.
- **get-total-skill-reserve**: Retrieves the total skill hours available in the system.
- **get-skill-reserve-limit**: Retrieves the global limit for skill hours.

## Contract Setup

To deploy and interact with this contract, follow the steps below:

### Prerequisites

- **Clarinet**: Make sure you have Clarinet installed. You can follow the installation instructions from [Clarinet's official documentation](https://docs.clarinet.xyz).
- **Stacks Wallet**: You need a Stacks wallet to deploy and interact with the contract on the Stacks blockchain.

### Setup Steps

1. Clone the repository:
   ```bash
   git clone https://github.com/Emmakinghub/skill-exchange-smart-contract.git
   cd skill-exchange
   ```

2. Deploy the contract:
   Make sure your Clarinet environment is set up and deploy the contract:
   ```bash
   clarinet deploy
   ```

3. Interact with the contract:
   You can interact with the deployed contract through Clarinet or by writing a script using the `clarinet` CLI.

### Contract Owner Setup

Once deployed, the contract owner can configure the initial values for skill exchange rate, service fee, and skill reserve limit using the following commands:

```bash
clarinet call contract_name.set-skill-rate 20
clarinet call contract_name.set-service-fee 10
clarinet call contract_name.set-skill-reserve-limit 1000
```

## Testing

To ensure the contract is functioning correctly, we have written several tests to verify skill balances, exchanges, and fee calculations.

### Example Tests

- **Test skill exchange**: Ensures that users can exchange STX for skills and receive the correct balance update.
- **Test service fee**: Verifies that the service fee is correctly calculated and deducted.
- **Test skill offering**: Confirms that users can offer skills with valid hours and rate.

To run the tests, use the following command:

```bash
clarinet test
```

## Known Issues

- **Skill Limit**: The skill reserve limit is a global limit, so once it is reached, no more skills can be offered, even if individual users have available hours.
- **Owner Permissions**: Only the contract owner can change key configurations (such as rate, service fee, and reserve limit).

## License

This contract is licensed under the MIT License.

## Acknowledgments

- Thanks to the Clarinet team for providing the platform to develop this smart contract.
- Special thanks to the Stacks community for their contributions and support.
