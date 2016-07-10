
import Foundation
import Socket

// Aphid
public class Aphid {
    
    
    func connectFlags(cleanSession: Bool, willFlag: Bool, willQoS: Bool ) -> UInt8 {
        
        return 0x00
        
    }
    
    enum ControlPacketType: UInt8 {
        case connect = 0x10
        case publish = 0x03
        case pubAck  = 0x40
    }
    
    func encode<T>( value: T) -> NSData {
        var value = value
        return withUnsafePointer(&value) { p in
            NSData(bytes: p, length: sizeofValue(value))
        }
    }
    
    struct FixedHeader {
        var type: ControlPacketType
        var remainingLength: UInt8 = 0
    }
    
    struct ConnectPacket {
        let mqtt: [UInt8] = [0x4C, 0x51, 0x54, 0x54]
        let level: UInt8 = 0x04
        let flags: UInt8 = 0x00
        let keepAliveMSB: UInt8 = 0x00
        let keepAliveLSB: UInt8 = 0x01
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
        
        var controlPacket = FixedHeader(type: .connect, remainingLength: 0)
        let connectPacket = ConnectPacket()
        
        var length = sizeof(FixedHeader) + sizeof(ConnectPacket)
        
        print("Remaining length is \(length)")
        
        
        
//        out.append(encode(value: 0x10))
//        out.append(encode(value: 0)) // length
//        out.append(encode(value: 0x4C))
//        out.append(encode(value: 0x51))
//        out.append(encode(value: 0x54))
//        out.append(encode(value: 0x54))
//        out.append(encode(value: 0x04))
//        out.append(encode(value: 0x00))
//        out.append(encode(value: 0x00))
//        out.append(encode(value: 0x01))
        
        // buffer[0] = Aphid.CONNECT
//        buffer[1] = 0               // length TODO
//        buffer[2] = 0x4C            // M
//        buffer[3] = 0x51            // Q
//        buffer[4] = 0x54            // T
//        buffer[5] = 0x54            // T
//        buffer[6] = 0x04            // protocol level 4
//        buffer[7] = connectFlags(cleanSession: false, willFlag: false, willQoS: false)
//        buffer[8] = 0x00            // keep alive duration
//        buffer[9] = 0x01            // 1 second
        
        let clientIDData = clientID.data(using: NSUTF8StringEncoding)!
        
        length += clientIDData.length
        
        controlPacket.remainingLength = UInt8(10 + length)
        
        out.append(encode(value: controlPacket))
        out.append(encode(value: connectPacket))
        out.append(clientIDData)
        
        
        try socket.write(from: out)
        
        let incomingLength = try socket.read(into: incomingData!)
        
        print(incomingLength)
        
    }
    
}