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

struct ConnackPacket {
    var header: FixedHeader
    var flags: Byte
    var responseCode: Byte

    init(header: FixedHeader) {
        self.header = header
        self.flags = 0x00 // TEmporary
        self.responseCode = 0x00 // TEmporary
    }

    init(header: FixedHeader, data: Data) {
        self.header = header
        flags = data[0]
        responseCode = data[1]
    }

}

extension ConnackPacket: ControlPacket {

    var description: String {
        return header.description
    }

    mutating func write(writer: SocketWriter) throws {

        guard var buffer = Data(capacity: 128) else {
            throw NSError()
        }

        buffer.append(flags.data)
        buffer.append(responseCode.data)
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

        switch responseCode {
        case 0: return .accepted
        case 1: return .errRefusedBadProtocolVersion
        case 2: return .errRefusedIDRejected
        case 3: return .errServerUnavailable
        case 4: return .errBadUsernameOrPassword
        case 5: return .errNotAuthorize
        default: return .errUnknown
        }
    }
}
