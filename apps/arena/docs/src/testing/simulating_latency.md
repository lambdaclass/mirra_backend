# Simulating High Latency/Network Failures

The backend can be configured to point to [ToxiProxy](https://github.com/Shopify/toxiproxy), which is a server that can act as a proxy between the client and the backend, allowing you to add network latency and simulate poor network environments in general.

To install ToxiProxy on `macOS``:

```
brew tap shopify/shopify
brew install toxiproxy
```

To use it, do the following:

- Start a `toxiproxy` server with
    ```
    toxiproxy-server
    ```

- Set the following environment variable before running the backend:
    ```
    USE_PROXY=true
    ```
    This will make the backend setup the proxy on startup.
- Edit the `GameSettings.json` file setting `use_proxy` to `"true"`.
- Use the `toxiproxy` CLI to set the desired network conditions. As an example, if you want to add 300 ms of latency, run
    ```
    toxiproxy-cli toxic add -n latency -t latency -a latency=300 game_proxy
    ```
    To update it to 500 ms:
    ```
    toxiproxy-cli toxic update -n latency -a latency=500 game_proxy
    ```
    To continuosly change latency to simulate lag spikes, there's a small bash script on the root directory called `lag_spikes.sh` that will randomly set the latency to values in the range of `100-300` ms. With everything setup all you need to do is run
    ```
    ./lag_spikes.sh
    ``````
    You should see your ping in-game varying wildy.
