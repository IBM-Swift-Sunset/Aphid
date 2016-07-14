//
//  Connack.swift
//  Aphid
//
//  Created by Aaron Liberatore on 7/13/16.
//
//

import Foundation
import Socket

class ConnackPacket {
    var header: FixedHeader
    var flags: Byte
    // ----------- //
    // 0 - Accepted | 1 - Unacceptable Protocol | 2 - Identifier Invalid | 3  - Server Unavailable
    // 4 - Bad Username/Password | 5 - Not Authorized
    var responseCode: Byte
    
    init(header: FixedHeader) {
        self.header = header
        self.flags = 0x00 // TEmporary
        self.responseCode = 0x00 // TEmporary
    }
    
    init?(reader: SocketReader) {
        let code = decodeUInt8(reader)
        let _ = decodeUInt8(reader)
        header = FixedHeader(messageType: ControlCode(rawValue: code)!)
        flags = decodeUInt8(reader)
        responseCode = decodeUInt8(reader)
    }
    
}

extension ConnackPacket: ControlPacket {
    func printPacket() {
        print("Connack Packet Information")
        print(header.messageType)
        print(flags)
        print(responseCode)
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
        return .accepted
    }

}
func parseConnack(reader: SocketReader) {
    let code = decodeUInt8(reader)
    let length = decodeUInt8(reader)
    let flags = decodeUInt8(reader)
    let responseCode = decodeUInt8(reader)
    
    print("Connack Packet Information -- in Int form")
    print("Code \(code)   | Length \(length)")
    print("Flags \(flags) | Response \(responseCode)")
}
