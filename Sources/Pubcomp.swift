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

struct PubcompPacket {
    var header: FixedHeader
    var packetId: UInt16

    init(header: FixedHeader, packetId: UInt16) {
        self.header = header
        self.packetId = packetId
    }

    init?(header: FixedHeader, data: Data) {
        self.header = header
        packetId = UInt16(msb: data[0], lsb: data[1])
    }
}

extension PubcompPacket : ControlPacket {
    var description: String {
        return header.description
    }

    mutating func write(writer: SocketWriter) throws {
        guard var buffer = Data(capacity: 128) else {
            throw NSError()
        }

        buffer.append(packetId.data)

        header.remainingLength = 2

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
