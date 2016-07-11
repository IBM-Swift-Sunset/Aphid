//
//  Connect.swift
//  Aphid
//
//  Created by Robert F. Dickerson on 7/10/16.
//
//

import Foundation

import Socket

protocol ControlPacket {
    
    mutating func write(writer: SocketWriter) throws
    mutating func unpack(reader: SocketReader)
    func validate()
}

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
         willQoS: UInt8 = 10,
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
    
    mutating func write(writer: SocketWriter) throws {
        
        guard let buffer = NSMutableData(capacity: 512) else {
            throw NSError()
        }
        
        buffer.append( encodeString(str: self.protocolName))
        buffer.append( encode(self.protocolVersion) )
        buffer.append( encode(encodeBit(cleanSession) << 1 | encodeBit(willFlag) << 2 | (willQoS >> 1) << 3 | willQoS << 3 |
                       encodeBit(willRetain) << 5 | encodeBit(passwordFlag) << 6 | encodeBit(usernameFlag) << 7))
        buffer.append( encode(keepAliveTimer))
        
        //Begin Payload
        buffer.append( encodeString(str: clientIdentifier))
        
        if willFlag {
            buffer.append( encodeString(str: willTopic!))
            buffer.append( encodeString(str: willMessage!))
        }
        if usernameFlag {
            buffer.append( encodeString(str: username!))
        }
        if passwordFlag {
             buffer.append( encodeString(str: password!))
        }
        
        fixedHeader.remainingLength = UInt8(encodeLength(buffer.length).count)
        buffer.append(fixedHeader.pack())
        
        do {
            try writer.write(from: buffer)

        } catch {
            throw error
            
        }
        
    }
    
    mutating func unpack(reader: SocketReader) {
      /*  var data = NSMutableData()

        do {
            let _ = try reader.read(into: data)
        } catch {
            print(error)
        }

        let bytes: [Byte] = decode(data)
        self.protocolName = decodeString(bytes[0])
        self.protocolVersion = UInt8(bytes[1])
        let options = bytes[2]
        
        self.reservedBit  = 1 & options
        self.cleanSession = 1 & (options >> 1) > 0
        self.willFlag     = 1 & (options >> 2) > 0
        self.willQoS     = 3 & (options >> 3)
        self.willRetain   = 1 & (options >> 5) > 0
        self.usernameFlag = 1 & (options >> 6) > 0
        self.passwordFlag = 1 & (options >> 7) > 0
        
        self.keepAliveTimer = decodeUInt16(bytes[3])
        self.clientIdentifier = decodeString(bytes[4])

        if willFlag {
            self.willTopic = decodeString(bytes[5])
            self.willMessage = decodeString(bytes[6])
        }
        if usernameFlag {
            self.username = decodeString(bytes[7])
        }
        if passwordFlag {
            self.password = decodeString(bytes[8])
        }*/
    }
    
    func validate() {
        
    }
    
    
}