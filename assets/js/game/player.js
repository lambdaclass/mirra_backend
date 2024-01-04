var messages = require('../protobuf/messages_pb');

export class Player{
    constructor(game_id) {
        this.socket = new WebSocket(this.getplayConnection(game_id))
    }

    move(direction_x, direction_y) {
        let moveMsg = this.createMoveMessage(direction_x, direction_y);
        this.socket.send(moveMsg);
    }
    
    createMoveMessage(direction_x, direction_y) {
        var message = new messages.Direction();
        
        message.setX(direction_x);
        message.setY(direction_y);
        
        console.log("Pressed: " + event.key + ". Msg: [" + message.getX() + ", " + message.getY() + "]");

        return message.serializeBinary();
    }

    getplayConnection(game_id) {
        let protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:'
        let host = window.location.host
        let path = '/play'

        return `${protocol}${host}${path}/${game_id}`
    }
}
