//
//  File.swift
//  Aphid
//
//  Created by Aaron Liberatore on 7/11/16.
//
//

import Foundation

struct ClientOptions {
	var Servers: [NSURL]
	var ClientID: String
	var Username: String?
	var Password: String?
	var CleanSession: Bool
	var Order: Bool
	var WillEnabled: Bool
	var WillTopic: String?
	var WillPayload: [Byte]
	var WillQos: Byte
	var WillRetain: Bool
	var ProtocolVersion: UInt
	var protocolVersionExplicit: Bool
	//var TLSConfig:               tls.Config
	var KeepAlive: UInt16
	var PingTimeout: UInt16
	var ConnectTimeout: UInt16
	var MaxReconnectInterval: UInt16
	var AutoReconnect: Bool
	/*var Store:                   Store?
	var DefaultPublishHander:    MessageHandler
	var OnConnect:               OnConnectHandler?
	var OnConnectionLost:        ConnectionLostHandler*/
	var WriteTimeout: UInt16?
	var MessageChannelDepth: UInt

    init() {
        Servers = [NSURL]()
        ClientID = ""
        Username = ""
        Password = ""
        CleanSession = true
        Order = true
        WillEnabled = false
        WillTopic = ""
        WillPayload = [Byte]()
        WillQos = 0
        WillRetain = false
        ProtocolVersion = 0
        protocolVersionExplicit = false
        //TLSConfig = tls.Config{}
        KeepAlive = 30
        PingTimeout = 10
        ConnectTimeout = 30
        MaxReconnectInterval = 10
        AutoReconnect = true
        /*Store = nil
        OnConnect = nil
        OnConnectionLost = DefaultConnectionLostHandler*/
        WriteTimeout = nil // nil represents timeout disabled
        MessageChannelDepth = 100
    }

    mutating func addBroker(server: String) {
        let brokerURI = server // url.Parse(server)
        Servers.append(NSURL(string: brokerURI)!)
    }
}
