/// This Source Code Form is subject to the terms of the Mozilla Public
/// License, v. 2.0. If a copy of the MPL was not distributed with this
/// file, You can obtain one at http://mozilla.org/MPL/2.0/.

extension Result {
    // Construct a `Result` from a pair of optional value and optional error.
    public init(success: Success?, failure: Failure?) {
        switch (success, failure) {
        case (let .some(value), .none):
            self = .success(value)
        case (.none, let .some(error)):
            self = .failure(error)
        case (.some(_), let .some(error)):
            self = .failure(error)
        case (.none, .none):
            fatalError("Expected at least one of `success` and `failure` to be non-nil.")
        }
    }
}
