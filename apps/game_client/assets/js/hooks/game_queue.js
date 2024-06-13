import {Player} from "../game/player.js"
var messages = require('../protobuf/messages_pb');

export const GameQueue = function () {
    this.mounted = function () {
        let player_id = document.getElementById("board_game").dataset.playerId
        let character = document.getElementById("board_game").dataset.character
        let player_name = document.getElementById("board_game").dataset.playerName
        let game_mode = document.getElementById("board_game").dataset.gameMode
        let gateway_jwt = document.getElementById("board_game").dataset.gatewayJwt
        let player = new Player(getQueueSocketUrl(gateway_jwt, player_id, character, player_name, game_mode))

        player.socket.addEventListener("message", (event) => {
            lobby_event = messages.LobbyEvent.deserializeBinary(event.data);
            if ( lobby_event.hasGame() && lobby_event.getGame().getGameId()) {
                this.pushEvent("join_game", { game_id: lobby_event.getGame().getGameId(), player_id: player_id });
            }
        });
    };
}

function getQueueSocketUrl(gateway_jwt, player_id, character, player_name, game_mode) {
    const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:'
    const host = getHost()
    return `${protocol}//${host}/${game_mode}/${player_id}/${character}/${player_name}?gateway_jwt=${gateway_jwt}`
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
