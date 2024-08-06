import { Application, Container, Graphics, Text } from "pixi.js";

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
  const easing = 0.4;
  const entities = new Map();
  const colors = {
    board: 0xb5b8c8,
    currentPlayer: 0x007cff,
    players: 0x000000,
    obstacle: 0x00aa77,
    transitioningObstacle: 0xff944d,
    deactivatedObstacle: 0xff0000,
    lakeObstacle: 0xff7900,
    colliding: 0xff0000,
    projectile: 0x0000ff,
    item: 0x238636,
    trap: 0x6600cc,
    crate: 0xcc9900,
    bush: 0x9DE7CA,
    pool: 0x00ffff
  };
  let player_id;

  let movementKeys = {
    W: { state: false, direction: { x: 0, y: -1 } },
    A: { state: false, direction: { x: -1, y: 0 } },
    S: { state: false, direction: { x: 0, y: 1 } },
    D: { state: false, direction: { x: 1, y: 0 } },
  };

  (this.mounted = function () {
    let _this = this;
    let game_id = document.getElementById("board_game").dataset.gameId;
    let player_id = document.getElementById("board_game").dataset.playerId;

    const app = new Application({
      width: document.getElementById("board_game").dataset.boardWidth,
      height: document.getElementById("board_game").dataset.boardHeight,
      backgroundColor: colors.board,
    });
    const container = new Container();
    app.stage.addChild(container);
    container.sortableChildren = true;

    document.getElementById("board_container").appendChild(app.view);


    window.addEventListener("phx:joinedGame", (e) => {
      let zoneCircle = new Graphics();
      zoneCircle.beginFill(0xFFFFFF)
      zoneCircle.lineStyle(1, 0x000000, 1);
      zoneCircle.drawCircle(
        document.getElementById("board_game").dataset.boardWidth / 2,
        document.getElementById("board_game").dataset.boardHeight / 2,
        document.getElementById("board_game").dataset.mapRadius
      );
      zoneCircle.zIndex = 0;
      zoneCircle.endFill();
      container.addChild(zoneCircle);
    })

    window.addEventListener("phx:updateEntities", (e) => {
      // Updates every entity's info and position, and creates it if it doesn't exist
      let selfBackEntity = Array.from(e.detail.entities).find((backEntity) => backEntity.id == e.detail.player_id)

      Array.from(e.detail.entities).forEach((backEntity) => {
        if (Array.from(selfBackEntity.visible_players).includes(backEntity.id) || backEntity.category != "player" || backEntity.id === e.detail.player_id) {
          if (!entities.has(backEntity.id)) {
            let newEntity = this.createEntity(backEntity);

            container.addChild(newEntity.boardObject);
            entities.set(backEntity.id, newEntity);
          }
          let entity = entities.get(backEntity.id);
          this.updateEntityColor(entity, backEntity.is_colliding, backEntity);
          this.updateEntityText(entity, backEntity);

          this.updateEntityPosition(entity, backEntity.x, backEntity.y);
        } else if (entities.has(backEntity.id)) {
          let toRemoveEntity = entities.get(backEntity.id)
          container.removeChild(toRemoveEntity.boardObject)
          entities.delete(backEntity.id)
        }
      });
    });

    window.addEventListener("phx:debug_mode", (e) => {
      for (const [_, entity] of entities.entries()) {
        if (entity.category == "player") {

          if (entity.debugText) {
            app.stage.removeChild(entity.debugText)
            entity.debugText = null
          } else {
            debugText = new Text('[]', {
              style: {
                fontFamily: 'Arial',
                fontSize: 24,
                fill: 0xff1010,
                align: 'center',
              },
            });
            app.stage.addChild(debugText);
            entity.debugText = debugText;
          }
        }
      }
    });

    app.ticker.add(() => {
      entities.forEach((entity) => {
        // Use linear interpolation (lerp) for smoother movement
        entity.boardObject.x += (entity.x - entity.boardObject.x) * easing;
        entity.boardObject.y += (entity.y - entity.boardObject.y) * easing;

        // Update the entity's position
        entity.boardObject.position.x = entity.boardObject.x;
        entity.boardObject.position.y = entity.boardObject.y;
      });
    });

    document.addEventListener("keydown", function onPress(event) {
      if (event.repeat) return;

      const key = event.key.toUpperCase();

      if (Object.keys(movementKeys).includes(key)) {
        movementKeys[key].state = true;
        _this.pushEvent("move", movementKeys[key].direction);
        _this.updateDebug("key: " + key);
      }



      if (event.key === "i") {
        _this.pushEvent("attack", "1");
        _this.updateDebug("key: " + key);
      }

      if (event.key === "o") {
        _this.pushEvent("attack", "2");
        _this.updateDebug("key: " + key);
      }

      if (event.key === "p") {
        _this.pushEvent("attack", "3");
        _this.updateDebug("key: " + key);
      }

      if (event.key === "l") {
        _this.pushEvent("use_item", "1");
        _this.updateDebug("key: " + key);
      }
    });

    document.addEventListener("keyup", function onPress(event) {
      const key = event.key.toUpperCase();
      if (Object.keys(movementKeys).includes(key)) {
        movementKeys[key].state = false;

        if (!Object.values(movementKeys).some((keyItem) => keyItem.state)) {
          _this.pushEvent("move", { x: 0, y: 0 });
          _this.updateDebug("");
        } else {
          const previousKey = Object.keys(movementKeys).find(
            (keyItem) => movementKeys[keyItem].state
          );
          const previousDirection = movementKeys[previousKey].direction;
          _this.updateDebug("key: " + previousKey);
          _this.pushEvent("move", previousDirection);
        }
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


      // Use the correct draw functions based on the shape
      switch (newEntity.shape) {
        case "circle":
          newEntity.boardObject.drawCircle(0, 0, newEntity.radius);
          break;
        case "polygon":
          newEntity.boardObject.lineStyle(1, 0xFF00FF, 1);
          newEntity.boardObject.drawPolygon(newEntity.coords.flat());
          break;
      }

      // Set the display order position based on the category
      switch (newEntity.category) {
        case "player":
          newEntity.boardObject.zIndex = 10;
          break;
        case "obstacle":
          newEntity.boardObject.zIndex = 1;
          break;
        case "projectile":
          newEntity.boardObject.zIndex = 15;
          break;
        case "item":
          newEntity.boardObject.zIndex = 20;
          break;
        case "trap":
          newEntity.boardObject.zIndex = 5;
          break;
        case "crate":
          newEntity.boardObject.zIndex = 5;
          break;
        case "pool":
          newEntity.boardObject.zIndex = 2;
          break;
      }

      newEntity.boardObject.endFill();

      newEntity.boardObject.position.x = newEntity.x;
      newEntity.boardObject.position.y = newEntity.y;

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
    (this.updateEntityColor = function (entity, is_colliding, backEntity) {
      let color;
      if (is_colliding == true) {
        color = colors.colliding;
      } else {
        switch (entity.category) {
          case "player":
            color =
              entity.id == player_id ? colors.currentPlayer : colors.players;
            break;
          case "obstacle":
            switch (backEntity.type) {
              case "lake":
                color = colors.lakeObstacle;
                break;
              case "dynamic":
                if (backEntity.status === "underground") {
                  color = colors.deactivatedObstacle;
                } else if (backEntity.status === "transitioning") {
                  color = colors.transitioningObstacle;
                } else {
                  color = colors.obstacle;
                }
                break;
              default:
                color = colors.obstacle;
                break;
            }
            break;
          case "projectile":
            color = colors.projectile;
            break;
          case "item":
            color = colors.item;
            break;
          case "crate":
            color = colors.crate;
            break;
          case "trap":
            color = colors.trap;
            break;
          case "bush":
            color = colors.bush;
            break;
          case "pool":
            color = colors.pool;
        }
      }
      entity.boardObject.tint = color;
    }),
    (this.updateEntityText = function (entity, backEntity) {
      if (entity.category == "player" && entity.debugText) {
        entity.debugText.text = "health: " + backEntity.health + "\n";
        entity.debugText.text += "Position: x:" + (backEntity.back_x).toFixed(2) + " y: " + (backEntity.back_y).toFixed(2) + "\n";
        entity.debugText.text += "Effects: [" + backEntity.effects.join('\n') + "]" + "\n";
        entity.debugText.x = entity.x
        entity.debugText.y = entity.y + 25
      }
    })
};
