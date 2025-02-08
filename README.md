# LLBroker Smart Contracts

This collection of contracts is responsible for handling information about servers and current client-server agreements in LLMBroker

## LLMBroker
This contract is to create new LLMServers, and hold necessary information in the market array to allow clients to find a suitable server for there needs

## LLMServer
This contract handles the prices and model available on a server. It is also responsible for using FTSO to convert USD amounts to FLR. Clients create LLMAgreements from LLMServer contracts.

## LLMAgreement
This contract stores the prices and model for which the client made the agreement. Wei is transferred to the token on creation and "remainingBalance" is depleted as the server confirms API calls from the client. Wei is transferred out of the contract based on whether the client is "satisfied", "unsatisfied" or the server owner issues a "refund". The LLMAgreement is also used to store a public key which is used by the server to verify signatures in its API requests are from an authentic client.
