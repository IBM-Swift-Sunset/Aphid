//
//  File.swift
//  Aphid
//
//  Created by Aaron Liberatore on 7/11/16.
//
//

import Foundation

struct ClientOptions  {
	var Servers:                 [NSURL]
	var ClientID:                String
	var Username:                String
	var Password:                String
	var CleanSession:            Bool
	var Order:                   Bool
	var WillEnabled:             Bool
	var WillTopic:               String
	var WillPayload:             [Byte]
	var WillQos:                 Byte
	var WillRetained:            Bool
	var ProtocolVersion:         UInt
	var protocolVersionExplicit: Bool
	//var TLSConfig:               tls.Config
	/*var KeepAlive:               NSDate
	var PingTimeout:             NSDate
	var ConnectTimeout:          NSDate
	var MaxReconnectInterval:    NSDate*/
	var AutoReconnect:           Bool
	/*var Store:                   Store?
	var DefaultPublishHander:    MessageHandler
	var OnConnect:               OnConnectHandler?
	var OnConnectionLost:        ConnectionLostHandler
	var WriteTimeout:            time.Duration*/
	var MessageChannelDepth:     UInt
    
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
        WillRetained = false
        ProtocolVersion = 0
        protocolVersionExplicit = false
        //TLSConfig = tls.Config{}
        /*KeepAlive = 30 * time.Second
        PingTimeout = 10 * time.Second
        ConnectTimeout = 30 * time.Second
        MaxReconnectInterval = 10 * time.Minute*/
        AutoReconnect = true
        /*Store = nil
        OnConnect = nil
        OnConnectionLost = DefaultConnectionLostHandler
        WriteTimeout = 0 // 0 represents timeout disabled*/
        MessageChannelDepth = 100
    }
    
    mutating func addBroker(server: String) {
        let brokerURI = server // url.Parse(server)
        Servers.append(NSURL(string: brokerURI)!)
    }
}