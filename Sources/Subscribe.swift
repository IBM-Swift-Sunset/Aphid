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
    var messageID: UInt16
    var topics: [String]
    var qoss: [Byte]
    
    init(header: FixedHeader, messageID: UInt16, topics: [String], qoss: [Byte]){
        self.header = header
        self.messageID = messageID
        self.topics = topics
        self.qoss = qoss
        
    }
}

extension SubscribePacket : ControlPacket {
    
    func write(writer: SocketWriter) throws {
       guard var buffer = Data(capacity: 512) else {
            throw NSError()
        }
        
        buffer.append(encodeUInt16ToData(messageID))
        
        for (topic, qos) in zip(topics, qoss) {
            buffer.append(encodeString(str: topic))
            buffer.append(encodeUInt8(qos))
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
        
    }
    func validate() -> ErrorCodes {
        return .accepted
    }
}
