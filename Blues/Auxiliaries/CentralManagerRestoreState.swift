// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import CoreBluetooth

/// A `CentralManager`s restore state.
public struct CentralManagerRestoreState {

    /// The peripheral scan options that were being used by the central manager
    /// at the time the app was terminated by the system.
    public let scanOptions: CentralManagerScanningOptions?

    /// An array of `Peripheral` objects that contains all of the peripherals
    /// that were connected to the central manager (or had a connection pending)
    /// at the time the app was terminated by the system.
    ///
    /// - Note:
    ///   When possible, all the information about a peripheral is restored,
    ///   including any discovered services, characteristics, characteristic
    ///   descriptors, and characteristic notification states.
    public let peripherals: [Peripheral]?

    /// An array of service `Identifier` objects that identifies all the services
    /// the central manager was scanning for at the time the app was terminated by the system.
    public let scanServices: [Identifier]?

    private enum Keys {
        static let scanOptions = CBCentralManagerRestoredStateScanOptionsKey
        static let peripherals = CBCentralManagerRestoredStatePeripheralsKey
        static let scanServices = CBCentralManagerRestoredStateScanServicesKey
    }

    /// A dictionary-representation according to Core Bluetooth's `CBConnectPeripheralOption`s.
    internal var dictionary: [String: Any] {
        var dictionary: [String: Any] = [:]

        if let scanOptions = self.scanOptions {
            let scanOptions: [String: Any] = scanOptions.dictionary
            dictionary[Keys.scanOptions] = scanOptions
        }

        if let peripherals = self.peripherals {
            let peripherals: [CBPeripheralProtocol] = peripherals.compactMap { $0.core }
            dictionary[Keys.peripherals] = peripherals
        }

        if let scanServices = self.scanServices {
            let scanServices: [CBUUID] = scanServices.map { $0.core }
            dictionary[Keys.scanServices] = scanServices
        }

        return dictionary
    }

    /// Initializes an instance based on a dictionary of `CBConnectPeripheralOption`s
    ///
    /// - Parameters:
    ///   - dictionary: The dictionary to take values from.
    internal init?(dictionary: [String: Any], closure: (CBPeripheralProtocol) -> Peripheral) {
        guard let scanOptionsDictionary = dictionary[Keys.scanOptions] as? [String: Any] else {
            return nil
        }
        
        guard let scanOptions = CentralManagerScanningOptions(dictionary: scanOptionsDictionary) else {
            return nil
        }
        
        self.scanOptions = scanOptions

        guard let peripherals = dictionary[Keys.peripherals] as? [CBPeripheralProtocol]? else {
            return nil
        }
        self.peripherals = peripherals?.map { closure($0) }

        guard let scanServices = dictionary[Keys.scanServices] as? [CBUUID]? else {
            return nil
        }
        self.scanServices = scanServices?.map {
            Identifier(uuid: $0)
        }
    }
}
