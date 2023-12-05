## Specs:
### Game Server:
- OS: -
- CPU: -
- Hyper-thread `enabled`/`disabled`.
- -GB RAM.
- -GB Swap.
- location
- Erlang version
- Elixir version

### Load Testing Client:
- OS: -
- CPU: -
- Hyper-thread `enabled`/`disabled`.
- -GB RAM.
- -GB Swap.
- location
- Erlang version
- Elixir version

### Purpose of the load test:

- [ ] Regular
- [ ] Feature (commit: ` `)
    - If feature, explain a bit what it changes

### Any relevant changes to consider

Write down here any changes that might have an impact on this test compared to
previous load test runs. For example, if we changed any erlang VM's flags, or
we disabled some costly feature such as projectiles.

## Tests

- How many games are you running?: X games of Y players each.
- How many updates are the clients sending: one update every X milliseconds

### Test Methodology

We'll be running tests while we also try to play with the app to see if there
is a noticeable downgrade on the UX. We'll run using
`LoadTest.PlayerSupervisor.spawn_players(NUMBER_OF_USERS, PLAY_TIME)` where
PLAY_TIME is the amount in seconds the players play before closing the
connection in seconds.

- NUMBER_OF_USERS = X1, PLAY_TIME = Y1min
- NUMBER_OF_USERS = X2, PLAY_TIME = Y2min

## Test Results

### NUMBER_OF_USERS = X1, PLAY_TIME = Y1min

#### Briefly describe the UX exprerience:

#### Screenshots of htop, newrelic and other extra tools if used
![image]()

### NUMBER_OF_USERS = X2, PLAY_TIME = Y2min
#### Briefly describe the UX exprerience:

#### Screenshots of htop, newrelic and other extra tools if used
![image]()

## Measures taken

This could be a mix of a conclusion and actions taken from it or other new
measurements gathered.
