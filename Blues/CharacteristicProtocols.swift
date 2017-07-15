//
//  CharacteristicProtocols.swift
//  Blues
//
//  Created by Vincent Esche on 21/11/2016.
//  Copyright © 2016 NWTN Berlin. All rights reserved.
//

import Foundation

import Result

public protocol CharacteristicProtocol: class {
    var identifier: Identifier { get }

    var name: String? { get }

    var service: Service { get }
    var peripheral: Peripheral { get }

    var descriptors: [Descriptor]? { get }

    init(identifier: Identifier, service: Service)

    var shouldDiscoverDescriptorsAutomatically: Bool { get }

    var shouldSubscribeToNotificationsAutomatically: Bool { get }

    var data: Data? { get }

    func descriptor<D>(ofType type: D.Type) -> D?
    where D: Descriptor, D: TypeIdentifiable

    var properties: CharacteristicProperties { get }

    var isNotifying: Bool { get }

    func discoverDescriptors()

    func read()
    func write(data: Data, type: WriteType)
    func set(notifyValue: Bool)
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

/// A characteristic of a peripheral’s service,
/// providing further information about one of its value.
public protocol CharacteristicValueTransformer {
    /// The characteristic's value type.
    associatedtype Value

    /// The transformation logic for decoding the characteristic's
    /// data value into type-safe value representation
    func transform(data: Data) -> Result<Value, TypedCharacteristicError>

    /// The transformation logic for encoding the characteristic's
    /// type-safe value into a data representation
    func transform(value: Value) -> Result<Data, TypedCharacteristicError>
}

public protocol TypedCharacteristic {
    associatedtype Transformer: CharacteristicValueTransformer

    var transformer: Transformer { get }
}
