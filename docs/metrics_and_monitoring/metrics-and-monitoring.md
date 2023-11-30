# Metrics and monitoring

## Available custom metrics

The following metrics are available in the APM Metric Explorer section in NewRelic

- `GameBackend/GameTickExecutionTimeMs`: Timing in milliseconds for calling `GameBackend.game_tick/2`

This metrics are only visible by selecting them as `COUNT`
- `GameBackend/TotalPlayers`: Count of players added across all games
- `GameBackend/TotalBots`: Count of bots added across all games
- `GameBackend/TotalGames`: Count of game gen_servers currently alive
- `GameBackend/TotalGameWebSockets`: Count of websockets connected for games
