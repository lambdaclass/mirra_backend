import { Application, Graphics } from "pixi.js";
import { Player } from "../game/player.js";

export const BoardGame = function () {
  const easing = 0.2;
  const elements = new Map();
  const colors = {
    board: 0xb5b8c8,
    currentPlayer: 0x007cff,
    players: 0x000000,
    obstacle: 0x00aa77,
    colliding: 0xff0000
  };
  let player_id, player;

  (this.mounted = function () {
    player_id = document.getElementById("board_game").dataset.playerId;
    player = new Player(player_id);

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
        let element = elements.get(backElement["name"]);
        this.updateElementColor(element, backElement["is_colliding"]);

        this.updateElementPosition(
          element,
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
        player.move(-1, 0);
      }
      if (event.key === "w") {
        player.move(0, -1);
      }
      if (event.key === "s") {
        player.move(0, 1);
      }
      if (event.key === "d") {
        player.move(1, 0);
      }
    });
  }),
    (this.updateElementPosition = function (element, x, y) {
      element["targetX"] = x;
      element["targetY"] = y;
    }),
    (this.createElement = function (backElement) {
      let elementInfo = new Map();

      elementInfo["id"] = backElement["id"];
      elementInfo["name"] = backElement["name"];
      elementInfo["targetX"] = backElement["x"];
      elementInfo["targetY"] = backElement["y"];
      elementInfo["shape"] = backElement["shape"];
      elementInfo["type"] = backElement["type"];
      elementInfo["object"] = new Graphics();

      elementInfo["object"].beginFill(0xffffff);

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
    }),
    this.updateElementColor = function (element, is_colliding){
      let color;
      if (is_colliding == true){
        color = colors.colliding;
      } else {
        switch (element["type"]) {
          case "player":
            color =
              element["id"] == player_id
                ? colors.currentPlayer
                : colors.players;
            break;
          case "obstacle":
            color = colors.obstacle;
            break;
        }
      }
      element["object"].tint = color;
    }
};
