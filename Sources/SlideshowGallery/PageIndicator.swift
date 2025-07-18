//
//  PageIndicator.swift
//  SlideshowGallery
//
//  Created by Jerwin Metromart on 11/27/24.
//
#if canImport(UIKit)
import UIKit
#endif

@MainActor
public protocol PageIndicatorView: AnyObject {
    var view: UIView { get }
    var page: Int { get set }
    var numberOfPages: Int { get set }
}

extension UIPageControl: PageIndicatorView {
    public var view: UIView {
        return self
    }

    public var page: Int {
        get {
            return currentPage
        }
        set {
            currentPage = newValue
        }
    }

    open override func sizeToFit() {
        var frame = self.frame
        frame.size = size(forNumberOfPages: numberOfPages)
        frame.size.height = 30
        self.frame = frame
    }

    public static func withSlideshowColors() -> UIPageControl {
        let pageControl = UIPageControl()

        if #available(iOS 13.0, *) {
            pageControl.currentPageIndicatorTintColor = UIColor { traits in
                traits.userInterfaceStyle == .dark ? .white : .lightGray
            }
        } else {
            pageControl.currentPageIndicatorTintColor = .lightGray
        }
        
        if #available(iOS 13.0, *) {
            pageControl.pageIndicatorTintColor = UIColor { traits in
                traits.userInterfaceStyle == .dark ? .systemGray : .black
            }
        } else {
            pageControl.pageIndicatorTintColor = .black
        }

        return pageControl
    }
}

public class LabelPageIndicator: UILabel, PageIndicatorView {
    public var view: UIView {
        return self
    }

    public var numberOfPages: Int = 0 {
        didSet {
            updateLabel()
        }
    }

    public var page: Int = 0 {
        didSet {
            updateLabel()
        }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }

    private func initialize() {
        self.textAlignment = .center
    }

    private func updateLabel() {
        text = "\(page+1)/\(numberOfPages)"
    }

    public override func sizeToFit() {
        let maximumString = String(repeating: "8", count: numberOfPages) as NSString
        self.frame.size = maximumString.size(withAttributes: [.font: font as Any])
    }
}
