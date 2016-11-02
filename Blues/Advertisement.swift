//
//  Advertisement.swift
//  Blues
//
//  Created by Vincent Esche on 26/10/2016.
//  Copyright © 2016 NWTN Berlin. All rights reserved.
//

import Foundation
import CoreBluetooth

public struct Advertisement {
    /// A string (an instance of `String`) containing the local name of a peripheral.
    public let localName: String?
    /// A `Data` object containing the manufacturer data of a peripheral.
    public let manufacturerData: Data?

    /// A dictionary containing service-specific advertisement data.
    ///
    /// The keys are `CBUUID` objects, representing `CBService` UUIDs.
    /// The values are `Data` objects, representing service-specific data.
    public let serviceData: [AnyHashable: Any]

    /// An array of service UUIDs.
    public let serviceUUIDs: [String]
    /// An array of one or more `CBUUID` objects, representing `CBService` UUIDs
    /// that were found in the “overflow” area of the advertisement data.
    ///
    /// Due to the nature of the data stored in this area,
    /// UUIDs listed here are “best effort” and may not always be accurate.
    /// For details about the overflow area of advertisement data,
    /// see the `startAdvertising(_:)` method in `CBPeripheral`.
    public let overflowServiceUUIDs: [String]
    /// An array of one or more CBUUID objects, representing CBService UUIDs.
    public let solicitedServiceUUIDs: [String]

    /// A number (an instance of NSNumber) containing the transmit power of a peripheral.

    /// This key and value are available if the broadcaster (peripheral)
    /// provides its Tx power level in its advertising packet.
    /// Using the RSSI value and the Tx power level, it is possible to calculate path loss.
    public let txPowerLevel: Int?
    /// A Boolean value that indicates whether the advertising event type is connectable.

    /// The value for this key is an NSNumber object. You can use this value
    /// to determine whether a peripheral is connectable at a particular moment.
    public let isConnectable: Bool?

    init(advertisementData: [String: Any]) {
        self.localName = advertisementData[CBAdvertisementDataLocalNameKey] as? String
        self.manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data
        self.serviceData = advertisementData[CBAdvertisementDataServiceDataKey] as? [AnyHashable: Any] ?? [:]
        self.serviceUUIDs = advertisementData[CBAdvertisementDataServiceDataKey] as? [String] ?? []
        self.overflowServiceUUIDs = advertisementData[CBAdvertisementDataOverflowServiceUUIDsKey] as? [String] ?? []
        self.solicitedServiceUUIDs = advertisementData[CBAdvertisementDataSolicitedServiceUUIDsKey] as? [String] ?? []
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
