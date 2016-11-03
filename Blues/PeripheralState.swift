//
//  PeripheralState.swift
//  Blues
//
//  Created by Vincent Esche on 28/10/2016.
//  Copyright © 2016 NWTN Berlin. All rights reserved.
//

import Foundation
import CoreBluetooth

/// Thin enum wrapper around `CBPeripheralState`.
public enum PeripheralState {

    /// The peripheral is currently not connected to the central manager.
    case disconnected

    /// The peripheral is currently in the process of connecting to the central manager.
    case connecting

    /// The peripheral is currently connected to the central manager.
    case connected

    /// The peripheral is currently in the process of disconnecting from the central manager.
    case disconnecting

    var inner: CBPeripheralState {
        switch self {
        case .disconnected: return .disconnected
        case .connecting: return .connecting
        case .connected: return .connected
        case .disconnecting: return .disconnecting
        }
    }

    /// Initializes an instance of `State` from an instance of `CBPeripheralState`.
    ///
    /// - Parameter state: The original state to initialize from.
    init(state: CBPeripheralState) {
        switch state {
        case .disconnected: self = .disconnected
        case .connecting: self = .connecting
        case .connected: self = .connected
        case .disconnecting: self = .disconnecting
        }
    }
}

extension PeripheralState: CustomStringConvertible {
    public var description: String {
        switch self {
        case .disconnected: return ".disconnected"
        case .connecting: return ".connecting"
        case .connected: return ".connected"
        case .disconnecting: return ".disconnecting"
        }
    }
}
