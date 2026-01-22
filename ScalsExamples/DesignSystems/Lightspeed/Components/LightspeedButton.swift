//
//  LightspeedButton.swift
//  ScalsExamples
//
//  A pure SwiftUI button component for the Lightspeed design system.
//  Handles dark mode internally via @Environment(\.colorScheme).
//  No SCALS dependency - SCALS wraps this for action integration.
//

import SwiftUI

/// Pure Lightspeed button - no SCALS dependency.
/// Handles dark mode internally via @Environment.
public struct LightspeedButton: View {
    
    // MARK: - Style Variants
    
    public enum Style {
        case primary
        case secondary
        case destructive
    }
    
    // MARK: - Properties
    
    let label: String
    let style: Style
    let isLoading: Bool
    let isDisabled: Bool
    let onTap: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed = false
    
    // MARK: - Initialization
    
    public init(
        label: String,
        style: Style = .primary,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        onTap: @escaping () -> Void
    ) {
        self.label = label
        self.style = style
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.onTap = onTap
    }
    
    // MARK: - Body
    
    public var body: some View {
        Button(action: {
            guard !isDisabled && !isLoading else { return }
            onTap()
        }) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: foregroundColor))
                        .scaleEffect(0.8)
                }
                Text(label)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(foregroundColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 24)
            .background(backgroundColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: style == .secondary ? 1 : 0)
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .opacity(isDisabled ? 0.6 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled || isLoading)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isDisabled && !isLoading {
                        isPressed = true
                    }
                }
                .onEnded { _ in isPressed = false }
        )
    }
    
    // MARK: - Dark Mode Adaptive Colors
    
    private var backgroundColor: Color {
        switch (style, colorScheme) {
        case (.primary, .light):     return Color(hex: "#6366F1")  // Indigo
        case (.primary, .dark):      return Color(hex: "#818CF8")  // Lighter indigo
        case (.secondary, .light):   return Color(hex: "#F3F4F6")  // Light gray
        case (.secondary, .dark):    return Color(hex: "#374151")  // Dark gray
        case (.destructive, .light): return Color(hex: "#EF4444")  // Red
        case (.destructive, .dark):  return Color(hex: "#F87171")  // Lighter red
        @unknown default:            return Color(hex: "#6366F1")
        }
    }
    
    private var foregroundColor: Color {
        switch (style, colorScheme) {
        case (.primary, _):          return .white
        case (.secondary, .light):   return Color(hex: "#374151")
        case (.secondary, .dark):    return Color(hex: "#F9FAFB")
        case (.destructive, _):      return .white
        @unknown default:            return .white
        }
    }
    
    private var borderColor: Color {
        colorScheme == .dark ? Color(hex: "#4B5563") : Color(hex: "#D1D5DB")
    }
}

// MARK: - Preview

#Preview("Lightspeed Button Styles") {
    VStack(spacing: 16) {
        LightspeedButton(label: "Primary Button", style: .primary) {}
        LightspeedButton(label: "Secondary Button", style: .secondary) {}
        LightspeedButton(label: "Destructive Button", style: .destructive) {}
        LightspeedButton(label: "Loading...", style: .primary, isLoading: true) {}
        LightspeedButton(label: "Disabled", style: .primary, isDisabled: true) {}
    }
    .padding()
}

// MARK: - Hex Color Extension (Local)

/// Local hex color initializer to keep LightspeedButton independent from SCALS.
private extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
