// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import XCTest
import CoreBluetooth

@testable import Blues

private struct CBCentralMock: CBCentralProtocol {
    var identifier: UUID
    var maximumUpdateValueLength: Int
}

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
            Key.serviceUUIDsKey: [CBUUID()],
            Key.overflowServiceUUIDsKey: [CBUUID()],
            Key.solicitedServiceUUIDsKey: [CBUUID()],
            Key.txPowerLevelKey: 100,
            Key.isConnectable: true
        ]
    }
    
    //MARK: Service Data
    func test_existingServiceData() {
        var dictionary = Stub.dictionary
        let uuid = UUID()
        dictionary[Key.serviceDataKey] = [
            CBUUID(nsuuid: uuid): Data(),
        ] as Dictionary<CBUUID, Data>
        
        let advertisement = Advertisement(dictionary: dictionary)
        
        XCTAssertEqual(advertisement.serviceData?.count, 1)
    }
    
    func test_emptyServiceData() {
        var dictionary = Stub.dictionary
        
        dictionary[Key.serviceDataKey] = [:] as Dictionary<CBUUID, Data>
        
        let advertisement = Advertisement(dictionary: dictionary)
        
        XCTAssertEqual(advertisement.serviceData?.count, 0)
    }
    
    func test_nonUUIDServiceData() {
        var dictionary = Stub.dictionary
        
        dictionary[Key.serviceDataKey] = ["Test": "Test"] as Dictionary<String, String>
        
        let advertisement = Advertisement(dictionary: dictionary)
        
        XCTAssertEqual(advertisement.serviceData?.count, nil)
    }
    
    //MARK: Services
    func test_services() {
        let services = [
            \Advertisement.serviceUUIDs: Key.serviceUUIDsKey,
            \Advertisement.overflowServiceUUIDs: Key.overflowServiceUUIDsKey,
            \Advertisement.solicitedServiceUUIDs: Key.solicitedServiceUUIDsKey,
        ]
        
        for (keyPath, key) in services {
            self.test_existingServices(keyPath: keyPath, key: key)
            self.test_duplicatedServices(keyPath: keyPath, key: key)
            self.test_emptyServices(keyPath: keyPath, key: key)
            self.test_nonUUIDServices(keyPath: keyPath, key: key)
        }
    }
    
    func test_existingServices(keyPath: KeyPath<Advertisement, [Identifier]?>, key: String) {
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
    
    func test_duplicatedServices(keyPath: KeyPath<Advertisement, [Identifier]?>, key: String) {
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
    
    func test_emptyServices(keyPath: KeyPath<Advertisement, [Identifier]?>, key: String) {
        var dictionary = Stub.dictionary
        
        dictionary[key] = [] as Array<CBUUID>
        
        let advertisement = Advertisement(dictionary: dictionary)
        let value = advertisement[keyPath: keyPath]

        XCTAssertEqual(value?.count, 0)
    }
    
    func test_nonUUIDServices(keyPath: KeyPath<Advertisement, [Identifier]?>, key: String) {
        var dictionary = Stub.dictionary
        
        dictionary[key] = ["Test"] as Array<String>
        
        let advertisement = Advertisement(dictionary: dictionary)
        let value = advertisement[keyPath: keyPath]
        XCTAssertEqual(value?.count, nil)
    }
    
    //MARK: Data Representation
    func test_dataRepresentation() {
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
        XCTAssertEqual(advertisement.serviceUUIDs, restored.serviceUUIDs)
        XCTAssertEqual(advertisement.solicitedServiceUUIDs, restored.solicitedServiceUUIDs)
        XCTAssertEqual(advertisement.overflowServiceUUIDs, restored.overflowServiceUUIDs)
        XCTAssertEqual(advertisement.serviceData, restored.serviceData)
    }
    
    func test_failingDataRepresentation() {
        let data = Data()
        let advertisement = Advertisement(data: data)
        XCTAssertNil(advertisement)
    }
    
    func test_description() {
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
            serviceUUIDs: [0000] \
            overflowServiceUUIDs: [0000] \
            solicitedServiceUUIDs: [0000] \
            txPowerLevel: 100 \
            isConnectable: true\
            >
            """
        )
    }
    
    //MARK: Primitive Values
    func test_powerLevel() {
        test_primitiveValue(
            keyPath: \Advertisement.txPowerLevel,
            key: Key.txPowerLevelKey,
            expectedValue: 100
        )
    }
    
    func test_localName() {
        test_primitiveValue(
            keyPath: \Advertisement.localName,
            key: Key.localNameKey,
            expectedValue: "Local Name"
        )
    }
    
    func test_isConnectable() {
        test_primitiveValue(
            keyPath: \Advertisement.isConnectable,
            key: Key.isConnectable,
            expectedValue: false
        )
    }
    
    //MARK: Generic Helpers
    
    func test_primitiveValue<T: Equatable>(keyPath: KeyPath<Advertisement, T?>, key: String, expectedValue: T) {
        self.test_primitiveValueExpected(keyPath: keyPath, key: key, value: expectedValue)
        self.test_primitiveValueNotExpected(keyPath: keyPath, key: key)
        self.test_primitiveValueNil(keyPath: keyPath, key: key)
    }
    
    func test_primitiveValueExpected<T: Equatable>(keyPath: KeyPath<Advertisement, T?>, key: String, value: T) {
        var dictionary = Stub.dictionary
        
        dictionary[key] = value
        
        let advertisement = Advertisement(dictionary: dictionary)
        let transformed = advertisement[keyPath: keyPath]
        
        XCTAssertEqual(transformed!, value)
    }
    
    func test_primitiveValueNotExpected<T: Equatable>(keyPath: KeyPath<Advertisement, T?>, key: String) {
        var dictionary = Stub.dictionary

        dictionary[key] = []
        
        let advertisement = Advertisement(dictionary: dictionary)
        let transformed = advertisement[keyPath: keyPath]
        
        XCTAssertEqual(transformed, nil)
    }
    
    func test_primitiveValueNil<T: Equatable>(keyPath: KeyPath<Advertisement, T?>, key: String) {
        var dictionary = Stub.dictionary
        
        dictionary[key] = nil as T?
        
        let advertisement = Advertisement(dictionary: dictionary)
        let transformed = advertisement[keyPath: keyPath]
        
        XCTAssertEqual(transformed, nil)
    }
}
