//
//  ActivityIndicator.swift
//  SlideshowGallery
//
//  Created by Jerwin Metromart on 11/27/24.
//

#if canImport(UIKit)
import UIKit
#endif

@MainActor
public protocol ActivityIndicatorView {
    var view: UIView { get }
    func show()
    func hide()
}

public protocol ActivityIndicatorFactory {
    func create() -> ActivityIndicatorView
}

extension UIActivityIndicatorView: ActivityIndicatorView {
    public var view: UIView {
        return self
    }
    
    public func show() {
        startAnimating()
    }
    
    public func hide() {
        stopAnimating()
    }
}

@objcMembers
open class DefaultActivityIndicator: @preconcurrency ActivityIndicatorFactory {
    
    open var style: UIActivityIndicatorView.Style
    open var color: UIColor?
    
    public init(style: UIActivityIndicatorView.Style = .gray, color: UIColor? = nil) {
        self.style = style
        self.color = color
    }
    
    @MainActor public func create() -> any ActivityIndicatorView {
    #if swift(>=4.2)
        let activityIndicator = UIActivityIndicatorView(style: style)
    #else
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: style)
    #endif
        activityIndicator.color = color
        activityIndicator.hidesWhenStopped = true
        
        return activityIndicator
    }
    
    
}

