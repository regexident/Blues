//
//  TestSetup.swift
//  BluesTests
//
//  Created by Michał Kałużny on 12/09/2017.
//  Copyright © 2017 NWTN Berlin. All rights reserved.
//

import Foundation
@testable import Blues

@objc class TestSetup: NSObject {
    
    override init() {
        super.init()
        
        setupLogger()
    }
    
    func setupLogger() {
        Log.shared.shouldFailOnError = false
    }
}
