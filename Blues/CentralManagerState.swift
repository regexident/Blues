//
//  CentralManagerState.swift
//  Blues
//
//  Created by Vincent Esche on 28/10/2016.
//  Copyright © 2016 NWTN Berlin. All rights reserved.
//

import Foundation
import CoreBluetooth

/// Abstraction layer around `CBManagerState`.
public enum CentralManagerState {
    /// The current state of the manager is unknown; an update is imminent.
    case unknown
    /// The connection with the system service was momentarily lost; an update is imminent.
    case resetting
    /// The platform does not support Bluetooth low energy.
    case unsupported
    /// The app is not authorized to use Bluetooth low energy.
    case unauthorized
    /// Bluetooth is currently powered off.
    case poweredOff
    /// Bluetooth is currently powered on and available to use.
    case poweredOn

    @available(iOSApplicationExtension 10.0, *)
    init(from state: CBManagerState) {
        switch state {
        case .unknown: self = .unknown
        case .resetting: self = .resetting
        case .unsupported: self = .unsupported
        case .unauthorized: self = .unauthorized
        case .poweredOff: self = .poweredOff
        case .poweredOn: self = .poweredOn
        }
    }
}
