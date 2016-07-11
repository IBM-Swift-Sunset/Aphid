//
//  Packet.swift
//  Aphid
//
//  Created by Robert F. Dickerson on 7/10/16.
//
//

import Foundation
import Socket

typealias Byte = UInt8

public func encode<T>( value: T) -> NSData {
    var value = value
    return withUnsafePointer(&value) { p in
        NSData(bytes: p, length: sizeofValue(value))
    }
}

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

let Connect: UInt8  = 1
let Connack  = 2
let Publish  = 3

enum errorCodes : Byte {
    case Accepted                       = 0x00
    case ErrRefusedBadProtocolVersion   = 0x01
    case ErrRefusedIDRejected           = 0x02
}

protocol ControlPacket {
    
    func write(writer: SocketWriter) throws
    func unpack(reader: SocketReader)
    func validate()
}

struct FixedHeader {
    let messageType: Byte
    let dup: Bool
    let qos: Byte
    let retain: Bool
    let remainingLength: Int
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
    
    init(messageType: Byte) {
        self.messageType = messageType
    }
}

func newControlPacket(packetType: Byte) -> ControlPacket? {
    switch packetType {
    case Connect:
        return ConnectPacket(fixedHeader: FixedHeader(messageType: Connect))
    default:
        return nil
    }
}

func encodeString(str: String) -> NSData? {
    return str.data(using: NSUTF8StringEncoding)
}

func encodeUInt16(int: UInt16) -> [Byte] {
    var bytes: [Byte] = [0x00, 0x00]
    return bytes
}

func encodeLength() -> [Byte] {
    var encLength: [Byte]()
    
    return encLength
}