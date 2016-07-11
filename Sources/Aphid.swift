
import Foundation
import Socket

// Aphid
public class Aphid {
    
    
    
    
    enum ControlPacketType: UInt8 {
        case connect = 0x10
        case publish = 0x03
        case pubAck  = 0x40
    }
    
    
    
    struct FixedHeader {
        var type: UInt8
        var remainingLength: UInt8 = 0
        
        init(type: ControlPacketType) {
            self.type = type.rawValue
        }
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
        
        var controlPacket = FixedHeader(type: .connect)
        let connectPacket = ConnectPacket(level: 4, keepAlive: 1)
        
        var length = 10
        
        let clientIDData = clientID.data(using: NSUTF8StringEncoding)!
        
        length += clientIDData.length
        
        controlPacket.remainingLength = UInt8(10 + length + 2)
        
        out.append(encode(value: controlPacket))
        out.append(encode(value: connectPacket))
        out.append(encode(value: 0x00))
        out.append(encode(value: 0x03))
        out.append(clientIDData)
        
        try socket.write(from: out)
        
        let incomingLength = try socket.read(into: incomingData!)
        
        print(incomingLength)
        
    }
    
}