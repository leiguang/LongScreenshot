//
//  TableViewController.swift
//  LongScreenshot
//
//  Created by Guang Lei on 2019/9/19.
//  Copyright © 2019 Guang Lei. All rights reserved.
//

import UIKit
import Photos

class TableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    @IBAction func tapButton(_ sender: Any) {
        
        guard let image = createImage(from: tableView) else {
            print("create image failure")
            return
        }
        
        // Info.plist: NSPhotoLibraryUsageDescription
        saveImageToPhotoLibrary(image: image)
        
        // Info.plist: Privacy - Photo Library Additions Usage Description
//        UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
        
        
        
                
        // Or use `Screenshot+UIScrollViewExtension.swift`
//        tableView.swContentCapture { (image) in
//            // TODO:
//        }
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: Any) {
        if let error = error {
            print(error)
        } else {
            print("success")
        }
    }
    
    func createImage(from scrollView: UIScrollView) -> UIImage? {
        let savedFrame = scrollView.frame
        let savedContentOffset = scrollView.contentOffset
        scrollView.frame = CGRect(origin: .zero, size: scrollView.contentSize)
        
        
        let size = scrollView.contentSize
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        guard let ctx = UIGraphicsGetCurrentContext() else {
            return nil
        }
        scrollView.layer.render(in: ctx)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        scrollView.contentOffset = savedContentOffset
        scrollView.frame = savedFrame
        
        return image
    }
    
    func saveImageToPhotoLibrary(image: UIImage) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }) { (isSuccess, error) in
            if let error = error {
                print("failure: \(error.localizedDescription)")
            } else {
                print("success")
            }
        }
    }
}
