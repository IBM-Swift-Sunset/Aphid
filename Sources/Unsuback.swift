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

class UnSubackPacket {
    var header: FixedHeader
    var packetId: UInt16
    
    init(header: FixedHeader, packetId: UInt16) {
        self.header = header
        self.packetId = packetId
    }
    
    init?(header: FixedHeader, bytes: [Byte]) {
        self.header = header
        packetId = UInt16(msb: bytes[0], lsb: bytes[1])
    }
}

extension UnSubackPacket : ControlPacket {
    var description: String {
        return "\(header.description) | ID: \(packetId)"
    }
    func printPacket() {
        print("Pubcomp Packet Information")
        print(header.messageType)
        print(packetId)
    }
    
    func write(writer: SocketWriter) throws {
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
    
    func unpack(reader: SocketReader) {
        packetId = decodeUInt16(reader)
    }
    
    func validate() -> ErrorCodes {
        return .accepted
    }
}

func unSubackPacket(reader: SocketReader) {
    let code = decodeUInt8(reader)
    let length = decodeUInt8(reader)
    let packetId = decodeUInt16(reader)
    
    print("Puback Packet Information -- in Int form")
    print("Code \(code)   | Length \(length)")
    print("packetId \(packetId)")
}
