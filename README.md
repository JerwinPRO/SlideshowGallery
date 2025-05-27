# Product Details Slideshow Gallery

[![Swift Version][swift-image]][swift-url]
[![License][license-image]][license-url]
[![Codebeat Badge][codebeat-image]][codebeat-url]

**SlideshowGallery** is a customizable Swift library for creating a product image slideshow. It features paginated scrolling, an automatic timer, and a full-screen image viewer, making it ideal for e-commerce and product showcase applications.

## Features

- **Paginated Scrolling:** Seamlessly swipe through images with pagination indicators.
- **Timer-Based Sliding:** Automatically transition between images at customizable intervals.
- **Full-Screen Viewer:** Tap on any image to view it in a full-screen interactive mode.
- **Customizable UI:** Tailor the look and feel to match your app's design.
- **Lightweight:** Minimal dependencies for easy integration.

---

## Installation

### Swift Package Manager (Recommended)
Add the following to your `Package.swift` file:

```swift
import PackageDescription

let package = Package(
    dependencies: [
        .package(url: "https://github.com/JerwinPRO/SlideshowGallery.git", from: "0.0.1")
    ]
)
```

Or integrate it directly in Xcode:
1. Go to **File > Add Packages**.
2. Enter the repository URL: `https://github.com/JerwinPRO/SlideshowGallery.git`.
3. Select the version rule and add it to your project.

---

## Usage

### Basic Setup

1. Import the library into your Swift file:
    ```swift
    import SlideshowGallery
    ```

2. Initialize and configure the slideshow:
    ```swift
    let slideshow = SlideshowGallery()
    slideshow.images = [
        UIImage(named: "image1")!,
        UIImage(named: "image2")!,
        UIImage(named: "image3")!
    ]
    slideshow.autoScrollInterval = 3.0 // Set auto-scroll every 3 seconds
    view.addSubview(slideshow)
    ```

3. Add constraints or frame settings to position the slideshow:
    ```swift
    slideshow.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        slideshow.leadingAnchor.constraint(equalTo: view.leadingAnchor),
        slideshow.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        slideshow.topAnchor.constraint(equalTo: view.topAnchor, constant: 100),
        slideshow.heightAnchor.constraint(equalToConstant: 200)
    ])
    ```

### Full-Screen Viewer

Enable the full-screen viewer with a tap gesture:
```swift
slideshow.enableFullScreenViewer = true
```

---

## Development Setup

To set up the project for development:

1. Clone the repository:
    ```sh
    git clone https://github.com/JerwinPRO/SlideshowGallery.git
    cd SlideshowGallery
    ```

2. Install dependencies:
    ```sh
    make install
    ```

3. Run the test suite:
    ```sh
    make test
    ```

---

## Contributing

Contributions are welcome! To contribute:

1. Fork the repository.
2. Create a new branch for your feature or bug fix:
    ```sh
    git checkout -b feature/your-feature-name
    ```
3. Commit your changes:
    ```sh
    git commit -m "Add your commit message here"
    ```
4. Push to your branch:
    ```sh
    git push origin feature/your-feature-name
    ```
5. Create a pull request on GitHub.

---

## License

Distributed under the **MIT License**. See `LICENSE` for more information.

---

## Meta

**Author**: [JerwinPRO](https://github.com/JerwinPRO)  
**Contact**: project@jerwinpastoral.com

For more information, visit the [GitHub repository](https://github.com/JerwinPRO/SlideshowGallery).

---

[swift-image]: https://img.shields.io/badge/swift-5.0-orange.svg
[swift-url]: https://swift.org/
[license-image]: https://img.shields.io/badge/License-MIT-blue.svg
[license-url]: LICENSE
[codebeat-image]: https://codebeat.co/badges/c19b47ea-2f9d-45df-8458-b2d952fe9dad
[codebeat-url]: https://codebeat.co/projects/github-com-vsouza-awesomeios-com
