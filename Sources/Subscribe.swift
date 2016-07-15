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

class SubscribePacket {
    var header: FixedHeader //bits 3,2,1,0 --> 0,0,1 and 0 respectively
    var packetId: UInt16
    var topics: [String]
    var qoss: [qosType]
    
    init(header: FixedHeader, packetId: UInt16, topics: [String], qoss: [qosType]){

        self.header = header
        self.packetId = packetId
        self.topics = topics
        self.qoss = qoss

    }
}

extension SubscribePacket : ControlPacket {
    var description: String {
        return header.description
    }
    func write(writer: SocketWriter) throws {
       guard var buffer = Data(capacity: 512) else {
            throw NSError()
        }
        
        buffer.append(packetId.data)

        for (topic, qos) in zip(topics, qoss) {
            buffer.append(topic.data)
            buffer.append(qos.rawValue.data)
        }

        header.remainingLength = buffer.count

        var packet = header.pack()
        packet.append(buffer)

        do {
            try writer.write(from: packet)

        } catch {
            throw NSError()

        }

    }
    func unpack(reader: SocketReader) {
        self.packetId = decodeUInt16(reader)
        var topics = [String]()
        var qoss = [qosType]()
        for _ in 0...10 {
            topics.append(decodeString(reader))
            qoss.append(qosType(rawValue: decodeUInt8(reader))!)
        }

    }
    func validate() -> ErrorCodes {
        return .accepted
    }
}
