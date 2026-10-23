//
//  Theme.swift
//  StrokeSense
//
//  Design tokens. Colors live in Assets.xcassets as light/dark color sets and are
//  available as generated symbols (e.g. `.brandPrimary`, `.inkMuted`):
//
//  - AccentColor   Tint for text, links and icons on surfaces (lighter in dark mode).
//  - BrandPrimary  Fills that carry white text: buttons, user chat bubbles, hero cards.
//  - BrandSoft     Quiet backgrounds behind brand-tinted icons.
//  - Emergency     Reserved for emergency guidance and BE FAST. Never decorative.
//  - Success       Correct quiz answers.
//  - Ink / InkMuted  Primary and secondary text.
//  - Surface / Card / Hairline  Screen background, raised content, 0.5pt borders.
//
//  Elevation comes from Surface vs Card plus a hairline, never from drop shadows.
//

import SwiftUI

enum Spacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let s: CGFloat = 12
    static let m: CGFloat = 16
    static let l: CGFloat = 20
    static let xl: CGFloat = 28
    static let xxl: CGFloat = 40
}

/// Corner radii. Always used with `style: .continuous`.
enum Radius {
    static let control: CGFloat = 12
    static let card: CGFloat = 20
    static let hero: CGFloat = 28
}

/// Typography: one family, SF Pro Rounded (applied app-wide with `.fontDesign(.rounded)`),
/// always from Dynamic Type text styles. Hierarchy comes from size and weight only:
/// no serif pairing, no uppercase or letter-spaced labels, and no small "eyebrow" labels above titles.
///
/// Icons: SF Symbols only. They inherit the weight and size of adjacent text, so they stay
/// consistent with the type. Symbols sit directly on the surface, never inside colored tiles
/// or circles. Default to solid monochrome in the accent color; use palette rendering for
/// glyphs over media (play button) and symbol effects for moments of feedback.
extension Font {
    /// Screen and hero headlines.
    static let heroTitle = Font.largeTitle.weight(.heavy)
    /// Card and sheet headlines.
    static let cardTitle = Font.title2.weight(.bold)
    /// Smaller card headlines.
    static let cardHeadline = Font.title3.weight(.bold)
    /// The BE FAST letters.
    static let letterMark = Font.largeTitle.weight(.black)
    /// Numbers such as scores and counts.
    static let statNumber = Font.system(.largeTitle, design: .rounded, weight: .heavy).monospacedDigit()
    /// Illustrative symbols. Pass a size from `@ScaledMetric` so it follows Dynamic Type.
    static func illustration(size: CGFloat) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }
}

extension View {
    /// Raised content: Card fill, continuous corners and a hairline border. No shadow.
    func cardStyle(radius: CGFloat = Radius.card) -> some View {
        background {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(.card)
                .strokeBorder(.hairline, lineWidth: 0.5)
        }
    }

    /// Pins controls to the bottom edge above scrolling content. On iOS 26 content fades softly
    /// beneath it; earlier versions get a solid Surface backing so text never shows through.
    @ViewBuilder
    func bottomBar<Bar: View>(@ViewBuilder _ bar: () -> Bar) -> some View {
        if #available(iOS 26.0, *) {
            safeAreaBar(edge: .bottom, content: bar)
        } else {
            safeAreaInset(edge: .bottom) {
                bar().background(.surface)
            }
        }
    }

    /// Liquid Glass on iOS 26, material on earlier versions. Only for controls that float above content.
    @ViewBuilder
    func floatingGlass<S: Shape>(in shape: S) -> some View {
        if #available(iOS 26.0, *) {
            glassEffect(.regular.interactive(), in: shape)
        } else {
            background(.regularMaterial, in: shape)
                .overlay(shape.stroke(.hairline, lineWidth: 0.5))
        }
    }
}
