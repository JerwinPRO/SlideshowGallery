import UIKit

@objc
public protocol SlideshowGalleryDelegate: AnyObject {
    @objc optional func slideshowGallery(_ slideshowGallery: SlideshowGallery, didChangeCurrentPageTo page: Int)
    @objc optional func slideshowGalleryWillBeginDragging(_ slideshowGallery: SlideshowGallery)
    @objc optional func slideshowGalleryDidEndDragging(_ slideshowGallery: SlideshowGallery)
}

public enum PageControlPosition {
    case hidden
    case insideScrollView
    case underScrollView
    case custom(padding: CGFloat)
}

public enum ImagePreload {
    case fixed(offset: Int)
    case all
}

@objcMembers
open class SlideshowGallery: UIView {
    public let scrollView = UIScrollView()
    
    @available(*, deprecated, message: "Use pageIndicator instead")
    open var pageControl: UIPageControl? {
        if let pageIndicator = pageIndicator as? UIPageControl {
            return pageIndicator
        }
        fatalError("pageControl is not a UIPageControl")
    }
    
    open var activityIndicator: ActivityIndicatorFactory? {
        didSet {
            reloadScrollView()
        }
    }
    
    open var pageIndicator: PageIndicatorView? {
        didSet {
            oldValue?.view.removeFromSuperview()
            if let pageIndicator = pageIndicator {
                addSubview(pageIndicator.view)
                if let pageIndicator = pageIndicator as? UIControl {
                    pageIndicator.addTarget(self, action: #selector(pageControlValueChanged), for: .valueChanged)
                }
            }
            setNeedsLayout()
        }
    }
    
    open var pageIndicatorPosition: PageIndicatorPosition = PageIndicatorPosition() {
        didSet {
            setNeedsLayout()
        }
    }
    
    @available(*, deprecated, message: "Use pageIndicatorPosition instead")
    open var pageControlPosition: PageControlPosition = .insideScrollView {
        didSet {
            pageIndicator = UIPageControl()
            switch pageControlPosition {
            case .hidden:
                pageIndicator = nil
            case .insideScrollView:
                pageIndicatorPosition = PageIndicatorPosition(vertical: .bottom)
            case .underScrollView:
                pageIndicatorPosition = PageIndicatorPosition(vertical: .under)
            case .custom(let padding):
                pageIndicatorPosition = PageIndicatorPosition(vertical: .customUnder(padding: padding-30))
            }
        }
    }
    
    open fileprivate(set) var currentPage: Int = 0 {
        didSet {
            if oldValue != currentPage {
                pageIndicator?.page = currentPage
                currentPageChanged?(currentPage)
                delegate?.slideshowGallery?(self, didChangeCurrentPageTo: currentPage)
            }
        }
    }
    
    open weak var delegate: SlideshowGalleryDelegate?
    open var currentPageChanged: ((_ page: Int) -> Void)?
    open var willBeginDragging: (() -> Void)?
    open var didEndDragging: (() -> Void)?
    open var currentSlideshowItem: SlideshowGalleryItem? {
        if slideshowGalleryItems.count > scrollViewPage {
            return slideshowGalleryItems[scrollViewPage]
        } else {
            return nil
        }
    }
    open fileprivate(set) var scrollViewPage: Int = 0
    open fileprivate(set) var images = [InputSource]()
    open fileprivate(set) var slideshowGalleryItems = [SlideshowGalleryItem]()
    open var circular = true {
        didSet {
            if images.count > 0 {
                setImageInputs(images)
            }
        }
    }
    open var draggingEnabled = true {
        didSet {
            scrollView.isUserInteractionEnabled = draggingEnabled
        }
    }
    open var zoomEnabled = false {
        didSet {
            reloadScrollView()
        }
    }
    open var maximumScale: CGFloat = 2.0 {
        didSet {
            reloadScrollView()
        }
    }
    
    open var slideshowInterval = 0.0 {
        didSet {
            slideshowGalleryTimer?.invalidate()
            slideshowGalleryTimer = nil
            setTimerIfNeeded()
        }
    }
    
    open var preload = ImagePreload.all
    open var contentScaleMode: UIView.ContentMode = UIView.ContentMode.scaleAspectFit {
        didSet {
            for view in slideshowGalleryItems {
                view.imageView.contentMode = contentScaleMode
            }
        }
    }
    
    fileprivate var slideshowGalleryTimer: Timer?
    fileprivate var scrollViewImages = [InputSource]()
    fileprivate var isAnimating: Bool = false
    
    fileprivate(set) var slideshowGalleryTransitioningDelegate: ZoomAnimatedTransitioningDelegate?
    
    private var primaryVisiblePage: Int {
        return scrollView.frame.size.width > 0 ? Int(scrollView.contentOffset.x + scrollView.frame.size.width / 2) / Int(scrollView.frame.size.width) : 0
    }
    
    // MARK: - Life cycle
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    convenience init() {
        self.init(frame: CGRect.zero)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    fileprivate func initialize() {
        autoresizesSubviews = true
        clipsToBounds = true
        if #available(iOS 13.0, *) {
            backgroundColor = .systemBackground
        }
        
        // scroll view configuration
        scrollView.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height - 50.0)
        scrollView.delegate = self
        scrollView.isPagingEnabled = true
        scrollView.bounces = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.autoresizingMask = autoresizingMask
        if UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft {
            scrollView.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
        }
        
        if #available(iOS 11.0, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        }
        addSubview(scrollView)
        
        if pageIndicator == nil {
            pageIndicator = UIPageControl()
        }
        
        setTimerIfNeeded()
        layoutScrollView()
    }
    
    open override func removeFromSuperview() {
        super.removeFromSuperview()
        pauseTimer()
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        // fixes the case when automaticallyAdjustsScrollViewInsets on parenting view controller is set to true
        scrollView.contentInset = UIEdgeInsets.zero
        
        layoutPageControl()
        layoutScrollView()
    }
    
    open func layoutPageControl() {
        if let pageIndicatorView = pageIndicator?.view {
            pageIndicatorView.isHidden = images.count < 2
            
            var edgeInsets: UIEdgeInsets = UIEdgeInsets.zero
            if #available(iOS 11.0, *) {
                edgeInsets = safeAreaInsets
            }
            
            pageIndicatorView.sizeToFit()
            pageIndicatorView.frame = pageIndicatorPosition.indicatorFrame(for: frame, indicatorSize: pageIndicatorView.frame.size, edgeInsets: edgeInsets)
        }
    }
    
    /// updates frame of the scroll view and its inner items
    func layoutScrollView() {
        let pageIndicatorViewSize = pageIndicator?.view.frame.size
        let scrollViewBottomPadding = pageIndicatorViewSize.flatMap { pageIndicatorPosition.underPadding(for: $0) } ?? 0
        
        scrollView.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height - scrollViewBottomPadding)
        scrollView.contentSize = CGSize(width: scrollView.frame.size.width * CGFloat(scrollViewImages.count), height: scrollView.frame.size.height)
        
        for (index, view) in slideshowGalleryItems.enumerated() {
            if !view.zoomInInitially {
                view.zoomOut()
            }
            view.frame = CGRect(x: scrollView.frame.size.width * CGFloat(index), y: 0, width: scrollView.frame.size.width, height: scrollView.frame.size.height)
        }
        
        setScrollViewPage(scrollViewPage, animated: false)
    }
    
    /// reloads scroll view with latest slideshow items
    func reloadScrollView() {
        // remove previous slideshow items
        for view in slideshowGalleryItems {
            view.removeFromSuperview()
        }
        slideshowGalleryItems = []
        
        var i = 0
        for image in scrollViewImages {
            let item = SlideshowGalleryItem(image: image, zoomEnabled: zoomEnabled, activityIndicator: activityIndicator?.create(), maximumScale: maximumScale)
            item.imageView.contentMode = contentScaleMode
            slideshowGalleryItems.append(item)
            scrollView.addSubview(item)
            i += 1
        }
        
        if circular && (scrollViewImages.count > 1) {
            scrollViewPage = 1
            scrollView.scrollRectToVisible(CGRect(x: scrollView.frame.size.width, y: 0, width: scrollView.frame.size.width, height: scrollView.frame.size.height), animated: false)
        } else {
            scrollViewPage = 0
        }
        
        loadImages(for: scrollViewPage)
    }
    
    private func loadImages(for scrollViewPage: Int) {
        let totalCount = slideshowGalleryItems.count
        
        for i in 0..<totalCount {
            let item = slideshowGalleryItems[i]
            switch preload {
            case .all:
                item.loadImage()
            case .fixed(let offset):
                // if circular scrolling is enabled and image is on the edge, a helper ("dummy") image on the other side needs to be loaded too
                let circularEdgeLoad = circular && ((scrollViewPage == 0 && i == totalCount-3) || (scrollViewPage == 0 && i == totalCount-2) || (scrollViewPage == totalCount-2 && i == 1))
                
                // load image if page is in range of loadOffset, else release image
                let shouldLoad = abs(scrollViewPage-i) <= offset || abs(scrollViewPage-i) > totalCount-offset || circularEdgeLoad
                shouldLoad ? item.loadImage() : item.releaseImage()
            }
        }
    }
    
    // MARK: - Image setting
    
    open func setImageInputs(_ inputs: [InputSource]) {
        images = inputs
        pageIndicator?.numberOfPages = inputs.count
        
        // in circular mode we add dummy first and last image to enable smooth scrolling
        if circular && images.count > 1 {
            var scImages = [InputSource]()
            
            if let last = images.last {
                scImages.append(last)
            }
            scImages += images
            if let first = images.first {
                scImages.append(first)
            }
            
            scrollViewImages = scImages
        } else {
            scrollViewImages = images
        }
        
        reloadScrollView()
        layoutScrollView()
        layoutPageControl()
        setTimerIfNeeded()
    }
    
    // MARK: paging methods
    
    open func setCurrentPage(_ newPage: Int, animated: Bool) {
        var pageOffset = newPage
        if circular && (scrollViewImages.count > 1) {
            pageOffset += 1
        }
        
        setScrollViewPage(pageOffset, animated: animated)
    }
    
    open func setScrollViewPage(_ newScrollViewPage: Int, animated: Bool) {
        if scrollViewPage < scrollViewImages.count {
            scrollView.scrollRectToVisible(CGRect(x: scrollView.frame.size.width * CGFloat(newScrollViewPage), y: 0, width: scrollView.frame.size.width, height: scrollView.frame.size.height), animated: animated)
            setCurrentPageForScrollViewPage(newScrollViewPage)
            if animated {
                isAnimating = true
            }
        }
    }
    
    fileprivate func setTimerIfNeeded() {
        if slideshowInterval > 0 && scrollViewImages.count > 1 && slideshowGalleryTimer == nil {
            slideshowGalleryTimer = Timer.scheduledTimer(timeInterval: slideshowInterval, target: self, selector: #selector(SlideshowGallery.slideshowTick(_:)), userInfo: nil, repeats: true)
        }
    }
    
    @objc func slideshowTick(_ timer: Timer) {
        let page = scrollView.frame.size.width > 0 ? Int(scrollView.contentOffset.x / scrollView.frame.size.width) : 0
        var nextPage = page + 1
        
        if !circular && page == scrollViewImages.count - 1 {
            nextPage = 0
        }
        
        setScrollViewPage(nextPage, animated: true)
    }
    
    fileprivate func setCurrentPageForScrollViewPage(_ page: Int) {
        if scrollViewPage != page {
            // current page has changed, zoom out this image
            if slideshowGalleryItems.count > scrollViewPage {
                slideshowGalleryItems[scrollViewPage].zoomOut()
            }
        }
        
        if page != scrollViewPage {
            loadImages(for: page)
        }
        scrollViewPage = page
        currentPage = currentPageForScrollViewPage(page)
    }
    
    fileprivate func currentPageForScrollViewPage(_ page: Int) -> Int {
        if circular {
            if page == 0 {
                // first page contains the last image
                return Int(images.count) - 1
            } else if page == scrollViewImages.count - 1 {
                // last page contains the first image
                return 0
            } else {
                return page - 1
            }
        } else {
            return page
        }
    }
    
    fileprivate func restartTimer() {
        if slideshowGalleryTimer?.isValid != nil {
            slideshowGalleryTimer?.invalidate()
            slideshowGalleryTimer = nil
        }
        
        setTimerIfNeeded()
    }
    
    /// Stops slideshow timer
    open func pauseTimer() {
        slideshowGalleryTimer?.invalidate()
        slideshowGalleryTimer = nil
    }
    
    /// Restarts slideshow timer
    open func unpauseTimer() {
        setTimerIfNeeded()
    }
    
    @available(*, deprecated, message: "use pauseTimer instead")
    open func pauseTimerIfNeeded() {
        pauseTimer()
    }
    
    @available(*, deprecated, message: "use unpauseTimer instead")
    open func unpauseTimerIfNeeded() {
        unpauseTimer()
    }
    
    open func nextPage(animated: Bool) {
        if !circular && currentPage == images.count - 1 {
            return
        }
        if isAnimating {
            return
        }
        
        setCurrentPage(currentPage + 1, animated: animated)
        restartTimer()
    }
    
    open func previousPage(animated: Bool) {
        if !circular && currentPage == 0 {
            return
        }
        if isAnimating {
            return
        }
        
        let newPage = scrollViewPage > 0 ? scrollViewPage - 1 : scrollViewImages.count - 3
        setScrollViewPage(newPage, animated: animated)
        restartTimer()
    }
    
    @discardableResult
    open func presentFullScreenController(from controller: UIViewController, completion: (() -> Void)? = nil) -> FullScreenSlideshowViewController {
        let fullscreen = FullScreenSlideshowViewController()
        fullscreen.pageSelected = {[weak self] (page: Int) in
            self?.setCurrentPage(page, animated: false)
        }
        
        fullscreen.initialPage = currentPage
        fullscreen.inputs = images
        slideshowGalleryTransitioningDelegate = ZoomAnimatedTransitioningDelegate(slideshowView: self, slideshowController: fullscreen)
        fullscreen.transitioningDelegate = slideshowGalleryTransitioningDelegate
        fullscreen.modalPresentationStyle = .custom
        controller.present(fullscreen, animated: true, completion: completion)
        
        return fullscreen
    }
    
    @objc private func pageControlValueChanged() {
        if let currentPage = pageIndicator?.page {
            setCurrentPage(currentPage, animated: true)
        }
    }
}

extension SlideshowGallery: UIScrollViewDelegate {
    
    open func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        restartTimer()
        willBeginDragging?()
        delegate?.slideshowGalleryWillBeginDragging?(self)
    }
    
    open func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        setCurrentPageForScrollViewPage(primaryVisiblePage)
        didEndDragging?()
        delegate?.slideshowGalleryDidEndDragging?(self)
    }
    
    open func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if circular && (scrollViewImages.count > 1) {
            let regularContentOffset = scrollView.frame.size.width * CGFloat(images.count)
            
            if scrollView.contentOffset.x >= scrollView.frame.size.width * CGFloat(images.count + 1) {
                scrollView.contentOffset = CGPoint(x: scrollView.contentOffset.x - regularContentOffset, y: 0)
            } else if scrollView.contentOffset.x <= 0 {
                scrollView.contentOffset = CGPoint(x: scrollView.contentOffset.x + regularContentOffset, y: 0)
            }
        }
        
        // Updates the page indicator as the user scrolls (#204). Not called when not dragging to prevent flickers
        // when interacting with PageControl directly (#376).
        if scrollView.isDragging {
            pageIndicator?.page = currentPageForScrollViewPage(primaryVisiblePage)
        }
    }
    
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        isAnimating = false
    }
}


