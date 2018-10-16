//
//  PeripheralManagerAuthorizationStatus.swift
//  Blues
//
//  Created by Vincent Esche on 7/16/17.
//  Copyright © 2017 NWTN Berlin. All rights reserved.
//

import Foundation
import CoreBluetooth

/// Represents the current state of a PeripheralManager.
///
/// - notDetermined: User has not yet made a choice with regards to this application.
/// - restricted: This application is not authorized to share data while backgrounded.
///   The user cannot change this application’s status, possibly due to active
///   restrictions such as parental controls being in place.
/// - denied: User has explicitly denied this application from sharing data while backgrounded.
/// - authorized: User has authorized this application to share data while backgrounded.
public enum PeripheralManagerAuthorizationStatus {
    case notDetermined
    case restricted
    case denied
    case authorized
    
    init(from coreStatus: CBPeripheralManagerAuthorizationStatus) {
        switch coreStatus {
        case .authorized: self = .authorized
        case .denied: self = .denied
        case .notDetermined: self = .notDetermined
        case .restricted: self = .restricted
        }
    }
}
