//
// Copyright (c) 2015 Zalando SE. All rights reserved.
//

import UIKit

public final class DiskStorage: Storage {

    let fileManager: NSFileManager = {
        return NSFileManager.defaultManager()
    }()
    let storageQueue: dispatch_queue_t = {
        dispatch_queue_create("de.zalando.MapleBacon.Storage", DISPATCH_QUEUE_SERIAL)
    }()
    let storagePath: String

    public var maxAge: NSTimeInterval = 60 * 60 * 24 * 7

    public static let sharedStorage = DiskStorage()

    public convenience init() {
        self.init(name: "default")
    }

    public init(name: String) {
        let paths = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true)
        storagePath = paths.first!.stringByAppendingPathComponent("de.zalando.MapleBacon.\(name)")
        do {
            try fileManager.createDirectoryAtPath(storagePath, withIntermediateDirectories: true, attributes: nil)
        } catch _ {
        }
    }

    public func storeImage(image: UIImage, var data: NSData?, forKey key: String) {
        dispatch_async(storageQueue) {
            if (data == nil) {
                data = UIImagePNGRepresentation(image)
            }
            self.fileManager.createFileAtPath(self.defaultStoragePath(forKey: key), contents: data!, attributes: nil)
            self.pruneStorage()
        }
    }

    public func pruneStorage() {
        dispatch_async(storageQueue) {
            let directoryURL = NSURL(fileURLWithPath: self.storagePath, isDirectory: true)
            if let enumerator = self.fileManager.enumeratorAtURL(directoryURL,
                    includingPropertiesForKeys: [NSURLIsDirectoryKey, NSURLContentModificationDateKey],
                    options: .SkipsHiddenFiles,
                    errorHandler: nil) {
                self.deleteExpiredFiles(self.expiredFiles(usingEnumerator: enumerator))
            }
        }
    }

    private func expiredFiles(usingEnumerator enumerator: NSDirectoryEnumerator) -> [NSURL] {
        let expirationDate = NSDate(timeIntervalSinceNow: -maxAge)
        var expiredFiles = [NSURL]()
        while let fileURL = enumerator.nextObject() as? NSURL {
            if self.isDirectory(fileURL) {
                enumerator.skipDescendants()
                continue
            }
            if let modificationDate = self.modificationDate(fileURL) where modificationDate.laterDate(expirationDate) == expirationDate {
                expiredFiles.append(fileURL)
            }
        }
        return expiredFiles
    }

    private func isDirectory(fileURL: NSURL) -> Bool {
        do {
            var isDirectoryResource: AnyObject?
            try fileURL.getResourceValue(&isDirectoryResource, forKey: NSURLIsDirectoryKey)
            if let isDirectory = isDirectoryResource as? NSNumber {
                return isDirectory.boolValue
            }
        } catch _ {
            return false
        }
        return false
    }

    private func modificationDate(fileURL: NSURL) -> NSDate? {
        do {
            var modificationDateResource: AnyObject?
            try fileURL.getResourceValue(&modificationDateResource, forKey: NSURLContentModificationDateKey)
            return modificationDateResource as? NSDate
        } catch _ {
            return nil
        }
    }

    private func deleteExpiredFiles(files: [NSURL]) {
        for file in files {
            do {
                try fileManager.removeItemAtURL(file)
            } catch _ {
            }
        }
    }

    public func image(forKey key: String) -> UIImage? {
        guard let data = NSData(contentsOfFile: defaultStoragePath(forKey: key)) else {
            return nil
        }
        return UIImage.imageWithCachedData(data)
    }

    private func defaultStoragePath(forKey key: String) -> String {
        return storagePath(forKey: key, inPath: storagePath)
    }

    private func storagePath(forKey key: String, inPath path: String) -> String {
        return (path as NSString).stringByAppendingPathComponent(key.MD5())
    }

    public func removeImage(forKey key: String) {
        dispatch_async(storageQueue) {
            do {
                try self.fileManager.removeItemAtPath(self.defaultStoragePath(forKey: key))
            } catch _ {
            }
            return
        }
    }

    public func clearStorage() {
        dispatch_async(storageQueue) {
            do {
                try self.fileManager.removeItemAtPath(self.storagePath)
            } catch _ {
            }
            do {
                try self.fileManager.createDirectoryAtPath(self.storagePath, withIntermediateDirectories: true, attributes: nil)
            } catch _ {
            }
        }
    }

}
