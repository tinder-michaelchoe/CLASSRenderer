//
//  IRTypeTests.swift
//  CLADSTests
//
//  Unit tests for platform-agnostic IR types.
//

import Foundation
import Testing
@testable import CLADS

// MARK: - IR.Color Tests

struct IRColorTests {
    
    @Test func initializesWithRGBA() {
        let color = IR.Color(red: 1.0, green: 0.5, blue: 0.25, alpha: 0.8)
        
        #expect(color.red == 1.0)
        #expect(color.green == 0.5)
        #expect(color.blue == 0.25)
        #expect(color.alpha == 0.8)
    }
    
    @Test func initializesWithDefaultAlpha() {
        let color = IR.Color(red: 1.0, green: 0.5, blue: 0.25)
        
        #expect(color.alpha == 1.0)
    }
    
    @Test func initializesFromHex6() {
        let color = IR.Color(hex: "#FF8040")
        
        #expect(color.red == 1.0)
        #expect(abs(color.green - 0.502) < 0.01)
        #expect(abs(color.blue - 0.251) < 0.01)
        #expect(color.alpha == 1.0)
    }
    
    @Test func initializesFromHex8() {
        let color = IR.Color(hex: "#80FF8040")
        
        #expect(abs(color.alpha - 0.502) < 0.01)
        #expect(color.red == 1.0)
        #expect(abs(color.green - 0.502) < 0.01)
        #expect(abs(color.blue - 0.251) < 0.01)
    }
    
    @Test func initializesFromHex3() {
        let color = IR.Color(hex: "#F84")
        
        #expect(color.red == 1.0)
        #expect(abs(color.green - 0.533) < 0.01)
        #expect(abs(color.blue - 0.267) < 0.01)
    }
    
    @Test func handlesHexWithoutHash() {
        let color = IR.Color(hex: "FF0000")
        
        #expect(color.red == 1.0)
        #expect(color.green == 0.0)
        #expect(color.blue == 0.0)
    }
    
    @Test func isEquatable() {
        let color1 = IR.Color(red: 1.0, green: 0.5, blue: 0.25, alpha: 1.0)
        let color2 = IR.Color(red: 1.0, green: 0.5, blue: 0.25, alpha: 1.0)
        let color3 = IR.Color(red: 0.5, green: 0.5, blue: 0.25, alpha: 1.0)
        
        #expect(color1 == color2)
        #expect(color1 != color3)
    }
    
    @Test func isCodable() throws {
        let original = IR.Color(red: 0.5, green: 0.25, blue: 0.75, alpha: 0.9)

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(IR.Color.self, from: encoded)

        #expect(decoded == original)
    }

    @Test func initializesFromRGBAOpaque() {
        let color = IR.Color(hex: "rgba(255, 128, 64, 1.0)")

        #expect(color.red == 1.0)
        #expect(abs(color.green - 0.502) < 0.01)
        #expect(abs(color.blue - 0.251) < 0.01)
        #expect(color.alpha == 1.0)
    }

    @Test func initializesFromRGBATranslucent() {
        let color = IR.Color(hex: "rgba(0, 122, 255, 0.1)")

        #expect(color.red == 0.0)
        #expect(abs(color.green - 0.478) < 0.01)
        #expect(color.blue == 1.0)
        #expect(color.alpha == 0.1)
    }

    @Test func initializesFromRGBASemiTransparent() {
        let color = IR.Color(hex: "rgba(255, 255, 255, 0.15)")

        #expect(color.red == 1.0)
        #expect(color.green == 1.0)
        #expect(color.blue == 1.0)
        #expect(color.alpha == 0.15)
    }

    @Test func initializesFromRGBAWithSpaces() {
        let color = IR.Color(hex: "rgba( 128 , 64 , 32 , 0.5 )")

        #expect(abs(color.red - 0.502) < 0.01)
        #expect(abs(color.green - 0.251) < 0.01)
        #expect(abs(color.blue - 0.125) < 0.01)
        #expect(color.alpha == 0.5)
    }

    @Test func initializesFromRGBACaseInsensitive() {
        let color1 = IR.Color(hex: "rgba(255, 0, 0, 1.0)")
        let color2 = IR.Color(hex: "RGBA(255, 0, 0, 1.0)")

        #expect(color1 == color2)
    }
}

// MARK: - IR.EdgeInsets Tests

struct IREdgeInsetsTests {
    
    @Test func initializesWithAllEdges() {
        let insets = IR.EdgeInsets(top: 10, leading: 20, bottom: 30, trailing: 40)
        
        #expect(insets.top == 10)
        #expect(insets.leading == 20)
        #expect(insets.bottom == 30)
        #expect(insets.trailing == 40)
    }
    
    @Test func hasZeroConstant() {
        let zero = IR.EdgeInsets.zero
        
        #expect(zero.top == 0)
        #expect(zero.leading == 0)
        #expect(zero.bottom == 0)
        #expect(zero.trailing == 0)
    }
    
    @Test func isEquatable() {
        let insets1 = IR.EdgeInsets(top: 10, leading: 20, bottom: 30, trailing: 40)
        let insets2 = IR.EdgeInsets(top: 10, leading: 20, bottom: 30, trailing: 40)
        let insets3 = IR.EdgeInsets(top: 5, leading: 20, bottom: 30, trailing: 40)
        
        #expect(insets1 == insets2)
        #expect(insets1 != insets3)
    }
}

// MARK: - IR.Alignment Tests

struct IRAlignmentTests {
    
    @Test func hasPresetAlignments() {
        #expect(IR.Alignment.center.horizontal == .center)
        #expect(IR.Alignment.center.vertical == .center)
        
        #expect(IR.Alignment.topLeading.horizontal == .leading)
        #expect(IR.Alignment.topLeading.vertical == .top)
        
        #expect(IR.Alignment.bottomTrailing.horizontal == .trailing)
        #expect(IR.Alignment.bottomTrailing.vertical == .bottom)
    }
    
    @Test func initializesWithComponents() {
        let alignment = IR.Alignment(horizontal: .trailing, vertical: .top)
        
        #expect(alignment.horizontal == .trailing)
        #expect(alignment.vertical == .top)
    }
    
    @Test func isEquatable() {
        let a1 = IR.Alignment(horizontal: .leading, vertical: .top)
        let a2 = IR.Alignment(horizontal: .leading, vertical: .top)
        let a3 = IR.Alignment(horizontal: .center, vertical: .top)
        
        #expect(a1 == a2)
        #expect(a1 != a3)
    }
}

// MARK: - IR.UnitPoint Tests

struct IRUnitPointTests {
    
    @Test func hasPresetPoints() {
        #expect(IR.UnitPoint.zero.x == 0)
        #expect(IR.UnitPoint.zero.y == 0)
        
        #expect(IR.UnitPoint.center.x == 0.5)
        #expect(IR.UnitPoint.center.y == 0.5)
        
        #expect(IR.UnitPoint.top.x == 0.5)
        #expect(IR.UnitPoint.top.y == 0)
        
        #expect(IR.UnitPoint.bottom.x == 0.5)
        #expect(IR.UnitPoint.bottom.y == 1)
        
        #expect(IR.UnitPoint.leading.x == 0)
        #expect(IR.UnitPoint.leading.y == 0.5)
        
        #expect(IR.UnitPoint.trailing.x == 1)
        #expect(IR.UnitPoint.trailing.y == 0.5)
    }
    
    @Test func initializesWithCoordinates() {
        let point = IR.UnitPoint(x: 0.3, y: 0.7)
        
        #expect(point.x == 0.3)
        #expect(point.y == 0.7)
    }
    
    @Test func isEquatable() {
        let p1 = IR.UnitPoint(x: 0.5, y: 0.5)
        let p2 = IR.UnitPoint(x: 0.5, y: 0.5)
        let p3 = IR.UnitPoint(x: 0.3, y: 0.5)
        
        #expect(p1 == p2)
        #expect(p1 != p3)
    }
}

// MARK: - IR.ColorScheme Tests

struct IRColorSchemeTests {
    
    @Test func hasLightDarkSystem() {
        let light: IR.ColorScheme = .light
        let dark: IR.ColorScheme = .dark
        let system: IR.ColorScheme = .system
        
        #expect(light.rawValue == "light")
        #expect(dark.rawValue == "dark")
        #expect(system.rawValue == "system")
    }
}

// MARK: - IR.FontWeight Tests

struct IRFontWeightTests {
    
    @Test func hasAllWeights() {
        let weights: [IR.FontWeight] = [
            .ultraLight, .thin, .light, .regular, .medium,
            .semibold, .bold, .heavy, .black
        ]
        
        #expect(weights.count == 9)
    }
    
    @Test func isCodable() throws {
        let original: IR.FontWeight = .semibold
        
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(IR.FontWeight.self, from: encoded)
        
        #expect(decoded == original)
    }
}

// MARK: - IR.TextAlignment Tests

struct IRTextAlignmentTests {
    
    @Test func hasAllAlignments() {
        let alignments: [IR.TextAlignment] = [.leading, .center, .trailing]
        
        #expect(alignments.count == 3)
    }
    
    @Test func isCodable() throws {
        let original: IR.TextAlignment = .center
        
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(IR.TextAlignment.self, from: encoded)
        
        #expect(decoded == original)
    }
}
