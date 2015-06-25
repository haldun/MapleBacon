//
// Copyright (c) 2015 Zalando SE. All rights reserved.
//

import UIKit
import MapleBacon

class ResizerResultView: UIView {

    var image: UIImage?
    var selectedContentMode: UIViewContentMode?
    let deviceScale = UIScreen.mainScreen().scale

    override func drawRect(rect: CGRect) {
        if let contentMode = selectedContentMode, let image = image {
            Resizer.resizeImage(image, contentMode: contentMode, toSize: rect.size,
                    interpolationQuality: CGInterpolationQuality.High, async: false) {
                resizedImage in
                let (xOffset, yOffset) = self.offsetsForImage(resizedImage, inRect: rect)
                let imageRect = CGRect(x: xOffset, y: yOffset, width: resizedImage.size.width / self.deviceScale,
                        height: resizedImage.size.height / self.deviceScale)
                resizedImage.drawInRect(imageRect)
            }
        }
    }

    private func offsetsForImage(image: UIImage, inRect rect: CGRect) -> (CGFloat, CGFloat) {
        let rectWidth = CGRectGetWidth(rect)
        let rectHeight = CGRectGetHeight(rect)
        let xOffset = rectWidth > image.size.width / deviceScale ? (rectWidth - image.size.width / deviceScale) / 2 : 0
        let yOffset = rectHeight > image.size.height / deviceScale ? (rectHeight - image.size.height / deviceScale) / 2 : 0
        return (xOffset, yOffset)
    }

}
