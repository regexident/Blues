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
public class DefaultDescriptor: Descriptor, DelegatedDescriptor {
    
    public let shadow: ShadowDescriptor

    public weak var delegate: DescriptorDelegate?

    public required init(shadow: ShadowDescriptor) {
        self.shadow = shadow
    }
}

extension DefaultDescriptor: DescriptorDelegate {

    public func didUpdate(any: Result<Any, Error>, forDescriptor descriptor: Descriptor) {
        self.delegate?.didUpdate(any: any, forDescriptor: descriptor)
    }

    public func didWrite(any: Result<Any, Error>, forDescriptor descriptor: Descriptor) {
        self.delegate?.didWrite(any: any, forDescriptor: descriptor)
    }
}

extension DefaultDescriptor: CustomStringConvertible {

    public var description: String {
        let attributes = [
            "uuid = \(self.uuid)",
        ].joined(separator: ", ")
        return "<DefaultDescriptor \(attributes)>"
    }
}

/// A descriptor of a peripheral’s characteristic,
/// providing further information about its value.
public protocol Descriptor: class, DescriptorDelegate {
    
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

    var nextResponder: Responder? {
        return self.shadow.characteristic as! Responder?
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
        return (self as! Responder).tryToHandle(ReadValueForDescriptorMessage(
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
        return (self as! Responder).tryToHandle(WriteValueForDescriptorMessage(
            data: data,
            descriptor: self
        )) ?? .err(.unhandled)
    }
}

/// A descriptor of a peripheral’s characteristic, providing further information about its value.
public protocol TypesafeDescriptor: Descriptor {

    /// The descriptor value's type.
    associatedtype Value

    /// The value of the descriptor.
    ///
    /// - Note:
    ///   This is a thin type-safe wrapper around `Descriptor.data`.
    ///   See its documentation for more information. All this wrapper basically
    ///   does is transforming `self.data` into an `Value` object by calling
    ///   `self.transform(data: self.data)` and then returning the result.
    var value: Value? { get }

    /// A transformation from `Data` to `Value`.
    func transform(data: Data) -> Value

    /// A transformation from `Value` to `Data`.
    func transform(value: Value) -> Data
}

/// A `Descriptor` that supports delegation.
public protocol DelegatedDescriptor: Descriptor {
    
    /// The descriptor's delegate.
    weak var delegate: DescriptorDelegate? { get set }
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

/// A `DelegatedDescriptor`'s type-safe delegate.
public protocol TypesafeDescriptorDelegate: DescriptorDelegate {
    associatedtype Value

    /// Invoked when you retrieve a specified characteristic descriptor’s value.
    ///
    /// - Note:
    ///   This is a thin type-safe wrapper around `Descriptor.didUpdate(data:forDescriptor:)`.
    ///   See its documentation for more information. All this wrapper basically
    ///   does is transforming `self.data` into an `Value` object by calling
    ///   `self.transform(data: self.data)` and then returning the result.
    ///
    /// - Parameters:
    ///   - value: `.ok(value)` with the updated value iff successful, otherwise `.err(error)`.
    ///   - descriptor: The descriptor whose value has been retrieved.
    func didUpdate(value: Result<Value, Error>, forDescriptor descriptor: Descriptor)

    /// Invoked when you write data to a characteristic descriptor’s value.
    ///
    /// - Note:
    ///   This is a thin type-safe wrapper around `Descriptor.didWrite(data:forDescriptor:)`.
    ///   See its documentation for more information. All this wrapper basically
    ///   does is transforming `self.data` into an `Value` object by calling
    ///   `self.transform(data: self.data)` and then returning the result.
    ///
    /// - Parameters:
    ///   - value: `.ok(value)` with the written value iff successful, otherwise `.err(error)`.
    ///   - descriptor: The descriptor whose value has been retrieved.
    func didWrite(value: Result<Value, Error>, forDescriptor descriptor: Descriptor)
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
