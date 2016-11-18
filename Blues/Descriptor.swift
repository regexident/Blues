//
//  Descriptor.swift
//  Blues
//
//  Created by Vincent Esche on 28/10/2016.
//  Copyright © 2016 NWTN Berlin. All rights reserved.
//

import Foundation
import CoreBluetooth

/// Default implementation of `Descriptor` protocol.
public class DefaultDescriptor: DelegatedDescriptor {

    public let shadow: ShadowDescriptor

    public weak var delegate: DescriptorDelegate?

    public required init(shadow: ShadowDescriptor) {
        self.shadow = shadow
    }
}

/// A descriptor of a peripheral’s characteristic,
/// providing further information about its value.
public protocol Descriptor: class, DescriptorDelegate, CustomStringConvertible {

    /// The descriptor's name.
    ///
    /// - Note:
    ///   Default implementation returns `nil`
    var name: String? { get }

    /// The supporting "shadow" descriptor that does the heavy lifting.
    var shadow: ShadowDescriptor { get }

    /// Initializes a `Descriptor` as a shim for a provided shadow descriptor.
    init(shadow: ShadowDescriptor)
}

extension Descriptor {

    /// The Bluetooth-specific identifier of the descriptor.
    public var uuid: Identifier {
        return self.shadow.uuid
    }

    /// The descriptor's name.
    ///
    /// - Note:
    ///   Override this property to provide a name for your custom descriptor type.
    public var name: String? {
        return nil
    }

    /// The value of the descriptor, or an error.
    public var any: Result<Any?, PeripheralError> {
        return self.core.map {
            $0.value
        }
    }

    /// The characteristic that this descriptor belongs to.
    public var characteristic: Characteristic? {
        return self.shadow.characteristic
    }

    var core: Result<CBDescriptor, PeripheralError> {
        return self.shadow.core.okOr(.unreachable)
    }

    /// Retrieves the value of the characteristic descriptor, or an error.
    ///
    /// - Note:
    ///   When you call this method to read the value of a characteristic
    ///   descriptor, the descriptor calls the `didUpdate(any:forDescriptor:)`
    ///   method of its delegate object with the retrieved value, or an error.
    ///
    /// - Returns: `.ok(())` iff successfull, `.err(error)` otherwise.
    public func read() -> Result<(), PeripheralError> {
        return self.shadow.tryToHandle(ReadValueForDescriptorMessage(
            descriptor: self
        )) ?? .err(.unhandled)
    }

    /// Writes the value of a characteristic descriptor.
    ///
    /// - Note:
    ///   When you call this method to write the value of a characteristic
    ///   descriptor, the peripheral calls the `didWrite(any:forDescriptor:)`
    ///   method of its delegate object. The data passed into the data
    ///   parameter is copied, and you can dispose of it after the method returns.
    ///
    /// - Important:
    ///   You cannot use this method to write the value of a client
    ///   configuration descriptor (represented by the
    ///   `CBUUIDClientCharacteristicConfigurationString` constant),
    ///   which describes how notification or indications are configured
    ///   for a characteristic’s value with respect to a client.
    ///   If you want to manage notifications or indications for a
    ///   characteristic’s value, you must use the `set(notifyValue:)`
    ///   method of `Characteristic` instead.
    ///
    /// Parameters:
    /// - data: The value to be written.
    ///
    /// - Returns: `.ok(())` iff successfull, `.err(error)` otherwise.
    public func write(data: Data) -> Result<(), PeripheralError> {
        return self.shadow.tryToHandle(WriteValueForDescriptorMessage(
            data: data,
            descriptor: self
        )) ?? .err(.unhandled)
    }
    
    public var description: String {
        let className = type(of: self)
        let attributes = [
            "uuid = \(self.shadow.uuid)",
            "name = \(self.name ?? "<nil>")",
        ].joined(separator: ", ")
        return "<\(className) \(attributes)>"
    }
}

/// A descriptor of a peripheral’s characteristic, providing further information about its value.
public protocol TypesafeDescriptor: Descriptor {

    /// The descriptor's value type.
    associatedtype Value
    
    /// The transformation logic for decoding the descriptor's
    /// data value into type-safe value representation
    func transform(any: Any) -> Result<Value, TypesafeDescriptorError>

    /// The transformation logic for encoding the descriptor's
    /// type-safe value into a data representation
    func transform(value: Value) -> Result<Data, TypesafeDescriptorError>
}

extension TypesafeDescriptor {
    /// A type-safe value representation of the descriptor.
    ///
    /// - Note:
    ///   This is a thin type-safe wrapper around `Descriptor.data`.
    ///   See its documentation for more information. All this wrapper basically
    ///   does is transforming `self.data` into an `Value` object by calling
    ///   `self.transform(data: self.data)` and then returning the result.
    public var value: Result<Value?, TypesafeDescriptorError> {
        return self.any.mapErr(f: TypesafeDescriptorError.peripheral).andThen { any in
            guard let any = any else {
                return .ok(nil)
            }
            return self.transform(any: any).map { .some($0) }
        }
    }
    
    /// Writes the value of a descriptor.
    ///
    /// - Note:
    ///   This is a thin type-safe wrapper around `Descriptor.write(data:type:)`.
    ///   See its documentation for more information. All this wrapper basically does
    ///   is transforming `any` into an `Data` object by calling `self.transform(any: any)`
    ///   and then passing the result to `Descriptor.write(data:type:)`.
    ///
    /// - SeeAlso: `Descriptor.write(data:type:)`
    ///
    /// - Parameters:
    ///   - value: The value to be written.
    ///   - type: The type of write to be executed.
    ///
    /// - Returns: `.ok(())` iff successful, `.err(error)` otherwise.
    public func write(value: Value, type: WriteType) -> Result<(), TypesafeDescriptorError> {
        return self.transform(value: value).andThen { data in
            let answer = self.shadow.tryToHandle(WriteValueForDescriptorMessage(
                data: data,
                descriptor: self
            ))
            if answer != nil {
                return .ok(())
            } else {
                return .err(.peripheral(.unhandled))
            }
        }
    }
}

/// A `Descriptor` that supports delegation.
///
/// Note: Conforming to `DelegatedDescriptor` adds a default implementation for all
/// functions found in `DescriptorDelegate` which simply forwards all method calls
/// to its delegate.
public protocol DelegatedDescriptor: Descriptor {

    /// The descriptor's delegate.
    weak var delegate: DescriptorDelegate? { get set }
}

extension DelegatedDescriptor {
    public func didUpdate(any: Result<Any, Error>, forDescriptor descriptor: Descriptor) {
        self.delegate?.didUpdate(any: any, forDescriptor: descriptor)
    }
    
    public func didWrite(any: Result<Any, Error>, forDescriptor descriptor: Descriptor) {
        self.delegate?.didWrite(any: any, forDescriptor: descriptor)
    }
}

/// A `DelegatedDescriptor`'s delegate.
public protocol DescriptorDelegate: class {

    /// Invoked when you retrieve a specified characteristic descriptor’s value.
    ///
    /// - Parameters:
    ///   - any: `.ok(any)` with the updated value iff successful, otherwise `.err(error)`.
    ///   - descriptor: The descriptor whose value has been retrieved.
    func didUpdate(any: Result<Any, Error>, forDescriptor descriptor: Descriptor)

    /// Invoked when you write data to a characteristic descriptor’s value.
    ///
    /// - Parameters:
    ///   - any: `.ok(any)` with the written value iff successful, otherwise `.err(error)`.
    ///   - descriptor: The descriptor whose value has been retrieved.
    func didWrite(any: Result<Any, Error>, forDescriptor descriptor: Descriptor)
}

/// The supporting "shadow" descriptor that does the actual heavy lifting
/// behind any `Descriptor` implementation.
public class ShadowDescriptor {

    /// The Bluetooth-specific identifier of the descriptor.
    public let uuid: Identifier

    weak var core: CBDescriptor?
    weak var characteristic: Characteristic?

    init(core: CBDescriptor, characteristic: Characteristic) {
        self.uuid = Identifier(uuid: core.uuid)
        self.core = core
        self.characteristic = characteristic
    }

    func attach(core: CBDescriptor) {
        self.core = core
    }

    func detach() {
        self.core = nil
    }
}

extension ShadowDescriptor: Responder {

    var nextResponder: Responder? {
        return self.characteristic?.shadow
    }
}
