/**
 Copyright IBM Corporation 2016
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import Foundation
import Socket

protocol ControlPacket {
    var description: String { get }
    func write(writer: SocketWriter) throws
    func unpack(reader: SocketReader)
    func validate() -> ErrorCodes
}

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

public enum ControlCode: Byte {
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

public enum ErrorCodes: Byte {
    case accepted                       = 0x00
    case errRefusedBadProtocolVersion   = 0x01
    case errRefusedIDRejected           = 0x02
    case errServerUnavailable           = 0x03
    case errBadUsernameOrPassword       = 0x04
    case errNotAuthorize                = 0x05
    case errUnknown                     = 0x06
}
public enum qosType: Byte {
    case atMostOnce = 0x00 // At Most One Delivery
    case atLeastOnce = 0x01 // At Least Deliver Once
    case exactlyOnce = 0x02 // Deliver Exactly Once
}

public struct FixedHeader {
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
    init?(_ data: Data){
        self.messageType = UInt8(data[0] & 0xF0) >> 4
        dup = ((data[0] & 0x08) >> 3).bool
        qos = (data[0] & 0x06) >> 1
        retain = (data[0] & 0x01).bool
        remainingLength = Int(data[1])
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

   public var description: String {
        return "\(messageType): dup: \(dup) qos: \(qos) retain \(retain) remainingLength \(remainingLength)"
    }
    var desc: String {
        return "\(messageType): dup: \(dup) qos: \(qos) retain \(retain) remainingLength \(remainingLength)"
    }

}

extension Aphid {
    func newControlPacket(packetType: ControlCode, topicName: String? = nil, packetId: UInt16? = nil,
                          topics: [String]? = nil, qoss: [qosType]? = nil, message: [String]? = nil, returnCode: Byte? = nil) -> ControlPacket? {
        switch packetType {
        case .connect:
            return ConnectPacket(header: FixedHeader(messageType: .connect), clientId: clientId )
        case .connack:
            return ConnackPacket(header: FixedHeader(messageType: .connack))
        case .publish:
            return PublishPacket(header: FixedHeader(messageType: .publish), topicName: topicName!, packetId: packetId!, payload: message!)
        case .puback:
            return PubackPacket(header: FixedHeader(messageType: .puback), packetId: packetId!)
        case .pubrec:
            return PubrecPacket(header: FixedHeader(messageType: .pubrec), packetId: packetId!)
        case .pubrel:
            return PubrelPacket(header: FixedHeader(messageType: .pubrel), packetId: packetId!)
        case .pubcomp:
            return PubcompPacket(header: FixedHeader(messageType: .pubcomp), packetId: packetId!)
        case .subscribe:
            return SubscribePacket(header: FixedHeader(messageType: .subscribe), packetId: packetId!, topics: topics!, qoss: qoss!)
        case .suback:
            return SubackPacket(header: FixedHeader(messageType: .suback), packetId: packetId!, returnCode: returnCode!)
        case .unsubscribe:
            return UnsubscribePacket(header: FixedHeader(messageType: .unsubscribe), packetId: packetId!, topics: topics!)
        case .unsuback:
            return UnSubackPacket(header: FixedHeader(messageType: .unsuback), packetId: packetId!)
        case .pingreq:
            return PingreqPacket(header: FixedHeader(messageType: .pingreq))
        case .pingresp:
            return PingrespPacket(header: FixedHeader(messageType: .pingresp))
        case .disconnect:
            return DisconnectPacket(header: FixedHeader(messageType: .disconnect))
        default:
            return nil
        }
    }
    func newControlPacket(header: FixedHeader, data: Data) -> ControlPacket? {
        let code: ControlCode = ControlCode(rawValue: (header.messageType << 4))!
        switch code {
        
        case .connect:
            return ConnectPacket(header: header, data: data)
        case .connack:
            return ConnackPacket(header: header, data: data)
        case .publish:
            return PublishPacket(header: header, data: data)
        case .puback:
            return PubackPacket(header: header, data: data)
        case .pubrec:
            return PubrecPacket(header: header, data: data)
        case .pubrel:
            return PubrelPacket(header: header, data: data)
        case .pubcomp:
            return PubcompPacket(header: header, data: data)
        case .subscribe:
            return SubscribePacket(header: header, data: data)
        case .suback:
            return SubackPacket(header: header, data: data)
        case .unsubscribe:
            return UnsubscribePacket(header: header, data: data)
        case .unsuback:
            return UnSubackPacket(header: header, data: data)
        case .pingreq:
            return PingreqPacket(header: header)
        case .pingresp:
            return PingrespPacket(header: header)
        case .disconnect:
            return DisconnectPacket(header: header)
        default:
            return ConnackPacket(header: header, data: data)
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
    
    var int: Int {
        return Int(self)
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
    init(random: Bool){
        var r: UInt16 = 0
        arc4random_buf(&r, sizeof(UInt16.self))
        self = r
    }
    
    init(msb: Byte, lsb: Byte) {
        self = (UInt16(msb) << 8) | UInt16(lsb)
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
extension Data {
    var decodeUInt8: UInt8 {
        mutating get {
            let uint = UInt8(self[0])
            self = self.subdata(in: Range(uncheckedBounds: (1, self.count)))
            return uint
        }
    }
    var decodeUInt16: UInt16 {
        mutating get {
            let uint = UInt16(msb: self[0], lsb: self[1])
            self = self.subdata(in: Range(uncheckedBounds: (2,self.count)))
            return uint
        }
    }
    var decodeString: String {
        mutating get {
            let length = UInt16(msb: self[0], lsb: self[1])
            let str = self.subdata(in: Range(uncheckedBounds: (2, 2 + Int(length))))
            self = self.subdata(in: Range(uncheckedBounds: (2 + Int(length), self.count)))
            return String(str)
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
