//
//  Characteristic.swift
//  Blues
//
//  Created by Vincent Esche on 28/10/2016.
//  Copyright © 2016 NWTN Berlin. All rights reserved.
//

import Foundation
import CoreBluetooth

/// Default implementation of `Characteristic` protocol.
public class DefaultCharacteristic: DelegatedCharacteristic, DataSourcedCharacteristic {

    public let shadow: ShadowCharacteristic

    public weak var delegate: CharacteristicDelegate?
    public weak var dataSource: CharacteristicDataSource?

    public required init(shadow: ShadowCharacteristic) {
        self.shadow = shadow
    }
}

/// A characteristic of a peripheral’s service,
/// providing further information about one of its value.
public protocol Characteristic:
    class, CharacteristicDataSource, CharacteristicDelegate, CustomStringConvertible {

    /// The characteristic's name.
    ///
    /// - Note:
    ///   Default implementation returns `nil`
    var name: String? { get }

    /// The supporting "shadow" characteristic that does the heavy lifting.
    var shadow: ShadowCharacteristic { get }

    /// Whether the characteristic should discover descriptors automatically
    ///
    /// - Note:
    ///   Default implementation returns `true`
    var shouldDiscoverDescriptorsAutomatically: Bool { get }

    /// Whether the characteristic should subscribe to notifications automatically
    ///
    /// - Note:
    ///   Default implementation returns `true`
    var shouldSubscribeToNotificationsAutomatically: Bool { get }

    /// Initializes a `Characteristic` as a shim for a provided shadow characteristic.
    /// - Parameters:
    ///   - shadow: The characteristic's "shadow" characteristic
    init(shadow: ShadowCharacteristic)
}

/// A characteristic of a peripheral’s service,
/// providing further information about one of its value.
public protocol TypesafeCharacteristic: Characteristic {

    /// The characteristic's value type.
    associatedtype Value

    /// The transformation logic for decoding the characteristic's
    /// data value into type-safe value representation
    func transform(data: Data) -> Result<Value, TypesafeCharacteristicError>

    /// The transformation logic for encoding the characteristic's
    /// type-safe value into a data representation
    func transform(value: Value) -> Result<Data, TypesafeCharacteristicError>
}

extension Characteristic {

    /// The Bluetooth-specific identifier of the characteristic.
    public var uuid: Identifier {
        return self.shadow.uuid
    }

    public var name: String? {
        return nil
    }

    public var shouldDiscoverDescriptorsAutomatically: Bool {
        return true
    }

    public var shouldSubscribeToNotificationsAutomatically: Bool {
        return true
    }

    /// The value data of the characteristic.
    public var data: Result<Data?, PeripheralError> {
        return self.core.map { $0.value }
    }

    /// A list of the descriptors that have been discovered in this characteristic.
    ///
    /// - Note:
    ///   The value of this property is an array of `Descriptor` objects that
    ///   represent a characteristic’s descriptors. `Characteristic` descriptors
    ///   provide more information about a characteristic’s value.
    ///   For example, they may describe the value in human-readable form
    ///   and describe how the value should be formatted for presentation purposes.
    ///   For more information about characteristic descriptors, see `Descriptor`.
    public var descriptors: [Identifier: Descriptor]? {
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

    /// The service that this characteristic belongs to.
    public var service: Service? {
        return self.shadow.service
    }

    /// The peripheral that this characteristic belongs to.
    public var peripheral: Peripheral? {
        return self.shadow.peripheral
    }

    var core: Result<CBCharacteristic, PeripheralError> {
        return self.shadow.core.okOr(.unreachable)
    }

    /// Discovers the descriptors of a characteristic.
    ///
    /// - Note:
    ///   When the characteristic discovers one or more descriptors, it calls the
    ///   `didDiscover(descriptors:forCharacteristic:)` method of its delegate object.
    ///
    /// - Returns: `.ok(())` iff successful, `.err(error)` otherwise.
    public func discoverDescriptors() -> Result<(), PeripheralError> {
        return self.shadow.tryToHandle(DiscoverDescriptorsMessage(
            characteristic: self
        )) ?? .err(.unhandled)
    }

    /// Retrieves the value of a specified characteristic.
    ///
    /// - Note:
    ///   When you call this method to read the value of a characteristic,
    ///   the peripheral calls the `didUpdate(data:, forCharacteristic:)` method
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
        return self.shadow.tryToHandle(ReadValueForCharacteristicMessage(
            characteristic: self
        )) ?? .err(.unhandled)
    }

    /// Writes the value of a characteristic.
    ///
    /// - Note:
    ///   When you call this method to write the value of a characteristic,
    ///   it calls the `didWrite(data:, forCharacteristic:)` method of its
    ///   delegate object only if you specified the write type as withResponse.
    ///   The response you receive through the `didWrite(data:, forCharacteristic:)`
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
        return self.shadow.tryToHandle(WriteValueForCharacteristicMessage(
            data: data,
            characteristic: self,
            type: type
        )) ?? .err(.unhandled)
    }

    /// Sets notifications or indications for the value of a specified characteristic.
    ///
    /// - Note:
    ///   When you enable notifications for the characteristic’s value,
    ///   the peripheral calls the `func didUpdate(notificationState:forCharacteristic:)`
    ///   method of its delegate object to indicate whether or not the action succeeded.
    ///   If successful, the peripheral then calls the `didUpdate(data:, forCharacteristic:)`
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
        return self.shadow.tryToHandle(SetNotifyValueForCharacteristicMessage(
            notifyValue: notifyValue,
            characteristic: self
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

extension TypesafeCharacteristic {
    /// A type-safe value representation of the characteristic.
    ///
    /// - Note:
    ///   This is a thin type-safe wrapper around `Characteristic.data`.
    ///   See its documentation for more information. All this wrapper basically
    ///   does is transforming `self.data` into an `Value` object by calling
    ///   `self.transform(data: self.data)` and then returning the result.
    public var value: Result<Value?, TypesafeCharacteristicError> {
        return self.data.mapErr(closure: TypesafeCharacteristicError.peripheral).andThen { data in
            guard let data = data else {
                return .ok(nil)
            }
            return self.transform(data: data).map { .some($0) }
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
    public func write(value: Value, type: WriteType) -> Result<(), TypesafeCharacteristicError> {
        return self.transform(value: value).andThen { data in
            let answer = self.shadow.tryToHandle(WriteValueForCharacteristicMessage(
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

    public func transform(data: Result<Data, Error>) -> Result<Value, TypesafeCharacteristicError> {
        return data.mapErr { .peripheral(.other($0)) }.andThen { self.transform(data: $0) }
    }
}

extension Characteristic {
    
    func descriptor(
        shadow: ShadowDescriptor,
        forCharacteristic characteristic: Characteristic
    ) -> Descriptor {
        return DefaultDescriptor(shadow: shadow)
    }
}

/// The supporting "shadow" characteristic that does the actual heavy lifting
/// behind any `Characteristic` implementation.
public class ShadowCharacteristic {

    /// The Bluetooth-specific identifier of the characteristic.
    public let uuid: Identifier

    weak var core: CBCharacteristic?
    weak var peripheral: Peripheral?
    weak var service: Service?
    var descriptors: [Identifier: Descriptor] = [:]

    init(core: CBCharacteristic, service: Service) {
        self.uuid = Identifier(uuid: core.uuid)
        self.core = core
        self.service = service
        self.peripheral = service.peripheral
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

extension ShadowCharacteristic: Responder {

    var nextResponder: Responder? {
        return self.service?.shadow
    }
}
