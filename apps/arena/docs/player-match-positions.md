# Player Match Positions

Every time a player dies, we assign them a position.  
When the game ends, we set the winners to position **1**.

## Positioning Rules

- **Solo Mode:**  
  Player positions range from **N to 1**, where **1** is the winner and **N** is the first player to die.  

- **Team Modes:**  
  Player positions range from **N to 1**, where **1** is assigned to **all players on the winning team**.  
  The remaining players are ranked from **N to 2**, based on the order in which they died.

## Potential Issue

A possible bug occurs when a player initially receives a position (e.g., **6**) upon dying.  
If their team later wins, their position is overridden to **1**, leaving the **6th position empty**.

