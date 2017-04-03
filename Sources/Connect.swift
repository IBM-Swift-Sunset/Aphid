/**
 Copyright IBM Corporation 2017

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

struct ConnectPacket: ControlPacket {
    var will: LastWill? = nil

    init(){}

    init(data: Data) {
        var data = data

        let _ = data.decodeString    // protocol name
        let _ = data.decodeUInt8     // protocolVersion
        let options = data.decodeUInt8

        let _  = (1 & options).bool       // reserved bit
        let _ = (1 & (options >> 1)).bool // cleanSession
        let willFlag     = (1 & (options >> 2)).bool
        let willQoS      = QosType(rawValue: 3 & (options >> 3))!
        let willRetain   = (1 & (options >> 5)).bool
        let usernameFlag = (1 & (options >> 6)).bool
        let passwordFlag = (1 & (options >> 7)).bool

        let _ = data.decodeUInt16 // keepAlive

        //Payload
        let _ = data.decodeString //clientID

        if willFlag {
            let willTopic = data.decodeString
            let willMessage = data.decodeString
            self.will = LastWill(topic: willTopic, message: willMessage, qos: willQoS, retain: willRetain)
        }
        if usernameFlag {
            let _ = data.decodeString
        }
        if passwordFlag {
            let _ = data.decodeString
        }
    }

    var description: String {
        return String(describing: ControlCode.connect)
    }

    mutating func write(writer: SocketWriter) throws {
		var packet = Data(capacity: 512)
		var buffer = Data(capacity: 512)

        buffer.append(config.protocolName.data)
        buffer.append(config.protocolVersion.data)
        buffer.append(config.flags.data)
        buffer.append(config.keepAlive.data)

        //Begin Payload
        buffer.append(config.clientId.data)

        if let will = config.will {
            buffer.append(will.topic.data)
            buffer.append(will.message?.data ?? "".data)
        }
        if let username = config.username {
            buffer.append(username.data)
        }
        if let password = config.password {
             buffer.append(password.data)
        }

        packet.append(ControlCode.connect.rawValue.data)
        for byte in buffer.count.toBytes {
            packet.append(byte.data)
        }

        packet.append(buffer)

        do {
            try writer.write(from: packet)

        } catch {
            throw error

        }

    }

    mutating func unpack(reader: SocketReader) {
    }

    func validate() -> MQTTErrors {
        /*if config.username != nil && config.password != nil {
            return .errRefusedIDRejected
        }
        if true { // reservedBit
            return .errRefusedBadProtocolVersion
        }
        if (config.protocolName == "MQIsdp" && config.protocolVersion != 3) || (config.protocolName == "MQTT" && config.protocolVersion != 4) {
            return .errRefusedBadProtocolVersion
        }
        if config.protocolName != "MQIsdp" && config.protocolName != "MQTT" {
            return .errRefusedBadProtocolVersion
        }
        if config.clientId.lengthOfBytes(using: String.Encoding.utf8) > 65535 ||
          config.username?.lengthOfBytes(using: String.Encoding.utf8) > 65535 ||
          config.password?.lengthOfBytes(using: String.Encoding.utf8) > 65535 {
           return .errRefusedBadProtocolVersion
        }*/
        return .accepted
    }
}
