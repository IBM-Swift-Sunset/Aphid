//
//  Packet.swift
//  Aphid
//
//  Created by Robert F. Dickerson on 7/10/16.
//
//

import Foundation
import Socket

let PacketNames: [UInt8:String] = [
    1: "CONNECT",
    2: "CONNACK",
    3: "PUBLISH",
    4: "PUBACK",
    5: "PUBREC",
    6: "PUBREL",
    7: "PUBCOMP",
    8: "SUBSCRIBE",
    9: "SUBACK",
    10: "UNSUBSCRIBE",
    11: "UNSUBACK",
    12: "PINGREQ",
    13: "PINGRESP",
    14: "DISCONNECT"
]

enum ControlCode: Byte {
    case connect    = 0x10
    case connack    = 0x20
    case publish    = 0x30 // special case
    case puback     = 0x40
    case pubrec     = 0x50
    case pubrel     = 0x62
    case pubcomp    = 0x70
    case subscribe  = 0x82
    case suback     = 0x90
    case unsubscribe = 0xa2
    case unsuback   = 0xb0
    case pingreq    = 0xc0
    case pingresp   = 0xd0
    case disconnect = 0xe0
    case reserved   = 0xf0
}

enum ErrorCodes: Byte {
    case accepted                       = 0x00
    case errRefusedBadProtocolVersion   = 0x01
    case errRefusedIDRejected           = 0x02
    case errServerUnavailable           = 0x03
    case errBadUsernameOrPassword       = 0x04
    case errNotAuthorize                = 0x05
    case errUnknown                     = 0x06
}
enum qosType: Byte {
    case atMostOnce = 0x00 // At Most One Delivery
    case atLeastOnce = 0x01 // At Least Deliver Once
    case exactlyOnce = 0x02 // Deliver Exactly Once
}

struct FixedHeader {
    let messageType: Byte
    var dup: Bool
    var qos: Byte
    var retain: Bool
    var remainingLength: Int

    init(messageType: ControlCode) {
        self.messageType = UInt8(messageType.rawValue & 0xF0) >> 4
        dup = ((messageType.rawValue & 0x08) >> 3).bool
        qos = (messageType.rawValue & 0x06) >> 1
        retain = (messageType.rawValue & 0x01).bool
        remainingLength = 0
    }

    func pack() -> Data {
        var data = Data()
        data.append((messageType << 4 | dup.toByte << 3 | qos << 1 | retain.toByte).data)

        for byte in remainingLength.toBytes {
            data.append(byte.data)
        }

        return data
    }
}

extension FixedHeader: CustomStringConvertible {

    var description: String {
        return "\(messageType): dup: \(dup) qos: \(qos) retain \(retain)"
    }

}

extension Aphid {
    func newControlPacket(packetType: ControlCode, topicName: String? = nil, packetId: UInt16? = nil,
                          topics: [String]? = nil, qoss: [qosType]? = nil, message: [String]? = nil) -> ControlPacket? {
        switch packetType {
        case .connect:
            return ConnectPacket(header: FixedHeader(messageType: .connect), clientId: clientId )
        case .connack:
            return ConnackPacket(header: FixedHeader(messageType: .connack))
        case .publish:
            return PublishPacket(header: FixedHeader(messageType: .publish), topicName: topicName!, packetId: packetId!, payload: message!)
        case .puback:
            return ConnackPacket(header: FixedHeader(messageType: .connack)) // Wrong
        case .pubrec:
            return ConnackPacket(header: FixedHeader(messageType: .connack)) // Wrong
        case .pubrel:
            return ConnackPacket(header: FixedHeader(messageType: .connack)) // Wrong
        case .pubcomp:
            return ConnackPacket(header: FixedHeader(messageType: .connack)) // Wrong
        case .subscribe:
            return SubscribePacket(header: FixedHeader(messageType: .subscribe), packetId: packetId!, topics: topics!, qoss: qoss!)// Wrong
        case .suback:
            return ConnackPacket(header: FixedHeader(messageType: .connack)) // Wrong
        case .unsubscribe:
            return UnsubscribePacket(header: FixedHeader(messageType: .unsubscribe), packetId: packetId!, topics: topics!) // Wrong
        case .unsuback:
            return ConnackPacket(header: FixedHeader(messageType: .connack)) // Wrong
        case .pingreq:
            return PingreqPacket(header: FixedHeader(messageType: .pingreq))
        case .pingresp:
            return ConnackPacket(header: FixedHeader(messageType: .connack)) // Wrong
        case .disconnect:
            return DisconnectPacket(header: FixedHeader(messageType: .disconnect))
        default:
            return nil
        }
    }
}


extension Bool {

    var toByte: Byte {
        get {
            return self ? 0x01 : 0x00
        }
    }
}
extension String {

    init(_ reader: SocketReader) {
        let fieldLength = decodeUInt16(reader)
        let field = NSMutableData(capacity: Int(fieldLength))
        do {
            let _ = try reader.read(into: field!)
        } catch {
            
        }
        self = String(field)
    }

    var data: Data {
        get {
            var array = Data()

            let utf = self.data(using: String.Encoding.utf8)!

            array.append(UInt16(utf.count).data)
            array.append(utf)

            return array
        }
    }
}
extension Int {

    init(_ reader: SocketReader) {     // This doesn't work at the moment
        var rLength: UInt32 = 0
        var multiplier: UInt32 = 0
        var b: Byte = 0x00
        while true {
            b = UInt8(reader)
            let digit = b[0]
            rLength |= UInt32(digit & 127) << multiplier
            if (digit & 128) == 0 {
                break
            }
            multiplier += 7
        }
        self = Int(rLength)
    }

    var toBytes: [Byte] {
        get {
            var encLength = [Byte]()
            var length = self
            
            repeat {
                var digit = Byte(length % 128)
                length /= 128
                if length > 0 {
                    digit |= 0x80
                }
                encLength.append(digit)
                
            } while length != 0
            
            return encLength
        }
    }
    
}
extension UInt8 {

    init(_ reader: SocketReader) {
        let num = NSMutableData(capacity: 1)
        do {
            let _ = try reader.read(into: num!)
        } catch {
            
        }
        self = decode(num!)
    }

    var data: Data {
        return Data(bytes: [self])
    }

    var bool: Bool {
        return self == 0x01 ? true : false
    }
    
    subscript(index: Int) -> UInt8 { //Returns a byte with only the index bit set if applicable
        return 0
    }
}
extension UInt16 {

    init(_ reader: SocketReader) {
        let uint = NSMutableData(capacity: 2)
        do {
            let _ = try reader.read(into: uint!)
        } catch {
            
        }
        self = decode(uint!)
    }

    var data: Data {
        get {
            var data = Data()
            var bytes: [UInt8] = [0x00, 0x00]
            bytes[0] = UInt8(self >> 8)
            bytes[1] = UInt8(self & 0x00ff)
            data.append(Data(bytes: bytes, count: 2))
            return data
        }
    }

    var bytes: [Byte] {
        get {
            var bytes: [UInt8] = [0x00, 0x00]
            bytes[0] = UInt8(self >> 8)
            bytes[1] = UInt8(self & 0x00ff)
            return bytes
        }
    }
}


func getBytes(_ value: Data) {
    value.enumerateBytes() {
        buffer, byteIndex, stop in

        print(buffer.first!)
        if byteIndex == value.count {
            stop = true
        }
    }
}

func decodeString(_ reader: SocketReader) -> String {
    let fieldLength = decodeUInt16(reader)
    let field = NSMutableData(capacity: Int(fieldLength))
    do {
       let _ = try reader.read(into: field!)
    } catch {

    }
    return String(field)
}
func decodeUInt8(_ reader: SocketReader) -> UInt8 {
    let num = NSMutableData(capacity: 1)
    do {
        let _ = try reader.read(into: num!)
    } catch {

    }
    return decode(num!)
}
func decodeUInt16(_ reader: SocketReader) -> UInt16 {
    let uint = NSMutableData(capacity: 2)
    do {
        let _ = try reader.read(into: uint!)
    } catch {

    }
    return decode(uint!)
}
public func decode<T>(_ data: NSData) -> T {
    let pointer = UnsafeMutablePointer<T>(allocatingCapacity: sizeof(T.self))
    data.getBytes(pointer, length: sizeof(T.self))
    return pointer.move()
}
func decodeLength(_ bytes: [Byte]) -> Int {
    var rLength: UInt32 = 0
    var multiplier: UInt32 = 0
    var b: [Byte] = [0x00]
    while true {
        let digit = b[0]
        rLength |= UInt32(digit & 127) << multiplier
        if (digit & 128) == 0 {
            break
        }
        multiplier += 7
    }
    return Int(rLength)
}
