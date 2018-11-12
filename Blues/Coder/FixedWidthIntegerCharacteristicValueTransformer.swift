//
//  FixedWidthIntegerValueCoder.swift
//  Blues
//
//  Created by Vincent Esche on 11/10/18.
//  Copyright © 2018 NWTN Berlin. All rights reserved.
//

import Foundation

public enum Endianness {
    case bigEndian
    case littleEndian
}

/// Value coder for trivially copyable (i.e. no indirect memory) types of fixed-length.
public struct FixedWidthIntegerValueCoder<T>
where
    T: FixedWidthInteger
{
    public typealias Value = T

    public var endianness: Endianness = .bigEndian
    
    public init(endianness: Endianness = .bigEndian) {
        self.endianness = endianness
    }
}

extension FixedWidthIntegerValueCoder: ValueEncoder {
    public typealias Output = Data
    
    public func encode(_ value: Value) -> Result<Output, EncodingError> {
        // Adjust for protocol endianness:
        let endian: Value
        switch self.endianness {
        case .bigEndian:
            endian = value.bigEndian
        case .littleEndian:
            endian = value.littleEndian
        }
        // Dump bytes into data object:
        return .ok(Swift.withUnsafePointer(to: endian) { (pointer: UnsafePointer<Value>) in
            return Data(bytes: pointer, count: MemoryLayout<Value>.size)
        })
    }
}

extension FixedWidthIntegerValueCoder: ValueDecoder {
    public typealias Input = Data
    
    public func decode(_ input: Input) -> Result<Value, DecodingError> {
        let expectedLength = MemoryLayout<Value>.size
        let foundBytes = input.count
        guard foundBytes == expectedLength else {
            let message = "Expected \(expectedLength) bytes, found \(foundBytes) bytes."
            return .err(.init(message: message))
        }
        // Read raw bytes from data object:
        let endian = input.withUnsafeBytes { (pointer: UnsafePointer<Value>) in
            pointer.pointee
        }
        // Adjust for native endianness:
        switch self.endianness {
        case .bigEndian: return .ok(Value(bigEndian: endian))
        case .littleEndian: return .ok(Value(littleEndian: endian))
        }
    }
}

//extension Int: TransformableValue {
//    public typealias Coder = FixedWidthIntegerValueCoder<Int>
//}
//
//extension UInt: TransformableValue {
//    public typealias Coder = FixedWidthIntegerValueCoder<UInt>
//}
//
//extension Int8: TransformableValue {
//    public typealias Coder = FixedWidthIntegerValueCoder<Int8>
//}
//
//extension UInt8: TransformableValue {
//    public typealias Coder = FixedWidthIntegerValueCoder<UInt8>
//}
//
//extension Int16: TransformableValue {
//    public typealias Coder = FixedWidthIntegerValueCoder<Int16>
//}
//
//extension UInt16: TransformableValue {
//    public typealias Coder = FixedWidthIntegerValueCoder<UInt16>
//}
//
//extension Int32: TransformableValue {
//    public typealias Coder = FixedWidthIntegerValueCoder<Int32>
//}
//
//extension UInt32: TransformableValue {
//    public typealias Coder = FixedWidthIntegerValueCoder<UInt32>
//}
//
//extension Int64: TransformableValue {
//    public typealias Coder = FixedWidthIntegerValueCoder<Int64>
//}
//
//extension UInt64: TransformableValue {
//    public typealias Coder = FixedWidthIntegerValueCoder<UInt64>
//}

