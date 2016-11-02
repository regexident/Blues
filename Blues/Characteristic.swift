//
//  Characteristic.swift
//  Blues
//
//  Created by Vincent Esche on 28/10/2016.
//  Copyright © 2016 NWTN Berlin. All rights reserved.
//

import Foundation
import CoreBluetooth

public class DefaultCharacteristic: Characteristic, DelegatedCharacteristic {
    public let shadow: ShadowCharacteristic
    public weak var delegate: CharacteristicDelegate?

    public var name: String? {
        return nil
    }

    public required init(shadow: ShadowCharacteristic) {
        self.shadow = shadow
    }

    public func makeDescriptor(shadow: ShadowDescriptor) -> Descriptor {
        return DefaultDescriptor(shadow: shadow)
    }
}

extension DefaultCharacteristic: CharacteristicDelegate {

    public func didUpdate(data: Result<Data, Error>, forCharacteristic characteristic: Characteristic) {
        self.delegate?.didUpdate(data: data, forCharacteristic: characteristic)
    }

    public func didWrite(data: Result<Data, Error>, forCharacteristic characteristic: Characteristic) {
        self.delegate?.didWrite(data: data, forCharacteristic: characteristic)
    }

    public func didUpdate(notificationState isNotifying: Result<Bool, Error>, forCharacteristic characteristic: Characteristic) {
        self.delegate?.didUpdate(notificationState: isNotifying, forCharacteristic: characteristic)
    }

    public func didDiscover(descriptors: Result<[Descriptor], Error>, forCharacteristic characteristic: Characteristic) {
        self.delegate?.didDiscover(descriptors: descriptors, forCharacteristic: characteristic)
    }
}

extension DefaultCharacteristic: CustomStringConvertible {
    public var description: String {
        let attributes = [
            "uuid = \(self.uuid)",
            "name = \(self.name ?? "<nil>")",
        ].joined(separator: ", ")
        return "<DefaultCharacteristic \(attributes)>"
    }
}

public protocol Characteristic: class, CharacteristicDelegate, Responder {
    var name: String? { get }
    var shadow: ShadowCharacteristic { get }

    init(shadow: ShadowCharacteristic)

    func makeDescriptor(shadow: ShadowDescriptor) -> Descriptor
}

public protocol TypesafeCharacteristic: Characteristic {
    associatedtype Value

    /// The value of the descriptor.
    var value: Value? { get }

    func transform(data: Data) -> Value
    func transform(value: Value) -> Data
}

extension Characteristic {
    public var uuid: Identifier {
        return self.shadow.uuid
    }

    public var name: String? {
        return nil
    }

    /// The value of the characteristic.
    public var data: Result<Data?, PeripheralError> {
        return self.core.map { $0.value }
    }

    public var descriptors: [Identifier: Descriptor] {
        return self.shadow.descriptors
    }

    /// The properties of the characteristic.
    public var properties: Result<CharacteristicProperties, PeripheralError> {
        return self.core.map {
            CharacteristicProperties(core: $0.properties)
        }
    }

    /// A Boolean value indicating whether the characteristic is
    /// currently notifying a subscribed central of its value.
    public var isNotifying: Result<Bool, PeripheralError> {
        return self.core.map {
            $0.isNotifying
        }
    }

    public var service: Service? {
        return self.shadow.service
    }

    public var nextResponder: Responder? {
        return self.shadow.service
    }

    public func discoverDescriptors(uuids: [Identifier]? = nil) -> Result<(), PeripheralError> {
        return self.tryToHandle(DiscoverDescriptorsMessage(
            uuids: uuids,
            characteristic: self
        )) ?? .err(.unhandled)
    }

    public func read() -> Result<(), PeripheralError> {
        return self.tryToHandle(ReadValueForCharacteristicMessage(
            characteristic: self
        )) ?? .err(.unhandled)
    }

    public func write(data: Data, type: WriteType) -> Result<(), PeripheralError> {
        return self.tryToHandle(WriteValueForCharacteristicMessage(
            data: data,
            characteristic: self,
            type: type
        )) ?? .err(.unhandled)
    }

    public func set(notifyValue: Bool) -> Result<(), PeripheralError> {
        return self.tryToHandle(SetNotifyValueForCharacteristicMessage(
            notifyValue: notifyValue,
            characteristic: self
        )) ?? .err(.unhandled)
    }

    var core: Result<CBCharacteristic, PeripheralError> {
        return self.shadow.core.okOr(.unreachable)
    }
}

extension TypesafeCharacteristic {
    /// The value of the characteristic.
    public var value: Result<Value?, PeripheralError> {
        return self.data.andThen {
            .ok($0.map { self.transform(data: $0) })
        }
    }

    /*
     public func write(value: Value, type: WriteType) {
     let data = self.transform(value: value)
     self.service.write(value: data, to: self, type: type)
     }
    */
}

public protocol DelegatedCharacteristic: Characteristic {
    weak var delegate: CharacteristicDelegate? { get set }
}

public protocol CharacteristicDelegate: class {
    func didUpdate(data: Result<Data, Error>, forCharacteristic characteristic: Characteristic)
    func didWrite(data: Result<Data, Error>, forCharacteristic characteristic: Characteristic)
    func didUpdate(notificationState isNotifying: Result<Bool, Error>, forCharacteristic characteristic: Characteristic)

    func didDiscover(descriptors: Result<[Descriptor], Error>, forCharacteristic characteristic: Characteristic)
}

public protocol TypesafeCharacteristicDelegate: CharacteristicDelegate {
    associatedtype Value

    func didUpdate(value: Result<Value, Error>, forCharacteristic characteristic: Characteristic)
    func didWrite(value: Result<Value, Error>, forCharacteristic characteristic: Characteristic)
    func didUpdate(notificationState isNotifying: Result<Bool, Error>, forCharacteristic characteristic: Characteristic)
}

public class ShadowCharacteristic {
    public let uuid: Identifier
    weak var core: CBCharacteristic?
    weak var service: Service?
    var descriptors: [Identifier: Descriptor] = [:]

    init(core: CBCharacteristic, service: Service) {
        self.uuid = Identifier(uuid: core.uuid)
        self.core = core
        self.service = service
    }

    func attach(core: CBCharacteristic) {
        self.core = core
        guard let cores = core.descriptors else {
            return
        }
        for core in cores {
            let uuid = Identifier(uuid: core.uuid)
            guard let descriptor = self.descriptors[uuid] else {
                continue
            }
            descriptor.shadow.attach(core: core)
        }
    }

    func detach() {
        self.core = nil
        for descriptor in self.descriptors.values {
            descriptor.shadow.detach()
        }
    }
}
