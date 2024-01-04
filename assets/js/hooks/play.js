import {Player} from "../game/player.js"

export const Play = function () {
    this.mounted = function () {
        // let game_id = document.getElementById("board_game").dataset.gameId
        let player_id = document.getElementById("board_game").dataset.playerId
        let player = new Player(player_id)

        document.addEventListener("keypress", function onPress(event) {
            if (event.key === "a") {
                player.move(-1, 0)
            }
            if (event.key === "w") {
                player.move(0, -1)
            }
            if (event.key === "s") {
                player.move(0, 1)
            }
            if (event.key === "d") {
                player.move(1, 0)
            }
        });
    }
}
