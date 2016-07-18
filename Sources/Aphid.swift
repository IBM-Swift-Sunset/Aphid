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
import Dispatch

public typealias Byte = UInt8

public enum connectionStatus: Int {
    case connected = 1
    case disconnected = -1
    case connecting = 0
}

// Aphid
public class Aphid {
    
    public var host = "localhost"
    public var port: Int32 = 1883
    public var clientId: String
    public var username: String?
    public var password: String?
    public var secureMQTT: Bool = false
    public var cleanSess: Bool
    public var keepAliveTime = 15
    
    public var status = connectionStatus.disconnected
    public var config: Config
    
    public var delegate: MQTTDelegate?

    var outMessages = [UInt16:ControlPacket]()
    var socket: Socket?
    
    var buffer = Data()
    
    var keepAliveTimer: DispatchSourceTimer? = nil
    
    #if os(Linux)
    public let readQueue: dispatch_queue_t
    public let writeQueue: dispatch_queue_t
    public let timerQueue: dispatch_queue_t

    #else
    public let readQueue: DispatchQueue
    public let writeQueue: DispatchQueue
    public let timerQueue: DispatchQueue
    
    #endif

    public var isConnected: Bool {
        get {
            if status == .connected {
                return true
            } else {
                return false
            }
        }
    }
    
    public init(clientId: String, cleanSess: Bool = true, username: String? = nil, password: String? = nil,
         host: String = "localhost", port: Int32 = 1883) {
        
        !cleanSess && (clientId == "") ? (self.clientId = NSUUID().uuidString) : (self.clientId = clientId)
        
        self.config = Config(clientId: clientId, username: username, password: password, cleanSess: cleanSess)
        self.username = username
        self.password = password
        self.cleanSess = cleanSess
        
        #if os(Linux)
            readQueue = dispatch_queue_t(label: "timer queue", attributes: .concurrent)
            writeQueue = dispatch_queue_t(label: "timer queue", attributes: .concurrent)
            timerQueue = dispatch_queue_t(label: "timer queue", attributes: .concurrent)
            
        #else
            readQueue = DispatchQueue(label: "read queue" , attributes: .concurrent)
            writeQueue = DispatchQueue(label: "write queue", attributes: .concurrent)
            timerQueue = DispatchQueue(label: "timer queue", attributes: .concurrent)
            
        #endif
    }
    
    // Initial Connect
    public func connect() throws -> Bool {
        
        socket = try Socket.create(family: .inet6, type: .stream, proto: .tcp)
        
        guard let sock = socket,
              var connectPacket = newControlPacket(packetType: .connect) else {
                
                throw NSError()
        }
        do {
            try sock.setBlocking(mode: false)
            
            try sock.connect(to: self.host, port: self.port)
            
            try connectPacket.write(writer: sock)
            
            self.read()

        } catch {
            NSLog("Connection could not be made")

        }
        
        startTimer()
        
        status = .connected
        
        return true
    }
    
    public func reconnect() -> Bool {
        return true
    }
    
    public func disconnect(uint: UInt) throws {
        
        guard isConnected else {
            NSLog("Already Disconnected")
            return
        }
        
        guard let sock = socket,
              var disconnectPacket = newControlPacket(packetType: .disconnect) else {
                throw NSError()
        }
        #if os(Linux)
            dispatch_sync(writeQueue) {
                do {
                    try disconnectPacket.write(writer: sock)
                    
                    self.status = .disconnected
                    self.readQueue.suspend()
                    sock.close()
                    
                } catch {
                    NSLog("failure")
                }
            }
        #else
            writeQueue.sync {
                do {
                    try disconnectPacket.write(writer: sock)
                    
                    self.status = .disconnected
                    self.readQueue.suspend()
                    sock.close()
                    
                } catch {
                    NSLog("failure")
                }
            }
        #endif
       
    }
    
    public func publish(topic: String, withMessage message: String, qos: qosType, retained: Bool, dup: Bool) -> UInt16 {
        
        let unusedID: UInt16 = UInt16(random: true)
        
        guard let sock = socket,
              var publishPacket = newControlPacket(packetType: .publish, topicName: topic, packetId: unusedID, message: [message]) else {
                
                return 0
        }
        #if os(Linux)
            dispatch_sync(writeQueue) {
                do {
                    try publishPacket.write(writer: sock)
                    
                    self.outMessages[unusedID] = publishPacket
                    
                    self.resetTimer()
                    
                    
                } catch {
                    
                }
            }
        #else
            writeQueue.sync {
                do {
                    try publishPacket.write(writer: sock)
                    
                    self.outMessages[unusedID] = publishPacket
                    
                    self.resetTimer()
                    
                    
                } catch {
                    
                }
            }
        #endif
       
        return 0
    }
    
    public func publish(topic: String, message: String) -> UInt16 {
        
        let unusedID: UInt16 = UInt16(random: true)
        
        guard let sock = socket,
              var publishPacket = newControlPacket(packetType: .publish, topicName: topic, packetId: unusedID, message: [message]) else {
                
                return 0
        }
        #if os(Linux)
            dispatch_sync(writeQueue) {
                do {
                    try publishPacket.write(writer: sock)
                    
                    self.outMessages[unusedID] = publishPacket
                    
                    self.resetTimer()
                    
                } catch {
                    
                }
            }
        #else
            writeQueue.sync {
                do {
                    try publishPacket.write(writer: sock)
                    
                    self.outMessages[unusedID] = publishPacket
                    
                    self.resetTimer()
                    
                } catch {
                    
                }
            }
        #endif
    
        return 1
    }
    
    public func subscribe(topic: [String], qoss: [qosType]) -> UInt16 {
        
        let unusedID: UInt16 = UInt16(random: true)
        
        guard let sock = socket,
              var subscribePacket = newControlPacket(packetType: .subscribe, packetId: unusedID, topics: topic, qoss: qoss) else {
                
                return 0
        }
        #if os(Linux)
            dispatch_sync(writeQueue) {
                do {
                    try unsubscribePacket.write(writer: sock)
                    
                    self.outMessages[unusedID] = subscribePacket
                    
                    self.resetTimer()
                    
                } catch {
                    
                }
            }
        #else
            writeQueue.sync {
                do {
                    try subscribePacket.write(writer: sock)
                    
                    self.outMessages[unusedID] = subscribePacket
                    
                    self.resetTimer()
                    
                } catch {
                    
                }
            }
        #endif
        
        return 1
    }
    
    public func unsubscribe(topic: [String]) -> UInt16 {
        
        let unusedID: UInt16 = UInt16(random: true)
        
        guard let sock = socket,
              var unsubscribePacket = newControlPacket(packetType: .unsubscribe, packetId: unusedID, topics: topic) else {
                
                return 0
        }
        
        #if os(Linux)
            dispatch_sync(writeQueue) {
                do {
                    try unsubscribePacket.write(writer: sock)
                    
                    self.outMessages[unusedID] = unsubscribePacket
                    
                    self.resetTimer()
                    
                } catch {
                    
                }
            }
        #else
            writeQueue.sync {
                do {
                    try unsubscribePacket.write(writer: sock)
                    
                    self.outMessages[unusedID] = unsubscribePacket
                    
                    self.resetTimer()
                    
                } catch {
                    
                }
            }
        #endif
        
        return 1
    }
    
    public func ping() {
        guard let sock = socket,
              var pingreqPacket = newControlPacket(packetType: .pingreq) else {
                
                return
        }
        #if os(Linux)
            dispatch_sync(writeQueue) {
                do {
                    try pingreqPacket.write(writer: sock)
                    
                } catch {
                    return
                    
                }
            }
        #else
            writeQueue.sync {
                do {
                    try pingreqPacket.write(writer: sock)
                    
                } catch {
                    return
                    
                }
            }
        #endif
    }
}

extension Aphid {
    public func read() {
        
        
        
        guard let sock = socket else {
            return
        }
        
        #if os(Linux)
            /*let iochannel = dispatch_io_create_with_path(DISPATCH_IO_STREAM,
                                     sock.socketfd,
                                     0,
                                     O_RDONLY,
                                     self.readQueue,
                                     ^(int, error),{
                                        // Cleanup code for normal channel operation.
                                        // Assumes that dispatch_io_close was called elsewhere.
                                        if (error == 0) {
                                            dispatch_release(self.channel);
                                        }
                                    });
            dispatch_io_read(iochannel, 1024, 1024, self.writeQueue,
                            ^(bool done, dispatch_data_t data, int error){
                                if (error == 0) {
                                    let bytes: [Byte]? = data?.map {
                                        byte in
                                        return byte
                                    }
                                    
                                    if let d = bytes {
                                        
                                        self.buffer.append(d, count: d.count)
                                        
                                        if self.buffer.count >= 2 {
                                            let _ = self.parseBuffer()
                                        }
                                        
                                        self.read()
                                    }
                                }
                        });*/

        #else
            let iochannel = DispatchIO(type: DispatchIO.StreamType.stream, fileDescriptor: sock.socketfd, queue: readQueue, cleanupHandler: {
                error in
            })
            
            iochannel.read(offset: off_t(0), length: 1, queue: readQueue) {
                done, data, error in
                
                let bytes: [Byte]? = data?.map {
                    byte in
                    return byte
                }
                
                if let d = bytes {
                    
                    self.buffer.append(d, count: d.count)
                    
                    if self.buffer.count >= 2 {
                        let _ = self.parseBuffer()
                    }
                    
                    self.read()
                }
            }
        #endif
    }
    func parseBuffer() -> [ControlPacket]? {
        
        var packets = [ControlPacket]()
        
        while buffer.count > 0 {
            
            guard let header = FixedHeader(buffer.subdata(in: Range(uncheckedBounds: (0, 2)))) else {
                return packets
            }
            if buffer.count - header.remainingLength < 2 {
                return nil
            }

            let body = buffer.subdata(in: Range(uncheckedBounds: (2, 2 + header.remainingLength)))

            buffer = buffer.subdata(in: Range(uncheckedBounds: (2 + header.remainingLength, buffer.count)))

            let packet = newControlPacket(header: header, data: body)!

            packets.append(packet)
            if packet is PublishPacket {
                let p = packet as! PublishPacket

                do {
                    try delegate?.messageArrived(topic: p.topicName, message: p.payload[0])
                } catch {
                    
                }
            }
            delegate?.deliveryComplete(token: packet.description)
        }
        
        return packets
    }
}

extension Aphid {
    func startTimer(){
        #if os(Linux)
            keepAliveTimer = keepAliveTimer ?? dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, timerQueue)
            dispatch_source_set_timer(keepAliveTimer, DISPATCH_TIME_NOW, keepAliveTime * NSEC_PER_SEC, 1 * NSEC_PER_SEC)
            dispatch_source_set_event_handler(timer) {
                
                dispatch_async(writeQueue) {
                    self.ping()
                }

            }
        
            dispatch_resume(timer)
        #else
            keepAliveTimer = keepAliveTimer ?? DispatchSource.timer(flags: DispatchSource.TimerFlags.strict, queue: timerQueue)
            
            keepAliveTimer?.scheduleRepeating(deadline: .now(), interval: .seconds(keepAliveTime), leeway: .milliseconds(500))
            
            keepAliveTimer?.setEventHandler {
                
                self.writeQueue.async {
                    self.ping()
                }
            }
            
            keepAliveTimer?.resume()
        #endif
        
    }
    func resetTimer(){
        #if os(Linux)
            dispatch_source_cancel(keepAliveTimer)
            timer = nil
        #else
            keepAliveTimer?.cancel()
            keepAliveTimer = nil
            startTimer()
        #endif
    }
}
