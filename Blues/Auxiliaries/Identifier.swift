// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import CoreBluetooth

public protocol TypeIdentifiable {
    static var typeIdentifier: Identifier { get }
}

/// Thin wrapper around `CBUUID`.
public struct Identifier {
    let core: CBUUID

    /// The identifier represented as a `CBUUID`.
    public var uuid: CBUUID {
        return self.core
    }

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

// MARK: - Equatable
extension Identifier: Equatable {
    public static func == (lhs: Identifier, rhs: Identifier) -> Bool {
        return lhs.core == rhs.core
    }
}

// MARK: - Hashable
extension Identifier: Hashable {
    public var hashValue: Int {
        return self.core.hashValue
    }
}

// MARK: - CustomStringConvertible
extension Identifier: CustomStringConvertible {
    public var description: String {
        return self.string
    }
}
