/**
 Copyright IBM Corporation 2017

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import Foundation
import SSLService

public var config = Config.sharedInstance

public struct Config {
    
    static var sharedInstance = Config()
    
    public var host = "localhost"
    public var port: Int32 = 1883
    
    public var protocolName: String
    public var protocolVersion: UInt8
    
    public var clientId: String
    public var username: String?
    public var password: String?
    public var dup: Bool
    public var qos: QosType
    public var retain: Bool

    public var cleanSession: Bool
    public var secureMQTT: Bool = false
    public var willTopic: String?
	public var willPayload: [Byte]
	public var willQos: QosType
	public var willRetain: Bool
	public var keepAlive: UInt16
	public var pingTimeout: UInt16
	public var connectTimeout: UInt16
	public var maxReconnectInterval: UInt16
	public var autoReconnect: Bool
    public var quiesce: UInt32 = 2
	public var writeTimeout: UInt16?
    public var status: ConnectionStatus
    public var will: LastWill? = nil
    var SSLConfig: SSLService.Configuration? = nil
    
    let subscribePattern = "[A-Z,a-z,0-9, ,+]+((/[A-Z,a-z,0-9, ]+)|(/[+]))*[A-Z,a-z,0-9, ]*(/#)?"
    let publishPattern = "[A-Z,a-z,0-9, ]+(/[A-Z,a-z,0-9, ]+)*"

    var flags: UInt8 {
        get {
            return (cleanSession.toByte << 1 | (will != nil).toByte << 2 | willQos.rawValue << 3  |
                willRetain.toByte << 5 | (password != nil).toByte << 6 | (username != nil).toByte << 7)
        }
    }

    private init() {
        protocolName = "MQTT"
        protocolVersion = 4
        
        host = "localhost"
        port = 1883
        
        clientId = ""
        username = nil
        password = nil
        
        dup = true
        qos = QosType.atMostOnce
        retain = true
        
        cleanSession = true
        willTopic = nil
        willPayload = [Byte]()
        willQos = .atMostOnce
        willRetain = false
        
        keepAlive = 10
        pingTimeout = 10
        connectTimeout = 30
        maxReconnectInterval = 10
        autoReconnect = true
        writeTimeout = nil
        status = .disconnected

    }

    mutating func addBroker(host: String, port: Int32) {
        self.host = host
        self.port = port
    }

    mutating func setUser(clientId: String, username: String? = nil, password: String? = nil){
        self.clientId = clientId
        self.username = username
        self.password = password
    }

    mutating func setFlags(qos: QosType, dup: Bool, retain: Bool) {
        self.qos = qos
        self.dup = dup
        self.retain = retain
    }
}
