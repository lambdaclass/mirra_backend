import {Player} from "../game/player.js"
var messages = require('../protobuf/messages_pb');

export const GameQueue = function () {
    this.mounted = function () {
        let player_id = document.getElementById("board_game").dataset.playerId
        let player = new Player(getQueueSocketUrl(player_id))

        player.socket.addEventListener("message", (event) => {
            game_state = messages.GameState.deserializeBinary(event.data);
            if (game_state.getGameId()) {
                this.pushEvent("join_game", { game_id: game_state.getGameId(), player_id: player_id });
            }
        });
    };
}
        
function getQueueSocketUrl(player_id) {
    let protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:'
    // TODO Remove hardcoded host
    let host = '//localhost:4000'
    let path = '/join'

    return `${protocol}${host}${path}/${player_id}/muflus`
}
