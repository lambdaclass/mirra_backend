# Quests

Quests are a set of conditions that players need to meet by playing matches in order to get rewards (for the time being, currencies). You can specify an objective that's the final goal.

## Configuration

- `config_id`: Unique ID for the quests in the config file.
- `description`: A description of the quest.
- `type`: The duration of the quest. Possible values can be ["daily"]. 
- `objective`: What the player needs to achieve in order to complete the quest (can be left empty).
  - `match_tracking_field`: The match_tracking_field of the arena match result table that will be used as a target.
  - `value`: The amount of progress that the player needs to meet to complete the quest.
  - `comparison`: Comparator to use against the progress to check quest completion.
  - `scope`: Will determine how the progress will be processed to meet quest completion. `match` will only add 1 for each valid match, `day` will sum the numeric value of the field. *Do not use with string fields*.
- `conditions`: A list of conditions to filter if a match is valid in order to add to the progress of quest completion.
  - `value`: Value to compare with arena results to check validity.
  - `match_tracking_field`: match_tracking_field from the arena result to take to compare.
  - `comparison`: Comparator to use against the arena results to check validity.
- `reward`: Reward to give when the user completes.
    - `currency`: Currency to give on quest completion.
    - `amount`: Amount of currency to give on quest completion.
