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
}

public protocol ReadableDescriptorDelegate: DescriptorDelegate {

    /// Invoked when you retrieve a specified characteristic descriptor’s value.
    ///
    /// - Parameters:
    ///   - any: `.ok(any)` with the updated value iff successful, otherwise `.err(error)`.
    ///   - descriptor: The descriptor whose value has been retrieved.
    func didUpdate(any: Result<Any, Error>, for descriptor: Descriptor)
}

public protocol WritableDescriptorDelegate: DescriptorDelegate {
    /// Invoked when you write data to a characteristic descriptor’s value.
    ///
    /// - Parameters:
    ///   - any: `.ok(any)` with the written value iff successful, otherwise `.err(error)`.
    ///   - descriptor: The descriptor whose value has been retrieved.
    func didWrite(any: Result<Any, Error>, for descriptor: Descriptor)
}

public typealias FullblownDescriptorDelegate =
    ReadableDescriptorDelegate
    & WritableDescriptorDelegate
