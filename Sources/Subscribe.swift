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
    var fixedHeader: FixedHeader
    var messageID: UInt16
    var topics: [String]
    var QoSs: [Byte]
    
    init(fixedHeader: FixedHeader, messageID: UInt16, topics: [String], QoSs: [Byte]){
        self.fixedHeader = fixedHeader
        self.messageID = messageID
        self.topics = topics
        self.QoSs = QoSs
        
    }
}

extension SubscribePacket : ControlPacket {
    
    func write(writer: SocketWriter) throws {
        guard let buffer = NSMutableData(capacity: 512) else {
            throw NSError()
        }
        
        buffer.append(encodeUInt16(messageID))
        
        for i in 0..<topics.count {
            buffer.append(encodeString(str: topics[i]))
            buffer.append(encode(QoSs[i]))
        }
        
    }
    func unpack(reader: SocketReader) {
        
    }
    func validate() -> ErrorCodes {
        return .accepted
    }
}