import { Application, Graphics } from "pixi.js";
import { Player } from "../game/player.js";

export const BoardGame = function () {
  const easing = 0.2;
  const elements = new Map();
  const colors = {
    board: 0xb5b8c8,
    currentPlayer: 0xff00d7,
    players: 0x000000,
    obstacle: 0x00aa77,
  };
  let player_id, player;

  (this.mounted = function () {
    let game_id = document.getElementById("board_game").dataset.gameId
    let player_id = document.getElementById("board_game").dataset.playerId
    let player = new Player(getGameSocketUrl(game_id, player_id))

    const app = new Application({
      width: document.getElementById("board_game").dataset.boardWidth,
      height: document.getElementById("board_game").dataset.boardHeight,
      backgroundColor: colors.board,
    });

    document.getElementById("board_container").appendChild(app.view);

    window.addEventListener("phx:updateElements", (e) => {
      Array.from(e.detail.elements).forEach((backElement) => {
        if (!elements.has(backElement["name"])) {
          let elementInfo = this.createElement(backElement);

          app.stage.addChild(elementInfo["object"]);
          elements.set(backElement["name"], elementInfo);
        }
        this.updateElementPosition(
          elements.get(backElement["name"]),
          backElement["x"],
          backElement["y"]
        );
      });
    });

    app.ticker.add(() => {
      elements.forEach((element) => {
        // Use linear interpolation (lerp) for smoother movement
        element["object"].x +=
          (element["targetX"] - element["object"].x) * easing;
        element["object"].y +=
          (element["targetY"] - element["object"].y) * easing;

        // Update the element's position
        element["object"].position.x = element["object"].x;
        element["object"].position.y = element["object"].y;
      });
    });

    document.addEventListener("keypress", function onPress(event) {
      if (event.key === "a") {
        player.move(-10, 0);
      }
      if (event.key === "w") {
        player.move(0, -10);
      }
      if (event.key === "s") {
        player.move(0, 10);
      }
      if (event.key === "d") {
        player.move(10, 0);
      }
    });
  }),
    (this.updateElementPosition = function (element, x, y) {
      element["targetX"] = x;
      element["targetY"] = y;
    }),
    (this.createElement = function (backElement) {
      let elementInfo = new Map();
      let color;

      elementInfo["name"] = backElement["name"];
      elementInfo["targetX"] = backElement["x"];
      elementInfo["targetY"] = backElement["y"];
      elementInfo["object"] = new Graphics();

      switch (backElement["type"]) {
        case "player":
          color =
            backElement["id"] == player_id
              ? colors.currentPlayer
              : colors.players;
          break;
        case "obstacle":
          color = colors.obstacle;
          break;
      }

      elementInfo["object"].beginFill(color);

      switch (backElement["shape"]) {
        case "circle":
          elementInfo["object"].drawCircle(0, 0, backElement["radius"]);
          break;
        case "polygon":
          elementInfo["coords"] = backElement["coords"];
          elementInfo["object"].drawPolygon(elementInfo["coords"].flat());
          break;
      }

      elementInfo["object"].endFill();

      elementInfo["object"].on("pointerover", (event) => {
        this.updateDebug(
          elementInfo["name"] +
            " - " +
            "pos: [" +
            Math.round(elementInfo["object"].position.x) +
            "," +
            Math.round(elementInfo["object"].position.y) +
            "]"
        );
      });
      elementInfo["object"].on("pointerleave", (event) => {
        this.updateDebug("");
      });
      elementInfo["object"].eventMode = "static";

      return elementInfo;
    }),
    (this.updateDebug = function (msg) {
      document.querySelector("#board-debug span").innerHTML = msg;
    });
};

function getGameSocketUrl(game_id, player_id) {
  let protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:'
  let host = window.location.host
  let path = '/play'

  return `${protocol}${host}${path}/${game_id}/${player_id}`
}
