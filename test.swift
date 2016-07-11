

func encodeUInt16(_ int: UInt16) -> [UInt8] {
    var bytes: [UInt8] = [0x00, 0x00]
    //let uNv = UInt16(bitPattern: int)
    bytes[0] = UInt8(int >> 8)
    bytes[1] = UInt8(int & 0x00ff)
    return bytes
}

let test = UInt16(772)

print(test)
let answer = encodeUInt16(test)
print(answer)

//print(answer)

print("hello")
