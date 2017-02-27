//
//  DescriptorProtocols.swift
//  Blues
//
//  Created by Vincent Esche on 21/11/2016.
//  Copyright © 2016 NWTN Berlin. All rights reserved.
//

import Foundation

import Result

/// A `DelegatedDescriptor`'s delegate.
public protocol DescriptorDelegate: class {

    /// Invoked when you retrieve a specified characteristic descriptor’s value.
    ///
    /// - Parameters:
    ///   - any: `.ok(any)` with the updated value iff successful, otherwise `.err(error)`.
    ///   - descriptor: The descriptor whose value has been retrieved.
    func didUpdate(any: Result<Any, Error>, forDescriptor descriptor: Descriptor)

    /// Invoked when you write data to a characteristic descriptor’s value.
    ///
    /// - Parameters:
    ///   - any: `.ok(any)` with the written value iff successful, otherwise `.err(error)`.
    ///   - descriptor: The descriptor whose value has been retrieved.
    func didWrite(any: Result<Any, Error>, forDescriptor descriptor: Descriptor)
}

/// A `Descriptor`'s data source.
public protocol DescriptorDataSource: class {

}

/// A `Descriptor` that supports delegation.
///
/// Note: Conforming to `DelegatedDescriptor` adds a default implementation for all
/// functions found in `DescriptorDelegate` which simply forwards all method calls
/// to its delegate.
public protocol DelegatedDescriptor: Descriptor {

    /// The descriptor's delegate.
    weak var delegate: DescriptorDelegate? { get set }
}

extension DelegatedDescriptor {
    public func didUpdate(any: Result<Any, Error>, forDescriptor descriptor: Descriptor) {
        self.delegate?.didUpdate(any: any, forDescriptor: descriptor)
    }

    public func didWrite(any: Result<Any, Error>, forDescriptor descriptor: Descriptor) {
        self.delegate?.didWrite(any: any, forDescriptor: descriptor)
    }
}

/// A `Descriptor` that supports data sourcing.
///
/// Note: Conforming to `DataSourcedDescriptor` adds a default implementation for all
/// functions found in `DescriptorDataSource` which simply forwards all method calls
/// to its data source.
public protocol DataSourcedDescriptor: Descriptor {

    /// The descriptor's delegate.
    weak var dataSource: DescriptorDataSource? { get set }
}

extension DelegatedDescriptor {

}
