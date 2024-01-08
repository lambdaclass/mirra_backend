import { Application, Graphics } from "pixi.js";
import { Player } from "../game/player.js";

function Element({ id, name, shape, type, x, y, coords, radius }) {
  this.id = id;
  this.name = name;
  this.shape = shape;
  this.type = type;
  this.x = x;
  this.y = y;
  this.coords = coords;
  this.radius = radius;
}

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
        if (!elements.has(backElement.name)) {
          let newElement = this.createElement(backElement);

          app.stage.addChild(newElement.boardObject);
          elements.set(backElement.name, newElement);
        }
        let element = elements.get(backElement.name);
        this.updateElementColor(element, backElement.is_colliding);

        this.updateElementPosition(
          element,
          backElement.x,
          backElement.y
        );
      });
    });

    app.ticker.add(() => {
      elements.forEach((element) => {
        // Use linear interpolation (lerp) for smoother movement
        element.boardObject.x +=
          (element.x - element.boardObject.x) * easing;
        element.boardObject.y +=
          (element.y - element.boardObject.y) * easing;

        // Update the element's position
        element.boardObject.position.x = element.boardObject.x;
        element.boardObject.position.y = element.boardObject.y;
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
      element.x = x;
      element.y = y;
    }),
    (this.createElement = function (backElement) {
      newElement = new Element(backElement);
      newElement.boardObject = new Graphics();

      newElement.boardObject.beginFill(0xffffff);

      switch (newElement.shape) {
        case "circle":
          newElement.boardObject.drawCircle(0, 0, newElement.radius);
          break;
        case "polygon":
          newElement.boardObject.drawPolygon(newElement.coords.flat());
          break;
      }

      newElement.boardObject.endFill();

      newElement.boardObject.on("pointerover", (event) => {
        this.updateDebug(
          newElement.name +
            " - " +
            "pos: [" +
            Math.round(newElement.boardObject.position.x) +
            "," +
            Math.round(newElement.boardObject.position.y) +
            "]"
        );
      });
      newElement.boardObject.on("pointerleave", (event) => {
        this.updateDebug("");
      });
      newElement.boardObject.eventMode = "static";

      return newElement;
    }),
    (this.updateDebug = function (msg) {
      document.querySelector("#board-debug span").innerHTML = msg;
    }),
    this.updateElementColor = function (element, is_colliding){
      let color;
      if (is_colliding == true){
        color = colors.colliding;
      } else {
        switch (element.type) {
          case "player":
            color =
              element.id == player_id
                ? colors.currentPlayer
                : colors.players;
            break;
          case "obstacle":
            color = colors.obstacle;
            break;
        }
      }
      element.boardObject.tint = color;
    }
};
