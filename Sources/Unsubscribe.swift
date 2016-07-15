//
//  Unsubscribe.swift
//  Aphid
//
//  Created by Aaron Liberatore on 7/11/16.
//
//

import Foundation
import Socket

class UnsubscribePacket {
    var header: FixedHeader
    var packetId: UInt16
    var topics: [String]
    
    init(header: FixedHeader, packetId: UInt16, topics: [String]) {

        self.header = header
        self.packetId = packetId
        self.topics = topics
    }
}

extension UnsubscribePacket : ControlPacket {
    var description: String {
        return header.description
    }
    func write(writer: SocketWriter) throws {

        guard var buffer = Data(capacity: 512) else {
            throw NSError()
        }
        
        buffer.append(packetId.data)

        for i in 0..<topics.count {
            buffer.append(topics[i].data)
        }

        header.remainingLength = buffer.count
        var packet = header.pack()
        packet.append(buffer)

        do {
            try writer.write(from: packet)

        } catch {
            throw error

        }
    }
    func unpack(reader: SocketReader) {

    }
    func validate() -> ErrorCodes {
        return .accepted
    }
}
