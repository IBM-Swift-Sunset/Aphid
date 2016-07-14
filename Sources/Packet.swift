//
//  Packet.swift
//  Aphid
//
//  Created by Robert F. Dickerson on 7/10/16.
//
//

import Foundation
import Socket

let PacketNames : [UInt8:String] = [
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

enum ControlCode : Byte {
    case connect    = 0x01
    case connack    = 0x02
    case publish    = 0x03
    case puback     = 0x04
    case pubrec     = 0x05
    case pubrel     = 0x06
    case pubcomp    = 0x07
    case subscribe  = 0x08
    case suback     = 0x09
    case unsubscribe = 0x0a
    case unsuback   = 0x0b
    case pingreq    = 0x0c
    case pingresp   = 0x0d
    case disconnect = 0x0e
    case reserved   = 0x0f
}
let Connect: UInt8  = 1
let Connack: UInt8  = 2
let Publish  = 3

enum ErrorCodes : Byte {
    case accepted                       = 0x00
    case errRefusedBadProtocolVersion   = 0x01
    case errRefusedIDRejected           = 0x02
    case error                          = 0x03
}
enum qosType: UInt8 {
    case atMostOnce = 0 // At Most One Delivery
    case atLeave = 1 // At Least Deliver Once
    case exactlyOnce = 2 // Deliver Exactly Once
}
struct Details {
    var qos: Byte
    var messageID: UInt16
}
struct FixedHeader {
    let messageType: ControlCode
    var dup: Bool
    var qos: UInt16
    var retain: Bool
    var remainingLength: UInt8
    
    init(messageType: ControlCode) {
        self.messageType = messageType
        self.dup = false
        self.qos = 0x00
        self.retain = false
        self.remainingLength = 1
    }
    
    func pack() -> Data {
        var data = Data()
        data.append(encodeUInt8(messageType.rawValue << 4 | encodeBit(dup) << 3 | (encodeUInt16(qos)[0] >> 7) << 2 |
                         (encodeUInt16(qos)[1] >> 7) << 1 | encodeBit(dup)))
        data.append(encodeUInt8(remainingLength))
        return data
    }
}

extension FixedHeader: CustomStringConvertible {
    
    var description: String {
        return "\(messageType): dup: \(dup) qos: \(qos)"
    }
    
}

extension Aphid {
    func newControlPacket(packetType: ControlCode) -> ControlPacket? {
        switch packetType {
        case .connect:
            return ConnectPacket(header: FixedHeader(messageType: .connect), clientId: clientId )
        case .connack:
            return ConnackPacket(header: FixedHeader(messageType: .connack))
        case .publish:
            return PublishPacket(header: FixedHeader(messageType: .publish), topicName: "Test", packetIdentifier: 0x00) // Wrong
        case .subscribe:
            return SubscribePacket(header: FixedHeader(messageType: .subscribe), messageID: 0, topics: [String](), qoss: [Byte]())  // Wrong
        case .unsubscribe:
            return UnsubscribePacket(header: FixedHeader(messageType: .unsubscribe), messageID: 0x00, topics: [String]()) // Wrong
        case .disconnect:
            return DisconnectPacket(header: FixedHeader(messageType: .disconnect))
        default:
            return nil
        }
    }
}

func encodeString(str: String) -> Data {
    var array = Data()
    
    let utf = str.data(using: String.Encoding.utf8)!
    array.append(encodeUInt16T(UInt16(utf.count)))
    array.append(utf)
    return array
}

func encodeBit(_ bool: Bool) -> Byte {
    return bool ? 0x01 : 0x00
}

func encodeUInt16T(_ value: UInt16) -> Data {
    var data = Data()
    var bytes: [UInt8] = [0x00, 0x00]
    bytes[0] = UInt8(value >> 8)
    bytes[1] = UInt8(value & 0x00ff)
    data.append(Data(bytes: bytes, count: 2))
    return data
}
func encodeUInt16(_ value: UInt16) -> [Byte] {
    var bytes: [UInt8] = [0x00, 0x00]
    bytes[0] = UInt8(value >> 8)
    bytes[1] = UInt8(value & 0x00ff)
    return bytes
}

func encodeUInt8(_ value: UInt8) -> Data {
    return Data(bytes: [value])
}

/*func encodeUInt16(_ value: UInt16) -> Data {
    var value = value
    return Data(bytes: &UInt8(value), count: sizeof(UInt16))
}*/

/*public func encode<T>(_ value: T) -> Data {
    var value = value
    return withUnsafePointer(&value) { p in
        Data(bytes: UnsafePointer<UInt8>(p), count: sizeof(p))
        //Data(bytes: p, count: sizeofValue(value))
    }
}*/
func getBytes(_ value: Data) {
    value.enumerateBytes() {
        buffer, byteIndex, stop in
        
        print(buffer.first!)
        if byteIndex == value.count {
            stop = true
        }
    }
}
func encodeLength(_ length: Int) -> [Byte] {
    var encLength = [Byte]()
    var length = length

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

func decodebit(_ byte: Byte) -> Bool {
    return byte == 0x01 ? true : false
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
