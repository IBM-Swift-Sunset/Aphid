//
//  Suback.swift
//  Aphid
//
//  Created by Joseph Yin on 7/14/16.
//
//

import Foundation
import Socket

class SubackPacket {
    var header: FixedHeader
    var packetId: UInt16
    
    init(header: FixedHeader, packetId: UInt16) {
        self.header = header
        self.packetId = packetId
    }
    
    init?(reader: SocketReader) {
        let code = decodeUInt8(reader)
        let _ = decodeUInt8(reader)
        header = FixedHeader(messageType: ControlCode(rawValue: code)!)
        packetId = decodeUInt16(reader)
    }
}

extension SubackPacket : ControlPacket {
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

func subackPacket(reader: SocketReader) {
    let code = decodeUInt8(reader)
    let length = decodeUInt8(reader)
    let packetId = decodeUInt16(reader)
    
    print("Puback Packet Information -- in Int form")
    print("Code \(code)   | Length \(length)")
    print("packetId \(packetId)")
}
