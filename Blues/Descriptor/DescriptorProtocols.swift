// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

public protocol DescriptorProtocol: class {
    var identifier: Identifier { get }

    var name: String? { get }

    var characteristic: Characteristic { get }
    var service: ServiceProtocol { get }
    var peripheral: Peripheral { get }

    var any: Any? { get }

    init(identifier: Identifier, characteristic: Characteristic)

    func read()

    func write(data: Data)
}

public protocol TypedDescriptorProtocol: DescriptorProtocol {
    associatedtype Transformer: DescriptorValueTransformer

    var transformer: Transformer { get }
}

public protocol StringConvertibleDescriptorProtocol: DescriptorProtocol {
    var stringValue: Result<String?, TypedDescriptorError> { get }
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
