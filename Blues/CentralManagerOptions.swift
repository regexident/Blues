//
//  CentralManagerOptions.swift
//  Blues
//
//  Created by Vincent Esche on 28/10/2016.
//  Copyright © 2016 NWTN Berlin. All rights reserved.
//

import Foundation
import CoreBluetooth

public enum RestoreIdentifier {
    case shared
    case custom(String)

    var string: String {
        switch self {
        case .shared:
            return "com.nwtnberlin.blues.sharedRestoreIdentifier"
        case .custom(let string):
            return string
        }
    }
}

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
    public var restoreIdentifier: RestoreIdentifier? = nil

    /// System should display a warning dialog to the user
    /// if Bluetooth is powered off when the manager is instantiated.
    public var showPowerAlert: Bool? = nil

    public init() {

    }

    enum Keys {
        static let restoreIdentifier = CBCentralManagerOptionRestoreIdentifierKey
        static let showPowerAlert = CBCentralManagerOptionShowPowerAlertKey
    }

    /// A dictionary-representation according to Core Bluetooth's `CBConnectPeripheralOption`s.
    var dictionary: [String: Any] {
        var dictionary: [String: Any] = [:]

        if let restoreIdentifier = self.restoreIdentifier {
            dictionary[Keys.restoreIdentifier] = restoreIdentifier
        }

        if let showPowerAlert = self.showPowerAlert {
            dictionary[Keys.showPowerAlert] = showPowerAlert
        }

        return dictionary
    }

    /// Initializes an instance based on a dictionary of `CBConnectPeripheralOption`s
    ///
    /// - Parameter dictionary: The dictionary to take values from.
    init(dictionary: [String: Any]) {
        guard let restoreIdentifier = dictionary[Keys.restoreIdentifier] as? String? else {
            fatalError()
        }
        self.restoreIdentifier = restoreIdentifier.map { .custom($0) }

        guard let showPowerAlert = dictionary[Keys.showPowerAlert] as? Bool? else {
            fatalError()
        }
        self.showPowerAlert = showPowerAlert
    }
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
