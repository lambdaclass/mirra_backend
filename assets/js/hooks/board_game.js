import { Application, Container, Graphics } from "pixi.js";
import { Player } from "../game/player.js";

function Entity({ id, name, shape, category, x, y, coords, radius }) {
  this.id = id;
  this.name = name;
  this.shape = shape;
  this.category = category;
  this.x = x;
  this.y = y;
  this.coords = coords;
  this.radius = radius;
}

export const BoardGame = function () {
  const easing = 0.2;
  const entities = new Map();
  const colors = {
    board: 0xb5b8c8,
    currentPlayer: 0x007cff,
    players: 0x000000,
    obstacle: 0x00aa77,
    colliding: 0xff0000
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
    const container = new Container();
    app.stage.addChild(container);
    container.sortableChildren = true;

    document.getElementById("board_container").appendChild(app.view);

    window.addEventListener("phx:updateEntities", (e) => {
      Array.from(e.detail.entities).forEach((backEntity) => {
        if (!entities.has(backEntity.name)) {
          let newEntity = this.createEntity(backEntity);

          container.addChild(newEntity.boardObject);
          entities.set(backEntity.name, newEntity);
        }
        let entity = entities.get(backEntity.name);
        this.updateEntityColor(entity, backEntity.is_colliding);

        this.updateEntityPosition(
          entity,
          backEntity.x,
          backEntity.y
        );
      });
    });

    app.ticker.add(() => {
      entities.forEach((entity) => {
        // Use linear interpolation (lerp) for smoother movement
        entity.boardObject.x +=
          (entity.x - entity.boardObject.x) * easing;
        entity.boardObject.y +=
          (entity.y - entity.boardObject.y) * easing;

        // Update the entity's position
        entity.boardObject.position.x = entity.boardObject.x;
        entity.boardObject.position.y = entity.boardObject.y;
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
    (this.updateEntityPosition = function (entity, x, y) {
      entity.x = x;
      entity.y = y;
    }),
    (this.createEntity = function (backEntity) {
      newEntity = new Entity(backEntity);
      newEntity.boardObject = new Graphics();

      newEntity.boardObject.beginFill(0xffffff);

      switch (newEntity.shape) {
        case "circle":
          newEntity.boardObject.drawCircle(0, 0, newEntity.radius);
          break;
        case "polygon":
          newEntity.boardObject.drawPolygon(newEntity.coords.flat());
          break;
      }

      switch (newEntity.category) {
        case "player":
          newEntity.boardObject.zIndex = 10;
          break;
        case "obstacle":
          newEntity.boardObject.zIndex = 1;
          break;
      }

      newEntity.boardObject.endFill();

      newEntity.boardObject.on("pointerover", (event) => {
        this.updateDebug(
          newEntity.name +
            " - " +
            "pos: [" +
            Math.round(newEntity.boardObject.position.x) +
            "," +
            Math.round(newEntity.boardObject.position.y) +
            "]"
        );
      });
      newEntity.boardObject.on("pointerleave", (event) => {
        this.updateDebug("");
      });
      newEntity.boardObject.eventMode = "static";

      return newEntity;
    }),
    (this.updateDebug = function (msg) {
      document.querySelector("#board-debug span").innerHTML = msg;
    }),
    this.updateEntityColor = function (entity, is_colliding){
      let color;
      if (is_colliding == true){
        color = colors.colliding;
      } else {
        switch (entity.category) {
          case "player":
            color =
              entity.id == player_id
                ? colors.currentPlayer
                : colors.players;
            break;
          case "obstacle":
            color = colors.obstacle;
            break;
        }
      }
      entity.boardObject.tint = color;
    }
};

function getGameSocketUrl(game_id, player_id) {
  let protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:'
  let host = window.location.host
  let path = '/play'

  return `${protocol}${host}${path}/${game_id}/${player_id}`
}
