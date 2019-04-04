// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import CoreBluetooth

/// A characteristic of a peripheral’s service,
/// providing further information about one of its value.
open class Characteristic: PeripheralCharacteristicProtocol {
    /// The Bluetooth-specific identifier of the characteristic.
    public let identifier: Identifier

    /// The characteristic's name.
    ///
    /// - Note:
    ///   Default implementation returns the identifier.
    ///   Override this property to provide a name for your custom type.
    open var name: String? = nil

    /// The service that this characteristic belongs to.
    ///
    /// - Note:
    ///   This property is made `open` to allow for subclasses
    ///   to override getters to return a specialized service:
    ///   ```
    ///   open var service: CustomService {
    ///       return super.service as! CustomService
    ///   }
    ///   ```
    public var service: ServiceProtocol {
        guard let service = self._service else {
            fatalError("Expected `Service`, found `nil` in `self.service`.")
        }
        return service
    }

    private weak var _service: ServiceProtocol?
    
    /// The peripheral that this characteristic belongs to.
    ///
    /// - Note:
    ///   This property is made `open` to allow for subclasses
    ///   to override getters to return a specialized peripheral:
    ///   ```
    ///   open var peripheral: CustomPeripheral {
    ///       return super.peripheral as! CustomPeripheral
    ///   }
    ///   ```
    public var peripheral: Peripheral {
        return self.service.peripheral
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
    public var descriptors: [Descriptor]? {
        return self.descriptorsByIdentifier.map { Array($0.values) }
    }
    
    /// Whether the characteristic should discover descriptors automatically
    ///
    /// - Note:
    ///   Default implementation returns `true`
    open var shouldDiscoverDescriptorsAutomatically: Bool {
        return false
    }
    
    /// The properties of the characteristic.
    public var properties: CharacteristicProperties {
        return CharacteristicProperties(core: self.core.properties)
    }

    internal var descriptorsByIdentifier: [Identifier: Descriptor]? = nil

    internal var core: CBCharacteristic!

    public init(identifier: Identifier, service: ServiceProtocol) {
        self.identifier = identifier
        self.core = nil
        self._service = service
    }

    /// The descriptor associated with a given type if it has previously been discovered in this characteristic.
    public func descriptor<D>(ofType type: D.Type) -> D?
        where D: Descriptor,
              D: TypeIdentifiable
    {
        guard let descriptorsByIdentifier = self.descriptorsByIdentifier else {
            return nil
        }
        return descriptorsByIdentifier[type.typeIdentifier] as? D
    }

    /// Discovers the descriptors of a characteristic.
    ///
    /// - Note:
    ///   When the characteristic discovers one or more descriptors, it calls the
    ///   `didDiscover(descriptors:for:)` method of its delegate object.
    ///
    /// - Returns: `.success(())` iff successful, `.failure(error)` otherwise.
    public func discoverDescriptors() {
        if self.descriptors != nil {
            return
        }
        self.peripheral.discoverDescriptors(for: self)
    }

    internal func apiMisuseErrorMessage() -> String {
        return "\(type(of: self)) can only accept commands while in the connected state."
    }

    internal func wrapper(for core: CBDescriptor) -> Descriptor {
        let identifier = Identifier(uuid: core.uuid)
        let descriptor: Descriptor
        descriptor = self.dataSourced(from: CharacteristicDataSource.self) { dataSource in
            return dataSource.descriptor(with: identifier, for: self)
        } ?? DefaultDescriptor(identifier: identifier, characteristic: self)
        descriptor.core = core
        return descriptor
    }

    internal func dataSourced<T, U>(from type: T.Type, closure: (T) -> (U)) -> U? {
        if let dataSource = self as? T {
            return closure(dataSource)
        } else if let dataSourcedSelf = self as? DataSourcedCharacteristicProtocol {
            if let dataSource = dataSourcedSelf.dataSource as? T {
                return closure(dataSource)
            }
        }
        return nil
    }

    internal func delegated<T, U>(to type: T.Type, closure: (T) -> (U)) -> U? {
        if let delegate = self as? T {
            return closure(delegate)
        } else if let delegatedSelf = self as? DelegatedCharacteristicProtocol {
            if let delegate = delegatedSelf.delegate as? T {
                return closure(delegate)
            }
        }
        return nil
    }
}

// MARK: - Equatable
extension Characteristic: Equatable {
    public static func == (lhs: Characteristic, rhs: Characteristic) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}

// MARK: - Hashable
extension Characteristic: Hashable {
    public func hash(into hasher: inout Hasher) {
        self.identifier.hash(into: &hasher)
    }
}

// MARK: - CustomStringConvertible
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

extension ReadableCharacteristicProtocol
where
    Self: Characteristic
{
    /// The value data of the characteristic.
    public var data: Data? {
        return self.core.value
    }
    
    /// Whether the characteristic should subscribe to notifications automatically
    ///
    /// - Note:
    ///   Default implementation returns `true`
    public var shouldSubscribeToNotificationsAutomatically: Bool {
        return false
    }
    
    /// A Boolean value indicating whether the characteristic is
    /// currently notifying a subscribed central of its value.
    public var isNotifying: Bool {
        return self.core.isNotifying
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
    /// - Returns: `.success(())` iff successful, `.failure(error)` otherwise.
    public func read() {
        assert(self.peripheral.state == .connected, self.apiMisuseErrorMessage())
        self.peripheral.readData(for: self)
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
    /// - Returns: `.success(())` iff successful, `.failure(error)` otherwise.
    public func set(notifyValue: Bool) {
        assert(self.peripheral.state == .connected, self.apiMisuseErrorMessage())
        self.peripheral.set(notifyValue: notifyValue, for: self)
    }
}

extension WritableCharacteristicProtocol
where
    Self: Characteristic
{
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
    /// - Returns: `.success(())` iff successful, `.failure(error)` otherwise.
    public func write(data: Data, type: WriteType) {
        assert(self.peripheral.state == .connected, self.apiMisuseErrorMessage())
        self.peripheral.write(data: data, for: self, type: type)
    }
}

extension ReadableCharacteristicProtocol
where
    Self: Characteristic & TypedReadableCharacteristicProtocol
{
    /// A type-safe value representation of the characteristic.
    ///
    /// - Note:
    ///   This is a thin type-safe wrapper around `Characteristic.data`.
    ///   See its documentation for more information. All this wrapper basically
    ///   does is transforming `self.data` into an `Value` object by calling
    ///   `self.transform(data: self.data)` and then returning the result.
    public var value: Result<Decoder.Value?, DecodingError> {
        guard let data = self.data else {
            return .success(nil)
        }
        return self.decoder.decode(data).map { .some($0) }
    }
}

extension WritableCharacteristicProtocol
where
    Self: Characteristic & TypedWritableCharacteristicProtocol
{
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
    /// - Returns: `.success(())` iff successful, `.failure(error)` otherwise.
    public func write(value: Encoder.Value, type: WriteType) -> Result<(), EncodingError> {
        return self.encoder.encode(value).map { data in
            return self.write(data: data, type: type)
        }
    }
}

extension StringConvertibleCharacteristicProtocol
where
    Self: Characteristic & TypedReadableCharacteristicProtocol,
    Self.Decoder.Value: CustomStringConvertible
{
    public var stringValue: Result<String?, DecodingError> {
        return self.value.map { $0?.description }
    }
}
