import {Player} from "../game/player.js"
var messages = require('../protobuf/messages_pb');

export const GameQueue = function () {
    this.mounted = function () {
        let player_id = document.getElementById("board_game").dataset.playerId
        let character = document.getElementById("board_game").dataset.character
        let player = new Player(getQueueSocketUrl(player_id, character))

        player.socket.addEventListener("message", (event) => {
            game_state = messages.GameState.deserializeBinary(event.data);
            if (game_state.getGameId()) {
                this.pushEvent("join_game", { game_id: game_state.getGameId(), player_id: player_id });
            }
        });
    };
}

function getQueueSocketUrl(player_id, character) {
    const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:'
    const host = getHost()
    const path = '/join'

    return `${protocol}//${host}${path}/${player_id}/${character}`
}

// TODO: This will work for while the Arena is using the default wss port and
//      both Arena and GameClient are running on the same host. Once this is
//      no longer the case, we will need to fetch the host from a config or
//      hardcode the host for Arena. To read from config we can use the same
//      trick as for the csrf_token, we put the host in a meta tag in root.html.heex
//      and read it from there
function getHost() {
    const host = window.location.hostname

    if (host.includes('localhost')) {
        return 'localhost:4000'
    } else {
        return host
    }
}
