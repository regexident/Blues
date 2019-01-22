// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import XCTest
import CoreBluetooth
@testable import Blues

class AdvertisementTests: XCTestCase {
    private enum Key {
        static let localNameKey: String = CBAdvertisementDataLocalNameKey
        static let manufacturerDataKey: String = CBAdvertisementDataManufacturerDataKey
        static let serviceDataKey: String = CBAdvertisementDataServiceDataKey
        static let serviceUUIDsKey: String = CBAdvertisementDataServiceUUIDsKey
        static let overflowServiceUUIDsKey: String = CBAdvertisementDataOverflowServiceUUIDsKey
        static let solicitedServiceUUIDsKey: String = CBAdvertisementDataSolicitedServiceUUIDsKey
        static let txPowerLevelKey: String = CBAdvertisementDataTxPowerLevelKey
        static let isConnectable: String = CBAdvertisementDataIsConnectable
    }
    
    private enum Stub {
        static let dictionary: [String: Any] = [
            Key.localNameKey: "Test Device",
            Key.manufacturerDataKey: Data(),
            Key.serviceDataKey: [CBUUID(): Data()],
            Key.serviceUUIDsKey: [],
            Key.overflowServiceUUIDsKey: [],
            Key.solicitedServiceUUIDsKey: [],
            Key.txPowerLevelKey: 100,
            Key.isConnectable: true
        ]
    }
    
    //MARK: Service Data
    func testExistingServiceData() {
        var dictionary = Stub.dictionary
        let uuid = UUID()
        dictionary[Key.serviceDataKey] = [
            CBUUID(nsuuid: uuid): Data(),
        ] as Dictionary<CBUUID, Data>
        
        let advertisement = Advertisement(dictionary: dictionary)
        
        XCTAssertEqual(advertisement.serviceData?.count, 1)
    }
    
    func testEmptyServiceData() {
        var dictionary = Stub.dictionary
        
        dictionary[Key.serviceDataKey] = [:] as Dictionary<CBUUID, Data>
        
        let advertisement = Advertisement(dictionary: dictionary)
        
        XCTAssertEqual(advertisement.serviceData?.count, 0)
    }
    
    func testNonUUIDServiceData() {
        var dictionary = Stub.dictionary
        
        dictionary[Key.serviceDataKey] = ["Test": "Test"] as Dictionary<String, String>
        
        let advertisement = Advertisement(dictionary: dictionary)
        
        XCTAssertEqual(advertisement.serviceData?.count, nil)
    }
    
    //MARK: Services
    func testServices() {
        let services = [
            \Advertisement.serviceUUIDs: Key.serviceUUIDsKey,
            \Advertisement.overflowServiceUUIDs: Key.overflowServiceUUIDsKey,
            \Advertisement.solicitedServiceUUIDs: Key.solicitedServiceUUIDsKey,
        ]
        
        for (keyPath, key) in services {
            testExistingServices(keyPath: keyPath, key: key)
            testDuplicatedServices(keyPath: keyPath, key: key)
            testEmptyServices(keyPath: keyPath, key: key)
            testNonUUIDServices(keyPath: keyPath, key: key)
        }
    }
    
    func testExistingServices(keyPath: KeyPath<Advertisement, [Identifier]?>, key: String) {
        var dictionary = Stub.dictionary
        let uuid = UUID()
        dictionary[key] = [
            CBUUID(nsuuid: uuid),
        ] as Array<CBUUID>
        
        let advertisement = Advertisement(dictionary: dictionary)
        let value = advertisement[keyPath: keyPath]

        XCTAssertEqual(value?.count, 1)

        guard let coreUUID = value?.first else {
            return XCTFail()
        }
        
        XCTAssertEqual(coreUUID.uuid.uuidString, uuid.uuidString)
    }
    
    func testDuplicatedServices(keyPath: KeyPath<Advertisement, [Identifier]?>, key: String) {
        var dictionary = Stub.dictionary
        let uuid = UUID()
        
        dictionary[key] = [
            CBUUID(nsuuid: uuid),
            CBUUID(nsuuid: uuid),
        ] as Array<CBUUID>
        
        let advertisement = Advertisement(dictionary: dictionary)
        let value = advertisement[keyPath: keyPath]

        XCTAssertEqual(value?.count, 2)
    }
    
    func testEmptyServices(keyPath: KeyPath<Advertisement, [Identifier]?>, key: String) {
        var dictionary = Stub.dictionary
        
        dictionary[key] = [] as Array<CBUUID>
        
        let advertisement = Advertisement(dictionary: dictionary)
        let value = advertisement[keyPath: keyPath]

        XCTAssertEqual(value?.count, 0)
    }
    
    func testNonUUIDServices(keyPath: KeyPath<Advertisement, [Identifier]?>, key: String) {
        var dictionary = Stub.dictionary
        
        dictionary[key] = ["Test"] as Array<String>
        
        let advertisement = Advertisement(dictionary: dictionary)
        let value = advertisement[keyPath: keyPath]
        XCTAssertEqual(value?.count, nil)
    }
    
    //MARK: Data Representation
    func testDataRepresentation() {
        let dictionary = Stub.dictionary
        
        let advertisement = Advertisement(dictionary: dictionary)
        let data = advertisement.data
        guard let restored = Advertisement(data: data) else {
            return XCTFail()
        }
        
        XCTAssertEqual(advertisement.localName, restored.localName)
        XCTAssertEqual(advertisement.isConnectable, restored.isConnectable)
        XCTAssertEqual(advertisement.txPowerLevel, restored.txPowerLevel)
        XCTAssertEqual(advertisement.manufacturerData, restored.manufacturerData)
        XCTAssert(areOptionalsEqual(advertisement.serviceUUIDs, restored.serviceUUIDs))
        XCTAssert(areOptionalsEqual(advertisement.solicitedServiceUUIDs, restored.solicitedServiceUUIDs))
        XCTAssert(areOptionalsEqual(advertisement.overflowServiceUUIDs, restored.overflowServiceUUIDs))
        
        guard
            let leftServiceData = advertisement.serviceData,
            let rightServiceData = restored.serviceData
        else {
            return XCTFail()
        }
        
        for (left, right) in zip(leftServiceData, rightServiceData) {
            XCTAssertEqual(left.key.string, right.key.string)
            XCTAssertEqual(left.value, right.value)
        }
    }
    
    func testFailingDataRepresentation() {
        let data = Data()
        let advertisement = Advertisement(data: data)
        XCTAssertNil(advertisement)
    }
    
    func testDescription() {
        let dictionary = Stub.dictionary
        
        let advertisement = Advertisement(dictionary: dictionary)
        let description = advertisement.description
        
        XCTAssertEqual(
            description,
            """
            <Advertisement \
            localName: "Test Device" \
            manufacturerData: 0 bytes \
            serviceData: [0000: 0 bytes] \
            serviceUUIDs: [] \
            overflowServiceUUIDs: [] \
            solicitedServiceUUIDs: [] \
            txPowerLevel: 100 \
            isConnectable: true\
            >
            """
        )
    }
    
    //MARK: Primitive Values
    func testPowerLevel() {
        testPrimitiveValue(
            keyPath: \Advertisement.txPowerLevel,
            key: Key.txPowerLevelKey,
            expectedValue: 100
        )
    }
    
    func testLocalName() {
        testPrimitiveValue(
            keyPath: \Advertisement.localName,
            key: Key.localNameKey,
            expectedValue: "Local Name"
        )
    }
    
    func testIsConnectable() {
        testPrimitiveValue(
            keyPath: \Advertisement.isConnectable,
            key: Key.isConnectable,
            expectedValue: false
        )
    }
    
    //MARK: Generic Helpers
    
    func testPrimitiveValue<T: Equatable>(keyPath: KeyPath<Advertisement, T?>, key: String, expectedValue: T) {
        testPrimitiveValueExpected(keyPath: keyPath, key: key, value: expectedValue)
        testPrimitiveValueNotExpected(keyPath: keyPath, key: key)
        testPrimitiveValueNil(keyPath: keyPath, key: key)
    }
    
    func testPrimitiveValueExpected<T: Equatable>(keyPath: KeyPath<Advertisement, T?>, key: String, value: T) {
        var dictionary = Stub.dictionary
        
        dictionary[key] = value
        
        let advertisement = Advertisement(dictionary: dictionary)
        let transformed = advertisement[keyPath: keyPath]
        
        XCTAssertEqual(transformed!, value)
    }
    
    func testPrimitiveValueNotExpected<T: Equatable>(keyPath: KeyPath<Advertisement, T?>, key: String) {
        var dictionary = Stub.dictionary

        dictionary[key] = []
        
        let advertisement = Advertisement(dictionary: dictionary)
        let transformed = advertisement[keyPath: keyPath]
        
        XCTAssertEqual(transformed, nil)
    }
    
    func testPrimitiveValueNil<T: Equatable>(keyPath: KeyPath<Advertisement, T?>, key: String) {
        var dictionary = Stub.dictionary
        
        dictionary[key] = nil as T?
        
        let advertisement = Advertisement(dictionary: dictionary)
        let transformed = advertisement[keyPath: keyPath]
        
        XCTAssertEqual(transformed, nil)
    }
}
