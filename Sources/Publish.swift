//
//  Publish.swift
//  Aphid
//
//  Created by Aaron Liberatore on 7/11/16.
//
//

import Foundation
import Socket

class PublishPacket {
    var header: FixedHeader
    let dupFlag: Bool
    let qos: UInt16
    let willRetain: Bool
    let topicName: String
    let identifier: UInt16
    let payload: [String]
    
    init(header: FixedHeader, dupFlag: Bool = false, qos: UInt16 = 0x0010, willRetain: Bool = false,
         topicName: String, packetIdentifier: UInt16, payload: [String] = []) {
        self.header = header
        self.dupFlag = dupFlag
        self.qos = qos
        self.willRetain = willRetain
        self.topicName = topicName
        self.identifier = packetIdentifier
        self.payload = payload
    }
}

extension PublishPacket: ControlPacket {
    func write(writer: SocketWriter) throws {
        guard var buffer = Data(capacity: 512) else {
            throw NSError()
        }
        
        buffer.append(encodeString(str: topicName))
        if qos == 1 || qos == 2 {
            buffer.append(encodeUInt16T(identifier))
        }
        header.remainingLength = UInt8(buffer.count + payload.count)
        
        var packet = header.pack()
        packet.append(buffer)
        
        do {
            try writer.write(from: packet)
        } catch {
            throw NSError()
        }
        
    }
    func unpack(reader: SocketReader) {
        let topic = decodeString(reader)
        
    }
    func validate() -> ErrorCodes {
        return .accepted
    }
}
