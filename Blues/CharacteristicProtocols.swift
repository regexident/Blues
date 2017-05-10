//
//  CharacteristicProtocols.swift
//  Blues
//
//  Created by Vincent Esche on 21/11/2016.
//  Copyright © 2016 NWTN Berlin. All rights reserved.
//

import Foundation

import Result

/// A `Characteristic`'s delegate.
public protocol CharacteristicDelegate: class {

}

/// A readable `Characteristic`'s delegate.
public protocol ReadableCharacteristicDelegate: CharacteristicDelegate {
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
public protocol WritableCharacteristicDelegate: CharacteristicDelegate {
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

/// A notifyable `Characteristic`'s delegate.
public protocol NotifyableCharacteristicDelegate: ReadableCharacteristicDelegate {
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
public protocol DescribableCharacteristicDelegate: CharacteristicDelegate {
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

public typealias FullblownCharacteristicDelegate =
    ReadableCharacteristicDelegate
    & WritableCharacteristicDelegate
    & NotifyableCharacteristicDelegate
    & DescribableCharacteristicDelegate

/// A `Characteristic`'s data source.
public protocol CharacteristicDataSource: class {
    /// Creates and returns a descriptor for a given shadow descriptor.
    ///
    /// - Note:
    ///   Override this property to provide a custom type for the given descriptor.
    ///   The default implementation creates `DefaultDescriptor`.
    ///
    /// - Parameters:
    ///   - shadow: The descriptor's shadow descriptor.
    ///
    /// - Returns: A new descriptor object.
    func descriptor(
        shadow: ShadowDescriptor,
        for characteristic: Characteristic
    ) -> Descriptor
}
