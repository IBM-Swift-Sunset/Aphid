/**
 Copyright IBM Corporation 2017

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

struct DisconnectPacket: ControlPacket {
    
    init(){}
    init(data: Data) {}

    var description: String {
        return String(describing: ControlCode.disconnect)
    }
    
    func write(writer: SocketWriter) throws {
	    var buffer = Data(capacity: 2)
	    
        buffer.append(ControlCode.disconnect.rawValue.data)
        buffer.append(0.data)
        try writer.write(from: buffer)
    }

    func unpack(reader: SocketReader) {
    }

    func validate() -> MQTTErrors {
        return .accepted
    }
}
