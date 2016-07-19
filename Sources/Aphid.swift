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

    public let readQueue: DispatchQueue
    public let writeQueue: DispatchQueue
    public let timerQueue: DispatchQueue

    public var isConnected: Bool {
        get {
            if status == .connected {
                return true
            } else {
                return false
            }
        }
    }

    private var bound = 2

    public init(clientId: String, cleanSess: Bool = true, username: String? = nil, password: String? = nil,
         host: String = "localhost", port: Int32 = 1883) {

        !cleanSess && (clientId == "") ? (self.clientId = NSUUID().uuidString) : (self.clientId = clientId)

        self.config = Config(clientId: clientId, username: username, password: password, cleanSess: cleanSess)
        self.username = username
        self.password = password
        self.cleanSess = cleanSess

        readQueue = DispatchQueue(label: "read queue", attributes: .concurrent)
        writeQueue = DispatchQueue(label: "write queue", attributes: .concurrent)
        timerQueue = DispatchQueue(label: "timer queue", attributes: .concurrent)

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

        writeQueue.sync {
            do {
                try disconnectPacket.write(writer: sock)

                self.status = .disconnected
                
                sock.close()
                
                buffer = Data()
                keepAliveTimer = nil

            } catch {
                NSLog("failure")
            }
        }
    }

    public func publish(topic: String, withMessage message: String, qos: qosType, retained: Bool, dup: Bool) -> UInt16 {

        let unusedID: UInt16 = UInt16(random: true)

        guard let sock = socket,
              var publishPacket = newControlPacket(packetType: .publish, topicName: topic, packetId: unusedID, message: [message]) else {

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

    public func publish(topic: String, message: String) -> UInt16 {

        let unusedID: UInt16 = UInt16(random: true)

        guard let sock = socket,
              var publishPacket = newControlPacket(packetType: .publish, topicName: topic, packetId: unusedID, message: [message]) else {

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

    public func subscribe(topic: [String], qoss: [qosType]) -> UInt16 {

        let unusedID: UInt16 = UInt16(random: true)

        guard let sock = socket,
              var subscribePacket = newControlPacket(packetType: .subscribe, packetId: unusedID, topics: topic, qoss: qoss) else {

                return 0
        }

        writeQueue.sync {
            do {
                try subscribePacket.write(writer: sock)

                self.outMessages[unusedID] = subscribePacket

                self.resetTimer()

            } catch {

            }
        }

        return 1
    }

    public func unsubscribe(topic: [String]) -> UInt16 {

        let unusedID: UInt16 = UInt16(random: true)

        guard let sock = socket,
              var unsubscribePacket = newControlPacket(packetType: .unsubscribe, packetId: unusedID, topics: topic) else {

                return 0
        }

        writeQueue.sync {
            do {
                try unsubscribePacket.write(writer: sock)

                self.outMessages[unusedID] = unsubscribePacket

                self.resetTimer()

            } catch {

            }
        }

        return 1
    }

    public func ping() {
        guard let sock = socket,
              var pingreqPacket = newControlPacket(packetType: .pingreq) else {

                return
        }

        writeQueue.sync {
            do {
                try pingreqPacket.write(writer: sock)

            } catch {

            }
        }
    }
}

extension Aphid {

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

    func unpack() -> [ControlPacket]? {

        var packets = [ControlPacket]()

        while buffer.count >= 2 {

            guard let header = FixedHeader(buffer.subdata(in: Range(uncheckedBounds: (0, bound)))) else {
                bound += 1
                return packets
            }
            if buffer.count - header.remainingLength < 2 {
                return nil
            }

            let body = buffer.subdata(in: Range(uncheckedBounds: (bound, bound + header.remainingLength)))

            buffer = buffer.subdata(in: Range(uncheckedBounds: (bound + header.remainingLength, buffer.count)))

            let packet = newControlPacket(header: header, data: body)!

            packets.append(packet)

            bound = 2

            if packet is PublishPacket {
                let p = packet as! PublishPacket

                do {
                    try delegate?.didReceiveMessage(topic: p.topicName, message: p.payload[0])

                } catch {

                }
            } else {
                delegate?.didCompleteDelivery(token: packet.description)
            }
        }

        return packets
    }
}

extension Aphid {

    func startTimer() {

        keepAliveTimer = keepAliveTimer ?? DispatchSource.timer(flags: DispatchSource.TimerFlags.strict, queue: timerQueue)

        keepAliveTimer?.scheduleRepeating(deadline: .now(), interval: .seconds(keepAliveTime), leeway: .milliseconds(500))

        keepAliveTimer?.setEventHandler {

            self.writeQueue.async {
                self.ping()
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
