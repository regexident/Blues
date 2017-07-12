//
//  DefaultCharacteristic.swift
//  Blues
//
//  Created by Vincent Esche on 10.05.17.
//  Copyright © 2017 NWTN Berlin. All rights reserved.
//

import Foundation

import Result

/// Default implementation of `Characteristic` protocol.
open class DefaultCharacteristic:
    Characteristic, DelegatedCharacteristicProtocol, DataSourcedCharacteristicProtocol {
    public weak var delegate: CharacteristicDelegate?
    public weak var dataSource: CharacteristicDataSource?
}

// MARK: - CharacteristicDataSource
extension DefaultCharacteristic: CharacteristicDataSource {
    public func descriptor(
        with identifier: Identifier,
        for characteristic: Characteristic
    ) -> Descriptor {
        if let dataSource = self.dataSource {
            return dataSource.descriptor(with: identifier, for: characteristic)
        } else {
            return DefaultDescriptor(identifier: identifier, characteristic: characteristic)
        }
    }
}

// MARK: - ReadableCharacteristicDelegate
extension DefaultCharacteristic: ReadableCharacteristicDelegate {
    public func didUpdate(
        data: Result<Data, Error>,
        for characteristic: Characteristic
    ) {
        self.delegate?.didUpdate(data: data, for: characteristic)
    }
}

// MARK: - WritableCharacteristicDelegate
extension DefaultCharacteristic: WritableCharacteristicDelegate {
    public func didWrite(
        data: Result<Data, Error>,
        for characteristic: Characteristic
    ) {
        self.delegate?.didWrite(data: data, for: characteristic)
    }
}

// MARK: - NotifiableCharacteristicDelegate
extension DefaultCharacteristic: NotifiableCharacteristicDelegate {
    public func didUpdate(
        notificationState isNotifying: Result<Bool, Error>,
        for characteristic: Characteristic
    ) {
        self.delegate?.didUpdate(notificationState: isNotifying, for: characteristic)
    }
}

// MARK: - DescribableCharacteristicDelegate
extension DefaultCharacteristic: DescribableCharacteristicDelegate {
    public func didDiscover(
        descriptors: Result<[Descriptor], Error>,
        for characteristic: Characteristic
    ) {
        self.delegate?.didDiscover(descriptors: descriptors, for: characteristic)
    }
}
