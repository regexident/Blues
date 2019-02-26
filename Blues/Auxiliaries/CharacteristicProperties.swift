// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import CoreBluetooth

/// Thin struct wrapper around `CBCharacteristicProperties`.
public struct CharacteristicProperties: OptionSet {

    /// The characteristic’s value can be broadcast using a characteristic configuration descriptor.
    ///
    /// - important: This property is not allowed for local characteristics published via the
    ///   `add(_:)` method of the `PeripheralManager` class. This means that you cannot use this
    ///   property when you initialize a new `MutableCharacteristic` object via the
    ///   `init(type:properties:value:permissions:)` method of the `MutableCharacteristic` class.

    public static var broadcast = CharacteristicProperties(core: .broadcast)
    /// The characteristic’s value can be read.
    ///
    /// Use the `read()` method of the `Peripheral` class to read the value of a characteristic.
    public static var read = CharacteristicProperties(core: .read)
    public static var writeWithoutResponse = CharacteristicProperties(core: .writeWithoutResponse)
    public static var write = CharacteristicProperties(core: .write)
    public static var notify = CharacteristicProperties(core: .notify)
    public static var indicate = CharacteristicProperties(core: .indicate)
    public static var authenticatedSignedWrites =
        CharacteristicProperties(core: .authenticatedSignedWrites)
    public static var extendedProperties = CharacteristicProperties(core: .extendedProperties)
    public static var notifyEncryptionRequired =
        CharacteristicProperties(core: .notifyEncryptionRequired)
    public static var indicateEncryptionRequired =
        CharacteristicProperties(core: .indicateEncryptionRequired)

    public let rawValue: UInt

    internal var core: CBCharacteristicProperties {
        return CBCharacteristicProperties(rawValue: rawValue)
    }

    public init() {
        self.rawValue = 0
    }

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    init(core: CBCharacteristicProperties) {
        self.rawValue = core.rawValue
    }
}

// MARK: - Equatable
extension CharacteristicProperties: Equatable {
    public static func == (lhs: CharacteristicProperties, rhs: CharacteristicProperties) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
}

// MARK: - Hashable
extension CharacteristicProperties: Hashable {
    public var hashValue: Int {
        return self.rawValue.hashValue
    }
}
