//
//  Connect.swift
//  Aphid
//
//  Created by Robert F. Dickerson on 7/10/16.
//
//

import Foundation

import Socket

protocol ControlPacket {

    func write(writer: SocketWriter) throws
    func unpack(reader: SocketReader)
    func validate() -> ErrorCodes
}

class ConnectPacket {

    var header: FixedHeader
    var protocolName: String
    var protocolVersion: UInt8
    var cleanSession: Bool
    var willFlag: Bool
    var willQoS: qosType
    var willRetain: Bool
    var usernameFlag: Bool
    var passwordFlag: Bool
    var reservedBit: Bool
    var keepAlive: UInt16
    var clientId: String
    var willTopic: String?
    var willMessage: String?
    var username: String?
    var password: String?

    init(header: FixedHeader,
         protocolName: String = "MQTT",
         protocolVersion: UInt8 = 4,
         cleanSession: Bool = true,
         willFlag: Bool = false,
         willQoS: qosType = .atMostOnce,
         willRetain: Bool = false,
         usernameFlag: Bool = false,
         passwordFlag: Bool = false,
         reservedBit: Bool = false,
         keepAlive: UInt16 = 15,
         clientId: String,
         willTopic: String? = nil,
         willMessage: String? = nil,
         username: String? = nil,
         password: String? = nil) {

        self.header = header
        self.protocolName = protocolName
        self.protocolVersion = protocolVersion
        self.cleanSession = cleanSession
        self.willFlag = willFlag
        self.willQoS = willQoS
        self.willRetain = willRetain
        self.usernameFlag = usernameFlag
        self.passwordFlag = passwordFlag
        self.reservedBit = reservedBit
        self.keepAlive = keepAlive
        self.clientId = clientId
        self.willTopic = willTopic
        self.willMessage = willMessage
        self.username = username
        self.password = password
    }
}

extension ConnectPacket : ControlPacket {

    func write(writer: SocketWriter) throws {

        guard var buffer = Data(capacity: 512) else {
            throw NSError()
        }

        buffer.append(protocolName.data)
        buffer.append(protocolVersion.data)
        buffer.append(flags.data)
        buffer.append(keepAlive.data)

        //Begin Payload
        buffer.append(clientId.data)
        if willFlag {
            buffer.append(willTopic!.data)
            buffer.append(willMessage!.data)
        }
        if usernameFlag {
            buffer.append(username!.data)
        }
        if passwordFlag {
             buffer.append(password!.data)
        }

        header.remainingLength = buffer.count

        var packet = header.pack()
        packet.append(buffer)

        do {
            try writer.write(from: packet)

        } catch {
            throw error

        }

    }

    func unpack(reader: SocketReader) {
        self.protocolName = decodeString(reader)
        self.protocolVersion = decodeUInt8(reader)
        let options = decodeUInt8(reader)

        self.reservedBit  = decodebit(1 & options)
        self.cleanSession = decodebit(1 & (options >> 1))
        self.willFlag     = decodebit(1 & (options >> 2))
        self.willQoS      = qosType(rawValue: 3 & (options >> 3))!
        self.willRetain   = decodebit(1 & (options >> 5))
        self.usernameFlag = decodebit(1 & (options >> 6))
        self.passwordFlag = decodebit(1 & (options >> 7))

        self.keepAlive = decodeUInt16(reader)

        //Payload
        self.clientId = decodeString(reader)

        if willFlag {
            self.willTopic = decodeString(reader)
            self.willMessage = decodeString(reader)
        }
        if usernameFlag {
            self.username = decodeString(reader)
        }
        if passwordFlag {
            self.password = decodeString(reader)
        }

    }

    func validate() -> ErrorCodes {
        if passwordFlag && !usernameFlag {
            return .errRefusedIDRejected
        }
        if reservedBit {
            //Bad reserved bit
            return .errRefusedBadProtocolVersion
        }
        if (protocolName == "MQIsdp" && protocolVersion != 3) || (protocolName == "MQTT" && protocolVersion != 4) {
            //Mismatched or unsupported protocol version
            return .errRefusedBadProtocolVersion
        }
        if protocolName != "MQIsdp" && protocolName != "MQTT" {
            //Bad protocol name
            return .errRefusedBadProtocolVersion
        }
        if clientId.lengthOfBytes(using: String.Encoding.utf8) > 65535 ||
          username?.lengthOfBytes(using: String.Encoding.utf8) > 65535 ||
          password?.lengthOfBytes(using: String.Encoding.utf8) > 65535 {
            //Bad size field
           return .errRefusedBadProtocolVersion
        }
        return .accepted
    }
}

extension ConnectPacket {
    var flags: UInt8 {
        get {
            return (cleanSession.toByte << 1 | willFlag.toByte << 2 | willQoS.rawValue << 3  |
                    willRetain.toByte << 5 | passwordFlag.toByte << 6 | usernameFlag.toByte << 7)
        }
    }
}
