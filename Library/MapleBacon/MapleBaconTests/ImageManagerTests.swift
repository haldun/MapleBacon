//
//  Copyright (c) 2015 Zalando SE. All rights reserved.
//

import XCTest
import Foundation
import UIKit
import MapleBacon

public let timeout: NSTimeInterval = 10

class ImageManagerTests: XCTestCase {

    let imageManager = ImageManager.sharedManager

    func test_whenImageManagerAsksForImageBeingDownloaded_thenImageInstanceReturnsDownloadingState() {
        MapleBaconStorage.sharedStorage.removeImage(forKey: imageURL)

        let downloadingImageExpectation = expectationWithDescription("Testing Downloading Image")
        let downloadedImageExpectation = expectationWithDescription("Testing Downloaded Image")

        imageManager.downloadImageAtURL(NSURL(string: imageURL)!, cacheScaled: false, imageView: nil, completion: {
            [unowned self] imageInstance, _ in
            guard let imageInstance = imageInstance where imageInstance.state == .New else {
                return
            }
            downloadedImageExpectation.fulfill()
            XCTAssertFalse(self.imageManager.hasDownloadsInProgress(),
                "Image downloaded but manager still has downloads in progress")
        })
        imageManager.downloadImageAtURL(NSURL(string: imageURL)!, cacheScaled: false, imageView: nil, completion: {
            [unowned self] imageInstance, _ in
            if let imageInstance = imageInstance {
                if imageInstance.state == .Downloading {
                    downloadingImageExpectation.fulfill()
                    XCTAssertTrue(self.imageManager.hasDownloadsInProgress(),
                            "Image downloading but manager has no downloads in progress")
                }
            }
        })

        waitForExpectationsWithTimeout(timeout) {
            error in
            if (error != nil) {
                XCTFail("Expectation failed")
            }
        }
    }

    func test_whenImageManagerAsksForImageAlreadyDownloaded_thenImageIsReturnedFromCache() {
        imageManager.downloadImageAtURL(NSURL(string: imageURL)!, cacheScaled: false, imageView: nil, completion: {
            [unowned self] imageInstance, _ in
            let cachedExpectation = self.expectationWithDescription("Testing Cached Image")

            self.imageManager.downloadImageAtURL(NSURL(string: imageURL)!, cacheScaled: false, imageView: nil, completion: {
                [unowned self] imageInstance, _ in
                guard let imageInstance = imageInstance where imageInstance.state == .Cached else {
                    return
                }
                cachedExpectation.fulfill()
                XCTAssertFalse(self.imageManager.hasDownloadsInProgress(),
                    "Image returned from cache but manager still has downloads in progress")
            })

            self.waitForExpectationsWithTimeout(timeout) {
                error in
                if (error != nil) {
                    XCTFail("Expectation failed")
                }
            }
        })
    }

    func test_whenImageManagerAsksForImageNotYetDownloaded_thenImageIsReturnedAsNew() {
        MapleBaconStorage.sharedStorage.removeImage(forKey: imageURL)
        let newImageExpectation = expectationWithDescription("Testing New Image")

        imageManager.downloadImageAtURL(NSURL(string: imageURL)!, cacheScaled: false, imageView: nil, completion: {
            [unowned self] imageInstance, error -> Void in
            guard let imageInstance = imageInstance where imageInstance.state == .New else {
                return
            }
            XCTAssertFalse(self.imageManager.hasDownloadsInProgress(),
                "Image downloaded but manager still has downloads in progress")
            newImageExpectation.fulfill()
        })

        waitForExpectationsWithTimeout(timeout) {
            error in
            if (error != nil) {
                XCTFail("Expectation failed")
            }
        }
    }

    func test_whenUsingImageManagerWithCustomStorage_imageIsStored() {
        let storage = InMemoryStorage(name: "customPath")
        storage.removeImage(forKey: imageURL)

        let newImageExpectation = expectationWithDescription("Testing New Image")

        imageManager.downloadImageAtURL(NSURL(string: imageURL)!, cacheScaled: false, imageView: nil, storage: storage) {
            imageInstance, _ in
            newImageExpectation.fulfill()
            XCTAssertNotNil(storage.image(forKey: imageURL))
        }

        waitForExpectationsWithTimeout(timeout) {
            error in
            if (error != nil) {
                XCTFail("Expectation failed")
            }
        }
    }

}
