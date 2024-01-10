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
        var message = new messages.Direction();
        
        message.setX(direction_x);
        message.setY(direction_y);
        
        console.log("Pressed: " + event.key + ". Msg: [" + message.getX() + ", " + message.getY() + "]");

        return message.serializeBinary();
    }
}
