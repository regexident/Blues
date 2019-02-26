//
//  StringValueCoder.swift
//  Blues
//
//  Created by Vincent Esche on 11/10/18.
//  Copyright © 2018 NWTN Berlin. All rights reserved.
//

import Foundation

/// Value coder for String values.
public struct StringValueCoder {
    public typealias Value = String
    
    public var encoding: String.Encoding = .utf8
    
    public init(encoding: String.Encoding = .utf8) {
        self.encoding = encoding
    }
}

extension StringValueCoder: ValueEncoder {
    public typealias Output = Data
    
    public func encode(_ value: Value) -> Result<Output, EncodingError> {
        guard let data = value.data(using: self.encoding) else {
            return .err(.init(message: "Failed to encode `String` as `Data`."))
        }
        return .ok(data)
    }
}

extension StringValueCoder: ValueDecoder {
    public typealias Input = Data
    
    public func decode(_ input: Input) -> Result<Value, DecodingError> {
        guard let string = String(data: input, encoding: self.encoding) else {
            return .err(.init(message: "Failed decode `String` from `Data`."))
        }
        return .ok(string)
    }
}
