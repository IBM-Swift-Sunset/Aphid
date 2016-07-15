//
//  Publish.swift
//  Aphid
//
//  Created by Aaron Liberatore on 7/11/16.
//
//

import Foundation
import Socket

class PublishPacket {
    var header: FixedHeader
    let dup: Bool
    let qos: qosType
    let willRetain: Bool
    var topicName: String
    var identifier: UInt16
    var payload: [String]

    init(header: FixedHeader, dup: Bool = false, qos: qosType = .atLeastOnce, willRetain: Bool = false,
        
        topicName: String, packetId: UInt16, payload: [String] = ["This plant needs water"]) {
        
        var header = header
        header.dup = dup
        header.qos = qos.rawValue
        header.retain = willRetain

        self.header = header
        self.dup = dup
        self.qos = qos
        self.willRetain = willRetain
        self.topicName = topicName
        self.identifier = packetId
        self.payload = payload
    }
}

extension PublishPacket: ControlPacket {
    func write(writer: SocketWriter) throws {
        guard var buffer = Data(capacity: 512) else {
            throw NSError()
        }

        buffer.append(topicName.data)

        if qos.rawValue > 0 {
            buffer.append(identifier.data)
        }

        for item in payload {
            buffer.append(item.data)
        }
        header.remainingLength = buffer.count + payload.count //payload count cant be pstring

        var packet = header.pack()
        packet.append(buffer)

        do {
            try writer.write(from: packet)

        } catch {
            throw NSError()

        }

    }

    func unpack(reader: SocketReader) {
        var payloadSize = header.remainingLength
        topicName = decodeString(reader)
        if qos.rawValue > 0 {
            identifier = decodeUInt16(reader)
            payloadSize -= topicName.characters.count + 4
        } else {
            payloadSize -= topicName.characters.count + 2
        }
        var payload = [String]()

        for _ in 0..<payloadSize {
            payload.append(decodeString(reader))
        }

    }

    func validate() -> ErrorCodes {
        return .accepted
    }
}
