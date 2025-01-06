# Bots

## Bot's State Machine

### What is a State Machine?

A state machine is a computational model used to design and describe systems with a limited number of specific states and defined rules for transitioning between them.


### Bot's States

Our current bots can transition between four states: `idling, moving, attacking, and running_away`. At the moment, there are no restrictions between states; that is to say, bots can transition from any state to any other state. However, specific conditions must be met for transitions depending on the state.

#### Idling

This is the base state, bots start in this state and basically means that they're doing nothing and they will not be sending actions to the server.

#### Moving

This is the default state when anything else is being done, it will tell the bots to keep moving on the same direction that they were moving.
When walking, they will charge energy to use the basic attack.

#### Attacking

Bots will enter into the attacking mode if they have charged enough energy to use them. I'll explain how do they charge energy below:

- Charging energy for the Basic Skill
    They should traverse a certain amount of units to gain 1 cell to use the basic skill
- Charging energvy for the Ultimate Skill
    They should've used the basic skill a certain amount of times, for instance, let's say 3.

This is just a gimmick that was added to avoid bots shooting skills everywhere and with no reason.

#### Running Away

Bots will transition to this state whenever their health drops below a certain percentage. For now, this threshold is set at 40%. In this state, bots will attempt to escape from players by running in the opposite direction of the closest one. This does not necessarily mean they will run away from the player attacking them.
