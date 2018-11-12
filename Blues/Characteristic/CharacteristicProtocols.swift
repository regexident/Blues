// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

public protocol CharacteristicProtocol: class {
    var identifier: Identifier { get }
    var name: String? { get }

    var descriptors: [Descriptor]? { get }
    var service: Service { get }
    var peripheral: Peripheral { get }

    var shouldDiscoverDescriptorsAutomatically: Bool { get }
    
    var properties: CharacteristicProperties { get }

    func discoverDescriptors()

    func descriptor<D>(ofType type: D.Type) -> D?
        where D: Descriptor, D: TypeIdentifiable
}

public protocol ReadableCharacteristicProtocol: CharacteristicProtocol {
    var data: Data? { get }
    
    var shouldSubscribeToNotificationsAutomatically: Bool { get }
    var isNotifying: Bool { get }
    
    func read()
    func set(notifyValue: Bool)
}

public protocol WritableCharacteristicProtocol: CharacteristicProtocol {
    func write(data: Data, type: WriteType)
}

public protocol MutableCharacteristicProtocol: class {
    var permissions: AttributePermissions { get set }
    var subscribedCentrals: [Central]? { get }
    var data: Data? { get set }
}

public protocol TypedReadableCharacteristicProtocol: ReadableCharacteristicProtocol {
    associatedtype Decoder: ValueDecoder where Self.Decoder.Input == Data
    
    var decoder: Decoder { get }
}

public protocol TypedWritableCharacteristicProtocol: WritableCharacteristicProtocol {
    associatedtype Encoder: ValueEncoder where Self.Encoder.Output == Data

    var encoder: Encoder { get }
}

public protocol StringConvertibleCharacteristicProtocol: CharacteristicProtocol {
    var stringValue: Result<String?, DecodingError> { get }
}

public protocol DelegatedCharacteristicProtocol: CharacteristicProtocol {
    var delegate: CharacteristicDelegate? { get set }
}

public protocol DataSourcedCharacteristicProtocol: CharacteristicProtocol {
    var dataSource: CharacteristicDataSource? { get set }
}

public protocol CharacteristicDelegate: class {}

/// A readable `Characteristic`'s delegate.
public protocol CharacteristicReadingDelegate: CharacteristicDelegate {
    /// Invoked when you retrieve a specified characteristic’s value,
    /// or when the peripheral device notifies your app that
    /// the characteristic’s value has changed.
    ///
    /// - Parameters:
    ///   - data: `.ok(data)` with the updated value iff successful, otherwise `.err(error)`.
    ///   - characteristic: The characteristic whose value has been retrieved.
    func didUpdate(data: Result<Data, Error>, for characteristic: Characteristic)
}

/// A writable `Characteristic`'s delegate.
public protocol CharacteristicWritingDelegate: CharacteristicDelegate {
    /// Invoked when you write data to a characteristic’s value.
    ///
    /// - Note:
    ///   This method is invoked only when your app calls the `write(data:type:)` or
    ///   `write(value:type:)` method with `.withResponse` specified as the write type.
    ///
    /// - Parameters:
    ///   - data: `.ok(data)` with the written value iff successful, otherwise `.err(error)`.
    ///   - characteristic: The characteristic whose value has been retrieved.
    func didWrite(data: Result<Data, Error>, for characteristic: Characteristic)
}

/// A notifiable `Characteristic`'s delegate.
public protocol CharacteristicNotificationStateDelegate: CharacteristicReadingDelegate {
    /// Invoked when the peripheral receives a request to start or stop providing
    /// notifications for a specified characteristic’s value.
    ///
    /// - Note:
    ///   This method is invoked when your app calls the set(notifyValue:for:) method.
    ///
    /// - Parameters:
    ///   - isNotifying: `.ok(flag)` with a boolean value indicating whether the
    ///     characteristic is currently notifying a subscribed central of its
    ///     value iff successful, otherwise `.err(error)`.
    ///   - characteristic: The characteristic whose notification state has been retrieved.
    func didUpdate(
        notificationState isNotifying: Result<Bool, Error>,
        for characteristic: Characteristic
    )
}

/// A describable `Characteristic`'s delegate.
public protocol CharacteristicDiscoveryDelegate: CharacteristicDelegate {
    /// Invoked when you discover the descriptors of a specified characteristic.
    ///
    /// - Note:
    ///   This method is invoked when your app calls the discoverDescriptors() method.
    ///
    /// - Parameters:
    ///   - descriptors: `.ok(descriptors)` with the character descriptors that
    ///     were discovered, iff successful, otherwise `.ok(error)`.
    ///   - characteristic: The characteristic that the characteristic descriptors belong to.
    func didDiscover(
        descriptors: Result<[Descriptor], Error>,
        for characteristic: Characteristic
    )
}

/// A `Characteristic`'s data source.
public protocol CharacteristicDataSource: class {
    /// Creates and returns a descriptor for a given identifier.
    ///
    /// - Note:
    ///   Override this property to provide a custom type for the given descriptor.
    ///   The default implementation creates `DefaultDescriptor`.
    ///
    /// - Parameters:
    ///   - identifier: The descriptor's identifier.
    ///   - characteristic: The descriptor's characteristic.
    ///
    /// - Returns: A new descriptor object.
    func descriptor(with identifier: Identifier, for characteristic: Characteristic) -> Descriptor
}
