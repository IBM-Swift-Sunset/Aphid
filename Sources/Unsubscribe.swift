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

struct UnsubscribePacket {
    var header: FixedHeader
    var packetId: UInt16
    var topics: [String]
    
    init(header: FixedHeader, packetId: UInt16, topics: [String]) {

        self.header = header
        self.packetId = packetId
        self.topics = topics
    }
    init(header: FixedHeader, data: Data) {
        var data = data
        
        self.header = header
        self.packetId = data.decodeUInt16
        
        var topics = [String]()
        while data.count > 0 {
            topics.append(data.decodeString)
        }
        self.topics = topics
    }
}

extension UnsubscribePacket : ControlPacket {

    var description: String {
        return header.description
    }

    mutating func write(writer: SocketWriter) throws {

        guard var buffer = Data(capacity: 512) else {
            throw NSError()
        }
        
        buffer.append(packetId.data)

        for i in 0..<topics.count {
            buffer.append(topics[i].data)
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
        return .accepted
    }
}
