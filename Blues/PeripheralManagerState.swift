//
//  PeripheralManagerState.swift
//  Blues
//
//  Created by Vincent Esche on 7/16/17.
//  Copyright © 2017 NWTN Berlin. All rights reserved.
//

import Foundation
import CoreBluetooth

/// Represents the current state of a PeripheralManager.
///
/// - unknown: State unknown, update imminent.
/// - resetting: The connection with the system service was momentarily lost, update imminent.
/// - unsupported: The platform doesn't support the Bluetooth Low Energy Peripheral/Server role.
/// - unauthorized: The application is not authorized to use the Bluetooth Low Energy Peripheral/Server role.
/// - poweredOff: Bluetooth is currently powered off.
/// - poweredOn: Bluetooth is currently powered on and available to use.
public enum PeripheralManagerState {
    case unknown
    case resetting
    case unsupported
    case unauthorized
    case poweredOff
    case poweredOn

    internal var core: CBPeripheralManagerState {
        switch self {
        case .unknown: return .unknown
        case .resetting: return .resetting
        case .unsupported: return .unsupported
        case .unauthorized: return .unauthorized
        case .poweredOff: return .poweredOff
        case .poweredOn: return .poweredOn
        }
    }
}
