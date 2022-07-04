# Hidden Recruiter

Hidden Recruiter is a deduction game that is played by up to five players, with
one player being the recruiter and the others being the agents. The recruiter
will play alone, trying to evade the agents for a maximum duration of 14
rounds. If the agents ever catch the recruiter, the game is over. If the
recruiter is able to evade the agents for the 14 rounds, the recruiter wins.

## Rules

The board is a grid of 42 squares (6x7), with one of 9 colors. There are
exactly 5 squares of each color, except for black, which only has 2.

The way the recruiter moves is hidden from the agents, who try to gain
information via one of three actions:

1. Ask
2. Reveal
3. Capture

### Ask

The agent can ask the recruiter if they've been to a square of the same color
as they currenly are on. If true, a token will be placed on a given square of
that color (only one is added, even if the recruiter has visited multiple of
this color).

The black color squares cannot be asked on, and are thus safe squares.

### Reveal

The agent can ask to reveal in which move the recruiter was on when they've
been at a place with an ask token. The agent must be at the location, in order
to reveal.

### Capture

The agent can try to capture the recruiter. If the agent and the recruiter are
in the same square, the agents wins.

Optionally, the agent can also move up to 2 orthogonally adjacent squares in
any direction, whereas the recruiter can only move 1.

## Zero Knowledge

This game used ZK (Zero Knowledge) to hide the way the recruiter moves and all
the actions associated with it. In order to acomplish that, it uses the
recruiter's local storage to keep a local version of the data that cannot be
shared and wasm files for each circuit to generate the proofs on the client,
thus never exposing this information. The smart contract will then verify the
proofs on the agents behalf before updating any relevant state.

The agents' moves are not hidden information, thus are controlled solely be the
contract, which uphelds the game's rules.

## Project Structure

The project has three main directories:

* circuits
* contracts
* web

### Circuits

Here you can find the circom files for all the circuits used in the game, which
match the actions the agent can take (the ones starting with `Agent`) or are
relevant to the Recruiter's movement.

The circuits can be compiled by running `just all` in the project's root, or
`just compile X` where X is the name of the circuit. The compiled wasm files
can then be moved to the public directory to be served, by running `just
prepare-all-js` or `just prepare-js X`.

### Contracts

Contains the only smart contract used in the game. It can be compiled by
running `just compile-contracts`.

It can be deployed to the hardhat node by running `hardhat deploy --network
localhost`.

### Web

The web directory contains the frontend for the game, which is served via
Next.JS. In terms of ZK, the most important files are `snarkjs.ts` and
`snarkjsZkproof.ts`, which generate the proofs. It is also relevant to look into
the `contracts.ts` file, which contains the configurations to interact with the
smart contract.

A game uses localstorage is currently doesn't clean up after itself, make sure to clear your localstorage when you move between games.

Also, there are no loading states in the app, depending on your network give it a seconds and/or refresh the page to see the outcome.

## Run locally

### Clone the Repo

```
git clone https://github.com/zamith/hidden_recruiter.git
```

### Install dependencies

```
yarn install
```

### Prepare the circuits

```
just all
just prepare-all-js
```

### Compile the contracts

```
just compile-contracts
```

### Run the node

In a separate terminal window or pane, run:

```
hardhat node
```

### Deploy the contracts

```
hardhat deploy --network localhost
```

### Run the web app

```
yarn web:dev
```

Open [http://localhost:3000](http://localhost:3000) with your browser to see the result.
