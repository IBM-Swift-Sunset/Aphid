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

    func write(writer: SocketWriter) throws {
        guard var buffer = Data(capacity: 512) else {
            throw NSError()
        }
        
        buffer.append(packetId.data)

        for i in 0..<topics.count {
            buffer.append(encodeString(str: topics[i]))
        }

        header.remainingLength = buffer.count
        let _ = header.pack()

        do {
            try writer.write(from: buffer)

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