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
    var messageID: UInt16
    var topics: [String]
    
    init(header: FixedHeader, messageID: UInt16, topics: [String]) {
        self.header = header
        self.messageID = messageID
        self.topics = topics
    }
}

extension UnsubscribePacket : ControlPacket {

    func write(writer: SocketWriter) throws {
        guard var buffer = Data(capacity: 512) else {
            throw NSError()
        }
        
        buffer.append(encodeUInt16T(messageID))
        
        for i in 0..<topics.count {
            buffer.append(encodeString(str: topics[i]))
        }
        
        header.remainingLength = encodeLength(buffer.count)
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
