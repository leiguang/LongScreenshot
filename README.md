Take a long screenshot of the content of `UIScrollView`, including its subclasses `UITableView` and `UICollectionView`.



### 介绍

对 `UIScrollView` 及其子类 `UITableView`、`UICollectionView` 的内容进行长截图。



### 思路

对 `UIScrollView`进行长截屏时，需要知道它的全部内容，包括未加载未渲染的内容。

做法是通过设置它的内容偏移量 `contentOffset`， 让 `ScrollView` 的内容滑动到底部，这样便可以触发 `ScrollView` 中全部内容的加载和渲染。

用 `CoreGraphics` 对 `ScrollView` 的内容渲染生成图片，此时我们需要令 `ScrollView` 的宽高等于 它 `contentSize` 的真实宽高，在截屏结束后再恢复，因此需要提前缓存一份 `ScrollView` 的属性。



### 问题

Q：设置 `ScrollView` 偏移量时，用户看见的界面内容会发生偏移，怎么处理？

A：在设置偏移之前，使用 `UIView` 的 `func snapshotView(afterScreenUpdates afterUpdates: Bool) -> UIView?` 方法对当前看见的内容截屏（注意：此方法只会截屏已显示加载出来的内容，非全部），然后用 `addSubview()` 添加 `Scrollview.superView`上，盖在 UIScrollView 之上，这样用户看见的就是一个假的不会变动的`View`。



### 使用：

```swift
scrollView.swContentCapture { (image) in
	// TODO:                           
}
```



### 全部代码如下：

代码也有详细注释

```swif
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
```

