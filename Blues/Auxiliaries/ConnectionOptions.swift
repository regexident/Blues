// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import CoreBluetooth

/// Thin struct wrapper around the options of a given `Peripheral`s connection.
public struct ConnectionOptions {

    /// A Boolean value that specifies whether the system should display
    /// an alert for a given peripheral if the app is suspended
    /// when a successful connection is made.
    @available(iOS 6, macOS 10.13, tvOS 9, watchOS 2, *)
    public var notifyOnConnection: Bool {
        get {
            return self.dictionary[Keys.notifyOnConnection] as? Bool ?? false
        }
        set {
            self.dictionary[Keys.notifyOnConnection] = newValue
        }
    }

    /// A Boolean value that specifies whether the system should display
    /// a disconnection alert for a given peripheral if the app is
    /// suspended at the time of the disconnection.
    @available(iOS 5, macOS 10.7, tvOS 9, watchOS 4, *)
    public var notifyOnDisconnection: Bool? {
        get {
            return self.dictionary[Keys.notifyOnDisconnection] as? Bool ?? false
        }
        set {
            self.dictionary[Keys.notifyOnDisconnection] = newValue
        }
    }

    /// A Boolean value that specifies whether the system should display
    /// an alert for all notifications received from a given peripheral
    /// if the app is suspended at the time.
    @available(iOS 6, macOS 10.13, tvOS 9, watchOS 2, *)
    public var notifyOnNotification: Bool? {
        get {
            return self.dictionary[Keys.notifyOnNotification] as? Bool ?? false
        }
        set {
            self.dictionary[Keys.notifyOnNotification] = newValue
        }
    }
    
    /// A dictionary-representation according to Core Bluetooth's `CBConnectPeripheralOption`s.
    internal private(set) var dictionary: [String: Any]

    public init() {
        self.dictionary = [:]
    }

    enum Keys {
        @available(iOS 6, macOS 10.13, tvOS 9, watchOS 2, *)
        static let notifyOnConnection = CBConnectPeripheralOptionNotifyOnConnectionKey
        
        @available(iOS 5, macOS 10.7, tvOS 9, watchOS 4, *)
        static let notifyOnDisconnection = CBConnectPeripheralOptionNotifyOnDisconnectionKey
        
        @available(iOS 6, macOS 10.13, tvOS 9, watchOS 2, *)
        static let notifyOnNotification = CBConnectPeripheralOptionNotifyOnNotificationKey
    }

    /// Initializes an instance based on a dictionary of `CBConnectPeripheralOption`s
    ///
    /// - Parameters
    ///   - dictionary: The dictionary to take values from.
    internal init(dictionary: [String: Any]) {
        self.dictionary = dictionary
    }
}

// MARK: - CustomStringConvertible
extension ConnectionOptions: CustomStringConvertible {
    public var description: String {
        var properties: [String] = []
        if #available(iOS 6, macOS 10.13, tvOS 9, watchOS 2, *) {
            properties.append("notifyOnConnection: \(String(describing: self.notifyOnConnection))")
        }
        if #available(iOS 5, macOS 10.7, tvOS 9, watchOS 4, *) {
            properties.append("notifyOnDisconnection: \(String(describing: self.notifyOnDisconnection))")
        }
        if #available(iOS 6, macOS 10.13, tvOS 9, watchOS 2, *) {
            properties.append("notifyOnNotification: \(String(describing: self.notifyOnNotification))")
        }
        let propertiesString = properties.joined(separator: ", ")
        return "<ConnectionOptions \(propertiesString)>"
    }
}
