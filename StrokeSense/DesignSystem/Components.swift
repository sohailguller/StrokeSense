//
//  Components.swift
//  StrokeSense
//
//  Shared building blocks. Screens compose these instead of styling inline,
//  so spacing, type and color stay consistent across the app.
//

import SwiftUI
import SafariServices

// MARK: - Section header

/// App Store style section title with an optional "See All" link.
struct SectionHeader<Destination: View>: View {
    let title: String
    let destination: Destination?

    init(_ title: String, @ViewBuilder seeAll destination: () -> Destination) {
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
    init(_ title: String) {
        self.title = title
        self.destination = nil
    }
}

// MARK: - Buttons

/// Full-width filled capsule. Defaults to the brand color.
struct PrimaryButtonStyle: ButtonStyle {
    var color: Color = .brandPrimary
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(color.opacity(isEnabled ? 1 : 0.35), in: Capsule())
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.snappy(duration: 0.2), value: configuration.isPressed)
    }
}

/// Full-width outlined capsule for secondary actions.
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.tint)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(Capsule().fill(.card).strokeBorder(.hairline, lineWidth: 1))
            .opacity(configuration.isPressed ? 0.7 : 1)
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
        .accessibilityLabel(isSaved ? "Remove from Saved" : "Save video")
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
                        .accessibilityLabel("Share video")
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
    let name: String
    let url: URL
    var id: URL { url }

    static let nhlbiOverview = Source(name: "NIH National Heart, Lung, and Blood Institute: What is a stroke?", url: URL(string: "https://www.nhlbi.nih.gov/health/stroke")!)
    static let nhlbiSymptoms = Source(name: "NIH NHLBI: Stroke signs, symptoms, and complications", url: URL(string: "https://www.nhlbi.nih.gov/health/stroke/symptoms")!)
    static let nhlbiCauses = Source(name: "NIH NHLBI: Stroke causes and risk factors", url: URL(string: "https://www.nhlbi.nih.gov/health/stroke/causes")!)
    static let nhlbiTreatment = Source(name: "NIH NHLBI: Stroke treatment", url: URL(string: "https://www.nhlbi.nih.gov/health/stroke/treatment")!)
    static let nhlbiRecovery = Source(name: "NIH NHLBI: Recovery after stroke", url: URL(string: "https://www.nhlbi.nih.gov/health/stroke/recovery")!)
}

/// Header for a topic: symbol, kicker, headline and summary.
struct TopicHero: View {
    let eyebrow: String
    let title: String
    let summary: String
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
            Text(eyebrow).kicker(tint)
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
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Symbol, title and description in a card list.
struct TopicItemRow: View {
    let systemImage: String
    let title: String
    let detail: String
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
                            Text(source.name)
                                .multilineTextAlignment(.leading)
                            Image(systemName: "arrow.up.right")
                                .imageScale(.small)
                        }
                        .font(.footnote)
                    }
                    .tint(.accentColor)
                }
                DisclaimerText("General information only, not medical advice. Talk to a doctor about your health.")
                    .padding(.top, Spacing.xs)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .safariSheet(url: $openURL)
        }
    }
}

struct DisclaimerText: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(.inkMuted)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// Detail content shown in a sheet for Types and Treatments.
struct TopicDetail: Identifiable {
    let id = UUID()
    let systemImage: String
    let title: String
    let summary: String
    let body: String
    let points: [String]
    let source: Source
}

struct TopicDetailSheet: View {
    let detail: TopicDetail
    let eyebrow: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.l) {
                    TopicHero(eyebrow: eyebrow, title: detail.title, summary: detail.summary, systemImage: detail.systemImage)
                    Text(detail.body)
                        .font(.body)
                        .foregroundStyle(.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    VStack(alignment: .leading, spacing: Spacing.s) {
                        ForEach(detail.points, id: \.self) { point in
                            HStack(alignment: .firstTextBaseline, spacing: Spacing.s) {
                                Circle()
                                    .fill(.tint)
                                    .frame(width: 6, height: 6)
                                    .alignmentGuide(.firstTextBaseline) { $0[.bottom] - 2 }
                                Text(point)
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
                Text(sourceName)
                    .kicker(font: .caption.weight(.semibold))
                    .lineLimit(1)
                Text(article.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.ink)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
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
