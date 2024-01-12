# Metrics and monitoring

## Available custom metrics

The following metrics are available in the APM Metric Explorer section in NewRelic

- `MirraBackend/GameTickExecutionTimeMs`: Timing in milliseconds for calling `MirraBackend.game_tick/2`

This metrics are only visible by selecting them as `COUNT`
- `MirraBackend/TotalPlayers`: Count of players added across all games
- `MirraBackend/TotalBots`: Count of bots added across all games
- `MirraBackend/TotalGames`: Count of game gen_servers currently alive
- `MirraBackend/TotalGameWebSockets`: Count of websockets connected for games
