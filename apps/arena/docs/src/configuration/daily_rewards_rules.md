# Daily Rewards Rules

This configuration contains the info of the daily rewards for each day

## Reward per day

This is a map where the keys are each day of the rewards, from 1 to N.
The values store the following:

- `currency`: Defines the type of currency to be rewarded.
- `amount`: Defines the amount of the defined currency.
- `next_reward`: The next day for the reward, works like a pointer to the next daily reward.

### Example

```
{
    "reward_per_day": {
        "day_1": {
            "currency": "Gold",
            "amount": 50,
            "next_reward": "day_2"
        },
        "day_2": {
            "currency": "Gems",
            "amount": 200,
            "next_reward": "day_1"
        }
    }
}
```
