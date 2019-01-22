// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import CoreBluetooth

#if os(iOS) || os(OSX)

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
            cores.map { core in
                Central(core: core, peripheralManager: self.peripheralManager)
            }
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

    internal var core: CBMutableCharacteristic!
    internal var peripheralManager: PeripheralManager
    
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
        permissions: AttributePermissions,
        peripheralManager: PeripheralManager
    ) {
        self.init(
            core: CBMutableCharacteristic(
                type: identifier.core,
                properties: properties.core,
                value: data,
                permissions: permissions.core
            ),
            peripheralManager: peripheralManager
        )
    }

    public init(core: CBMutableCharacteristic, peripheralManager: PeripheralManager) {
        self.core = core
        self.peripheralManager = peripheralManager
    }
}

// MARK: - TypedCharacteristicProtocol
extension TypedWritableCharacteristicProtocol
where
    Self: MutableCharacteristic,
    Self.Encoder.Value == Data
{
    public func set(value: Encoder.Value?) -> Result<(), EncodingError> {
        guard let value = value else {
            self.data = nil
            return .ok(())
        }
        switch self.encoder.encode(value) {
        case let .ok(data):
            self.data = data
            return .ok(())
        case let .err(error):
            return .err(error)
        }
    }
}

#endif
