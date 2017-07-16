//
//  ATTError.swift
//  Blues
//
//  Created by Vincent Esche on 7/16/17.
//  Copyright © 2017 NWTN Berlin. All rights reserved.
//

import Foundation
import CoreBluetooth

public enum ATTError {
    case success
    case invalidHandle
    case readNotPermitted
    case writeNotPermitted
    case invalidPdu
    case insufficientAuthentication
    case requestNotSupported
    case invalidOffset
    case insufficientAuthorization
    case prepareQueueFull
    case attributeNotFound
    case attributeNotLong
    case insufficientEncryptionKeySize
    case invalidAttributeValueLength
    case unlikelyError
    case insufficientEncryption
    case unsupportedGroupType
    case insufficientResources

    internal var core: CBATTError.Code {
        switch self {
        case .success: return CBATTError.success
        case .invalidHandle: return CBATTError.invalidHandle
        case .readNotPermitted: return CBATTError.readNotPermitted
        case .writeNotPermitted: return CBATTError.writeNotPermitted
        case .invalidPdu: return CBATTError.invalidPdu
        case .insufficientAuthentication: return CBATTError.insufficientAuthentication
        case .requestNotSupported: return CBATTError.requestNotSupported
        case .invalidOffset: return CBATTError.invalidOffset
        case .insufficientAuthorization: return CBATTError.insufficientAuthorization
        case .prepareQueueFull: return CBATTError.prepareQueueFull
        case .attributeNotFound: return CBATTError.attributeNotFound
        case .attributeNotLong: return CBATTError.attributeNotLong
        case .insufficientEncryptionKeySize: return CBATTError.insufficientEncryptionKeySize
        case .invalidAttributeValueLength: return CBATTError.invalidAttributeValueLength
        case .unlikelyError: return CBATTError.unlikelyError
        case .insufficientEncryption: return CBATTError.insufficientEncryption
        case .unsupportedGroupType: return CBATTError.unsupportedGroupType
        case .insufficientResources: return CBATTError.insufficientResources
        }
    }
}
