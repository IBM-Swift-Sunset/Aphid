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
    case connect = 0x01
    case connack = 0x02
    case publish = 0x03
}
let Connect: UInt8  = 1
let Connack  = 2
let Publish  = 3

enum ErrorCodes : Byte {
    case accepted                       = 0x00
    case errRefusedBadProtocolVersion   = 0x01
    case errRefusedIDRejected           = 0x02
}

protocol ControlPacket {
    
    func write(writer: SocketWriter) throws
    func unpack(reader: SocketReader)
    func validate()
}

struct FixedHeader {
    let messageType: ControlCode
    let dup: Bool
    let qos: UInt16
    let retain: Bool
    var remainingLength: UInt8
}

struct Details {
    var qos: Byte
    var messageID: UInt16
}

extension FixedHeader: CustomStringConvertible {
    
    var description: String {
        return "\(messageType): dup: \(dup) qos: \(qos)"
    }
    
}

extension FixedHeader {
    
    func pack() -> NSData {
        let data = NSMutableData()
        data.append(encode(messageType.rawValue << 4 | encodeBit(dup) << 3 | (encodeUInt16(qos)[1] >> 16) << 2 |
                                               (encodeUInt16(qos)[1] >> 16) << 1 | encodeBit(dup)))
        data.append(encode(remainingLength))
        return data
    }

    init(messageType: ControlCode) {
        self.messageType = messageType
        self.dup = true
        self.qos = 0x01
        self.retain = true
        self.remainingLength = 1
    }
}

func newControlPacket(packetType: Byte) -> ControlPacket? {
    switch packetType {
    case Connect:
        return ConnectPacket(fixedHeader: FixedHeader(messageType: .connect), clientIdentifier: "Hello" )
    default:
        return nil
    }
}

func encodeString(str: String) -> NSData? {
    return str.data(using: NSUTF8StringEncoding)
}

func encodeBit(_ bool: Bool) -> Byte {
    return bool ? 0x01 : 0x00
}

func encodeUInt16(_ value: UInt16) -> [Byte] {
    var bytes: [UInt8] = [0x00, 0x00]
    bytes[0] = UInt8(value >> 8)
    bytes[1] = UInt8(value & 0x00ff)
    return bytes
}
    

func encodeLength() -> [Byte] {
    var encLength = [Byte]()
    
    return encLength
}

public func encode<T>(_ value: T) -> NSData {
    var value = value
    return withUnsafePointer(&value) { p in
        NSData(bytes: p, length: sizeofValue(value))
    }
}