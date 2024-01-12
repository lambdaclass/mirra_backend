# Metrics and monitoring

## Available custom metrics

The following metrics are available in the APM Metric Explorer section in NewRelic

- `Arena/GameTickExecutionTimeMs`: Timing in milliseconds for calling `Arena.game_tick/2`

This metrics are only visible by selecting them as `COUNT`
- `Arena/TotalPlayers`: Count of players added across all games
- `Arena/TotalBots`: Count of bots added across all games
- `Arena/TotalGames`: Count of game gen_servers currently alive
- `Arena/TotalGameWebSockets`: Count of websockets connected for games
