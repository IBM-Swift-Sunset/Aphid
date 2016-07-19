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

struct ConnectPacket {

    var header: FixedHeader
    var protocolName: String
    var protocolVersion: UInt8
    var cleanSession: Bool
    
    var willFlag: Bool
    var willQoS: qosType
    var willRetain: Bool
    var usernameFlag: Bool
    var passwordFlag: Bool
    var reservedBit = false
    var keepAlive: UInt16
    var clientId: String
    var username: String?
    var password: String?
    var will: LastWill?

    init(header: FixedHeader,
         protocolName: String = "MQTT",
         protocolVersion: UInt8 = 4,
         cleanSession: Bool = true,
         keepAlive: UInt16 = 15,
         clientId: String,
         username: String? = nil,
         password: String? = nil,
         will: LastWill?) {

        self.header = header
        self.protocolName = protocolName
        self.protocolVersion = protocolVersion
        self.cleanSession = cleanSession
        self.keepAlive = keepAlive
        self.clientId = clientId
        
        self.willFlag   = will != nil ? true : false
        self.willQoS    = will?.qos ?? .atMostOnce
        self.willRetain = will?.retain ?? false
        self.usernameFlag = username != nil ? true : false
        self.passwordFlag = password != nil ? true : false

        self.will = will
        self.username = username
        self.password = password
    }
    init(header: FixedHeader, data: Data) {
        var data = data

        self.header = header
        self.protocolName = data.decodeString
        self.protocolVersion = data.decodeUInt8
        let options = data.decodeUInt8

        self.reservedBit  = (1 & options).bool
        self.cleanSession = (1 & (options >> 1)).bool
        self.willFlag     = (1 & (options >> 2)).bool
        self.willQoS      = qosType(rawValue: 3 & (options >> 3))!
        self.willRetain   = (1 & (options >> 5)).bool
        self.usernameFlag = (1 & (options >> 6)).bool
        self.passwordFlag = (1 & (options >> 7)).bool

        self.keepAlive = data.decodeUInt16

        //Payload
        self.clientId = data.decodeString

        if willFlag {
            let willTopic = data.decodeString
            let willMessage = data.decodeString
            self.will = LastWill(topic: willTopic, message: willMessage, qos: willQoS, retain: willRetain)
        }
        if usernameFlag {
            self.username = data.decodeString
        }
        if passwordFlag {
            self.password = data.decodeString
        }
    }

}

extension ConnectPacket : ControlPacket {

    var description: String {
        return header.description
    }

    mutating func write(writer: SocketWriter) throws {

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
            buffer.append(will!.topic.data)
            buffer.append(will!.message?.data ?? "".data)
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

    mutating func unpack(reader: SocketReader) {
    }

    func validate() -> ErrorCodes {
        if passwordFlag && !usernameFlag {
            return .errRefusedIDRejected
        }
        if reservedBit {
            return .errRefusedBadProtocolVersion
        }
        if (protocolName == "MQIsdp" && protocolVersion != 3) || (protocolName == "MQTT" && protocolVersion != 4) {
            return .errRefusedBadProtocolVersion
        }
        if protocolName != "MQIsdp" && protocolName != "MQTT" {
            return .errRefusedBadProtocolVersion
        }
        if clientId.lengthOfBytes(using: String.Encoding.utf8) > 65535 ||
          username?.lengthOfBytes(using: String.Encoding.utf8) > 65535 ||
          password?.lengthOfBytes(using: String.Encoding.utf8) > 65535 {
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
