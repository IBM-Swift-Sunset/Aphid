
import Foundation
import Socket

public struct Token {

}
public struct ConnectionStatus: Equatable {

}
public enum connectionStatus: Int {
    case connected = 1
    case disconnected = -1
    case connecting = 0
}
public func ==(lhs: ConnectionStatus, rhs: ConnectionStatus) -> Bool {
    return true
}

typealias Byte = UInt8

let disconnected = ConnectionStatus()
let connected = ConnectionStatus()

// Aphid
public class Aphid {

    var host = "localhost"
    var port: Int32 = 1883
    var clientId: String
    var username: String?
    var password: String?
    var secureMQTT: Bool = false
    var cleanSess: Bool
    
    var keepAliveTimer = Timer()
    var outMessages = [UInt16:ControlPacket]()
    var socket: Socket?

    var delegate: MQTTDelegate?
    
    var buffer: [Byte] = []

    var status = connectionStatus.disconnected
    var config: Config

    var isConnected: Bool {
        get {
            if status == .connected {
                return true
            } else if config.autoReconnect && status == .disconnected {
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
        
        guard let _ = socket else {
            NSLog("Failure Socket has not initialized: Call .connect()")
            return
        }

        DispatchQueue.global(attributes: DispatchQueue.GlobalAttributes.qosUtility).async {
            repeat {
            
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

            } while true
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

            try sock.connect(to: host, port: port)

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

            let length = try reader.read(into: tmpBuffer!)
            
            var bytes = [UInt8](repeating: 0, count: (tmpBuffer?.length)!)
            
            tmpBuffer?.getBytes(&bytes, length:(tmpBuffer?.length)! * sizeof(UInt8.self))
            
            buffer.append(contentsOf: bytes)
            
            return length

        } catch {
            NSLog("Could not read from socket")
            
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

        guard !isConnected else {
            NSLog("Already Disconnected")
            return
        }

        status = .disconnected

        guard let sock = socket,
                  disconnectPacket = newControlPacket(packetType: .disconnect) else {
            throw NSError()
        }

        try disconnectPacket.write(writer: sock)
        
        sock.close()
    }

    func publish(topic: String, withMessage message: String, qos: qosType, retained: Bool, dup: Bool) -> UInt16 {
        
        let unusedID: UInt16 = UInt16(random: true)
        
        guard let sock = socket,
                  publishPacket = newControlPacket(packetType: .publish, topicName: topic, packetId: unusedID, message: [message]) else {

                return 0
        }

        do {
            try publishPacket.write(writer: sock)

            outMessages[unusedID] = publishPacket

            resetTimer()

            return 1

        } catch {

            return 0
        }
    }

    func publish(topic: String, message: String) -> UInt16 {

        let unusedID: UInt16 = UInt16(random: true)
        
        guard let sock = socket,
                  publishPacket = newControlPacket(packetType: .publish, topicName: topic, packetId: unusedID, message: [message]) else {

                return 0
        }

        do {
            try publishPacket.write(writer: sock)

            outMessages[unusedID] = publishPacket

            resetTimer()

            return 1

        } catch {
            return 0

        }
    }

    func subscribe(topic: [String], qoss: [qosType]) -> UInt16 {

        let unusedID: UInt16 = UInt16(random: true)
        
        guard let sock = socket,
                  subscribePacket = newControlPacket(packetType: .subscribe, packetId: unusedID, topics: topic, qoss: qoss) else {

                return 0
        }

        do {
            try subscribePacket.write(writer: sock)

            outMessages[unusedID] = subscribePacket

            resetTimer()

            return 1

        } catch {

            return 0
        }
    }

    func unsubscribe(topic: [String]) -> UInt16 {
        
        let unusedID: UInt16 = UInt16(random: true)
        
        guard let sock = socket,
                  unsubscribePacket = newControlPacket(packetType: .unsubscribe, packetId: unusedID, topics: topic) else {
                    
                return 0
        }

        do {
            try unsubscribePacket.write(writer: sock)

            outMessages[unusedID] = unsubscribePacket

            resetTimer()

            return 0

        } catch {
            return 0

        }
    }

    func ping() {

        guard let sock = socket,
              pingreqPacket = newControlPacket(packetType: .pingreq) else {

            return
        }
        
        do {
            try pingreqPacket.write(writer: sock)

        } catch {
            return

        }

    }
    func startTimer(){
        print("start Timer")
        keepAliveTimer = Timer(timeInterval: 0.2, target: self, selector: #selector(Aphid.pingT(timer:)), userInfo: "timer", repeats: true)
        RunLoop.current().add(keepAliveTimer, forMode: RunLoopMode.commonModes)
    }
    func resetTimer() {
        keepAliveTimer.invalidate()
        startTimer()
    }

    @objc(pingT:)
    func pingT(timer: Timer) {
        print("ping")
    }
}

