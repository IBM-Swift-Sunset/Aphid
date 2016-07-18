/**
 Copyright IBM Corporation 2016

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

public struct Config {
    var clientId: String
    var username: String?
    var password: String?
    var protocolName: String
    var protocolVersion: UInt
    var servers: [NSURL]
	var cleanSession: Bool
	var order: Bool
	var willEnabled: Bool
	var willTopic: String?
	var willPayload: [Byte]
	var willQos: qosType
	var willRetain: Bool
	var keepAlive: UInt16
	var pingTimeout: UInt16
	var connectTimeout: UInt16
	var maxReconnectInterval: UInt16
	var autoReconnect: Bool
	var writeTimeout: UInt16?
	var messageChannelDepth: UInt

    init(clientId: String, username: String? = nil, password: String? = nil, cleanSess: Bool) {
        servers = [NSURL]()
        self.clientId = clientId
        self.username = username
        self.password = password
        cleanSession = cleanSess
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
        writeTimeout = nil // nil represents timeout disabled
        messageChannelDepth = 100

    }

    mutating func addBroker(server: String) {
        let brokerURI = server // url.Parse(server)
        servers.append(NSURL(string: brokerURI)!)
    }
}
