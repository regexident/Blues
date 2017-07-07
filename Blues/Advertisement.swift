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
    public var localName: String? {
        return self.dictionary[Keys.localName] as? String
    }

    /// A `Data` object containing the manufacturer data of a peripheral.
    public var manufacturerData: Data? {
        return self.dictionary[Keys.manufacturerData] as? Data
    }

    /// A dictionary containing service-specific advertisement data.
    ///
    /// The keys are `Identifier` objects, representing `Service` identifiers.
    /// The values are `Data` objects, representing service-specific data.
    public var serviceData: [Identifier: Data]? {
        guard let dict = self.dictionary[Keys.serviceData] as? [CBUUID: Data] else {
            return nil
        }
        var serviceDataDict: [Identifier: Data] = [:]
        for (uuid, data) in dict {
            serviceDataDict[Identifier(uuid: uuid)] = data
        }
        return serviceDataDict
    }

    /// An array of service identifiers.
    public var serviceUUIDs: [Identifier]? {
        guard let uuids = self.dictionary[Keys.serviceUUIDs] as? [CBUUID] else {
            return nil
        }
        return uuids.map { Identifier(uuid: $0) }
    }

    /// An array of one or more `Identifier` objects, representing `Service` identifiers
    /// that were found in the “overflow” area of the advertisement data.
    ///
    /// - Note:
    /// Due to the nature of the data stored in this area,
    /// identifiers listed here are “best effort” and may not always be accurate.
    /// For details about the overflow area of advertisement data,
    /// see the `startAdvertising(_:)` method in `PeripheralManager`.
    public var overflowServiceUUIDs: [Identifier]? {
        guard let uuids = self.dictionary[Keys.overflowServiceUUIDs] as? [CBUUID] else {
            return nil
        }
        return uuids.map { Identifier(uuid: $0) }
    }

    /// An array of one or more `Identifier` objects, representing `Service` identifiers.
    public var solicitedServiceUUIDs: [Identifier]? {
        guard let uuids = self.dictionary[Keys.solicitedServiceUUIDs] as? [CBUUID] else {
            return nil
        }
        return uuids.map { Identifier(uuid: $0) }
    }

    /// The transmit power of a peripheral commonly ranging from
    /// -100 dBm to +20 dBm to a resolution of 1 dBm.
    ///
    /// - Note:
    ///   Using the RSSI value and the Tx power level, it is possible to calculate path loss.
    public var txPowerLevel: Int? {
        return self.dictionary[Keys.txPowerLevel] as? Int
    }

    /// A Boolean value that indicates whether the advertising event type is connectable.
    public var isConnectable: Bool? {
        return self.dictionary[Keys.isConnectable] as? Bool
    }

    /// An opaque and plist-compatible `Data` representation of the advertisement.
    public var data: Data {
        let dictionary = self.dictionary
        var plist: [String : Any] = [:]
        let mapUUIDs: (Any?) -> [String]? = {
            ($0 as? [CBUUID]).map { $0.map { $0.uuidString } }
        }
        let mapServiceData: (Any?) -> [String : Data]? = {
            ($0 as? [CBUUID : Data]).map {
                var dict: [String : Data] = [:]
                for (uuid, data) in $0 {
                    dict[uuid.uuidString] = data
                }
                return dict
            }
        }
        plist[Keys.localName] = dictionary[Keys.localName]
        plist[Keys.manufacturerData] = dictionary[Keys.manufacturerData]
        plist[Keys.serviceData] = mapServiceData(dictionary[Keys.serviceData])
        plist[Keys.serviceUUIDs] = mapUUIDs(dictionary[Keys.serviceUUIDs])
        plist[Keys.overflowServiceUUIDs] = mapUUIDs(dictionary[Keys.overflowServiceUUIDs])
        plist[Keys.solicitedServiceUUIDs] = mapUUIDs(dictionary[Keys.solicitedServiceUUIDs])
        plist[Keys.txPowerLevel] = dictionary[Keys.txPowerLevel]
        plist[Keys.isConnectable] = dictionary[Keys.isConnectable]
        return NSKeyedArchiver.archivedData(withRootObject: plist)
    }

    fileprivate let dictionary: [String: Any]

    private enum Keys {
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
        assert(dictionary.count <= 8)
        self.dictionary = dictionary
    }

    /// Creates an advertisement from an opaque plist-compatible `Data` representation.
    public init(data: Data) {
        let unarchivedObject = NSKeyedUnarchiver.unarchiveObject(with: data)
        guard let plist = unarchivedObject as? [String : Any] else {
            let typeName = String(describing: type(of: unarchivedObject!))
            fatalError("Expected archived value of type '[String: Any]', found '\(typeName)'.")
        }
        var dictionary: [String : Any] = [:]
        let mapUUIDs: (Any?) -> [CBUUID]? = {
            ($0 as? [String]).map { $0.flatMap { CBUUID(string: $0) } }
        }
        let mapServiceData: (Any?) -> [CBUUID : Data]? = {
            ($0 as? [String : Data]).map {
                var dict: [CBUUID : Data] = [:]
                for (string, data) in $0 {
                    dict[CBUUID(string: string)] = data
                }
                return dict
            }
        }
        dictionary[Keys.localName] = plist[Keys.localName]
        dictionary[Keys.manufacturerData] = plist[Keys.manufacturerData]
        dictionary[Keys.serviceData] = mapServiceData(plist[Keys.serviceData])
        dictionary[Keys.serviceUUIDs] = mapUUIDs(plist[Keys.serviceUUIDs])
        dictionary[Keys.overflowServiceUUIDs] = mapUUIDs(plist[Keys.overflowServiceUUIDs])
        dictionary[Keys.solicitedServiceUUIDs] = mapUUIDs(plist[Keys.solicitedServiceUUIDs])
        dictionary[Keys.txPowerLevel] = plist[Keys.txPowerLevel]
        dictionary[Keys.isConnectable] = plist[Keys.isConnectable]
        self.dictionary = dictionary
    }
}

extension Advertisement: CustomStringConvertible {
    public var description: String {
        let className = String(describing: type(of: self))
        let properties = [
            "localName: \(String(describing: self.localName))",
            "manufacturerData: \(String(describing: self.manufacturerData))",
            "serviceData: \(String(describing: self.serviceData))",
            "serviceUUIDs: \(String(describing: self.serviceUUIDs))",
            "overflowServiceUUIDs: \(String(describing: self.overflowServiceUUIDs))",
            "solicitedServiceUUIDs: \(String(describing: self.solicitedServiceUUIDs))",
            "txPowerLevel: \(String(describing: self.txPowerLevel))",
            "isConnectable: \(String(describing: self.isConnectable))",
        ].joined(separator: ", ")
        return "<\(className) \(properties)>"
    }
}
