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
import SSLService
import Dispatch

public typealias Byte = UInt8

open class Aphid {

    public var delegate: MQTTDelegate?

    var socket: Socket?

    var buffer: Data

    var keepAliveTimer: DispatchSourceTimer? = nil

    var bound = 2

    let readQueue: DispatchQueue
    let writeQueue: DispatchQueue

    public init(clientId: String, cleanSess: Bool = true, username: String? = nil, password: String? = nil,
         host: String = "localhost", port: Int32 = 1883) {

        let clientId = !cleanSess && (clientId == "") ? NSUUID().uuidString : clientId

        Config.sharedInstance.setUser(clientId: clientId, username: username, password: password)

        readQueue = DispatchQueue(label: "read queue", attributes: DispatchQueue.Attributes.concurrent)
        writeQueue = DispatchQueue(label: "write queue", attributes: DispatchQueue.Attributes.concurrent)
        
        buffer = Data()
    }

    // Initial Connect
    public func connect(withSSL: Bool = false, certPath: String? = nil, keyPath: String? = nil) throws {

        if socket == nil {
            socket = try Socket.create(family: .inet6, type: .stream, proto: .tcp)

        }

        guard let sock = socket else {
            delegate?.didLoseConnection(error: Errors.socketNotOpen)
            return
        }

        do {
            var connectPacket = ConnectPacket()
            
            try sock.setBlocking(mode: false)

            try sock.connect(to: config.host, port: config.port)
            
            try connectPacket.write(writer: sock)

            read()

        } catch {
            print(error)

        }

        startTimer()

        config.status = .connected

    }

    public func reconnect() {
    }

    public func disconnect() {
        
        guard config.status != .disconnected else {
            print(Errors.alreadyDisconnected)
            return
        }

        guard let sock = socket else {
            delegate?.didLoseConnection(error: Errors.socketNotOpen)
            return
        }
        
        writeQueue.async {
            do {
                let disconnectPacket = DisconnectPacket()

                try disconnectPacket.write(writer: sock)

                config.status = .disconnected

                sleep(config.quiesce)   // Sleep to allow buffering packets to be sent

                sock.close()

                self.buffer = Data()

                self.keepAliveTimer = nil
                
                self.delegate?.didLoseConnection(error: nil)

            } catch {
                 print(error)

            }
        }
    }

    public func publish(topic: String, withMessage message: String, qos: QosType = .atLeastOnce, retain: Bool = false) {
        
        guard let sock = socket else {
            delegate?.didLoseConnection(error: Errors.socketNotOpen)
            return
        }
        
        guard topic.matches(pattern: config.publishPattern) else {
            print(Errors.invalidTopicName)
            return
        }
        
        writeQueue.async {
            do {
                // Dup: we have to decide if this the first time this is sent or just a duplicate; not the user's job
                var publishPacket = PublishPacket(topic: topic, message: message, dup: false, qos: qos, willRetain: retain)
                
                try publishPacket.write(writer: sock)
                
                if qos ==  .atMostOnce{
                    self.delegate?.didCompleteDelivery(token: String(publishPacket.identifier))
                }

                self.resetTimer()
                
            } catch {
                print(error)
                
            }
        }
    }

    public func subscribe(topic: [String], qoss: [QosType]) {

        guard let sock = socket else {
            delegate?.didLoseConnection(error: Errors.socketNotOpen)
            return
        }

        writeQueue.async {
            do {
                var subscribePacket = SubscribePacket(topics: topic, qoss: qoss)
                
                try subscribePacket.write(writer: sock)

                self.resetTimer()

            } catch {
                print(error)

            }
        }
    }

    public func unsubscribe(topics: [String]) {

        guard let sock = socket else {
            delegate?.didLoseConnection(error: Errors.socketNotOpen)
            return
        }

        writeQueue.async {
            do {
                var unsubscribePacket = UnsubscribePacket(topics: topics)
                
                try unsubscribePacket.write(writer: sock)

                self.resetTimer()

            } catch {
                print(error)

            }
        }
    }

    public func ping() throws {

        guard let sock = socket else {
            delegate?.didLoseConnection(error: Errors.socketNotOpen)
            return
        }

        writeQueue.async {
            do {
                var pingreqPacket = PingreqPacket()
                
                try pingreqPacket.write(writer: sock)

            } catch {
                print(error)

            }
        }
    }
    
    internal func pubrel(packetId: UInt16) {

        guard let sock = socket else {
            delegate?.didLoseConnection(error: Errors.socketNotOpen)
            return
        }

        writeQueue.async {
            do {
                var pubrelPacket = PubrelPacket(packetId: packetId)

                try pubrelPacket.write(writer: sock)
                
                self.resetTimer()

            } catch {
                print(error)

            }
        }
    }
}

extension Aphid {

    public func setWill(topic: String, message: String? = nil, willQoS: QosType = .atMostOnce, willRetain: Bool = false) {
        config.will = LastWill(topic: topic, message: message, qos: willQoS, retain: willRetain)
    }

    internal func read() {

        guard let sock = socket else {
            delegate?.didLoseConnection(error: Errors.socketNotOpen)
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

                if self.buffer.count >= self.bound {
                    self.unpack()
                }
                self.read()
            }
        }
    }

    internal func parseHeader() -> (Byte, Int)? {
        
        let controlByte: Byte = buffer[0]

        guard let length = decodeLength(buffer.subdata(in: Range(1..<bound))) else {
            return nil
        }

        return (controlByte, length)
    }

    internal func unpack() {

        while buffer.count >= 2  {

            // See if we have a header
            guard let (controlByte, bodyLength) = parseHeader() else {
                bound += 1
                return
            }
            // Do we have all the bytes we need for the full packet?
            let bytesNeeded = buffer.count - bodyLength - bound
            
            if bytesNeeded < 0 {
                return
            }

            let body = buffer.subdata(in: Range(bound..<bound + bodyLength))

            buffer = buffer.subdata(in: Range(bound + bodyLength..<buffer.count))

            guard let packet = newControlPacket(header: controlByte, bodyLength: bodyLength, data: body) else {
                print(Errors.unrecognizedOpcode)
                return
            }

            bound = 2

            switch packet {
            case _ as ConnackPacket     : delegate?.didConnect()
            case _ as PubackPacket      : delegate?.didCompleteDelivery(token: packet.description)
            case _ as PubcompPacket     : delegate?.didCompleteDelivery(token: packet.description)
            case let p as PublishPacket : delegate?.didReceiveMessage(topic: p.topic, message: p.message)
            case let p as PubrecPacket  :
                                          delegate?.didCompleteDelivery(token: packet.description)
                                          self.pubrel(packetId: p.packetId)
            default: delegate?.didCompleteDelivery(token: packet.description)
            }
        }
    }
}

extension Aphid {

    internal func startTimer() {

        keepAliveTimer = keepAliveTimer ?? DispatchSource.makeTimerSource(flags: DispatchSource.TimerFlags.strict, queue: writeQueue)

        keepAliveTimer?.scheduleRepeating(deadline: .now(), interval: .seconds(Int(config.keepAlive)), leeway: .milliseconds(500))

        keepAliveTimer?.setEventHandler {

            self.writeQueue.async {
                do {
                    try self.ping()

                } catch {
                    print("Error Sending Ping Request")
                }
            }
        }

        keepAliveTimer?.resume()

    }

    internal func resetTimer() {
        keepAliveTimer?.cancel()
        keepAliveTimer = nil
        startTimer()
    }
}
    
extension Aphid {
    internal func newControlPacket(header: Byte, bodyLength: Int, data: Data) -> ControlPacket? {

        guard let code: ControlCode = ControlCode(rawValue: (header & 0xF0)) else {
            print(Errors.unrecognizedOpcode)
            return nil
        }

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
            return PingreqPacket()
        case .pingresp:
            return PingrespPacket()
        case .disconnect:
            return DisconnectPacket(data: data)
        default:
            return ConnackPacket(data: data)
        }
    }
}
// SSL Certification Initialization: Must be called before connect
extension Aphid {

    public func setSSL(certPath: String? = nil, keyPath: String? = nil) throws {

        let SSLConfig = SSLService.Configuration(withCACertificateDirectory: nil, usingCertificateFile: certPath, withKeyFile: keyPath)
        
        config.SSLConfig = SSLConfig

         if socket == nil { socket = try Socket.create(family: .inet6, type: .stream, proto: .tcp) }

        socket?.delegate = try SSLService(usingConfiguration: SSLConfig)
    }

    public func setSSL(with ChainFilePath: String, usingSelfSignedCert: Bool) throws {

        let SSLConfig = SSLService.Configuration(withChainFilePath: ChainFilePath, usingSelfSignedCerts: usingSelfSignedCert)
        
        config.SSLConfig = SSLConfig

        if socket == nil { socket = try Socket.create(family: .inet6, type: .stream, proto: .tcp) }

        socket?.delegate = try SSLService(usingConfiguration: SSLConfig)
    }

    public func setSSL(with CACertificatePath: String?, using CertificateFile: String?, with KeyFile: String?, selfSignedCerts: Bool) throws {

        let SSLConfig = SSLService.Configuration(withCACertificateFilePath: CACertificatePath,
                                                usingCertificateFile: CertificateFile,
                                                withKeyFile: KeyFile,
                                                usingSelfSignedCerts: selfSignedCerts)
        config.SSLConfig = SSLConfig

        if socket == nil { socket = try Socket.create(family: .inet6, type: .stream, proto: .tcp) }

        socket?.delegate = try SSLService(usingConfiguration: SSLConfig)
    }
}
