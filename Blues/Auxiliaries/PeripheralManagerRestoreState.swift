// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import CoreBluetooth

#if os(iOS) || os(OSX)

public struct PeripheralManagerRestoreState {
    /// An array (an instance of NSArray) of CBMutableService objects that contains all of the
    /// services that were published to the local peripheral’s database at the time the app
    /// was terminated by the system.
    ///
    /// - Note:
    ///   All the information about a service is restored, including any included services,
    ///   characteristics, characteristic descriptors, and subscribed centrals.
    public let services: [MutableService]?

    /// The advertisement with which the peripheral manager was advertising
    /// at the time the app was terminated by the system.
    public let advertisement: Advertisement

    private enum Keys {
        static let services = CBPeripheralManagerRestoredStateServicesKey
        static let advertisementData = CBPeripheralManagerRestoredStateAdvertisementDataKey
    }

    internal init(dictionary: [String: Any]) {
        let servicesKey = Keys.services
        if let value = dictionary[servicesKey] {
            guard let services = value as? [CBMutableService] else {
                fatalError("Unexpected value: \"\(value)\" for key \(servicesKey)")
            }
            self.services = services.map {
                MutableService(core: $0)
            }
        } else {
            self.services = nil
        }

        let advertisementDataKey = Keys.advertisementData
        let advertisementData = dictionary[advertisementDataKey]
        guard let advertisementDictionary = advertisementData as? [String : Any] else {
            fatalError("Unexpected value: \"\(advertisementData ?? "nil")\" for key \(advertisementDataKey)")
        }
        self.advertisement = Advertisement(dictionary: advertisementDictionary)
    }

    internal var dictionary: [String: Any] {
        var dictionary: [String: Any] = [:]
        if let services = self.services {
            dictionary[Keys.services] = services.map { $0.core }
        }
        dictionary[Keys.advertisementData] = self.advertisement.dictionary
        return dictionary
    }
}

#endif
