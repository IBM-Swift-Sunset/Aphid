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
    
    func write(writer: SocketWriter) throws
    func unpack(reader: SocketReader)
    func validate() -> ErrorCodes
}

class ConnectPacket {
    
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
    let clientOptions: ClientOptions
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
         clientOptions: ClientOptions,
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
        self.clientOptions = clientOptions
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
        
        buffer.append( encodeString(str: protocolName))
        buffer.append( encode(protocolVersion) )
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
        let packet = fixedHeader.pack()
        packet.append(buffer)
        
        do {
            try writer.write(from: packet)

        } catch {
            throw error
            
        }
        
    }
    
    func unpack(reader: SocketReader) {

       do {
            let data = NSMutableData()
            let _ = try reader.read(into: data)

            self.protocolName = decodeString(reader)
            self.protocolVersion = decodeUInt8(reader)
            let options = decodeUInt8(reader)
            
            self.reservedBit  = decodebit(1 & options)
            self.cleanSession = decodebit(1 & (options >> 1))
            self.willFlag     = decodebit(1 & (options >> 2))
            self.willQoS      = 3 & (options >> 3)
            self.willRetain   = decodebit(1 & (options >> 5))
            self.usernameFlag = decodebit(1 & (options >> 6))
            self.passwordFlag = decodebit(1 & (options >> 7))
            
            self.keepAliveTimer = decodeUInt16(reader)

            //Payload
            self.clientIdentifier = decodeString(reader)
            
            if willFlag {
                self.willTopic = decodeString(reader)
                self.willMessage = decodeString(reader)
            }
            if usernameFlag {
                self.username = decodeString(reader)
            }
            if passwordFlag {
                self.password = decodeString(reader)
            }

        } catch {
            print(error)
        }
    }
    
    func validate() -> ErrorCodes {
        if passwordFlag && !usernameFlag {
            return .errRefusedIDRejected
        }
        if reservedBit {
            //Bad reserved bit
            return .errRefusedBadProtocolVersion
        }
        if (protocolName == "MQIsdp" && protocolVersion != 3) || (protocolName == "MQTT" && protocolVersion != 4) {
            //Mismatched or unsupported protocol version
            return .errRefusedBadProtocolVersion
        }
        if protocolName != "MQIsdp" && protocolName != "MQTT" {
            //Bad protocol name
            return .errRefusedBadProtocolVersion
        }
        if clientIdentifier.lengthOfBytes(using: NSUTF8StringEncoding) > 65535 ||
                  username?.lengthOfBytes(using: NSUTF8StringEncoding) > 65535 ||
                  password?.lengthOfBytes(using: NSUTF8StringEncoding) > 65535 {
            //Bad size field
           return .errRefusedBadProtocolVersion
        }
        return .accepted
    }
    
    
}
