// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import CoreBluetooth

#if os(iOS) || os(OSX)

/// Used to create a local service or included service, which can be added to the local database
/// via `CBPeripheralManager`. Once a service is published, it is cached and can no longer
/// be changed. This class adds write access to all properties in the `CBService` class.
open class MutableService {
    /// The Bluetooth-specific identifier of the service.
    public let identifier: Identifier
    
    open var includedServices: [MutableService]? {
        didSet {
            self.core.genericIncludedServices = self.includedServices.map { includedServices in
                includedServices.map { $0.core }
            }
        }
    }

    /// A list of characteristics of a service.
    ///
    /// - Note:
    ///   An array containing `Characteristic` objects that represent a service’s characteristics.
    ///   Characteristics provide further details about a peripheral’s service. For example,
    ///   a heart rate service may contain one characteristic that describes the intended
    ///   body location of the device’s heart rate sensor and another characteristic that
    ///   transmits heart rate measurement data.
    open var characteristics: [CharacteristicProtocol]? {
        didSet {
            self.core.genericCharacteristics = self.characteristics.map { characteristics in
                characteristics.compactMap { characteristic in
                    guard let facade = characteristic as? CharacteristicFacadeProtocol else {
                        return nil
                    }
                    return facade.core
                }
            }
        }
    }

    internal let core: CBMutableServiceProtocol

    /// Returns a service, initialized with a service type and UUID.
    ///
    /// - Parameters:
    ///   - identifier: The Bluetooth identifier of the service.
    ///   - isPrimary: The type of the service (primary or secondary).
    public init(
        identifier: Identifier,
        primary isPrimary: Bool = true
    ) {
        self.identifier = identifier
        self.core = CBMutableService(
            type: identifier.core,
            primary: isPrimary
        )
    }

    internal init(core: CBMutableServiceProtocol) {
        self.identifier = Identifier(uuid: core.uuid)
        self.core = core
    }
    
    // FIXME: remove
    public init(core: CBMutableService) {
        self.identifier = Identifier(uuid: core.uuid)
        self.core = core
    }
}

extension MutableService: Equatable {
    public static func == (lhs: MutableService, rhs: MutableService) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}

extension MutableService: Hashable {
    public func hash(into hasher: inout Hasher) {
        self.identifier.hash(into: &hasher)
    }
}

#endif
