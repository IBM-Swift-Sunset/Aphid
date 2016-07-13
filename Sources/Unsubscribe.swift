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
    var fixedHeader: FixedHeader
    var messageID: UInt16
    var topics: [String]
    
    init(fixedHeader: FixedHeader, messageID: UInt16, topics: [String]) {
        self.fixedHeader = fixedHeader
        self.messageID = messageID
        self.topics = topics
    }
}

extension UnsubscribePacket : ControlPacket {

    func write(writer: SocketWriter) throws {
        guard let buffer = NSMutableData(capacity: 512) else {
            throw NSError()
        }
        
        //buffer.append(fixed)
        buffer.append(encodeUInt16(messageID))
        
        for i in 0..<topics.count {
            buffer.append(encodeString(str: topics[i]))
        }
        
        fixedHeader.remainingLength = UInt8(buffer.length)
        let packet = fixedHeader.pack()
        
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