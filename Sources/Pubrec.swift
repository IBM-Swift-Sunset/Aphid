//
//  Pubrec.swift
//  Aphid
//
//  Created by Joseph Yin on 7/14/16.
//
//

import Foundation
import Socket

class PubrecPacket {
    var header: FixedHeader
    var messageIDMSB: Byte
    var messageIDLSB: Byte

    init(header: FixedHeader) {
        self.header = header
        self.messageIDMSB = 0x00
        self.messageIDLSB = 0x00
    }

    init?(reader: SocketReader) {
        let code = decodeUInt8(reader)
        let _ = decodeUInt8(reader)
        header = FixedHeader(messageType: ControlCode(rawValue: code)!)
        messageIDMSB = decodeUInt8(reader)
        messageIDLSB = decodeUInt8(reader)
    }
}

extension PubrecPacket : ControlPacket {
    func printPacket() {
        print("Pubrec Packet Information")
        print(header.messageType)
        print(messageIDMSB)
        print(messageIDLSB)
    }

    func write(writer: SocketWriter) throws {
        guard var buffer = Data(capacity: 128) else {
            throw NSError()
        }

        buffer.append(messageIDMSB.data)
        buffer.append(messageIDLSB.data)
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
        messageIDMSB = decodeUInt8(reader)
        messageIDLSB = decodeUInt8(reader)
    }

    func validate() -> ErrorCodes {
        return .accepted
    }
}

func parsePubrec(reader: SocketReader) {
    let code = decodeUInt8(reader)
    let length = decodeUInt8(reader)
    let messageIDMSB = decodeUInt8(reader)
    let messageIDLSB = decodeUInt8(reader)

    print("Pubrec Packet Information -- in Int form")
    print("Code \(code)   | Length \(length)")
    print("messageIDMSB \(messageIDMSB) | messageIDLSB \(messageIDLSB)")
}
