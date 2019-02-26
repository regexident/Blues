//
//  ValueCoder.swift
//  Blues
//
//  Created by Vincent Esche on 11/10/18.
//  Copyright © 2018 NWTN Berlin. All rights reserved.
//

import Foundation

/// Errors related to a value transformation.
public enum TypesafeValueError: Swift.Error {
    /// The characteristic failed to encode its value.
    case encodingFailed(EncodingError)
    /// The characteristic failed to decode its value.
    case decodingFailed(DecodingError)
    /// Another error has occured
    case other(Swift.Error)
}

/// Errors related to a value encoding.
public struct EncodingError: Swift.Error {
    let message: String
    
    public init(message: String) {
        self.message = message
    }
}

/// Errors related to a value decoding.
public struct DecodingError: Swift.Error {
    let message: String
    
    public init(message: String) {
        self.message = message
    }
}

/// A value coder of a given characteristic's value.
public protocol ValueEncoder {
    /// The encoder's decoded value type.
    associatedtype Value
    
    /// The encoder's encoded value type.
    associatedtype Output
    
    /// The coding logic for encoding a
    /// type-safe value into an encoded representation
    func encode(_ value: Value) -> Result<Output, EncodingError>
}

/// A value coder of a given characteristic's value.
public protocol ValueDecoder {
    /// The encoder's decoded value type.
    associatedtype Value
    
    /// The encoder's encoded value type.
    associatedtype Input
    
    /// The coding logic for decoding a
    /// encoded value into an decoded type-safe representation
    func decode(_ input: Input) -> Result<Value, DecodingError>
}

public typealias ValueCoder = ValueDecoder & ValueEncoder
