
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


struct Attributes {
/*    var conn:            net.Conn
    var ibound:          chan packets.ControlPacket
    var obound:          chan *PacketAndToken
    var oboundP:         chan *PacketAndToken
    var msgRouter:       *router
    var stopRouter:      chan bool
    var incomingPubChan: chan *packets.PublishPacket
    var errors:         chan error
    var stop:            chan struct{}
    var persist:         Store*/
    var options: ClientOptions
    var status: ConnectionStatus
    //var workers:         sync.WaitGroup

}

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
    var cleanSess: Bool = true

    var socket: Socket?

    var attributes = Attributes(options: ClientOptions(), status: ConnectionStatus())

    init(clientId: String, username: String? = nil, password: String? = nil) {
        self.clientId = clientId
        self.username = username
        self.password = password
    }

    public func connect() throws -> Bool {

        socket = try Socket.create(family: .inet6, type: .stream, proto: .tcp)

        guard let sock = socket,
                  connectPacket = newControlPacket(packetType: .connect) else {

            throw NSError()
        }

        try sock.setBlocking(mode: true)

        try sock.connect(to: host, port: port)

        try connectPacket.write(writer: sock)

        /*let incomingData = NSMutableData(capacity: 5192)
        let incomingLength = try sock.read(into: incomingData!)
        print(incomingData!.length, incomingLength)*/

        let _ = parseConnack(reader: sock)

        return true
    }

    func isConnected() -> Bool {
        if attributes.status == connected {
            return true
        } else if attributes.options.AutoReconnect && attributes.status == disconnected {
            return true
        } else {
            return false
        }
    }
    func disconnect(uint: UInt) throws {
        guard !isConnected() else {
            NSLog("Already Disconnected")
            return
        }

        attributes.status = disconnected

        guard let sock = socket,
                  disconnectPacket = newControlPacket(packetType: .disconnect) else {
            throw NSError()
        }

        try disconnectPacket.write(writer: sock)


    }
    func publish(topic: String, withString string: String, qos: qosType, retained: Bool, dup: Bool) -> UInt16 {

        guard let sock = socket,
                  publishPacket = newControlPacket(packetType: .publish, topicName: "insects", packetId: 1) else {

                return 0
        }

        do {
            try publishPacket.write(writer: sock)
            return 1

        } catch {

            return 0
        }
    }
    func publish(message: String) -> UInt16 {
        guard let sock = socket,
                  publishPacket = newControlPacket(packetType: .publish, topicName: message, packetId: 1) else {

                return 0
        }
        print("connected?", sock.isConnected, "active?", sock.isActive)
        do {
            try publishPacket.write(writer: sock)
            let data = NSMutableData(capacity: 150)
            let length = try sock.read(into: data!)
            print("length", length)
            return 1

        } catch {
            return 0

        }
    }

    func subscribe(topic: String, qos: String) -> UInt16 {

        guard let sock = socket,
            subscribePacket = newControlPacket(packetType: .subscribe) else {

                return 0
        }

        do {
            try subscribePacket.write(writer: sock)
            return 1

        } catch {

            return 0
        }
    }

    func unsubscribe(topic: String) -> UInt16 {

        guard let sock = socket,
            unsubscribePacket = newControlPacket(packetType: .unsubscribe) else {

                return 0
        }

        do {
            try unsubscribePacket.write(writer: sock)
            return 1

        } catch {

            return 0
        }
    }

    func ping() {

    }
}
