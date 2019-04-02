//
//  PrimitiveValueCoder.swift
//  Blues
//
//  Created by Vincent Esche on 11/10/18.
//  Copyright © 2018 NWTN Berlin. All rights reserved.
//

import Foundation

/// Value coder for trivially copyable (i.e. no indirect memory) types of fixed-length.
public struct PrimitiveValueCoder<T> {
    public typealias Value = T
}

extension PrimitiveValueCoder: ValueEncoder {
    public typealias Output = Data
    
    public func encode(_ value: Value) -> Result<Output, EncodingError> {
        return .ok(Swift.withUnsafePointer(to: value) { (pointer: UnsafePointer<Value>) in
            return Data(bytes: pointer, count: MemoryLayout<Value>.size)
        })
    }
}

extension PrimitiveValueCoder: ValueDecoder {
    public typealias Input = Data
    
    public func decode(_ input: Input) -> Result<Value, DecodingError> {
        let expectedLength = MemoryLayout<Value>.size
        let foundBytes = input.count
        guard foundBytes == expectedLength else {
            let message = "Expected \(expectedLength) bytes, found \(foundBytes) bytes."
            return .err(.init(message: message))
        }
        return .ok(input.withUnsafeBytes { unsafeRawBufferPointer in
            let unsafeBufferPointer = unsafeRawBufferPointer.bindMemory(to: Value.self)
            let unsafePointer = unsafeBufferPointer.baseAddress!
            return unsafePointer.pointee
        })
    }
}
