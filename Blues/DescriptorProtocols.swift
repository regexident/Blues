//
//  DescriptorProtocols.swift
//  Blues
//
//  Created by Vincent Esche on 21/11/2016.
//  Copyright © 2016 NWTN Berlin. All rights reserved.
//

import Foundation

import Result

public protocol DescriptorProtocol: class {
    var identifier: Identifier { get }

    var name: String? { get }

    var characteristic: Characteristic { get }
    var service: Service { get }
    var peripheral: Peripheral { get }

    var any: Any? { get }

    init(identifier: Identifier, characteristic: Characteristic)

    func read()

    func write(data: Data)
}

public protocol DelegatedDescriptorProtocol: DescriptorProtocol {
    var delegate: DescriptorDelegate? { get set }
}

/// A `DelegatedDescriptor`'s delegate.
public protocol DescriptorDelegate: class {}

public protocol DescriptorReadingDelegate: DescriptorDelegate {
    /// Invoked when you retrieve a specified characteristic descriptor’s value.
    ///
    /// - Parameters:
    ///   - any: `.ok(any)` with the updated value iff successful, otherwise `.err(error)`.
    ///   - descriptor: The descriptor whose value has been retrieved.
    func didUpdate(any: Result<Any, Error>, for descriptor: Descriptor)
}

public protocol DescriptorWritingDelegate: DescriptorDelegate {
    /// Invoked when you write data to a characteristic descriptor’s value.
    ///
    /// - Parameters:
    ///   - any: `.ok(any)` with the written value iff successful, otherwise `.err(error)`.
    ///   - descriptor: The descriptor whose value has been retrieved.
    func didWrite(any: Result<Any, Error>, for descriptor: Descriptor)
}

/// A descriptor of a peripheral’s characteristic, providing further information about its value.
public protocol DescriptorValueTransformer {
    /// The descriptor's value type.
    associatedtype Value

    /// The transformation logic for decoding the descriptor's
    /// data value into type-safe value representation
    func transform(any: Any) -> Result<Value, TypedDescriptorError>

    /// The transformation logic for encoding the descriptor's
    /// type-safe value into a data representation
    func transform(value: Value) -> Result<Data, TypedDescriptorError>
}

public protocol TypedDescriptorProtocol {
    associatedtype Transformer: DescriptorValueTransformer

    var transformer: Transformer { get }
}
