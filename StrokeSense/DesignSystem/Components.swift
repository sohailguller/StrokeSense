//
//  Components.swift
//  StrokeSense
//
//  Shared building blocks. Screens compose these instead of styling inline,
//  so spacing, type and color stay consistent across the app.
//

import SwiftUI
import SafariServices
import CoreImage.CIFilterBuiltins

// MARK: - Section header

/// App Store style section title with an optional "See All" link.
struct SectionHeader<Destination: View>: View {
    let title: LocalizedStringKey
    let destination: Destination?

    init(_ title: LocalizedStringKey, @ViewBuilder seeAll destination: () -> Destination) {
        self.title = title
        self.destination = destination()
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.title2.bold())
                .foregroundStyle(.ink)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            if let destination {
                NavigationLink("See All") { destination }
                    .font(.body)
                    .tint(.accentColor)
            }
        }
    }
}

extension SectionHeader where Destination == EmptyView {
    init(_ title: LocalizedStringKey) {
        self.title = title
        self.destination = nil
    }
}

// MARK: - Buttons

/// Chunky press-down button, Duolingo style: a solid darker edge sits under the face,
/// and the face drops onto it while pressed. Flat colors only, no blur.
struct ChunkyButtonStyle: ButtonStyle {
    var fill: Color
    var edge: Color
    var label: Color
    var border: Color? = nil

    func makeBody(configuration: Configuration) -> some View {
        ChunkyButton(label: configuration.label, isPressed: configuration.isPressed,
                     fill: fill, edge: edge, labelColor: label, border: border)
    }
}

/// The view behind ChunkyButtonStyle. A view (not the style) reads `isEnabled`, so the
/// disabled look also works when another style wraps this one.
private struct ChunkyButton: View {
    let label: ButtonStyleConfiguration.Label
    let isPressed: Bool
    let fill: Color
    let edge: Color
    let labelColor: Color
    let border: Color?
    @Environment(\.isEnabled) private var isEnabled

    private let depth: CGFloat = 4

    var body: some View {
        // Disabled buttons go flat gray, as in Duolingo, instead of a faded brand color.
        label
            .font(.headline)
            .foregroundStyle(isEnabled ? labelColor : .inkMuted)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background {
                Capsule()
                    .fill(isEnabled ? fill : .hairline)
                    .overlay {
                        if let border, isEnabled { Capsule().strokeBorder(border, lineWidth: 1.5) }
                    }
            }
            .offset(y: isPressed ? depth : 0)
            .background {
                Capsule()
                    .fill(isEnabled ? edge : .hairline.mix(with: .black, by: 0.12))
                    .offset(y: depth)
            }
            .padding(.bottom, depth)
            .animation(.snappy(duration: 0.12), value: isPressed)
    }
}

extension Color {
    /// The "3D" edge under white buttons on colored cards: neutral gray, never tinted pink.
    static let whiteButtonEdge = Color(white: 0.8)
}

/// Full-width filled button. Defaults to the brand color.
struct PrimaryButtonStyle: ButtonStyle {
    var color: Color = .brandPrimary

    func makeBody(configuration: Configuration) -> some View {
        ChunkyButtonStyle(fill: color, edge: color.mix(with: .black, by: 0.3), label: .white)
            .makeBody(configuration: configuration)
    }
}

/// Full-width outlined button for secondary actions.
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        ChunkyButtonStyle(fill: .card, edge: .hairline, label: .accentColor, border: .hairline)
            .makeBody(configuration: configuration)
    }
}

/// Compact suggestion chip.
struct ChipButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.ink)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Capsule().fill(.card).strokeBorder(.hairline, lineWidth: 0.5))
            .opacity(configuration.isPressed ? 0.6 : 1)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var secondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}

extension ButtonStyle where Self == ChipButtonStyle {
    static var chip: ChipButtonStyle { ChipButtonStyle() }
}

// MARK: - Surfaces

/// Depth for feature cards: a soft mesh of shades of one color, fine grain on top, and an
/// optional light sweep. Shades come from the base color, so dark mode adapts on its own.
/// Light surfaces should pass a tint as `shade` (e.g. BrandSoft) instead of darkening to gray.
struct FeatureBackground: View {
    var base: Color
    var highlight: Color = .white
    var shade: Color = .black
    var shine = false

    var body: some View {
        ZStack {
            MeshGradient(
                width: 3,
                height: 3,
                points: [
                    [0, 0], [0.5, 0], [1, 0],
                    [0, 0.5], [0.62, 0.42], [1, 0.5],
                    [0, 1], [0.5, 1], [1, 1]
                ],
                // Highlights stay subtle: white mixed into red quickly turns pink.
                colors: [
                    base.mix(with: highlight, by: 0.05), base.mix(with: highlight, by: 0.02), base,
                    base, base.mix(with: highlight, by: 0.03), base.mix(with: shade, by: 0.12),
                    base.mix(with: shade, by: 0.1), base.mix(with: shade, by: 0.2), base.mix(with: shade, by: 0.32)
                ]
            )
            GrainTexture()
            if shine { ShineSweep() }
        }
        .accessibilityHidden(true)
    }
}

/// Fine monochrome film grain, tiled. Gives flat color a printed, tactile surface.
struct GrainTexture: View {
    var opacity = 0.14

    private static let tile: UIImage? = {
        let size = CGRect(x: 0, y: 0, width: 160, height: 160)
        let noise = CIFilter.randomGenerator()
        let mono = CIFilter.colorControls()
        mono.inputImage = noise.outputImage?.cropped(to: size)
        mono.saturation = 0
        guard let output = mono.outputImage,
              let image = CIContext().createCGImage(output, from: size) else { return nil }
        return UIImage(cgImage: image, scale: 3, orientation: .up)
    }()

    var body: some View {
        if let tile = Self.tile {
            Image(uiImage: tile)
                .resizable(resizingMode: .tile)
                .blendMode(.overlay)
                .opacity(opacity)
                .allowsHitTesting(false)
        }
    }
}

/// A soft diagonal highlight that sweeps across every few seconds. Skipped with Reduce Motion.
struct ShineSweep: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var progress: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            LinearGradient(
                colors: [.clear, .white.opacity(0.14), .clear],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: geo.size.width * 0.35, height: geo.size.height * 2)
            .rotationEffect(.degrees(18))
            .position(x: -geo.size.width * 0.3 + progress * geo.size.width * 1.6, y: geo.size.height / 2)
        }
        .allowsHitTesting(false)
        .task {
            guard !reduceMotion else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(5))
                guard !Task.isCancelled else { return }
                withAnimation(.easeInOut(duration: 1.2)) { progress = 1 }
                try? await Task.sleep(for: .seconds(1.3))
                progress = 0
            }
        }
    }
}

/// An oversized symbol cropped by the card's edge, as a decorative shape.
/// Place it in a ZStack aligned to `.topTrailing` or `.bottomTrailing`.
struct CornerGlyph: View {
    let systemImage: String
    var color: Color
    var top = false
    @ScaledMetric(relativeTo: .largeTitle) private var size: CGFloat = 120

    var body: some View {
        Image(systemName: systemImage)
            .font(.illustration(size: size))
            .foregroundStyle(color)
            .rotationEffect(.degrees(-12))
            .offset(x: size * 0.42, y: size * (top ? -0.34 : 0.34))
            .accessibilityHidden(true)
            .allowsHitTesting(false)
    }
}

// MARK: - Symbols

/// A row or card symbol: SF Symbol drawn directly on the surface, two-tone, no container.
struct TopicSymbol: View {
    let systemImage: String
    var tint: Color = .accentColor
    @ScaledMetric(relativeTo: .title3) private var width: CGFloat = 32

    var body: some View {
        Image(systemName: systemImage)
            .font(.title2)
            .symbolRenderingMode(.monochrome)
            .foregroundStyle(tint)
            .frame(width: width)
            .accessibilityHidden(true)
    }
}

/// The Stroke Expert's mark, used beside its answers.
struct ExpertMark: View {
    var font: Font = .title3

    var body: some View {
        Image(systemName: "waveform.path.ecg")
            .font(font.weight(.bold))
            .foregroundStyle(.tint)
            .accessibilityHidden(true)
    }
}

// MARK: - Favorites

struct FavoriteButton: View {
    @EnvironmentObject private var favoritesManager: FavoritesManager
    let video: Video

    private var isSaved: Bool { favoritesManager.isFavorite(video.videoID) }

    var body: some View {
        Button {
            favoritesManager.toggle(videoID: video.videoID, title: video.name)
        } label: {
            Image(systemName: isSaved ? "heart.fill" : "heart")
                .font(.title3)
                .foregroundStyle(isSaved ? AnyShapeStyle(.brandPrimary) : AnyShapeStyle(.inkMuted))
                .symbolEffect(.bounce, value: isSaved)
                .contentTransition(.symbolEffect(.replace))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSaved)
        .accessibilityLabel(isSaved ? "Remove from Saved" : "Save episode")
    }
}

// MARK: - Video

enum YouTube {
    /// 1280x720 frame without letterboxing. Not every video has one.
    static func thumbnailURL(_ id: String) -> URL? {
        URL(string: "https://i.ytimg.com/vi/\(id)/maxresdefault.jpg")
    }

    /// 480x360 fallback that always exists (letterboxed for widescreen video).
    static func fallbackThumbnailURL(_ id: String) -> URL? {
        URL(string: "https://i.ytimg.com/vi/\(id)/hqdefault.jpg")
    }

    static func watchURL(_ id: String) -> URL {
        URL(string: "https://www.youtube.com/watch?v=\(id)")!
    }
}

/// 16:9 thumbnail with a play glyph. Loads an image rather than a web player,
/// so lists of videos scroll smoothly.
struct VideoThumbnail: View {
    let videoID: String
    var radius: CGFloat = Radius.card
    var showsPlayGlyph = true
    @State private var image: UIImage?

    var body: some View {
        Color.hairline
            .aspectRatio(16 / 9, contentMode: .fit)
            .overlay {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .transition(.opacity)
                }
            }
            .overlay {
                if showsPlayGlyph {
                    Image(systemName: "play.circle.fill")
                        .font(.system(.largeTitle, weight: .regular))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .black.opacity(0.45))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .accessibilityHidden(true)
            .task(id: videoID) {
                let loaded = await Self.load(videoID)
                withAnimation(.easeOut(duration: 0.2)) { image = loaded }
            }
    }

    private static func load(_ id: String) async -> UIImage? {
        for url in [YouTube.thumbnailURL(id), YouTube.fallbackThumbnailURL(id)].compactMap({ $0 }) {
            guard let (data, response) = try? await URLSession.shared.data(from: url),
                  (response as? HTTPURLResponse)?.statusCode == 200,
                  let image = UIImage(data: data) else { continue }
            return image
        }
        return nil
    }
}

/// Thumbnail plus title and save button. Tapping opens the player sheet.
struct VideoCard: View {
    let video: Video
    let onPlay: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Button(action: onPlay) {
                VideoThumbnail(videoID: video.videoID)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Play \(video.name)")

            HStack(alignment: .top, spacing: Spacing.xs) {
                Text(video.name)
                    .font(.headline)
                    .foregroundStyle(.ink)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                FavoriteButton(video: video)
                    .padding(.top, -10)
            }
        }
        .contextMenu {
            VideoContextActions(video: video)
        }
    }
}

struct VideoContextActions: View {
    @EnvironmentObject private var favoritesManager: FavoritesManager
    let video: Video

    var body: some View {
        let isSaved = favoritesManager.isFavorite(video.videoID)
        Button(isSaved ? "Remove from Saved" : "Save", systemImage: isSaved ? "heart.slash" : "heart") {
            favoritesManager.toggle(videoID: video.videoID, title: video.name)
        }
        ShareLink(item: YouTube.watchURL(video.videoID)) {
            Label("Share", systemImage: "square.and.arrow.up")
        }
        Link(destination: YouTube.watchURL(video.videoID)) {
            Label("Open in YouTube", systemImage: "arrow.up.forward.app")
        }
    }
}

/// Player presented as a sheet with detents.
struct VideoPlayerSheet: View {
    let video: Video
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.m) {
                    YouTubeView(videoID: video.videoID)
                        .aspectRatio(16 / 9, contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.control, style: .continuous))

                    Text(video.name)
                        .font(.cardTitle)
                        .foregroundStyle(.ink)

                    HStack(spacing: Spacing.s) {
                        FavoriteButton(video: video)
                        ShareLink(item: YouTube.watchURL(video.videoID)) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.title3)
                                .frame(width: 44, height: 44)
                        }
                        .accessibilityLabel("Share episode")
                        Spacer()
                        Link(destination: YouTube.watchURL(video.videoID)) {
                            Label("YouTube", systemImage: "arrow.up.forward")
                                .font(.subheadline.weight(.semibold))
                        }
                    }
                    .tint(.accentColor)
                }
                .padding(Spacing.l)
            }
            .background(.surface)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Topic screens

struct Source: Identifiable, Hashable {
    /// Translation key for the source's description.
    let name: String
    let url: URL
    var id: URL { url }

    static let nhlbiOverview = Source(name: "NIH National Heart, Lung, and Blood Institute: What is a stroke?", url: URL(string: "https://www.nhlbi.nih.gov/health/stroke")!)
    static let nhlbiSymptoms = Source(name: "NIH NHLBI: Stroke signs, symptoms, and complications", url: URL(string: "https://www.nhlbi.nih.gov/health/stroke/symptoms")!)
    static let nhlbiCauses = Source(name: "NIH NHLBI: Stroke causes and risk factors", url: URL(string: "https://www.nhlbi.nih.gov/health/stroke/causes")!)
    static let nhlbiTreatment = Source(name: "NIH NHLBI: Stroke treatment", url: URL(string: "https://www.nhlbi.nih.gov/health/stroke/treatment")!)
    static let nhlbiRecovery = Source(name: "NIH NHLBI: Recovery after stroke", url: URL(string: "https://www.nhlbi.nih.gov/health/stroke/recovery")!)
}

/// Header for a topic: symbol, headline and summary.
struct TopicHero: View {
    let title: LocalizedStringKey
    let summary: LocalizedStringKey
    let systemImage: String
    var tint: Color = .accentColor
    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Image(systemName: systemImage)
                .font(.system(.largeTitle).weight(.semibold))
                .imageScale(.large)
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(tint)
                .symbolEffect(.bounce, value: appeared)
                .padding(.bottom, Spacing.xs)
                .accessibilityHidden(true)
            Text(title)
                .font(.heroTitle)
                .foregroundStyle(.ink)
                .accessibilityAddTraits(.isHeader)
            Text(summary)
                .font(.body)
                .foregroundStyle(.inkMuted)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, Spacing.xxs)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear { appeared = true }
    }
}

/// Shared layout for every education topic: hero, content, sources and disclaimer.
struct InfoTopicScreen<Content: View>: View {
    /// Translation key.
    let navigationTitle: String
    let hero: TopicHero
    let sources: [Source]
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                hero
                content
                SourceFootnote(sources: sources)
            }
            .padding(.horizontal, Spacing.l)
            .padding(.top, Spacing.xs)
            .padding(.bottom, Spacing.xxl)
            .frame(maxWidth: 700)
            .frame(maxWidth: .infinity)
        }
        .background(.surface)
        .localizedNavigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Symbol, title and description in a card list.
struct TopicItemRow: View {
    let systemImage: String
    let title: LocalizedStringKey
    let detail: LocalizedStringKey
    var tint: Color = .accentColor

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.m) {
            TopicSymbol(systemImage: systemImage, tint: tint)
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.ink)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(Spacing.m)
        .accessibilityElement(children: .combine)
    }
}

/// Stacks rows inside one card with inset hairline dividers.
struct CardList<Item: Identifiable, Row: View>: View {
    let items: [Item]
    var dividerInset: CGFloat = 64
    @ViewBuilder let row: (Item) -> Row

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                row(item)
                if index < items.count - 1 {
                    Rectangle()
                        .fill(.hairline)
                        .frame(height: 0.5)
                        .padding(.leading, dividerInset)
                }
            }
        }
        .cardStyle()
    }
}

struct SourceFootnote: View {
    let sources: [Source]
    @State private var openURL: URL?

    var body: some View {
        if !sources.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Sources")
                    .font(.headline)
                    .foregroundStyle(.ink)
                ForEach(sources) { source in
                    Button {
                        openURL = source.url
                    } label: {
                        HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                            Text(LocalizedStringKey(source.name))
                                .multilineTextAlignment(.leading)
                            Image(systemName: "arrow.up.right")
                                .imageScale(.small)
                        }
                        .font(.footnote)
                    }
                    .tint(.accentColor)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .safariSheet(url: $openURL)
        }
    }
}

/// Detail content shown in a sheet for Types and Treatments.
struct TopicDetail: Identifiable {
    let id = UUID()
    let systemImage: String
    let title: LocalizedStringKey
    let summary: LocalizedStringKey
    let body: LocalizedStringKey
    let points: [LocalizedStringKey]
    let source: Source
}

struct TopicDetailSheet: View {
    let detail: TopicDetail
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.l) {
                    TopicHero(title: detail.title, summary: detail.summary, systemImage: detail.systemImage)
                    Text(detail.body)
                        .font(.body)
                        .foregroundStyle(.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    VStack(alignment: .leading, spacing: Spacing.s) {
                        ForEach(detail.points.indices, id: \.self) { index in
                            HStack(alignment: .firstTextBaseline, spacing: Spacing.s) {
                                Circle()
                                    .fill(.tint)
                                    .frame(width: 6, height: 6)
                                    .alignmentGuide(.firstTextBaseline) { $0[.bottom] - 2 }
                                Text(detail.points[index])
                                    .font(.body)
                                    .foregroundStyle(.ink)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    SourceFootnote(sources: [detail.source])
                }
                .padding(Spacing.l)
            }
            .background(.surface)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Articles

/// Compact article row: thumbnail, source in small caps, title.
struct ArticleRow: View {
    let article: NewsArticle
    @ScaledMetric(relativeTo: .body) private var thumbSize: CGFloat = 64

    private var sourceName: String {
        if let source = article.source { return source }
        guard let host = URL(string: article.url)?.host() else { return "" }
        return host.replacingOccurrences(of: "www.", with: "")
    }

    var body: some View {
        HStack(spacing: Spacing.m) {
            Color.hairline
                .frame(width: thumbSize, height: thumbSize)
                .overlay {
                    AsyncImage(url: URL(string: article.imageURL)) { phase in
                        if let image = phase.image {
                            image.resizable().scaledToFill()
                        } else {
                            Image(systemName: "doc.text")
                                .foregroundStyle(.inkMuted)
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: Radius.control, style: .continuous))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(article.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.ink)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                Text(sourceName)
                    .font(.caption)
                    .foregroundStyle(.inkMuted)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens the article")
    }
}

// MARK: - In-app Safari

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let controller = SFSafariViewController(url: url)
        controller.preferredControlTintColor = UIColor(named: "AccentColor")
        return controller
    }

    func updateUIViewController(_ controller: SFSafariViewController, context: Context) {}
}

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}

extension View {
    /// Presents `url` in an in-app Safari sheet whenever it is set.
    func safariSheet(url: Binding<URL?>) -> some View {
        sheet(item: url) { url in
            SafariView(url: url)
                .ignoresSafeArea()
        }
    }
}

// MARK: - Avatar

struct AvatarView: View {
    let image: UIImage
    var size: CGFloat = 36

    var body: some View {
        Group {
            if image.isSymbolImage {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .symbolRenderingMode(.monochrome)
                    .foregroundStyle(.inkMuted)
            } else {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}
