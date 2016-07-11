//
//  Connect.swift
//  Aphid
//
//  Created by Robert F. Dickerson on 7/10/16.
//
//

import Foundation

import Socket

struct ConnectPacket {
    
    var fixedHeader: FixedHeader
    var protocolName: String
    var protocolVersion: UInt8
    var cleanSession: Bool
    var willFlag: Bool
    var willQoS: UInt8
    var willRetain: Bool
    var usernameFlag: Bool
    var passwordFlag: Bool
    var reservedBit: UInt8
    var keepAliveTimer: UInt16
    
    var clientIdentifier: String
    var willTopic: String
    var willMessage: [UInt8]
    var username: String
    var password: [UInt8]
    
}

extension ConnectPacket {
    init(fixedHeader: FixedHeader) {
        self.fixedHeader = fixedHeader
    }
}

extension ConnectPacket : ControlPacket {
    
    func write(writer: SocketWriter) throws {
        
        guard let buffer = NSMutableData(capacity: 512) else {
            throw NSError()
        }
        
        buffer.append( encodeString(str: self.protocolName)!)
        buffer.append( encode(value: self.protocolVersion) )
        buffer.append( encode(value:))
        
        
    }
    
    func unpack(reader: SocketReader) {
        
    }
    
    func validate() {
        
    }
    
    
}