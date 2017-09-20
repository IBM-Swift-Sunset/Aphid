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

#if os(Linux)
    #if swift(>=3.1)
        typealias RegularExpressionType = NSRegularExpression
    #else
        typealias RegularExpressionType = RegularExpression
    #endif
#else
    typealias RegularExpressionType = NSRegularExpression
#endif

extension SocketWriter {
    func write(from data: Data) throws {
        try self.write(from: NSData(data: data))
    }
}

extension Bool {
    
    var toByte: Byte {
        return self ? 0x01 : 0x00
    }
}

extension String {
    
    var data: Data {
        var array = Data()
        
        if let utf = self.data(using: String.Encoding.utf8) {
            array.append(UInt16(utf.count).data)
            array.append(utf)
        } else {
            array.append(UInt16(0).data)
        }
        return array
    }
    
    var sData: Data {
        var array = Data()
        
        if let utf = self.data(using: String.Encoding.utf8) {
            array.append(utf)
        }
        return array
    }
    
    func matches(pattern: String!) -> Bool {
        
        do {
    
            let regex = try RegularExpressionType(pattern: pattern, options: [])
            let results = regex.numberOfMatches(in: self, options: .reportProgress, range: NSMakeRange(0, self.count))

            return results > 0
        } catch {
            print("Malformed Subscribe or Publish Expression")
        }
        
        return false
    }
}

extension Int {
    
    var toBytes: [Byte] {
        var encLength = [Byte]()
        var length = self
        
        repeat {
            var digit = Byte(length % 128)
            length /= 128
            if length > 0 {
                digit |= 0x80
            }
            encLength.append(digit)
            
        } while length != 0
        
        return encLength
    }
    var data: Data {
        return UInt8(self).data
    }
}

extension UInt8 {
    
    var data: Data {
        return Data(bytes: [self])
    }
    
    var bool: Bool {
        return self == 0x01 ? true : false
    }
    
    var int: Int {
        return Int(self)
    }
    
    subscript(index: Int) -> UInt8 { //Returns a byte with only the index bit set if applicable
        return 0
    }
}

extension UInt16 {
    
    static var random: UInt16 {
        #if os(Linux)
            return UInt16(rand() % Int32(UInt16.max))
        #else
            return UInt16(arc4random_uniform(UInt32(UInt16(max))))
        #endif
    }
    
    init(msb: Byte, lsb: Byte) {
        self = (UInt16(msb) << 8) | UInt16(lsb)
    }
    
    var data: Data {
        var data = Data()
        let bytes: [UInt8] = [UInt8(self >> 8), UInt8(self & 0x00ff)]
        data.append(Data(bytes: bytes, count: 2))
        return data
    }
    
    var bytes: [Byte] {
        return [UInt8(self >> 8), UInt8(self & 0x00ff)]
    }
}

extension Data {
    
    var decodeUInt8: UInt8 {
        mutating get {
            let uint = UInt8(self[0])
            self = self.subdata(in: Range(1..<self.count))
            return uint
        }
    }
    var decodeUInt16: UInt16 {
        mutating get {
            let uint = UInt16(msb: self[0], lsb: self[1])
            self = self.subdata(in: Range(2..<self.count))
            return uint
        }
    }
    var decodeString: String {
        mutating get {
            let length = UInt16(msb: self[0], lsb: self[1])
            let str = self.subdata(in: Range(2..<2 + Int(length)))
            self = self.subdata(in: Range(2 + Int(length)..<self.count))
            return String(data: str, encoding: String.Encoding.utf8)!
        }
    }
    var decodeSDataString: String {
        return String(data: self, encoding: String.Encoding.utf8)!
    }
}

// Unused Helper Functions
func decodeLength(_ data: Data) -> Int? {
    var data = data
    var rLength: UInt32 = 0
    var multiplier: UInt32 = 1
    var byte = UInt8(0x00)
    repeat {
        if data.count == 0 {
            return nil
        }
        byte = data.decodeUInt8
        rLength += UInt32(byte & 127) * multiplier
        multiplier *= 128
        if (multiplier) > 128*128*128 {
            break
        }
    } while (byte & 0x80) != 0
    return Int(rLength)
}
