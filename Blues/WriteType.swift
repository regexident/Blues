//
//  WriteType.swift
//  Blues
//
//  Created by Vincent Esche on 28/10/2016.
//  Copyright © 2016 NWTN Berlin. All rights reserved.
//

import Foundation
import CoreBluetooth

public enum WriteType {
    /// A characteristic value is to be written, with a response from
    /// the peripheral to indicate whether the write was successful.
    case withResponse
    /// A characteristic value is to be written, without any response from
    /// the peripheral to indicate whether the write was successful.
    case withoutResponse

    var inner: CBCharacteristicWriteType {
        switch self {
        case .withResponse: return .withResponse
        case .withoutResponse: return .withoutResponse
        }
    }

    init(writeType: CBCharacteristicWriteType) {
        switch writeType {
        case .withResponse: self = .withResponse
        case .withoutResponse: self = .withoutResponse
        }
    }
}
