//
//  DescriptorProtocols.swift
//  Blues
//
//  Created by Vincent Esche on 21/11/2016.
//  Copyright © 2016 NWTN Berlin. All rights reserved.
//

import Foundation

import Result

public protocol ReadableDescriptorDelegate: class {
    /// Invoked when you retrieve a specified characteristic descriptor’s value.
    ///
    /// - Parameters:
    ///   - any: `.ok(any)` with the updated value iff successful, otherwise `.err(error)`.
    ///   - descriptor: The descriptor whose value has been retrieved.
    func didUpdate(any: Result<Any, Error>, for descriptor: Descriptor)
}

public protocol WritableDescriptorDelegate: class {
    /// Invoked when you write data to a characteristic descriptor’s value.
    ///
    /// - Parameters:
    ///   - any: `.ok(any)` with the written value iff successful, otherwise `.err(error)`.
    ///   - descriptor: The descriptor whose value has been retrieved.
    func didWrite(any: Result<Any, Error>, for descriptor: Descriptor)
}

/// A `DelegatedDescriptor`'s delegate.
public typealias DescriptorDelegate =
    ReadableDescriptorDelegate
    & WritableDescriptorDelegate

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

public protocol TypedDescriptor {
    associatedtype Transformer: DescriptorValueTransformer

    var transformer: Transformer { get }
}
