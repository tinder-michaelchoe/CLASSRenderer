//
//  PageIndicatorNodeRenderer.swift
//  ScalsModules
//
//  Renders page indicator nodes to UIView.
//

import SCALS
import UIKit

/// Renders page indicator nodes to a UIView
public struct PageIndicatorNodeRenderer: UIKitNodeRendering {

    public static let nodeKind: RenderNodeKind = .pageIndicator

    public init() {}

    public func render(_ node: RenderNode, context: UIKitRenderContext) -> UIView {
        guard case .pageIndicator(let indicatorNode) = node else {
            return UIView()
        }

        let pageControl = PageIndicatorUIView(node: indicatorNode, stateStore: context.stateStore)
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        return pageControl
    }
}

// MARK: - Page Indicator UIView

private class PageIndicatorUIView: UIView {
    let node: PageIndicatorNode
    let stateStore: StateStore

    private var dotViews: [UIView] = []
    private let stackView: UIStackView

    init(node: PageIndicatorNode, stateStore: StateStore) {
        self.node = node
        self.stateStore = stateStore
        self.stackView = UIStackView()

        super.init(frame: .zero)

        setupStackView()
        updateDots()
        observeStateChanges()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupStackView() {
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        stackView.spacing = node.dotSpacing
        stackView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func updateDots() {
        let pageCount = getPageCount()
        let currentPage = getCurrentPage()

        // Remove existing dots
        dotViews.forEach { $0.removeFromSuperview() }
        dotViews.removeAll()

        // Create new dots
        for index in 0..<pageCount {
            let dotView = UIView()
            dotView.translatesAutoresizingMaskIntoConstraints = false
            dotView.layer.cornerRadius = node.dotSize / 2

            let isActive = index == currentPage
            dotView.backgroundColor = isActive ? node.currentDotColor.toUIKit : node.dotColor.toUIKit

            NSLayoutConstraint.activate([
                dotView.widthAnchor.constraint(equalToConstant: node.dotSize),
                dotView.heightAnchor.constraint(equalToConstant: node.dotSize)
            ])

            stackView.addArrangedSubview(dotView)
            dotViews.append(dotView)
        }
    }

    private func observeStateChanges() {
        // Observe state changes for currentPage and pageCount
        // This is a simplified implementation - in a full implementation,
        // you'd use Combine or similar to observe state changes
        // For now, we update once on init
    }

    private func getCurrentPage() -> Int {
        // Get current page from state
        return stateStore.get(node.currentPagePath) as? Int ?? 0
    }

    private func getPageCount() -> Int {
        if let staticCount = node.pageCountStatic {
            return staticCount
        }
        if let path = node.pageCountPath {
            return stateStore.get(path) as? Int ?? 5
        }
        return 5
    }
}
