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

class PublishPacket {
    var header: FixedHeader
    let dup: Bool
    let qos: qosType
    let willRetain: Bool
    var topicName: String
    var identifier: UInt16?
    var payload: [String]

    init(header: FixedHeader, dup: Bool = false, qos: qosType = .atLeastOnce, willRetain: Bool = false,
        
        topicName: String, packetId: UInt16, payload: [String] = ["This plant needs water"]) {
        
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
    
    init?(header: FixedHeader, bytes: [Byte]) {
        self.header = header
        var bytes = bytes
        let strLen = UInt16(msb: bytes.removeFirst(), lsb: bytes.removeFirst())
        var str: [Byte] = []
        for _ in 0..<strLen{
            str.append(bytes.removeFirst())
        }
        
        topicName = String(str)
        dup = header.dup
        qos = qosType(rawValue: header.qos)!
        willRetain = header.retain
        
        qos.rawValue > 0 ? (identifier = UInt16(msb: bytes.removeFirst(), lsb: bytes.removeFirst())) : (identifier = nil)
        
        var payload: [String] = []
        while bytes.count > 0 {
            let strLen = UInt16(msb: bytes.removeFirst(), lsb: bytes.removeFirst())
            var str: [Byte] = []
            for _ in 0..<strLen {
                str.append(bytes.removeFirst())
            }
            payload.append(String(str))
        }
        self.payload = payload
        
    }
}

extension PublishPacket: ControlPacket {
    var description: String {
        return header.description
    }
    func write(writer: SocketWriter) throws {
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
        header.remainingLength = buffer.count + payload.count //payload count cant be pstring

        var packet = header.pack()
        packet.append(buffer)

        do {
            try writer.write(from: packet)

        } catch {
            throw NSError()

        }

    }

    func unpack(reader: SocketReader) {
        var payloadSize = header.remainingLength
        topicName = decodeString(reader)
        if qos.rawValue > 0 {
            identifier = decodeUInt16(reader)
            payloadSize -= topicName.characters.count + 4
        } else {
            payloadSize -= topicName.characters.count + 2
        }
        var payload = [String]()

        for _ in 0..<payloadSize {
            payload.append(decodeString(reader))
        }

    }

    func validate() -> ErrorCodes {
        return .accepted
    }
}
