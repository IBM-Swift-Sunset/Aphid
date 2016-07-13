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
    let fixedHeader: FixedHeader
    
    init(fixedHeader: FixedHeader){
        self.fixedHeader = fixedHeader
    }
}

extension DisconnectPacket: ControlPacket {
    func write(writer: SocketWriter) throws {
        let packet = self.fixedHeader.pack()
        try writer.write(from: packet)
    }
    func unpack(reader: SocketReader) {

    }
    func validate() -> ErrorCodes {
        return .accepted
    }
}