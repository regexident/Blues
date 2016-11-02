//
//  Descriptor.swift
//  Blues
//
//  Created by Vincent Esche on 28/10/2016.
//  Copyright © 2016 NWTN Berlin. All rights reserved.
//

import Foundation
import CoreBluetooth

public class DefaultDescriptor: Descriptor, DelegatedDescriptor {
    public let shadow: ShadowDescriptor
    public weak var delegate: DescriptorDelegate?

    public var name: String? {
        return nil
    }

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

/// A descriptor of a peripheral’s characteristic, providing further information about its value.
public protocol Descriptor: class, DescriptorDelegate {
    var name: String? { get }
    var shadow: ShadowDescriptor { get }

    init(shadow: ShadowDescriptor)
}

extension Descriptor {
    public var uuid: Identifier {
        return self.shadow.uuid
    }

    public var any: Result<Any?, PeripheralError> {
        return self.core.map {
            $0.value
        }
    }

    public var characteristic: Characteristic? {
        return self.shadow.characteristic
    }

    var nextResponder: Responder? {
        return self.shadow.characteristic as! Responder?
    }

    public func read() -> Result<(), PeripheralError> {
        return (self as! Responder).tryToHandle(ReadValueForDescriptorMessage(
            descriptor: self
        )) ?? .err(.unhandled)
    }

    public func write(data: Data) -> Result<(), PeripheralError> {
        return (self as! Responder).tryToHandle(WriteValueForDescriptorMessage(
            data: data,
            descriptor: self
        )) ?? .err(.unhandled)
    }

    var core: Result<CBDescriptor, PeripheralError> {
        return self.shadow.core.okOr(.unreachable)
    }
}

/// A descriptor of a peripheral’s characteristic, providing further information about its value.
public protocol TypesafeDescriptor: Descriptor {
    associatedtype Value

    /// The value of the descriptor.
    var value: Value? { get }

    func transform(data: Data) -> Value
    func transform(value: Value) -> Data
}

public protocol DelegatedDescriptor: Descriptor {
    weak var delegate: DescriptorDelegate? { get set }
}

public protocol DescriptorDelegate: class {
    func didUpdate(any: Result<Any, Error>, forDescriptor descriptor: Descriptor)
    func didWrite(any: Result<Any, Error>, forDescriptor descriptor: Descriptor)
}

public protocol TypesafeDescriptorDelegate: DescriptorDelegate {
    associatedtype Value

    func didUpdate(value: Result<Value, Error>, forDescriptor descriptor: Descriptor)
    func didWrite(value: Result<Value, Error>, forDescriptor descriptor: Descriptor)
}

public class ShadowDescriptor {
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
