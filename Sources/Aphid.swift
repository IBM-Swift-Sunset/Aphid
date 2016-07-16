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
import Socket


public enum connectionStatus: Int {
    case connected = 1
    case disconnected = -1
    case connecting = 0
}

typealias Byte = UInt8

// Aphid
public class Aphid {
    
    var host = "localhost"
    var port: Int32 = 1883
    var clientId: String
    var username: String?
    var password: String?
    var secureMQTT: Bool = false
    var cleanSess: Bool
    
    var outMessages = [UInt16:ControlPacket]()
    var socket: Socket?
    
    var delegate: MQTTDelegate?
    
    var buffer: [Byte] = []
    
    var status = connectionStatus.disconnected
    var config: Config
    
    var keepAliveTimer: DispatchSourceTimer? = nil
    let timer = DispatchQueue(label: "timer")
    let writeQueue = DispatchQueue(label: "write")
    let readQueue = DispatchQueue(label: "readQueue")
    
    var isConnected: Bool {
        get {
            if status == .connected {
                return true
            } else {
                return false
            }
        }
    }
    
    init(clientId: String, cleanSess: Bool = true, username: String? = nil, password: String? = nil,
         host: String = "localhost", port: Int32 = 1883) {
        
        !cleanSess && (clientId == "") ? (self.clientId = NSUUID().uuidString) : (self.clientId = clientId)
        
        self.config = Config(clientId: clientId, username: username, password: password, cleanSess: cleanSess)
        self.username = username
        self.password = password
        self.cleanSess = cleanSess
        
    }
    
    public func loop() {
        
        readQueue.async {
            while self.isConnected {
                guard let _ = self.socket else {
                    NSLog("Failure Socket has not initialized: Call .connect()")
                    return
                }
                
                do {
                    let ready = try Socket.wait(for: [self.socket!], timeout: 1)
                    
                    if ready != nil {
                        let _ = self.readSocket(self.socket!)
                    }
                    if self.buffer.count > 0 {
                        let _ = self.parseBuffer()
                    }
                } catch {
                    NSLog("Failure on Socket.wait")
                    
                }
                
            }
        }
    }
    // Initial Connect
    public func connect() throws -> Bool {
        
        socket = try Socket.create(family: .inet6, type: .stream, proto: .tcp)
        
        guard let sock = socket,
            connectPacket = newControlPacket(packetType: .connect) else {
                
                throw NSError()
        }
        do {
            try sock.setBlocking(mode: false)
            
            try sock.connect(to: self.host, port: self.port)
            
            try connectPacket.write(writer: sock)
            
            
        } catch {
            NSLog("Connection could not be made")

        }
        
        startTimer()
        
        status = .connected
        
        return true
    }
    
    func readSocket(_ reader: SocketReader) -> Int? {
        do {
            let tmpBuffer = NSMutableData(capacity: 128)
            
            let _ = try reader.read(into: tmpBuffer!)
            
            var bytes = [UInt8](repeating: 0, count: (tmpBuffer?.length)!)
            
            tmpBuffer?.getBytes(&bytes, length:(tmpBuffer?.length)! * sizeof(UInt8.self))
            
            self.buffer.append(contentsOf: bytes)
            
        } catch {
            do { try delegate?.connectionLost() } catch {}
            
        }
        
        return nil
    }
    
    func parseBuffer() -> ControlPacket {

        let controlCode = buffer.removeFirst(), length = buffer.removeFirst()
        
        let bytes = [controlCode, length]
        
        let fixedHeader: FixedHeader = FixedHeader(bytes)!
        
        var body: [Byte] = []
        for _ in 0..<length {
            body.append(buffer.removeFirst())
        }
        
        let packet = newControlPacket(header: fixedHeader, bytes: body)
        
        delegate?.deliveryComplete(token: (packet?.description)!)
        
        return packet!
    }
    
    func reconnect() -> Bool {
        return true
    }
    
    func disconnect(uint: UInt) throws {
        
        guard isConnected else {
            NSLog("Already Disconnected")
            return
        }
        
        guard let sock = socket,
            disconnectPacket = newControlPacket(packetType: .disconnect) else {
                throw NSError()
        }
        writeQueue.sync {
            do {try disconnectPacket.write(writer: sock)
                
                self.status = .disconnected
                self.readQueue.suspend()
                sock.close()
                
            }catch{ print("failure")}
        }
    }
    
    func publish(topic: String, withMessage message: String, qos: qosType, retained: Bool, dup: Bool) -> UInt16 {
        
        let unusedID: UInt16 = UInt16(random: true)
        
        guard let sock = socket,
            publishPacket = newControlPacket(packetType: .publish, topicName: topic, packetId: unusedID, message: [message]) else {
                
                return 0
        }
        writeQueue.sync {
            do {
                try publishPacket.write(writer: sock)
                
                self.outMessages[unusedID] = publishPacket
                
                self.resetTimer()
                
                
            } catch {
                
            }
        }
        return 0
    }
    
    func publish(topic: String, message: String) -> UInt16 {
        
        let unusedID: UInt16 = UInt16(random: true)
        
        guard let sock = socket,
            publishPacket = newControlPacket(packetType: .publish, topicName: topic, packetId: unusedID, message: [message]) else {
                
                return 0
        }
        writeQueue.sync {
            do {
                try publishPacket.write(writer: sock)
                
                self.outMessages[unusedID] = publishPacket
                
                self.resetTimer()
                
                
            } catch {
                
            }
        }
        return 1
    }
    
    func subscribe(topic: [String], qoss: [qosType]) -> UInt16 {
        
        let unusedID: UInt16 = UInt16(random: true)
        
        guard let sock = socket,
            subscribePacket = newControlPacket(packetType: .subscribe, packetId: unusedID, topics: topic, qoss: qoss) else {
                
                return 0
        }
        writeQueue.sync {
            do {
                try subscribePacket.write(writer: sock)
                
                self.outMessages[unusedID] = subscribePacket
                
                self.resetTimer()
                
                //return 1
                
            } catch {
                
                // return 0
            }
        }
        return 1
    }
    
    func unsubscribe(topic: [String]) -> UInt16 {
        
        let unusedID: UInt16 = UInt16(random: true)
        
        guard let sock = socket,
            unsubscribePacket = newControlPacket(packetType: .unsubscribe, packetId: unusedID, topics: topic) else {
                
                return 0
        }
        writeQueue.sync {
            do {
                try unsubscribePacket.write(writer: sock)
                
                self.outMessages[unusedID] = unsubscribePacket
                
                self.resetTimer()
                
                //return 0
                
            } catch {
                //return 0
                
            }
        }
        return 1
    }
    
    func ping() {
        guard let sock = socket,
            pingreqPacket = newControlPacket(packetType: .pingreq) else {
                
                return
        }
        writeQueue.sync {
            do {
                try pingreqPacket.write(writer: sock)
                
            } catch {
                return
                
            }
        }
    }
    func startTimer(){
        if keepAliveTimer == nil {
            keepAliveTimer = DispatchSource.timer(flags: DispatchSource.TimerFlags.strict, queue: timer)
        }
        keepAliveTimer?.scheduleRepeating(deadline: .now(), interval: 1, leeway: .milliseconds(500))
        keepAliveTimer?.setEventHandler {
            self.ping()
        }
        keepAliveTimer?.resume()
    }
    func resetTimer(){
        keepAliveTimer?.cancel()
        keepAliveTimer = nil
    }
    
}

