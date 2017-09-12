//
//  CentralManagerOptions.swift
//  BluesTests
//
//  Created by Michał Kałużny on 11/09/2017.
//  Copyright © 2017 NWTN Berlin. All rights reserved.
//

import XCTest
import CoreBluetooth

@testable import Blues

class CentralManagerOptionsTestCase: XCTestCase {
    
    static private let RestoreIdentifierStub = "RestoreIdentifier"
    static private let ShouldShowPowerAlert = true

    let dictionary: [String: Any] = [
        CBCentralManagerOptionRestoreIdentifierKey: RestoreIdentifierStub,
        CBCentralManagerOptionShowPowerAlertKey: ShouldShowPowerAlert
    ]
    
    func testShouldShowPowerAlert() {
        var dictionary = self.dictionary
        dictionary[CBCentralManagerOptionShowPowerAlertKey] = true

        guard let options = CentralManagerOptions(dictionary: dictionary) else {
            return XCTFail()
        }
        
        XCTAssertEqual(options.showPowerAlert, true)
    }
    
    func testShouldntShowPowerAlert() {
        var dictionary = self.dictionary
        dictionary[CBCentralManagerOptionShowPowerAlertKey] = false
        
        guard let options = CentralManagerOptions(dictionary: dictionary) else {
            return XCTFail()
        }
        
        XCTAssertEqual(options.showPowerAlert, false)
    }
    
    func testShowPowerAlertWithNoKey() {
        var dictionary = self.dictionary
        dictionary[CBCentralManagerOptionShowPowerAlertKey] = nil
        
        guard let options = CentralManagerOptions(dictionary: dictionary) else {
            return XCTFail()
        }
        
        XCTAssertEqual(options.showPowerAlert, nil)
    }
    
    func testProperIdentifier() {
        let identifier = UUID().uuidString
        var dictionary = self.dictionary
        
        dictionary[CBCentralManagerOptionRestoreIdentifierKey] = identifier
        
        guard let options = CentralManagerOptions(dictionary: dictionary) else {
            return XCTFail()
        }
        guard let optionsIdentifier = options.restoreIdentifier else {
            return XCTFail()
        }
        
        guard case .custom(let value) = optionsIdentifier else {
            return XCTFail()
        }
        
        XCTAssertEqual(value, identifier)
    }
    
    func testNoRestoreIdentifier() {
        var dictionary = self.dictionary
        
        dictionary[CBCentralManagerOptionRestoreIdentifierKey] = nil
        
        guard let options = CentralManagerOptions(dictionary: dictionary) else {
            return XCTFail()
        }
        
        XCTAssertNil(options.restoreIdentifier)
    }
    
    func testDictionaryMarshalling() {
        guard let options = CentralManagerOptions(dictionary: dictionary) else {
            return XCTFail()
        }
        
        let parsed = options.dictionary
        
        guard
            let restoreIdentifier = parsed[CBCentralManagerOptionRestoreIdentifierKey] as? String,
            let shoudShowPowerAlert = parsed[CBCentralManagerOptionShowPowerAlertKey] as? Bool
        else {
            return XCTFail()
        }
        
        XCTAssertEqual(restoreIdentifier, CentralManagerOptionsTestCase.RestoreIdentifierStub)
        XCTAssertEqual(shoudShowPowerAlert, CentralManagerOptionsTestCase.ShouldShowPowerAlert)
    }
    
    func testInvalidDictionaryMarshalling() {
        var dictionary = self.dictionary
        
        dictionary[CBCentralManagerOptionRestoreIdentifierKey] = 123
        dictionary[CBCentralManagerOptionShowPowerAlertKey] = "Test"

        
        let options = CentralManagerOptions(dictionary: dictionary)
        
        XCTAssertNil(options)
    }
}
