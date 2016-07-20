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

// Aphid
public class Aphid {

    // User Configuration
    public var delegate: MQTTDelegate?

    private var socket: Socket?

    private var buffer = Data()

    private var keepAliveTimer: DispatchSourceTimer? = nil

    public let readQueue: DispatchQueue
    public let writeQueue: DispatchQueue


    private var bound = 2

    public init(clientId: String, cleanSess: Bool = true, username: String? = nil, password: String? = nil,
         host: String = "localhost", port: Int32 = 1883) {

        let clientId = !cleanSess && (clientId == "") ? NSUUID().uuidString : clientId

        Config.sharedInstance.setUser(clientId: clientId, username: username, password: password)

        readQueue = DispatchQueue(label: "read queue", attributes: .concurrent)
        writeQueue = DispatchQueue(label: "write queue", attributes: .concurrent)

    }

    // Initial Connect
    public func connect() throws {

        socket = try Socket.create(family: .inet6, type: .stream, proto: .tcp)

        guard let sock = socket else {
            throw ErrorCodes.errUnknown
        }
        
        do {
            var connectPacket = ConnectPacket()
            
            try sock.setBlocking(mode: false)

            try sock.connect(to: config.host, port: config.port)

            try connectPacket.write(writer: sock)

            self.read()

        } catch {
            print("error")

        }

        startTimer()

        config.status = connectionStatus.connected

        delegate?.didConnect()

    }

    public func reconnect() {
    }

    public func disconnect(uint: UInt) throws {
        
        guard config.status != connectionStatus.disconnected else {
            throw ErrorCodes.errAlreadyDisconnected
        }

        guard let sock = socket else {
            throw ErrorCodes.errUnknown
        }
        
        writeQueue.sync {
            do {
                let disconnectPacket = DisconnectPacket()

                try disconnectPacket.write(writer: sock)

                config.status = .disconnected
                
                // Look into waiting until it clears out the write queue then disconnect /
                sock.close()

                buffer = Data()

                keepAliveTimer = nil

            } catch {
                 print("error")

            }
        }
    }

    public func publish(topic: String, withMessage message: String, qos: qosType, retained: Bool, dup: Bool) throws {
        // Cant use Wildcards in topic names

        guard let sock = socket else {
            throw ErrorCodes.errUnknown
        }

        writeQueue.sync {
            do {
                var publishPacket = PublishPacket(topic: topic, message: message)

                try publishPacket.write(writer: sock)

                self.resetTimer()

            } catch {
                 print("error")

            }
        }
    }

    public func publish(topic: String, message: String) throws {
        // Cant use Wildcards in topic names #
        
        guard let sock = socket else {
            throw ErrorCodes.errUnknown
        }

        writeQueue.sync {
            do {
                
                var publishPacket = PublishPacket(topic: topic, message: message)
                
                try publishPacket.write(writer: sock)

                self.resetTimer()

            } catch {
                 print("error")
            }
        }
    }

    public func subscribe(topic: [String], qoss: [qosType]) throws {
        // Can use Wildcards in topic filters

        guard let sock = socket else {
                throw ErrorCodes.errUnknown
        }

        writeQueue.sync {
            do {
                var subscribePacket = SubscribePacket(topics: topic, qoss: qoss)
                
                try subscribePacket.write(writer: sock)

                self.resetTimer()

            } catch {
                 print("error")
            }
        }
    }

    public func unsubscribe(topics: [String]) throws {

        guard let sock = socket else {
            throw ErrorCodes.errUnknown
        }

        writeQueue.sync {
            do {
                var unsubscribePacket = UnsubscribePacket(topics: topics)
                
                try unsubscribePacket.write(writer: sock)

                self.resetTimer()

            } catch {
                 print("error")
            }
        }
    }

    public func ping() throws {

        guard let sock = socket else {
            throw ErrorCodes.errUnknown
        }

        writeQueue.sync {
            do {
                var pingreqPacket = PingreqPacket()
                
                try pingreqPacket.write(writer: sock)

            } catch {
                 print("error")
            }
        }
    }
}

extension Aphid {
    /*
     Paramters:
         topic: The topic that the will message should be published on.
         message: The message to send as a will. If not given, or set to nil a zero length message will be used as the will. 
         qos: The quality of service level to use for the will.
         retain: If set to true, the will message will be set as the "last known good"/retained message for the topic.
     */
    public func setWill(topic: String, message: String? = nil, willQoS: qosType = .atMostOnce, willRetain: Bool = false) {
        config.will = LastWill(topic: topic, message: message, qos: willQoS, retain: willRetain)
    }
    public func read() {

        guard let sock = socket else {
            return
        }
        
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
                    let _ = self.unpack()
                }

                self.read()
            }
        }
    }
    func parseHeader() -> (Byte, Int)? {
        let data = buffer.subdata(in: Range(0..<bound))
        
        let controlByte: [Byte] = data.subdata(in: Range(0..<1)).map {
            byte in
            return byte
        }
        guard let length = decodeLength(data.subdata(in: Range(1..<bound))) else {
            return nil
        }
        return (controlByte[0], length)
    }
    func unpack() -> [ControlPacket]? {

        var packets = [ControlPacket]()

        while buffer.count >= 2 {
            
            // See if we have enough bytes for the header
            guard let (controlByte, bodyLength) = parseHeader() else {
                bound += 1
                return packets
            }
            // Do we have all the bytes we need for the full packet?
            let bytesNeeded = buffer.count - bodyLength - 2

            if bytesNeeded < 0 {
                return nil
            }
            
            let body = buffer.subdata(in: Range(bound..<bound + bodyLength))

            buffer = buffer.subdata(in: Range(bound + bodyLength..<buffer.count))
            
            let packet = newControlPacket(header: controlByte, bodyLength: bodyLength, data: body)!

            packets.append(packet)

            bound = 2

            if let packet = packet as? PublishPacket {
                delegate?.didReceiveMessage(topic: packet.topic, message: packet.message)
            } else {
                delegate?.didCompleteDelivery(token: packet.description)
            }
        }

        return packets
    }
}

extension Aphid {

    func startTimer() {

        keepAliveTimer = keepAliveTimer ?? DispatchSource.timer(flags: DispatchSource.TimerFlags.strict, queue: writeQueue)

        keepAliveTimer?.scheduleRepeating(deadline: .now(), interval: .seconds(Int(config.keepAlive)), leeway: .milliseconds(500))

        keepAliveTimer?.setEventHandler {

            self.writeQueue.async {
                do {
                    try self.ping()
                } catch {
                    
                }
            }
        }

        keepAliveTimer?.resume()

    }

    func resetTimer() {
        keepAliveTimer?.cancel()
        keepAliveTimer = nil
        startTimer()
    }
}

extension Aphid {
    func newControlPacket(header: Byte, bodyLength: Int, data: Data) -> ControlPacket? {
        let code: ControlCode = ControlCode(rawValue: (header & 0xF0))!
        switch code {
        case .connect:
            return ConnectPacket(data: data)
        case .connack:
            return ConnackPacket(data: data)
        case .publish:
            return PublishPacket(header: header, bodyLength: bodyLength, data: data)
        case .puback:
            return PubackPacket(data: data)
        case .pubrec:
            return PubrecPacket(data: data)
        case .pubrel:
            return PubrelPacket(data: data)
        case .pubcomp:
            return PubcompPacket(data: data)
        case .subscribe:
            return SubscribePacket(data: data)
        case .suback:
            return SubackPacket(data: data)
        case .unsubscribe:
            return UnsubscribePacket(data: data)
        case .unsuback:
            return UnSubackPacket(data: data)
        case .pingreq:
            return PingreqPacket(data: data)
        case .pingresp:
            return PingrespPacket(data: data)
        case .disconnect:
            return DisconnectPacket(data: data)
        default:
            return ConnackPacket(data: data)
        }
    }
}
