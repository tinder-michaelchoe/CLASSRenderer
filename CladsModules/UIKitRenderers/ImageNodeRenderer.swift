//
//  ImageNodeRenderer.swift
//  CladsModules
//
//  Renders ImageNode to UIImageView.
//

import CLADS
import UIKit

/// Renders image nodes to UIImageView
public struct ImageNodeRenderer: UIKitNodeRendering {

    public static let nodeKind: RenderNodeKind = .image

    public init() {}

    public func render(_ node: RenderNode, context: UIKitRenderContext) -> UIView {
        guard case .image(let imageNode) = node else {
            return UIView()
        }

        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false

        // Set placeholder while loading
        let placeholderImage: UIImage? = {
            switch imageNode.placeholder ?? .system(name: "photo") {
            case .system(let name):
                return UIImage(systemName: name)
            case .asset(let name):
                return UIImage(named: name)
            case .url, .statePath:
                return UIImage(systemName: "photo")
            }
        }()
        
        switch imageNode.source {
        case .system(let name):
            imageView.image = UIImage(systemName: name)
        case .asset(let name):
            imageView.image = UIImage(named: name)
        case .url(let url):
            imageView.image = placeholderImage
            loadImageAsync(from: url, into: imageView, placeholder: placeholderImage)
        case .statePath:
            // statePath should be resolved to a URL by the resolver before reaching here
            // If it reaches here, show placeholder
            imageView.image = placeholderImage
        }

        if let width = imageNode.style.width {
            imageView.widthAnchor.constraint(equalToConstant: width).isActive = true
        }
        if let height = imageNode.style.height {
            imageView.heightAnchor.constraint(equalToConstant: height).isActive = true
        }

        return imageView
    }

    private func loadImageAsync(from url: URL, into imageView: UIImageView, placeholder: UIImage?) {
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let image = UIImage(data: data) {
                    await MainActor.run {
                        imageView.image = image
                    }
                }
            } catch {
                print("Failed to load image from \(url): \(error)")
                await MainActor.run {
                    imageView.image = UIImage(systemName: "questionmark.circle")
                }
            }
        }
    }
}
