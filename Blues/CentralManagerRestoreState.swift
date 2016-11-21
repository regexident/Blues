//
//  CentralManagerRestoreState.swift
//  Blues
//
//  Created by Vincent Esche on 02/11/2016.
//  Copyright © 2016 NWTN Berlin. All rights reserved.
//

import Foundation
import CoreBluetooth

public struct CentralManagerScanningOptions {
    /// A Boolean value that specifies whether the scan
    /// should run without duplicate filtering.
    ///
    /// If `true`, filtering is disabled and a discovery event is generated each
    /// time the central receives an advertising packet from the peripheral.
    /// Disabling this filtering can have an adverse effect on battery life and
    /// should be used only if necessary.
    ///
    /// If `false`, multiple discoveries of the same peripheral are coalesced
    /// into a single discovery event.
    ///
    /// If the key is not specified, the default value is `false`.
    public let allowDuplicates: Bool?

    /// An array of service identifiers that you want to scan for.
    ///
    /// Specifying this scan option causes the central manager to also scan for
    /// peripherals soliciting any of the services contained in the array.
    public let solicitedServiceIdentifiers: [Identifier]?

    init(dictionary: [String: Any]) {
        let allowDuplicatesKey = CBCentralManagerRestoredStateScanOptionsKey
        if let value = dictionary[allowDuplicatesKey] {
            guard let allowDuplicates = value as? Bool else {
                fatalError("Unexpected value: \"\(value)\" for key \(allowDuplicatesKey)")
            }
            self.allowDuplicates = allowDuplicates
        } else {
            self.allowDuplicates = nil
        }

        let solicitedServiceIdentifiersKey = CBCentralManagerRestoredStateScanOptionsKey
        if let value = dictionary[solicitedServiceIdentifiersKey] {
            guard let solicitedServiceIdentifiers = value as? [CBUUID] else {
                fatalError("Unexpected value: \"\(value)\" for key \(solicitedServiceIdentifiersKey)")
            }
            self.solicitedServiceIdentifiers = solicitedServiceIdentifiers.map {
                Identifier(uuid: $0)
            }
        } else {
            self.solicitedServiceIdentifiers = nil
        }
    }

    var dictionary: [String: Any] {
        var dictionary: [String: Any] = [:]
        if let allowDuplicates = self.allowDuplicates {
            dictionary[CBCentralManagerScanOptionAllowDuplicatesKey] = allowDuplicates
        }
        if let solicitedServiceIdentifiers = self.solicitedServiceIdentifiers {
            let identifiers = solicitedServiceIdentifiers.map { $0.core }
            dictionary[CBCentralManagerScanOptionSolicitedServiceUUIDsKey] = identifiers
        }
        return dictionary
    }
}

/// A `CentralManager`s restore state.
public struct CentralManagerRestoreState {

    /// The peripheral scan options that were being used by the central manager
    /// at the time the app was terminated by the system.
    public let scanOptions: CentralManagerScanningOptions?

    /// An array of `Peripheral` objects that contains all of the peripherals
    /// that were connected to the central manager (or had a connection pending)
    /// at the time the app was terminated by the system.
    ///
    /// When possible, all the information about a peripheral is restored,
    /// including any discovered services, characteristics, characteristic
    /// descriptors, and characteristic notification states.
    public let peripherals: [Peripheral]?

    /// An array of service `Identifier` objects that identifies all the services
    /// the central manager was scanning for at the time the app was terminated by the system.
    public let scanServices: [Identifier]?

    enum Keys {
        static let scanOptions = CBCentralManagerRestoredStateScanOptionsKey
        static let peripherals = CBCentralManagerRestoredStatePeripheralsKey
        static let scanServices = CBCentralManagerRestoredStateScanServicesKey
    }

    /// A dictionary-representation according to Core Bluetooth's `CBConnectPeripheralOption`s.
    var dictionary: [String: Any] {
        var dictionary: [String: Any] = [:]

        if let scanOptions = self.scanOptions {
            let scanOptions: [String: Any] = scanOptions.dictionary
            dictionary[Keys.scanOptions] = scanOptions
        }

        if let peripherals = self.peripherals {
            let peripherals: [CBPeripheral] = peripherals.map { $0.core }
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
    /// - Parameter dictionary: The dictionary to take values from.
    init(dictionary: [String: Any], closure: (CBPeripheral) -> Peripheral) {
        guard let scanOptions = dictionary[Keys.scanOptions] as? [String: Any]? else {
            fatalError()
        }
        self.scanOptions = scanOptions.map {
            CentralManagerScanningOptions(dictionary: $0)
        }

        guard let peripherals = dictionary[Keys.peripherals] as? [CBPeripheral]? else {
            fatalError()
        }
        self.peripherals = peripherals?.map { closure($0) }

        guard let scanServices = dictionary[Keys.scanServices] as? [CBUUID]? else {
            fatalError()
        }
        self.scanServices = scanServices?.map {
            Identifier(uuid: $0)
        }
    }
}
