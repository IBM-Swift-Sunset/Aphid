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
    var willQoS: UInt16
    var willRetain: Bool
    var usernameFlag: Bool
    var passwordFlag: Bool
    var reservedBit: Bool
    var keepAliveTimer: UInt16
    
    var clientIdentifier: String
    var willTopic: String?
    var willMessage: String?
    var username: String?
    var password: String?
    
    init(fixedHeader: FixedHeader,
         protocolName: String = "MQTT",
         protocolVersion: UInt8 = 4,
         cleanSession: Bool = true,
         willFlag: Bool = true,
         willQoS: UInt16 = 10,
         willRetain: Bool = true,
         usernameFlag: Bool = false,
         passwordFlag: Bool = false,
         reservedBit: Bool = false,
         keepAliveTimer: UInt16 = 30,
         clientIdentifier: String,
         willTopic: String? = nil,
         willMessage: String? = nil,
         username: String? = nil,
         password: String? = nil){
        
        self.fixedHeader = fixedHeader
        self.protocolName = protocolName
        self.protocolVersion = protocolVersion
        self.cleanSession = cleanSession
        self.willFlag = willFlag
        self.willQoS = willQoS
        self.willRetain = willRetain
        self.usernameFlag = usernameFlag
        self.passwordFlag = passwordFlag
        self.reservedBit = reservedBit
        self.keepAliveTimer = keepAliveTimer
        
        self.clientIdentifier = clientIdentifier
        self.willTopic = willTopic
        self.willMessage = willMessage
        self.username = username
        self.password = password
    }
}

extension ConnectPacket : ControlPacket {
    
    func write(writer: SocketWriter) throws {
        
        guard let buffer = NSMutableData(capacity: 512) else {
            throw NSError()
        }
        
        buffer.append( encodeString(str: self.protocolName)!)
        buffer.append( encode(self.protocolVersion) )
        //buffer.append( encode(value:))
        
        try writer.write(from: buffer)
        
    }
    
    func unpack(reader: SocketReader) {
        
    }
    
    func validate() {
        
    }
    
    
}