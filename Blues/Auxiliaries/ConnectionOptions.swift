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
    //    @available(iOS 6, tvOS 6, *)
    public let notifyOnConnection: Bool?

    /// A Boolean value that specifies whether the system should display
    /// a disconnection alert for a given peripheral if the app is
    /// suspended at the time of the disconnection.
    //    @available(iOS 8, OSX 10.10, tvOS 9, *)
    public let notifyOnDisconnection: Bool?

    /// A Boolean value that specifies whether the system should display
    /// an alert for all notifications received from a given peripheral
    /// if the app is suspended at the time.
    //    @available(iOS 6, tvOS 6, *)
    public let notifyOnNotification: Bool?

    public init(
        notifyOnConnection: Bool? = nil,
        notifyOnDisconnection: Bool? = nil,
        notifyOnNotification: Bool? = nil
    ) {
        self.notifyOnConnection = notifyOnConnection
        self.notifyOnDisconnection = notifyOnDisconnection
        self.notifyOnNotification = notifyOnNotification
    }

    enum Keys {
        static let notifyOnConnection = CBConnectPeripheralOptionNotifyOnConnectionKey
        static let notifyOnDisconnection = CBConnectPeripheralOptionNotifyOnDisconnectionKey
        static let notifyOnNotification = CBConnectPeripheralOptionNotifyOnNotificationKey
    }

    /// A dictionary-representation according to Core Bluetooth's `CBConnectPeripheralOption`s.
    var dictionary: [String: Any] {
        var dictionary: [String: Any] = [:]

        if let notifyOnConnection = self.notifyOnConnection {
            dictionary[Keys.notifyOnConnection] = notifyOnConnection
        }

        if let notifyOnDisconnection = self.notifyOnDisconnection {
            dictionary[Keys.notifyOnDisconnection] = notifyOnDisconnection
        }

        if let notifyOnNotification = self.notifyOnNotification {
            dictionary[Keys.notifyOnNotification] = notifyOnNotification
        }

        return dictionary
    }

    /// Initializes an instance based on a dictionary of `CBConnectPeripheralOption`s
    ///
    /// - Parameters
    ///   - dictionary: The dictionary to take values from.
    init(dictionary: [String: Any]) {
        guard let notifyOnConnection = dictionary[Keys.notifyOnConnection] as? Bool? else {
            fatalError()
        }
        self.notifyOnConnection = notifyOnConnection

        guard let notifyOnDisconnection = dictionary[Keys.notifyOnDisconnection] as? Bool? else {
            fatalError()
        }
        self.notifyOnDisconnection = notifyOnDisconnection

        guard let notifyOnNotification = dictionary[Keys.notifyOnNotification] as? Bool? else {
            fatalError()
        }
        self.notifyOnNotification = notifyOnNotification
    }
}

// MARK: - CustomStringConvertible
extension ConnectionOptions: CustomStringConvertible {
    public var description: String {
        let properties = [
            "notifyOnConnection: \(String(describing: self.notifyOnConnection))",
            "notifyOnDisconnection: \(String(describing: self.notifyOnDisconnection))",
            "notifyOnNotification: \(String(describing: self.notifyOnNotification))",
        ].joined(separator: ", ")
        return "<ConnectionOptions \(properties)>"
    }
}
