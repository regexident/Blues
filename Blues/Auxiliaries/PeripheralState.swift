// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

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
    /// - Parameters
    ///   - state: The original state to initialize from.
    init(state: CBPeripheralState) {
        switch state {
        case .disconnected: self = .disconnected
        case .connecting: self = .connecting
        case .connected: self = .connected
        case .disconnecting: self = .disconnecting
        case _:
            print("Encountered unknown state: \(state), falling back to `.disconnected`.")
            self = .disconnected
        }
    }
}

// MARK: - CustomStringConvertible
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
