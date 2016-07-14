
import Foundation
import Socket

public struct Token {

}
public struct ConnectionStatus: Equatable {
    
}

public func ==(lhs: ConnectionStatus, rhs: ConnectionStatus) -> Bool {
    return true
}

typealias Byte = UInt8

enum ControlPacketType: UInt8 {
    case connect = 0x10
    case publish = 0x03
    case pubAck  = 0x40
}

struct Attributes {
/*    var conn:            net.Conn
    var ibound:          chan packets.ControlPacket
    var obound:          chan *PacketAndToken
    var oboundP:         chan *PacketAndToken
    var msgRouter:       *router
    var stopRouter:      chan bool
    var incomingPubChan: chan *packets.PublishPacket
    var errors:         chan error
    var stop:            chan struct{}
    var persist:         Store*/
    var options:         ClientOptions
    var status:          ConnectionStatus
    //var workers:         sync.WaitGroup

}

let disconnected = ConnectionStatus()
let connected = ConnectionStatus()

// Aphid
public class Aphid {
    
    var host = "localhost"
    var port: Int32 = 1883
    var clientId: String
    var username: String?
    var password: String?
    var secureMQTT: Bool = false
    var cleanSess: Bool = true
    
    var socket: Socket?

    var attributes = Attributes(options: ClientOptions(), status: ConnectionStatus())
    
    init(clientId: String, username: String? = nil, password: String? = nil) {
        self.clientId = clientId
        self.username = username
        self.password = password
    }
    
    public func connect() throws -> Bool {
    
        // Send Fixed header
        // 0 0 0 1 0 0 0 0
        // remaining length (10 bytes + length of payload
        
        // variable header 
        // length MSB (0)   0 0 0 0 0 0 0 0
        // length LSB (4)   0 0 0 0 0 1 0 0
        // byte 3 'M'       0 1 0 0 1 1 0 1
        // byte 4 'Q'       0 1 0 1 0 0 0 1
        // byte 5 'T'       0 1 0 1 0 1 0 0
        // byte 6 'T'       0 1 0 1 0 1 0 0
        
        // Protocol Level
        
        // byte 7 level 4   0 0 0 0 0 1 0 0
        
        // Connect flags
        // The connect flags contains a number of parameters specifying the behavior of the MQTT connection.
        // It also indicates the presence or absence of fields in the payload.
        
        // byte 8           x x x x x x x 0
        
        // byte 9 keepalive (MSB)
        
        // The Keep Alive is a time interval measured in seconds. Expressed as a 16-bit word, it is the maximum
        // time interval that is permitted to elapse between the point at which the Client finishes transmitting one
        // Control Package and the point it starts sending the next. It is the reponsibility of the Client to ensure
        // that the interval between Control Packets being sent does not exceed the Keep Alive value. In the absence
        // of sending any other Control Packets, the Client MUST send a PINGREQ Packet
        
        // byte 10 keepalive (LSB)
        
        socket = try Socket.create(family: .inet6, type: .stream, proto: .tcp)
        try socket?.setBlocking(mode: true)
        
        try socket?.connect(to: host, port: port)
        print(socket?.isConnected)
        
        guard let sock = socket else {
            throw NSError()
        }
        
        let buffer = NSMutableData(capacity: 512)
        let incomingData = NSMutableData(capacity: 5192)
            
        guard buffer != nil else {
            throw NSError()
        }
        
        guard let connectPacket = newControlPacket(packetType: .connect) else {
            throw NSError()
        }
        
        try connectPacket.write(writer: sock)

        //let incomingLength = try socket.read(into: incomingData!)
        print(incomingData!.length)

        let _ = parseConnack(reader: sock)

        return true
    }

    func isConnected() -> Bool {
        if attributes.status == connected {
            return true
        } else if attributes.options.AutoReconnect && attributes.status == disconnected {
            return true
        }
        else {
            return false
        }
    }
    func disconnect(uint: UInt) throws {
        guard !isConnected() else {
            NSLog("Already Disconnected")
            return
        }
        
        attributes.status = disconnected
        
        guard let disconnectPacket = newControlPacket(packetType: .disconnect) else {
            throw NSError()
        }
        
        guard let sock = socket else {
            throw NSError()
        }
        try disconnectPacket.write(writer: sock)
        
        
    }
    func publish(topic: String, withString string: String, qos: qosType, retained: Bool, dup: Bool) -> UInt16 {
        return 0
    }
    func publish(message: String) -> UInt16 {
        return 0
    }
    func subscribe(topic: String, qos: String) -> UInt16 {
        return 0
    }
    func unsubscribe(topic: String) -> UInt16 {
        return 0
    }
    func ping() {
        
    }
}

