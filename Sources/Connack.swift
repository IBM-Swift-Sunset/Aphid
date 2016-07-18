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

class ConnackPacket {
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
    func write(writer: SocketWriter) throws {

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
    func unpack(reader: SocketReader) {
        flags = decodeUInt8(reader)
        responseCode = decodeUInt8(reader)
    }
    func validate() -> ErrorCodes {
        // ------ Response Codes ----- //
        // 0 - Accepted | 1 - Unacceptable Protocol | 2 - Identifier Invalid | 3  - Server Unavailable
        // 4 - Bad Username/Password | 5 - Not Authorized

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
func parseConnack(reader: SocketReader) {
    let code = UInt8(reader)
    let length = UInt8(reader)
    let flags = UInt8(reader)
    let responseCode = UInt8(reader)

    print("Connack Packet Information -- in Int form")
    print("Code \(code)   | Length \(length)")
    print("Flags \(flags) | Response \(responseCode)")
}
