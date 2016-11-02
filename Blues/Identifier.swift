//
//  Identifier.swift
//  Blues
//
//  Created by Vincent Esche on 30/10/2016.
//  Copyright © 2016 NWTN Berlin. All rights reserved.
//

import Foundation
import CoreBluetooth

public struct Identifier {
    let core: CBUUID

    public var string: String {
        return self.core.uuidString
    }

    public var data: Data {
        return self.core.data
    }

    public init(uuid: CBUUID) {
        self.core = uuid
    }

    public init(uuid: UUID) {
        self.core = CBUUID(nsuuid: uuid)
    }

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
