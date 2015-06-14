//
// Copyright (c) 2015 Zalando SE. All rights reserved.
//

import UIKit

public final class InMemoryStorage: Storage {

    private let cache = NSCache()
    
    public static let sharedStorage = InMemoryStorage()

    public convenience init() {
        self.init(name: "default")
    }

    public init(name: String) {
        cache.name = "de.zalando.MapleBacon.\(name)"
    }

    public func storeImage(image: UIImage, data: NSData?, forKey key: String) {
        cache.setObject(image, forKey: key, cost: cacheCost(forImage: image))
    }

    private func cacheCost(forImage image: UIImage) -> Int {
        let imagesCount = image.images?.count ?? 0
        return imagesCount * Int(image.size.width * image.size.height * image.scale * image.scale)
    }

    public func image(forKey key: String) -> UIImage? {
        return cache.objectForKey(key) as? UIImage
    }

    public func removeImage(forKey key: String) {
        cache.removeObjectForKey(key)
    }

    public func clearStorage() {
        cache.removeAllObjects()
    }

}
