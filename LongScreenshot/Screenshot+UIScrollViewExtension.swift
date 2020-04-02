//
//  Screenshot+UIScrollViewExtension.swift
//  LongScreenshot
//
//  Created by Guang Lei on 2020/4/2.
//  Copyright © 2020 Guang Lei. All rights reserved.
//

// Reference:  https://github.com/startry/SwViewCapture
// Notes: The 'swContentCapture(_:)' method would lose constraints of UIScrollview, we need remake its constraints after screenshot.

import UIKit

public extension UIScrollView {

    func swContentCapture (_ completionHandler: @escaping (_ capturedImage: UIImage?) -> Void) {

        // Put a fake Cover of View
        let snapShotView = self.snapshotView(afterScreenUpdates: false)
        snapShotView?.frame = CGRect(x: self.frame.origin.x, y: self.frame.origin.y, width: (snapShotView?.frame.size.width)!, height: (snapShotView?.frame.size.height)!)
        self.superview?.addSubview(snapShotView!)

        // Backup all properties of scrollview if needed
        let bakFrame     = self.frame
        let bakOffset    = self.contentOffset
        let bakSuperView = self.superview
        let bakIndex     = self.superview?.subviews.firstIndex(of: self)

        // Scroll To Bottom show all cached view
        if self.frame.size.height < self.contentSize.height {
            self.contentOffset = CGPoint(x: 0, y: self.contentSize.height - self.frame.size.height)
        }

        self.swRenderImageView({ [weak self] (capturedImage) -> Void in
            // Recover View

            let strongSelf = self!

            strongSelf.removeFromSuperview()
            strongSelf.frame = bakFrame
            strongSelf.contentOffset = bakOffset
            bakSuperView?.insertSubview(strongSelf, at: bakIndex!)

            snapShotView?.removeFromSuperview()

            completionHandler(capturedImage)
        })
    }

    private func swRenderImageView(_ completionHandler: @escaping (_ capturedImage: UIImage?) -> Void) {
        // Due to scroll to bottom, delay to wait for contentOffset refreshing.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            // Rebuild scrollView superView and their hold relationship
            let swTempRenderView = UIView(frame: CGRect(x: 0, y: 0, width: self.contentSize.width, height: self.contentSize.height))
            self.removeFromSuperview()
            swTempRenderView.addSubview(self)

            self.contentOffset = CGPoint.zero
            self.frame         = swTempRenderView.bounds

            // Sometimes ScrollView will Capture nothing without defer;
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                let bounds = self.bounds
                UIGraphicsBeginImageContextWithOptions(bounds.size, false, UIScreen.main.scale)
                self.layer.render(in: UIGraphicsGetCurrentContext()!)
                let capturedImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()

                completionHandler(capturedImage)
            }
        }
    }
}
