//
//  Advertisement.swift
//  Blues
//
//  Created by Vincent Esche on 26/10/2016.
//  Copyright © 2016 NWTN Berlin. All rights reserved.
//

import Foundation
import CoreBluetooth

/// A type-safe representation of a Bluetooth Low Energy advertisement.
public struct Advertisement {

    /// A string (an instance of `String`) containing the local name of a peripheral.
    public let localName: String?

    /// A `Data` object containing the manufacturer data of a peripheral.
    public let manufacturerData: Data?

    /// A dictionary containing service-specific advertisement data.
    ///
    /// The keys are `Identifier` objects, representing `Service` identifiers.
    /// The values are `Data` objects, representing service-specific data.
    public let serviceData: [Identifier: Data]?

    /// An array of service identifiers.
    public let serviceUUIDs: [Identifier]?

    /// An array of one or more `Identifier` objects, representing `Service` identifiers
    /// that were found in the “overflow” area of the advertisement data.
    ///
    /// - Note:
    /// Due to the nature of the data stored in this area,
    /// identifiers listed here are “best effort” and may not always be accurate.
    /// For details about the overflow area of advertisement data,
    /// see the `startAdvertising(_:)` method in `PeripheralManager`.
    public let overflowServiceUUIDs: [Identifier]?

    /// An array of one or more `Identifier` objects, representing `Service` identifiers.
    public let solicitedServiceUUIDs: [Identifier]?

    /// The transmit power of a peripheral commonly ranging from
    /// -100 dBm to +20 dBm to a resolution of 1 dBm.
    ///
    /// - Note:
    ///   Using the RSSI value and the Tx power level, it is possible to calculate path loss.
    public let txPowerLevel: Int?

    /// A Boolean value that indicates whether the advertising event type is connectable.
    public let isConnectable: Bool?

    enum Keys {
        static let localName = CBAdvertisementDataLocalNameKey
        static let manufacturerData = CBAdvertisementDataManufacturerDataKey
        static let serviceData = CBAdvertisementDataServiceDataKey
        static let serviceUUIDs = CBAdvertisementDataServiceUUIDsKey
        static let overflowServiceUUIDs = CBAdvertisementDataOverflowServiceUUIDsKey
        static let solicitedServiceUUIDs = CBAdvertisementDataSolicitedServiceUUIDsKey
        static let txPowerLevel = CBAdvertisementDataTxPowerLevelKey
        static let isConnectable = CBAdvertisementDataIsConnectable
    }

    init(dictionary: [String: Any]) {
        guard let localName = dictionary[Keys.localName] as? String? else {
            fatalError()
        }
        self.localName = localName

        guard let manufacturerData = dictionary[Keys.manufacturerData] as? Data? else {
            fatalError()
        }
        self.manufacturerData = manufacturerData

        guard let serviceData = dictionary[Keys.serviceData] as? [CBUUID: Data]? else {
            fatalError()
        }
        self.serviceData = serviceData.map { dictionary in
            var serviceData: [Identifier: Data] = [:]
            dictionary.forEach { key, value in
                serviceData[Identifier(uuid: key)] = value
            }
            return serviceData
        }

        guard let services = dictionary[Keys.serviceUUIDs] as? [CBUUID]? else {
            fatalError()
        }
        self.serviceUUIDs = services?.map { Identifier(uuid: $0) }

        guard let overflowServiceUUIDs = dictionary[Keys.overflowServiceUUIDs] as? [CBUUID]? else {
            fatalError()
        }
        self.overflowServiceUUIDs = overflowServiceUUIDs?.map { Identifier(uuid: $0) }

        guard let solicitedServices = dictionary[Keys.solicitedServiceUUIDs] as? [CBUUID]? else {
            fatalError()
        }
        self.solicitedServiceUUIDs = solicitedServices?.map { Identifier(uuid: $0) }

        guard let txPowerLevel = dictionary[Keys.txPowerLevel] as? Int? else {
            fatalError()
        }
        self.txPowerLevel = txPowerLevel

        guard let isConnectable = dictionary[Keys.isConnectable] as? Bool? else {
            fatalError()
        }
        self.isConnectable = isConnectable
    }
}

extension Advertisement: CustomStringConvertible {
    public var description: String {
        let properties = [
            "localName: \(self.localName)",
            "manufacturerData: \(self.manufacturerData)",
            "serviceData: \(self.serviceData)",
            "serviceUUIDs: \(self.serviceUUIDs)",
            "overflowServiceUUIDs: \(self.overflowServiceUUIDs)",
            "solicitedServiceUUIDs: \(self.solicitedServiceUUIDs)",
            "txPowerLevel: \(self.txPowerLevel)",
            "isConnectable: \(self.isConnectable)",
        ].joined(separator: ", ")
        return "<Advertisement \(properties)>"
    }
}
