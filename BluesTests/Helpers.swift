//
//  Helpers.swift
//  BluesTests
//
//  Created by Michał Kałużny on 11/09/2017.
//  Copyright © 2017 NWTN Berlin. All rights reserved.
//

import Foundation

func areOptionalsEqual<T: Equatable>(_ lhs: [T]?, _ rhs: [T]?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l == r
    case (.none, .none):
        return true
    default:
        return false
    }
}
