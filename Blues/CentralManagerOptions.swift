//
//  CentralManagerOptions.swift
//  Blues
//
//  Created by Vincent Esche on 28/10/2016.
//  Copyright © 2016 NWTN Berlin. All rights reserved.
//

import Foundation
import CoreBluetooth

/// Thin struct wrapper around the options of a given `CentralManager`s connection.
public struct CentralManagerOptions {
    /// A unique identifier (UID) for the manager that is being instantiated
    ///
    /// This UID is used to identify a specific manager.
    /// As a result, the UID must remain the same for subsequent executions
    /// of the app in order for the manager to be successfully restored.
    ///
    /// - note: Pass `nil` if you have a single shared manager, or a custom
    /// UID if you have multiple background instances of CentralManager in the app.
    var backgroundRestorationIdentifier: String?

    /// System should display a warning dialog to the user
    /// if Bluetooth is powered off when the manager is instantiated.
    var showPowerAlert: Bool = false

    init(dictionary: [String: Any]) {
        for (key, value) in dictionary {
            switch key {
            case CBCentralManagerOptionRestoreIdentifierKey:
                self.backgroundRestorationIdentifier = value as? String
            case CBCentralManagerOptionShowPowerAlertKey:
                guard let boolValue = value as? Bool else {
                    fatalError("Unexpected value: \"\(value)\"")
                }
                self.showPowerAlert = boolValue
            default:
                fatalError("Unexpected key: \"\(key)\"")
            }
        }
    }

    var dictionary: [String: Any] {
        var dictionary: [String: Any] = [:]
        if let backgroundRestorationIdentifier = self.backgroundRestorationIdentifier {
            dictionary[CBCentralManagerOptionRestoreIdentifierKey] = backgroundRestorationIdentifier
        }
        dictionary[CBCentralManagerOptionShowPowerAlertKey] = self.showPowerAlert
        return dictionary
    }

extension CentralManagerOptions: CustomStringConvertible {
    public var description: String {
        let properties = [
            "restoreIdentifier: \(self.restoreIdentifier)",
            "showPowerAlert: \(self.showPowerAlert)",
        ].joined(separator: ", ")
        return "<CentralManagerOptions \(properties)>"
    }
}
