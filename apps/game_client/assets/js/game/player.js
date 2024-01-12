var messages = require('../protobuf/messages_pb');

export class Player{
    constructor(socketUrl) {
        this.socket = new WebSocket(socketUrl)
        this.socket.binaryType = "arraybuffer";
    }

    move(direction_x, direction_y) {
        let moveMsg = this.createMoveMessage(direction_x, direction_y);
        this.socket.send(moveMsg);
    }
    
    createMoveMessage(direction_x, direction_y) {
        var direction = new messages.Direction();
        direction.setX(direction_x);
        direction.setY(direction_y);

        var movement = new messages.Move();
        movement.setDirection(direction);

        var message = new messages.GameAction();
        message.setMove(movement)

        return message.serializeBinary();
    }

    attack() {
        let attackMsg = this.createattackMessage();
        this.socket.send(attackMsg);
    }

    createattackMessage() {
        var skill = "basic";
        
        var attack = new messages.Attack();
        attack.setSkill(skill);

        var message = new messages.GameAction();
        message.setAttack(attack)

        return message.serializeBinary();
    }
}
