//
//  Identifier.swift
//  Blues
//
//  Created by Vincent Esche on 30/10/2016.
//  Copyright © 2016 NWTN Berlin. All rights reserved.
//

import Foundation
import CoreBluetooth

/// Thin wrapper around `CBUUID`.
public struct Identifier {
    let core: CBUUID

    /// The identifier represented as a string.
    public var string: String {
        return self.core.uuidString
    }

    /// The data of the identifier.
    public var data: Data {
        return self.core.data
    }

    /// Initializes an instance of `Identifier` from a `CBUUID` object.
    public init(uuid: CBUUID) {
        self.core = uuid
    }

    /// Initializes an instance of `Identifier` from a `UUID` object.
    public init(uuid: UUID) {
        self.core = CBUUID(nsuuid: uuid)
    }

    /// Initializes an instance of `Identifier` from a string.
    public init(string: String) {
        self.core = CBUUID(string: string)
    }
}

extension Identifier: Equatable {

    public static func == (lhs: Identifier, rhs: Identifier) -> Bool {
        return lhs.core == rhs.core
    }
}

extension Identifier: Hashable {

    public var hashValue: Int {
        return self.core.hashValue
    }
}
