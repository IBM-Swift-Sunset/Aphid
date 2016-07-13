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
    let fixedHeader: FixedHeader
    let dupFlag: Bool
    let QoS: UInt16
    let willRetain: Bool
    let topicName: String
    let packetIdentifier: UInt16
    let payload: [String]? //??
    
    init(fixedHeader: FixedHeader, dupFlag: Bool = false, QoS: UInt16 = 0x0010, willRetain: Bool = false, t
         topicName: String, packetIdentifier: UInt16, payload: [String]? = nil) {
        self.fixedHeader = fixedHeader
        self.dupFlag = dupFlag
        self.QoS = QoS
        self.willRetain = willRetain
        self.topicName = topicName
        self.packetIdentifier = packetIdentifier
        self.payload = payload
    }
}

extension PublishPacket: ControlPacket {
    func write(writer: SocketWriter) throws {
        //throw
    }
    func unpack(reader: SocketReader) {
        
    }
    func validate() -> ErrorCodes {
        return .accepted
    }
}