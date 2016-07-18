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

struct PublishPacket {
    var header: FixedHeader
    let dup: Bool
    let qos: qosType
    let willRetain: Bool
    var topicName: String
    var identifier: UInt16?
    var payload: [String]

    init(header: FixedHeader, dup: Bool = false, qos: qosType = .atLeastOnce, willRetain: Bool = false,

        topicName: String, packetId: UInt16, payload: [String] = []) {

        var header = header
        header.dup = dup
        header.qos = qos.rawValue
        header.retain = willRetain

        self.header = header
        self.dup = dup
        self.qos = qos
        self.willRetain = willRetain
        self.topicName = topicName
        self.identifier = packetId
        self.payload = payload
    }

    init?(header: FixedHeader, data: Data) {
        var data = data

        self.header = header

        dup = header.dup
        qos = qosType(rawValue: header.qos)!
        willRetain = header.retain

        var payloadSize = header.remainingLength

        topicName = data.decodeString

        if qos.rawValue > 0 {
            identifier = data.decodeUInt16
            payloadSize -= topicName.characters.count + 4

        } else {
            payloadSize -= topicName.characters.count + 2
        }

        var messages = [String]()

        while data.count > 1 {
            let str = data.decodeString
            messages.append(str)
            payloadSize -= str.characters.count
        }
        payload = messages

    }
}

extension PublishPacket: ControlPacket {

    var description: String {
        return header.description
    }

    mutating func write(writer: SocketWriter) throws {
        guard var buffer = Data(capacity: 512) else {
            throw NSError()
        }

        buffer.append(topicName.data)

        if qos.rawValue > 0 {
            buffer.append(identifier!.data)
        }

        for item in payload {
            buffer.append(item.data)
        }

        header.remainingLength = buffer.count + payload.count

        var packet = header.pack()
        packet.append(buffer)

        do {
            try writer.write(from: packet)

        } catch {
            throw NSError()

        }

    }

    mutating func unpack(reader: SocketReader) {
    }

    func validate() -> ErrorCodes {
        return .accepted
    }
}
