//
//  Disconnect.swift
//  Aphid
//
//  Created by Aaron Liberatore on 7/11/16.
//
//

import Foundation
import Socket

class DisconnectPacket {
    let header: FixedHeader

    init(header: FixedHeader) {
        self.header = header
    }
}

extension DisconnectPacket: ControlPacket {
    var description: String {
        return header.description
    }
    func write(writer: SocketWriter) throws {
        let packet = header.pack()
        try writer.write(from: packet)
    }

    func unpack(reader: SocketReader) {
    }

    func validate() -> ErrorCodes {
        return .accepted
    }
}
