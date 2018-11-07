// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

public protocol AdvertisementPersistence {
    func set(advertisement: Advertisement, for identifier: Identifier)
    func getAdvertisement(for identifier: Identifier) -> Advertisement?
}

// MARK: - AdvertisementPersistence
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
