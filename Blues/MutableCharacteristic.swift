//
//  MutableCharacteristic.swift
//  Blues
//
//  Created by Vincent Esche on 7/16/17.
//  Copyright © 2017 NWTN Berlin. All rights reserved.
//

import Foundation
import CoreBluetooth

import Result

public protocol MutableCharacteristicProtocol: class {
    var permissions: AttributePermissions { get set }
    var subscribedCentrals: [Central]? { get }
    var data: Data? { get set }
}

/// Used to create a local characteristic, which can be added to the local database via
/// `CBPeripheralManager`. Once a characteristic is published, it is cached and can no longer
/// be changed. If a characteristic value is specified, it will be cached and marked
/// `CBCharacteristicPropertyRead` and `CBAttributePermissionsReadable`. If a characteristic
/// value needs to be writeable, or may change during the lifetime of the published `CBService`,
/// it is considered a dynamic value and will be requested on-demand. Dynamic values are
/// identified by a _value_ of _nil_.
open class MutableCharacteristic: MutableCharacteristicProtocol {
    /// A list of descriptors that describe the characteristic.
    ///
    /// - Note:
    ///   The value of this property is an array of CBDescriptor objects that represent a
    ///   characteristic’s descriptors. Characteristic descriptors provide more information about
    ///   a characteristic’s value. For example, they may describe the value in human-readable
    ///   form and describe how the value should be formatted for presentation purposes.
    ///   For more information about characteristic descriptors, see CBDescriptor.
    var descriptors: [Descriptor]? {
        didSet {
            self.core.descriptors = self.descriptors.map { descriptors in
                descriptors.map { $0.core }
            }
        }
    }

    /// The permissions of the characteristic value.
    open var permissions: AttributePermissions {
        get {
            return AttributePermissions(rawValue: self.core.permissions.rawValue)
        }
        set {
            self.core.permissions = CBAttributePermissions(rawValue: self.permissions.rawValue)
        }
    }

    /// For notifying characteristics, the set of currently subscribed centrals.
    open var subscribedCentrals: [Central]? {
        return self.core.subscribedCentrals.map { cores in
            cores.map { Central(core: $0) }
        }
    }

    open var data: Data? {
        get {
            return self.core.value
        }
        set {
            self.core.value = self.data
        }
    }

    internal var core: CBMutableCharacteristic

    /// Returns a newly initialized mutable service specified by identifier and service type.
    ///
    /// - Parameters:
    ///   - identifier: The Bluetooth identifier of the characteristic.
    ///   - properties: The properties of the characteristic.
    ///   - value: The characteristic value to be cached.
    ///     If _nil_, the value will be dynamic and requested on-demand.
    ///   - permissions: The permissions of the characteristic value.
    public convenience init(
        type identifier: Identifier,
        properties: CharacteristicProperties,
        data: Data?,
        permissions: AttributePermissions
    ) {
        self.init(core: CBMutableCharacteristic(
            type: identifier.core,
            properties: properties.core,
            value: data,
            permissions: permissions.core
        ))
    }

    public init(core: CBMutableCharacteristic) {
        self.core = core
    }

}

// MARK: - TypedCharacteristicProtocol
extension TypedCharacteristicProtocol where Self: MutableCharacteristicProtocol {
    /// A type-safe value representation of the characteristic.
    ///
    /// - Note:
    ///   This is a thin type-safe wrapper around `Characteristic.data`.
    ///   See its documentation for more information. All this wrapper basically
    ///   does is transforming `self.data` into an `Value` object by calling
    ///   `self.transform(data: self.data)` and then returning the result.
    public var value: Result<Transformer.Value?, TypedCharacteristicError> {
        guard let data = self.data else {
            return .ok(nil)
        }
        return self.transformer.transform(data: data).map { .some($0) }
    }

    mutating func set(value: Transformer.Value?) -> Result<(), TypedCharacteristicError> {
        guard let value = value else {
            self.data = nil
            return .ok(())
        }
        switch self.transformer.transform(value: value) {
        case let .ok(data):
            self.data = data
            return .ok(())
        case let .err(error):
            return .err(error)
        }
    }

    public func transform(data: Result<Data, Error>) -> Result<Transformer.Value, TypedCharacteristicError> {
        return data.mapErr { .other($0) }.andThen { self.transformer.transform(data: $0) }
    }
}
