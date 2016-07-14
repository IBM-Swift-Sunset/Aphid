//
//  Pingresp.swift
//  Aphid
//
//  Created by Joseph Yin on 7/14/16.
//
//

import Foundation
import Socket


class PingrespPacket {
    let header: FixedHeader

    init(header: FixedHeader) {
        self.header = header
    }
}

extension PingrespPacket: ControlPacket {
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
