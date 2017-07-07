//
//  AdvertisementPersistence.swift
//  Blues
//
//  Created by Vincent Esche on 7/7/17.
//  Copyright © 2017 NWTN Berlin. All rights reserved.
//

import Foundation

public protocol AdvertisementPersistence {
    func set(advertisement: Advertisement, for identifier: Identifier)
    func getAdvertisement(for identifier: Identifier) -> Advertisement?
}

extension UserDefaults: AdvertisementPersistence {

    private enum AdvertisementPersistenceKey {
        static let advertisementsKey = "advertisements"
    }

    public func set(advertisement: Advertisement, for identifier: Identifier) {
        let key = AdvertisementPersistenceKey.advertisementsKey
        var advertisements: [String : Data]
        if let dict = self.object(forKey: key) as? [String : Data] {
            advertisements = dict
        } else {
            advertisements = [:]
        }
        advertisements[identifier.string] = advertisement.data
        self.set(advertisements, forKey: key)
    }

    public func getAdvertisement(for identifier: Identifier) -> Advertisement? {
        let key = AdvertisementPersistenceKey.advertisementsKey
        let value = self.object(forKey: key)
        let advertisements = value as? [String : Data]
        return advertisements.flatMap {
            $0[identifier.string]
        }.flatMap {
            Advertisement(data: $0)
        }
    }
}
