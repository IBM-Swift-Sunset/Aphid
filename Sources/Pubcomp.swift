//
//  Pubcomp.swift
//  Aphid
//
//  Created by Joseph Yin on 7/14/16.
//
//

import Foundation
import Socket

class PubcompPacket {
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

extension PubcompPacket : ControlPacket {
    var description: String {
        return header.description
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

func parsePubcomp(reader: SocketReader) {
    let code = decodeUInt8(reader)
    let length = decodeUInt8(reader)
    let packetId = decodeUInt16(reader)
    
    print("Puback Packet Information -- in Int form")
    print("Code \(code)   | Length \(length)")
    print("packetId \(packetId)")
}
