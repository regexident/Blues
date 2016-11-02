//
//  CharacteristicProperties.swift
//  Blues
//
//  Created by Vincent Esche on 30/10/2016.
//  Copyright © 2016 NWTN Berlin. All rights reserved.
//

import Foundation
import CoreBluetooth

public struct CharacteristicProperties: OptionSet {
    public static var broadcast = CharacteristicProperties(core: .broadcast)
    public static var read = CharacteristicProperties(core: .read)
    public static var writeWithoutResponse = CharacteristicProperties(core: .writeWithoutResponse)
    public static var write = CharacteristicProperties(core: .write)
    public static var notify = CharacteristicProperties(core: .notify)
    public static var indicate = CharacteristicProperties(core: .indicate)
    public static var authenticatedSignedWrites = CharacteristicProperties(core: .authenticatedSignedWrites)
    public static var extendedProperties = CharacteristicProperties(core: .extendedProperties)
    public static var notifyEncryptionRequired = CharacteristicProperties(core: .notifyEncryptionRequired)
    public static var indicateEncryptionRequired = CharacteristicProperties(core: .indicateEncryptionRequired)

    public let rawValue: UInt

    var core: CBCharacteristicProperties {
        return CBCharacteristicProperties(rawValue: rawValue)
    }

    public init() {
        self.rawValue = 0
    }

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    init(core: CBCharacteristicProperties) {
        self.rawValue = core.rawValue
    }
}

extension CharacteristicProperties: Equatable {

    public static func == (lhs: CharacteristicProperties, rhs: CharacteristicProperties) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
}

extension CharacteristicProperties: Hashable {
    public var hashValue: Int {
        return self.rawValue.hashValue
    }
}
