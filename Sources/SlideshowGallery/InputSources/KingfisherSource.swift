//
//  KingfisherSource.swift
//  SlideshowGallery
//
//  Created by Jerwin Metromart on 11/28/24.
//

import UIKit
#if SWIFT_PACKAGE
import SlideshowGallery
#endif
import Kingfisher

public class KingfisherSource: NSObject, InputSource {
    public var url: URL
    public var placeholder: UIImage?
    public var options: KingfisherOptionsInfo?

    public init(url: URL, placeholder: UIImage? = nil, options: KingfisherOptionsInfo? = nil) {
        self.url = url
        self.placeholder = placeholder
        self.options = options
        super.init()
    }

    public init?(urlString: String, placeholder: UIImage? = nil, options: KingfisherOptionsInfo? = nil) {
        if let validUrl = URL(string: urlString) {
            self.url = validUrl
            self.placeholder = placeholder
            self.options = options
            super.init()
        } else {
            return nil
        }
    }

    @MainActor @objc
    public func load(to imageView: UIImageView, with callback: @escaping (UIImage?) -> Void) {
        imageView.kf.setImage(with: self.url, placeholder: self.placeholder, options: self.options, progressBlock: nil) { result in
            switch result {
            case .success(let image):
                callback(image.image)
            case .failure:
                callback(self.placeholder)
            }
        }
    }

    @MainActor
    public func cancelLoad(on imageView: UIImageView) {
        imageView.kf.cancelDownloadTask()
    }
}
