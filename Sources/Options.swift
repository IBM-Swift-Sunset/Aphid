//
//  File.swift
//  Aphid
//
//  Created by Aaron Liberatore on 7/11/16.
//
//

import Foundation

struct ClientOptions  {
    var clientId:                String
    var username:                String?
    var password:                String?

    var protocolName:            String
    var protocolVersion:         UInt
    
    var servers:                 [NSURL]
	var cleanSession:            Bool
	var order:                   Bool
	var willEnabled:             Bool
	var willTopic:               String?
	var willPayload:             [Byte]
	var willQos:                 qosType
	var willRetain:              Bool
	var keepAlive:               UInt16
	var pingTimeout:             UInt16
	var connectTimeout:          UInt16
	var maxReconnectInterval:    UInt16
	var autoReconnect:           Bool

	/*var Store:                   Store?
	var DefaultPublishHander:    MessageHandler
	var OnConnect:               OnConnectHandler?
	var OnConnectionLost:        ConnectionLostHandler*/
	var writeTimeout:            UInt16?
	var messageChannelDepth:     UInt
    
    init(clientId: String, username: String? = nil, password: String? = nil) {
        servers = [NSURL]()
        self.clientId = clientId
        self.username = username
        self.password = password
        cleanSession = true
        order = true
        willEnabled = false
        willTopic = nil
        willPayload = [Byte]()
        willQos = .atMostOnce
        willRetain = false
        protocolName = "MQTT"
        protocolVersion = 4
        keepAlive = 10
        pingTimeout = 10
        connectTimeout = 30
        maxReconnectInterval = 10
        autoReconnect = true
        /*Store = nil
        OnConnect = nil
        OnConnectionLost = DefaultConnectionLostHandler*/
        writeTimeout = nil // nil represents timeout disabled
        messageChannelDepth = 100
        
    }

    mutating func addBroker(server: String) {
        let brokerURI = server // url.Parse(server)
        servers.append(NSURL(string: brokerURI)!)
    }
}
