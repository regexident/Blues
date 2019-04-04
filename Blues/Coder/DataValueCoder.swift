//
//  DataValueCoder.swift
//  Blues
//
//  Created by Vincent Esche on 11/10/18.
//  Copyright © 2018 NWTN Berlin. All rights reserved.
//

import Foundation

/// Value coder for String values.
public struct DataValueCoder {
    public typealias Value = Data
}

extension DataValueCoder: ValueEncoder {
    public typealias Output = Data
    
    public func encode(_ value: Value) -> Result<Output, EncodingError> {
        return .success(value)
    }
}

extension DataValueCoder: ValueDecoder {
    public typealias Input = Data
    
    public func decode(_ input: Input) -> Result<Value, DecodingError> {
        return .success(input)
    }
}
