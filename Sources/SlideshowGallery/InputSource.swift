//
//  InputSource.swift
//  SlideshowGallery
//
//  Created by Jerwin Metromart on 11/27/24.
//

#if canImport(UIKit)
import UIKit
#endif

@MainActor
@objc public protocol InputSource {
    func load(to imageView: UIImageView, with callback: @escaping (_ image: UIImage?) -> Void)
    @objc optional func cancelLoad(on imageView: UIImageView)
}

@MainActor
@objcMembers
open class ImageSource: NSObject, InputSource {
    var image: UIImage
    
    public init(image: UIImage) {
        self.image = image
    }
    
    @available(*, deprecated, message: "Use `BundleImageSource` instead")
    public init?(imageString: String) {
        if let image = UIImage(named: imageString) {
            self.image = image
            super.init()
        } else {
            return nil
        }
    }
    
    public func load(to imageView: UIImageView, with callback: @escaping (UIImage?) -> Void) {
        imageView.image = image
        callback(image)
    }
}

@MainActor
@objcMembers
open class BundleImageSource: NSObject, InputSource {
    var imageString: String
    
    public init(imageString: String) {
        self.imageString = imageString
        super.init()
    }
    
    public func load(to imageView: UIImageView, with callback: @escaping (UIImage?) -> Void) {
        let image = UIImage(named: imageString)
        imageView.image = image
        callback(image)
    }
}

@MainActor
@objcMembers
open class FileImageSource: NSObject, InputSource {
    var path: String
    
    public init(path: String) {
        self.path = path
        super.init()
    }
    
    public func load(to imageView: UIImageView, with callback: @escaping (UIImage?) -> Void) {
        let image = UIImage(contentsOfFile: path)
        
        imageView.image = image
        callback(image)
    }
}
