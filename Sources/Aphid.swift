
import Foundation
import Socket

public struct Token {

}
public struct ConnectionStatus: Equatable {

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

    var socket: Socket?
    
    var status = connected
    var config: Config

    var isConnected: Bool {
        get {
            if status == connected {
                return true
            } else if config.autoReconnect && status == disconnected {
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
        repeat {
            do {
                let _ = try Socket.checkStatus(for: [socket!])
            } catch {
                debugPrint("Socket cannot be read from")
            }
            /*DispatchQueue.global(
             attributes: DispatchQueue.GlobalAttributes(rawValue: UInt64(Int(QOS_CLASS_USER_INTERACTIVE.rawValue)))).sync() {
                 let _ = try Socket.wait(for: [sock], timeout: 100)
                 print("hello there")
                 let packet = ConnackPacket(reader: sock)?.validate()
                 print(packet)
             }*/
        } while true
    }
    // Initial Connect
    public func connect() throws -> Bool {

        socket = try Socket.create(family: .inet6, type: .stream, proto: .tcp)
            
        guard let sock = socket,
                  connectPacket = newControlPacket(packetType: .connect) else {

            throw NSError()
        }
        
        try sock.setBlocking(mode: false)

        try sock.connect(to: host, port: port)

        try connectPacket.write(writer: sock)

        return true
    }
    
    // Reconnect
    func reconnect() -> Bool {
        return true
    }

    func disconnect(uint: UInt) throws {
        guard !isConnected else {
            NSLog("Already Disconnected")
            return
        }

        status = disconnected

        guard let sock = socket,
                  disconnectPacket = newControlPacket(packetType: .disconnect) else {
            throw NSError()
        }

        try disconnectPacket.write(writer: sock)


    }

    func publish(topic: String, withString string: String, qos: qosType, retained: Bool, dup: Bool) -> UInt16 {
        
        let unusedID: UInt16 = 1 // This has to be calculated somehow
        
        guard let sock = socket,
            publishPacket = newControlPacket(packetType: .publish, topicName: "insects", packetId: unusedID, message: [string]) else {

                return 0
        }

        do {
            try publishPacket.write(writer: sock)
            return 1

        } catch {

            return 0
        }
    }

    func publish(topic: String, message: String) -> UInt16 {
        
        let unusedID: UInt16 = 76 // This has to be calculated somehow
        
        guard let sock = socket,
            publishPacket = newControlPacket(packetType: .publish, topicName: topic, packetId: unusedID, message: [message]) else {

                return 0
        }

        do {
            try publishPacket.write(writer: sock)
            let data = NSMutableData(capacity: 150)
            let _ = try sock.read(into: data!)
            return 1

        } catch {
            return 0

        }
    }

    func subscribe(topic: [String], qoss: [qosType]) -> UInt16 {

        let unusedID: UInt16 = 15 // This has to be calculated somehow
        
        guard let sock = socket,
            subscribePacket = newControlPacket(packetType: .subscribe, packetId: unusedID, topics: topic, qoss: qoss) else {

                return 0
        }
        

        do {
            try subscribePacket.write(writer: sock)
            let _ = try Socket.wait(for: [sock], timeout: 100)
            return 1

        } catch {

            return 0
        }
    }

    func unsubscribe(topic: [String]) -> UInt16 {
        
        let unusedID: UInt16 = 12 // This has to be calculated somehow
        
        guard let sock = socket,
            unsubscribePacket = newControlPacket(packetType: .unsubscribe, packetId: unusedID, topics: topic) else {
                return 0
        }

        do {
            try unsubscribePacket.write(writer: sock)
            return 100

        } catch {

            return 0
        }
    }

    func ping() {
        guard let sock = socket,
              let pingreqPacket = newControlPacket(packetType: .pingreq) else {
            return
        }
        
        do {
            try pingreqPacket.write(writer: sock)
        } catch {
            return 
        }

    }

}
