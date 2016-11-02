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
    public let serviceData: [AnyHashable: Data]

    /// An array of service identifiers.
    public let serviceUUIDs: [Identifier]
    
    /// An array of one or more `Identifier` objects, representing `Service` identifiers
    /// that were found in the “overflow” area of the advertisement data.
    ///
    /// Due to the nature of the data stored in this area,
    /// identifiers listed here are “best effort” and may not always be accurate.
    /// For details about the overflow area of advertisement data,
    /// see the `startAdvertising(_:)` method in `PeripheralManager`.
    public let overflowServiceUUIDs: [Identifier]
    
    /// An array of one or more `Identifier` objects, representing `Service` identifiers.
    public let solicitedServiceUUIDs: [Identifier]

    /// The transmit power of a peripheral commonly ranging from -100 dBm to +20 dBm to a resolution of 1 dBm.
    ///
    /// - note: Using the RSSI value and the Tx power level, it is possible to calculate path loss.
    public let txPowerLevel: Int?
    
    /// A Boolean value that indicates whether the advertising event type is connectable.
    public let isConnectable: Bool?

    init(advertisementData: [String: Any]) {
        self.localName = advertisementData[CBAdvertisementDataLocalNameKey] as? String
        self.manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data
        self.serviceData = advertisementData[CBAdvertisementDataServiceDataKey] as? [AnyHashable: Data] ?? [:]
        self.serviceUUIDs = (advertisementData[CBAdvertisementDataServiceDataKey] as? [CBUUID])?.map {
            Identifier(uuid: $0)
        } ?? []
        self.overflowServiceUUIDs = (advertisementData[CBAdvertisementDataOverflowServiceUUIDsKey] as? [CBUUID])?.map {
            Identifier(uuid: $0)
        } ?? []
        self.solicitedServiceUUIDs = (advertisementData[CBAdvertisementDataSolicitedServiceUUIDsKey] as? [CBUUID])?.map {
            Identifier(uuid: $0)
        } ?? []
        self.txPowerLevel = advertisementData[CBAdvertisementDataTxPowerLevelKey] as? Int
        self.isConnectable = advertisementData[CBAdvertisementDataIsConnectable] as? Bool
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
        ]
        let propertiesString = properties.joined(separator: ", ")
        return "<Advertisement \(propertiesString)>"
    }
}
