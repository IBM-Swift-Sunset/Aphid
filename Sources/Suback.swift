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

struct SubackPacket {
    var packetId: UInt16
    var returnCode: Byte

    init(packetId: UInt16, returnCode: Byte) {
        self.packetId = packetId
        self.returnCode = returnCode
    }

    init?(data: Data) {
        packetId = UInt16(msb: data[0], lsb: data[1])
        returnCode = data[2]
    }

}

extension SubackPacket : ControlPacket {

    var description: String {
        return String(describing: ControlCode.suback)
    }

    mutating func write(writer: SocketWriter) throws {
        var buffer = Data(capacity: 128)
        
        buffer.append(ControlCode.suback.rawValue.data)
        buffer.append(3.data)
        buffer.append(packetId.data)
        buffer.append(returnCode.data)

        do {
            try writer.write(from: buffer)

        } catch {
            throw error

        }
    }

    mutating func unpack(reader: SocketReader) {
    }

    func validate() -> MQTTErrors {
        return .accepted
    }
}
