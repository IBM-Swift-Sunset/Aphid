
import Foundation
import Socket

public struct Token {

}
public struct ConnectionStatus: Equatable {
    
}

public func ==(lhs: ConnectionStatus, rhs: ConnectionStatus) -> Bool {
    return true
}

public protocol AphidAPI {
    func isConnected() -> Bool
    func connect() -> Token
    func disconnect(uint: UInt)
    func publish(topic: String, byte: UInt8, isRetained: Bool) -> Token
    func subscribe(topic: String, byte: UInt8, callback: (String)) -> Token //MessageHandler
    func subscribeMultiple() -> Token
    func unsubscribe(topics: [String]) -> Token
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
    var persist:         Store
    var options:         ClientOptions
    var pingTimer:       *time.Timer
    var pingRespTimer:   *time.Timer
    var pingResp:        chan struct{}*/
    var status:          ConnectionStatus
    //var workers:         sync.WaitGroup

}

let disconnected = ConnectionStatus()
let connected = ConnectionStatus()
// Aphid
public class Aphid {
    
    /*var attributes: Attributes
    var options: ClientOptions

    init() {
        attributes = Attributes(status: disconnected)
        options = ClientOptions()
    }*/
    enum ControlPacketType: UInt8 {
        case connect = 0x10
        case publish = 0x03
        case pubAck  = 0x40
    }
    
    public func connect() throws {
    
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
        
        let socket = try Socket.create(family: .inet6, type: .stream, proto: .tcp)
        try socket.setBlocking(mode: true)
        
        try socket.connect(to: "localhost", port: 1883)
        print(socket.isConnected)
        
        // var buffer = [UInt8](repeating: 0x00, count: 5192 )
        
        let buffer = NSMutableData(capacity: 512)
        let incomingData = NSMutableData(capacity: 5192)
        
        // let keepAliveDuration: UInt16 = 1
        
        let clientID = "Bob"
        
        // construct the packet
    
        guard let out = buffer else {
            throw NSError()
        }
        
        var controlPacket = FixedHeader(messageType: .connect)
        let connectPacket = ConnectPacket(fixedHeader: controlPacket, keepAliveTimer: 1, clientIdentifier: "test")
        
        
        var length = 10
        
        let clientIDData = clientID.data(using: NSUTF8StringEncoding)!
        
        length += clientIDData.length
        
        controlPacket.remainingLength = UInt8(10 + length + 2)
        
        out.append(encode(controlPacket))
        out.append(encode(connectPacket))
        out.append(encode(0x00))
        out.append(encode(0x03))
        out.append(clientIDData)
        
        try socket.write(from: out)
        
        let incomingLength = try socket.read(into: incomingData!)
        
        print(incomingLength)
        
    }
    /*func isConnected() -> Bool {
        if attributes.status == connected {
            return true
        } else if attributes.options.AutoReconnect && attributes.status > disconnected {
            return true
        }
        else {
            return false
        }
    }
    func disconnect(uint: UInt){
        guard !isConnected() else {
            NSLog("Already Disconnected")
            return
        }
        
        self.attributes.status = disconnected
        
        
    }
    func publish(topic: String, byte: UInt8, isRetained: Bool) -> Token {
        
    }
    func subscribe(topic: String, byte: UInt8, callback: (String)) -> Token { //MessageHandler
    
    }
    func subscribeMultiple() -> Token {
    
    }
    func unsubscribe(topics: [String]) -> Token {
        
    }*/

}

