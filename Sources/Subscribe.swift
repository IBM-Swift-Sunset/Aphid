//
//  Subscribe.swift
//  Aphid
//
//  Created by Aaron Liberatore on 7/11/16.
//
//

import Foundation
import Socket

class SubscribePacket {
    var header: FixedHeader //bits 3,2,1,0 --> 0,0,1 and 0 respectively
    var packetId: UInt16
    var topics: [String]
    var qoss: [qosType]
    
    init(header: FixedHeader, packetId: UInt16, topics: [String], qoss: [qosType]){

        self.header = header
        self.packetId = packetId
        self.topics = topics
        self.qoss = qoss

    }
}

extension SubscribePacket : ControlPacket {
    var description: String {
        return header.description
    }
    func write(writer: SocketWriter) throws {
       guard var buffer = Data(capacity: 512) else {
            throw NSError()
        }
        
        buffer.append(packetId.data)

        for (topic, qos) in zip(topics, qoss) {
            buffer.append(topic.data)
            buffer.append(qos.rawValue.data)
        }

        header.remainingLength = buffer.count

        var packet = header.pack()
        packet.append(buffer)

        do {
            try writer.write(from: packet)

        } catch {
            throw NSError()

        }

    }
    func unpack(reader: SocketReader) {
        self.packetId = decodeUInt16(reader)
        var topics = [String]()
        var qoss = [qosType]()
        for _ in 0...10 {
            topics.append(decodeString(reader))
            qoss.append(qosType(rawValue: decodeUInt8(reader))!)
        }

    }
    func validate() -> ErrorCodes {
        return .accepted
    }
}
