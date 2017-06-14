//
//  Characteristic.swift
//  Blues
//
//  Created by Vincent Esche on 28/10/2016.
//  Copyright © 2016 NWTN Berlin. All rights reserved.
//

import Foundation
import CoreBluetooth

import Result

/// A characteristic of a peripheral’s service,
/// providing further information about one of its value.
open class Characteristic {
    /// The Bluetooth-specific identifier of the characteristic.
    public let identifier: Identifier

    /// The characteristic's name.
    ///
    /// - Note:
    ///   Default implementation returns the identifier.
    ///   Override this property to provide a name for your custom type.
    open var name: String? {
        return nil
    }
    
    /// The peripheral that this characteristic belongs to.
    public weak var peripheral: Peripheral?

    /// The service that this characteristic belongs to.
    public weak var service: Service?

    /// A list of the descriptors that have been discovered in this characteristic.
    ///
    /// - Note:
    ///   The value of this property is an array of `Descriptor` objects that
    ///   represent a characteristic’s descriptors. `Characteristic` descriptors
    ///   provide more information about a characteristic’s value.
    ///   For example, they may describe the value in human-readable form
    ///   and describe how the value should be formatted for presentation purposes.
    ///   For more information about characteristic descriptors, see `Descriptor`.
    public var descriptors: [Identifier: Descriptor]? = nil

    internal var core: Result<CBCharacteristic, PeripheralError>

    public init(identifier: Identifier, service: Service) {
        self.identifier = identifier
        self.core = .err(.unreachable)
        self.service = service
        self.peripheral = service.peripheral
    }

    /// Whether the characteristic should discover descriptors automatically
    ///
    /// - Note:
    ///   Default implementation returns `true`
    open var shouldDiscoverDescriptorsAutomatically: Bool {
        return false
    }

    /// Whether the characteristic should subscribe to notifications automatically
    ///
    /// - Note:
    ///   Default implementation returns `true`
    open var shouldSubscribeToNotificationsAutomatically: Bool {
        return false
    }

    /// The value data of the characteristic.
    public var data: Result<Data?, PeripheralError> {
        return self.core.map { $0.value }
    }

    /// The descriptor associated with a given type if it has previously been discovered in this characteristic.
    public func descriptor<D>(ofType type: D.Type) -> D?
        where D: Descriptor,
              D: TypeIdentifiable
    {
        guard let descriptors = self.descriptors else {
            return nil
        }
        return descriptors[type.typeIdentifier] as? D
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

    /// Discovers the descriptors of a characteristic.
    ///
    /// - Note:
    ///   When the characteristic discovers one or more descriptors, it calls the
    ///   `didDiscover(descriptors:for:)` method of its delegate object.
    ///
    /// - Returns: `.ok(())` iff successful, `.err(error)` otherwise.
    public func discoverDescriptors() -> Result<(), PeripheralError> {
        return self.tryToHandle(DiscoverDescriptorsMessage(
            characteristic: self
        )) ?? .err(.unhandled)
    }

    /// Retrieves the value of a specified characteristic.
    ///
    /// - Note:
    ///   When you call this method to read the value of a characteristic,
    ///   the peripheral calls the `didUpdate(data:, for:)` method
    ///   of its delegate object.
    ///
    /// - Important:
    ///   Not all characteristics are guaranteed to have a readable value.
    ///   You can determine whether a characteristic’s value is readable
    ///   by accessing the relevant properties of the `CharacteristicProperties`
    ///   enumeration, which are detailed in `Characteristic`.
    ///
    /// - Returns: `.ok(())` iff successful, `.err(error)` otherwise.
    public func read() -> Result<(), PeripheralError> {
        return self.tryToHandle(ReadValueForCharacteristicMessage(
            characteristic: self
        )) ?? .err(.unhandled)
    }

    /// Writes the value of a characteristic.
    ///
    /// - Note:
    ///   When you call this method to write the value of a characteristic,
    ///   it calls the `didWrite(data:, for:)` method of its
    ///   delegate object only if you specified the write type as withResponse.
    ///   The response you receive through the `didWrite(data:, for:)`
    ///   delegate method indicates whether the write was successful;
    ///   if the write failed, it details the cause of the failure in an error.
    ///   If you specify the write type as `.withoutResponse`,
    ///   the write is best-effort and not guaranteed. If the write does not succeed
    ///   in this case, you are not notified nor do you receive an error indicating
    ///   the cause of the failure. The data passed into the data parameter is copied,
    ///   and you can dispose of it after the method returns.
    ///
    /// - Important:
    ///   Characteristics may allow only certain type of writes to be
    ///   performed on their value. To determine which types of writes are permitted
    ///   to a characteristic’s value, you access the relevant properties of the
    ///   `CharacteristicProperties` enumeration, which are detailed in `Characteristic`.
    ///
    /// - Parameters:
    ///   - data: The value to be written.
    ///   - type: The type of write to be executed.
    ///
    /// - Returns: `.ok(())` iff successful, `.err(error)` otherwise.
    public func write(data: Data, type: WriteType) -> Result<(), PeripheralError> {
        return self.tryToHandle(WriteValueForCharacteristicMessage(
            data: data,
            characteristic: self,
            type: type
        )) ?? .err(.unhandled)
    }

    /// Sets notifications or indications for the value of a specified characteristic.
    ///
    /// - Note:
    ///   When you enable notifications for the characteristic’s value,
    ///   the peripheral calls the `func didUpdate(notificationState:for:)`
    ///   method of its delegate object to indicate whether or not the action succeeded.
    ///   If successful, the peripheral then calls the `didUpdate(data:, for:)`
    ///   method of its delegate object whenever the characteristic value changes.
    ///   Because it is the peripheral that chooses when to send an update,
    ///   your app should be prepared to handle them as long as notifications
    ///   or indications remain enabled. If the specified characteristic is configured
    ///   to allow both notifications and indications, calling this method
    ///   enables notifications only. You can disable notifications and indications for a
    ///   characteristic’s value by calling this method with the enabled parameter set to `false`.
    ///
    /// - Parameters
    ///   - notifyValue: A Boolean value indicating whether you wish to
    ///     receive notifications or indications whenever the characteristic’s
    ///     value changes. `true` if you want to enable notifications or indications
    ///     for the characteristic’s value. `false` if you do not want to receive
    ///     notifications or indications whenever the characteristic’s value changes.
    ///
    /// - Returns: `.ok(())` iff successful, `.err(error)` otherwise.
    public func set(notifyValue: Bool) -> Result<(), PeripheralError> {
        return self.tryToHandle(SetNotifyValueForCharacteristicMessage(
            notifyValue: notifyValue,
            characteristic: self
        )) ?? .err(.unhandled)
    }

    func wrapper(for core: CBDescriptor) -> Descriptor {
        let identifier = Identifier(uuid: core.uuid)
        let descriptor: Descriptor
        if let dataSource = self as? CharacteristicDataSource {
            descriptor = dataSource.descriptor(with: identifier, for: self)
        } else {
            descriptor = DefaultDescriptor(identifier: identifier, characteristic: self)
        }
        descriptor.core = .ok(core)
        return descriptor
    }

    internal func attach(core: CBCharacteristic) {
        self.core = .ok(core)
        guard let cores = core.descriptors else {
            return
        }
        guard let descriptors = self.descriptors else {
            return
        }
        for core in cores {
            let identifier = Identifier(uuid: core.uuid)
            guard let descriptor = descriptors[identifier] else {
                continue
            }
            descriptor.attach(core: core)
        }
    }

    internal func detach() {
        self.core = .err(.unreachable)
        guard let descriptors = self.descriptors else {
            return
        }
        for descriptor in descriptors.values {
            descriptor.detach()
        }
    }
}

extension Characteristic: Responder {
    internal var nextResponder: Responder? {
        return self.service
    }
}

extension Characteristic: CustomStringConvertible {
    open var description: String {
        let className = type(of: self)
        let attributes = [
            "identifier = \(self.identifier)",
            "name = \(self.name ?? "<nil>")",
        ].joined(separator: ", ")
        return "<\(className) \(attributes)>"
    }
}

extension TypedCharacteristic where Self: Characteristic {
    /// A type-safe value representation of the characteristic.
    ///
    /// - Note:
    ///   This is a thin type-safe wrapper around `Characteristic.data`.
    ///   See its documentation for more information. All this wrapper basically
    ///   does is transforming `self.data` into an `Value` object by calling
    ///   `self.transform(data: self.data)` and then returning the result.
    public var value: Result<Transformer.Value?, TypedCharacteristicError> {
        return self.data.mapErr(TypedCharacteristicError.peripheral).andThen { data in
            guard let data = data else {
                return .ok(nil)
            }
            return self.transformer.transform(data: data).map { .some($0) }
        }
    }

    /// Writes the value of a characteristic.
    ///
    /// - Note:
    ///   This is a thin type-safe wrapper around `Characteristic.write(data:type:)`.
    ///   See its documentation for more information. All this wrapper basically does
    ///   is transforming `value` into an `Data` object by calling `self.transform(value: value)`
    ///   and then passing the result to `Characteristic.write(data:type:)`.
    ///
    /// - SeeAlso: `Characteristic.write(data:type:)`
    ///
    /// - Parameters:
    ///   - value: The value to be written.
    ///   - type: The type of write to be executed.
    ///
    /// - Returns: `.ok(())` iff successful, `.err(error)` otherwise.
    public func write(value: Transformer.Value, type: WriteType) -> Result<(), TypedCharacteristicError> {
        return self.transformer.transform(value: value).andThen { data in
            let answer = self.tryToHandle(WriteValueForCharacteristicMessage(
                data: data,
                characteristic: self,
                type: type
            ))
            if answer != nil {
                return .ok(())
            } else {
                return .err(.peripheral(.unhandled))
            }
        }
    }

    public func transform(data: Result<Data, Error>) -> Result<Transformer.Value, TypedCharacteristicError> {
        return data.mapErr { .peripheral(.other($0)) }.andThen { self.transformer.transform(data: $0) }
    }
}
