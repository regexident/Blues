//
//  ConnectionOptions.swift
//  Blues
//
//  Created by Vincent Esche on 28/10/2016.
//  Copyright © 2016 NWTN Berlin. All rights reserved.
//

import Foundation
import CoreBluetooth

/// The options of a given `Peripheral`s connection.
public struct ConnectionOptions {

    /// A Boolean value that specifies whether the system should display
    /// an alert for a given peripheral if the app is suspended
    /// when a successful connection is made.
    //    @available(iOS 6, tvOS 6, *)
    var notifyOnConnection: Bool = false

    /// A Boolean value that specifies whether the system should display
    /// a disconnection alert for a given peripheral if the app is
    /// suspended at the time of the disconnection.
    //    @available(iOS 8, OSX 10.10, tvOS 9, *)
    var notifyOnDisconnection: Bool = false

    /// A Boolean value that specifies whether the system should display
    /// an alert for all notifications received from a given peripheral
    /// if the app is suspended at the time.
    //    @available(iOS 6, tvOS 6, *)
    var notifyOnNotification: Bool = false

    /// A dictionary-representation according to Core Bluetooth's `CBConnectPeripheralOption`s.
    var dictionary: [String: Any] {
        return [
            CBConnectPeripheralOptionNotifyOnConnectionKey: self.notifyOnConnection,
            CBConnectPeripheralOptionNotifyOnDisconnectionKey: self.notifyOnDisconnection,
            CBConnectPeripheralOptionNotifyOnNotificationKey: self.notifyOnNotification,
        ]
    }

    /// Initializes an instance based on a dictionary of `CBConnectPeripheralOption`s
    ///
    /// - Parameter dictionary: The dictionary to take values from.
    init(dictionary: [String: Any]) {
        for (key, value) in dictionary {
            guard let boolValue = value as? Bool else {
                fatalError("Unexpected value: \"\(value)\"")
            }
            switch key {
            case CBConnectPeripheralOptionNotifyOnConnectionKey:
                self.notifyOnConnection = boolValue
            case CBConnectPeripheralOptionNotifyOnDisconnectionKey:
                self.notifyOnDisconnection = boolValue
            case CBConnectPeripheralOptionNotifyOnNotificationKey:
                self.notifyOnNotification = boolValue
            default:
                fatalError("Unexpected key: \"\(key)\"")
            }
        }
    }
}
