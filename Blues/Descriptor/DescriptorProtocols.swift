// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

public protocol DescriptorProtocol: class {
    var identifier: Identifier { get }

    var name: String? { get }

    var characteristic: PeripheralCharacteristicProtocol { get }
    var service: ServiceProtocol { get }
    var peripheral: PeripheralProtocol { get }
}

public protocol ReadableDescriptorProtocol: DescriptorProtocol {
    var any: Any? { get }
    
    func read()
}

public protocol WritableDescriptorProtocol: DescriptorProtocol {
    func write(data: Data)
}

public protocol TypedReadableDescriptorProtocol: ReadableDescriptorProtocol {
    associatedtype Decoder: ValueDecoder where Self.Decoder.Input == Any
    
    var decoder: Decoder { get }
}

public protocol TypedWritableDescriptorProtocol: WritableDescriptorProtocol {
    associatedtype Encoder: ValueEncoder where Self.Encoder.Output == Data
    
    var encoder: Encoder { get }
}

public protocol StringConvertibleDescriptorProtocol: DescriptorProtocol {
    var stringValue: Result<String?, DecodingError> { get }
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
    ///   - any: `.success(any)` with the updated value iff successful, otherwise `.failure(error)`.
    ///   - descriptor: The descriptor whose value has been retrieved.
    func didUpdate(any: Result<Any, Error>, for descriptor: Descriptor)
}

public protocol DescriptorWritingDelegate: DescriptorDelegate {
    /// Invoked when you write data to a characteristic descriptor’s value.
    ///
    /// - Parameters:
    ///   - any: `.success(any)` with the written value iff successful, otherwise `.failure(error)`.
    ///   - descriptor: The descriptor whose value has been retrieved.
    func didWrite(any: Result<Any, Error>, for descriptor: Descriptor)
}
