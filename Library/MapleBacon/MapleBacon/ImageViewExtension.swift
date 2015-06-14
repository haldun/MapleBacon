//
// Copyright (c) 2015 Zalando SE. All rights reserved.
//

import UIKit

var ImageViewAssociatedObjectHandle: UInt8 = 0

extension UIImageView {

    public final func setImageWithURL(url: NSURL, cacheScaled: Bool = false) {
        setImageWithURL(url, cacheScaled: cacheScaled, completion: nil)
    }

    public final func setImageWithURL(url: NSURL, cacheScaled: Bool = false, completion: ImageDownloaderCompletion?) {
        cancelDownload()
        let downloadCompletion: ImageDownloaderCompletion = {
            [weak self] imageInstance, error in
            dispatch_async(dispatch_get_main_queue()) {
                if let image = imageInstance?.image {
                    self?.image = image
                }
                completion?(imageInstance, error)
            }
        }

        guard let operation = ImageManager.sharedManager.downloadImageAtURL(url, cacheScaled: cacheScaled, imageView: self, completion: downloadCompletion) else {
            return
        }
        self.operation = operation
    }

    var operation: ImageDownloadOperation? {
        get {
            return objc_getAssociatedObject(self, &ImageViewAssociatedObjectHandle) as? ImageDownloadOperation
        }
        set {
            objc_setAssociatedObject(self, &ImageViewAssociatedObjectHandle, newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    private final func cancelDownload() {
        operation?.cancel()
    }

}
