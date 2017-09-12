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
    /// - Important: Restore identifiers require the `Info.plist`'s `"UIBackgroundModes"`
    ///   array to contain an entry with: `"bluetooth-central"`.
    ///
    /// - Note: Pass `nil` if you have a single shared manager, or a custom
    /// UID if you have multiple background instances of CentralManager in the app.
    public let restoreIdentifier: RestoreIdentifier?

    /// System should display a warning dialog to the user
    /// if Bluetooth is powered off when the manager is instantiated.
    public let showPowerAlert: Bool?
    
    enum Keys {
        static let restoreIdentifier = CBCentralManagerOptionRestoreIdentifierKey
        static let showPowerAlert = CBCentralManagerOptionShowPowerAlertKey
    }

    /// A dictionary-representation according to Core Bluetooth's `CBConnectPeripheralOption`s.
    var dictionary: [String: Any] {
        var dictionary: [String: Any] = [:]

        if let restoreIdentifier = self.restoreIdentifier {
            dictionary[Keys.restoreIdentifier] = restoreIdentifier.string
        }

        if let showPowerAlert = self.showPowerAlert {
            dictionary[Keys.showPowerAlert] = showPowerAlert
        }

        return dictionary
    }

    /// Initializes an instance based on a dictionary of `CBConnectPeripheralOption`s
    ///
    /// - Parameters:
    ///   - dictionary: The dictionary to take values from.
    init?(dictionary: [String: Any]) {
        guard let rawRestoreIdentifier = dictionary[Keys.restoreIdentifier] as? String? else {
            Log.shared.error("Provided dictionary contains non-string value for \(Keys.showPowerAlert)")
            return nil
        }
        
        let restoreIdentifier = rawRestoreIdentifier.map { RestoreIdentifier.custom($0) }
        
        guard let showPowerAlert = dictionary[Keys.showPowerAlert] as? Bool? else {
            Log.shared.error("Provided dictionary contains non-boolean value for \(Keys.showPowerAlert)")
            return nil
        }

        self.init(restoreIdentifier: restoreIdentifier, showPowerAlert: showPowerAlert)
    }
    
    public init(restoreIdentifier: RestoreIdentifier? = nil, showPowerAlert: Bool? = nil) {
        self.restoreIdentifier = restoreIdentifier
        self.showPowerAlert = showPowerAlert
    }
}

// MARK: - CustomStringConvertible
extension CentralManagerOptions: CustomStringConvertible {
    public var description: String {
        let properties = [
            "restoreIdentifier: \(String(describing: self.restoreIdentifier))",
            "showPowerAlert: \(String(describing: self.showPowerAlert))",
        ].joined(separator: ", ")
        return "<CentralManagerOptions \(properties)>"
    }
}
