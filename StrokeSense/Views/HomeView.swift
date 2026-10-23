//
//  HomeView.swift
//  StrokeSense
//
//  Created by Sohail Guller on 10/20/24.
//

import SwiftUI

/// The Home tab: stroke signs first, then the expert, videos, quiz and reading.
struct HomeView: View {
    @EnvironmentObject private var store: UserStore
    @StateObject private var videoVM = VideoViewModel()
    @StateObject private var newsVM = NewsViewModel()
    @Namespace private var transition

    @State private var showProfile = false
    @State private var showQuiz = false
    @State private var playingVideo: Video?
    @State private var openArticle: URL?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xxl) {
                BeFastHeroCard()
                    .matchedTransitionSource(id: "befast", in: transition)

                AskExpertCard()

                if !videoVM.videos.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.m) {
                        SectionHeader("Podcast Episodes") {
                            InterviewsView(viewModel: videoVM)
                        }
                        VideoCarousel(videos: videoVM.videos) { playingVideo = $0 }
                    }
                }

                QuizCard { showQuiz = true }

                articleSection("Resources", articles: newsVM.staticArticles) {
                    ResourcesView(viewModel: newsVM)
                }

                articleSection("News", articles: newsVM.newsArticles) {
                    NewsView(viewModel: newsVM)
                }
            }
            .padding(.horizontal, Spacing.l)
            .padding(.bottom, Spacing.xxl)
            .frame(maxWidth: 700)
            .frame(maxWidth: .infinity)
        }
        .background(.surface)
        .navigationTitle("StrokeSense")
        .toolbar {
            if #available(iOS 26.0, *) {
                // The avatar is its own circle, so skip the glass circle iOS 26 puts behind toolbar items.
                ToolbarItem(placement: .topBarTrailing) { profileButton }
                    .sharedBackgroundVisibility(.hidden)
            } else {
                ToolbarItem(placement: .topBarTrailing) { profileButton }
            }
        }
        .navigationDestination(for: String.self) { route in
            if route == "befast" {
                BefastView()
                    .navigationTransition(.zoom(sourceID: "befast", in: transition))
            }
        }
        .refreshable {
            videoVM.fetchVideos(force: true)
            newsVM.fetchArticles(force: true)
        }
        .onAppear {
            videoVM.fetchVideos()
            newsVM.fetchArticles()
        }
        .sheet(isPresented: $showProfile) { ProfileView() }
        .sheet(item: $playingVideo) { VideoPlayerSheet(video: $0) }
        .fullScreenCover(isPresented: $showQuiz) { GameView() }
        .safariSheet(url: $openArticle)
    }

    private var profileButton: some View {
        Button {
            showProfile = true
        } label: {
            AvatarView(image: store.user.profilePicture, size: 36)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Profile")
    }

    @ViewBuilder
    private func articleSection<Destination: View>(_ title: String, articles: [NewsArticle], @ViewBuilder seeAll: () -> Destination) -> some View {
        if !articles.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.m) {
                SectionHeader(title, seeAll: seeAll)
                CardList(items: Array(articles.prefix(3)), dividerInset: 96) { article in
                    Button {
                        openArticle = URL(string: article.url)
                    } label: {
                        ArticleRow(article: article)
                            .padding(Spacing.m)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Cards

/// The signs of stroke, cycling one at a time like a flash card. Tapping a letter jumps to it.
/// The panel and the letter indicator move together, sideways, on one animation.
private struct BeFastHeroCard: View {
    private struct Sign {
        let letter: String
        let name: String
        let prompt: String
        let systemImage: String
    }

    private let signs = [
        Sign(letter: "B", name: "Balance", prompt: "Sudden loss of balance or dizziness", systemImage: "figure.fall"),
        Sign(letter: "E", name: "Eyes", prompt: "Sudden blurred, double or lost vision", systemImage: "eye.fill"),
        Sign(letter: "F", name: "Face", prompt: "One side of the face droops", systemImage: "face.smiling"),
        Sign(letter: "A", name: "Arms", prompt: "One arm or leg is weak or numb", systemImage: "figure.arms.open"),
        Sign(letter: "S", name: "Speech", prompt: "Slurred speech or trouble speaking", systemImage: "mouth.fill"),
        Sign(letter: "T", name: "Time", prompt: "Call 911 right away", systemImage: "clock.fill")
    ]

    private static let motion = Animation.smooth(duration: 0.45)

    @State private var index = 0
    @State private var forward = true
    @State private var taps = 0
    @Namespace private var indicator
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .largeTitle) private var symbolSize: CGFloat = 56

    /// Symbol beside the text normally; stacked at accessibility text sizes.
    private var signLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.m))
            : AnyLayout(HStackLayout(spacing: Spacing.l))
    }

    private func show(_ newIndex: Int) {
        forward = newIndex > index
        withAnimation(reduceMotion ? .none : Self.motion) { index = newIndex }
    }

    private func panel(_ sign: Sign) -> some View {
        signLayout {
            Image(systemName: sign.systemImage)
                .font(.illustration(size: symbolSize))
                // Wide enough for the widest symbol (the eye); the push transition clips to this frame.
                .frame(width: symbolSize * 1.7, height: symbolSize * 1.2)
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(sign.name)
                    .font(.cardTitle)
                Text(sign.prompt)
                    .font(.subheadline.weight(.medium))
                    .opacity(0.9)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundStyle(.white)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.l) {
            ZStack(alignment: .leading) {
                // Every sign laid out invisibly so the card never changes height.
                ForEach(signs.indices, id: \.self) { i in
                    panel(signs[i]).hidden()
                }
                panel(signs[index])
                    .id(index)
                    .transition(.push(from: forward ? .trailing : .leading))
            }
            .accessibilityHidden(true)

            HStack(spacing: 0) {
                ForEach(signs.indices, id: \.self) { i in
                    Button {
                        taps += 1
                        show(i)
                    } label: {
                        VStack(spacing: Spacing.xxs) {
                            Text(signs[i].letter)
                                .font(.letterMark)
                                .foregroundStyle(.white.opacity(i == index ? 1 : 0.45))
                            Capsule()
                                .fill(.clear)
                                .frame(width: 20, height: 4)
                                .overlay {
                                    if i == index {
                                        Capsule()
                                            .fill(.white)
                                            .matchedGeometryEffect(id: "indicator", in: indicator)
                                    }
                                }
                        }
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(signs[i].name): \(signs[i].prompt)")
                    .accessibilityAddTraits(i == index ? .isSelected : [])
                }
            }
            .sensoryFeedback(.selection, trigger: taps)

            NavigationLink("Learn the Signs", value: "befast")
                .buttonStyle(ChunkyButtonStyle(
                    fill: .white,
                    edge: Color.white.mix(with: .brandPrimary, by: 0.45),
                    label: .brandPrimary
                ))
        }
        .padding(Spacing.l)
        .background(FeatureBackground(base: .brandPrimary, shine: true))
        .clipShape(RoundedRectangle(cornerRadius: Radius.hero, style: .continuous))
        // Restarts whenever the sign changes, so a tap resets the timer.
        .task(id: index) {
            guard !reduceMotion else { return }
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            show((index + 1) % signs.count)
        }
    }
}

/// Entry point to the Stroke Expert: a field that opens Ask, plus suggested questions.
private struct AskExpertCard: View {
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var session: ChatSession
    /// The example being typed; tapping the field carries it over to Ask.
    @State private var typedQuestion: String?

    private static let examples = [
        "Can young people have a stroke?",
        "How long does recovery take?",
        "Is a mini-stroke serious?",
        "Can stress cause a stroke?",
        "What does a stroke feel like?"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.s) {
                ExpertMark(font: .title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Stroke Expert")
                        .font(.cardTitle)
                        .foregroundStyle(.ink)
                    Text("Plain-language answers about stroke")
                        .font(.subheadline)
                        .foregroundStyle(.inkMuted)
                }
            }

            Button {
                router.draftQuestion = typedQuestion
                router.focusChatInput = true
                router.selectedTab = .ask
            } label: {
                HStack {
                    TypingPrompt(prompts: Self.examples, current: $typedQuestion)
                    Spacer(minLength: Spacing.xs)
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.tint)
                }
                .padding(.leading, Spacing.m)
                .padding(.trailing, Spacing.xs)
                .frame(minHeight: 48)
                .background(.surface, in: Capsule())
                .overlay(Capsule().strokeBorder(.hairline, lineWidth: 0.5))
                .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Ask the Stroke Expert a question")

            SuggestionList(questions: Array(ChatSession.suggestions.prefix(2)), horizontalPadding: 0) { question in
                session.ask(question)
                router.selectedTab = .ask
            }
        }
        .padding(Spacing.l)
        .background(alignment: .topTrailing) {
            ZStack(alignment: .topTrailing) {
                FeatureBackground(base: .card, shade: .brandSoft)
                CornerGlyph(systemImage: "bubble.left.and.text.bubble.right.fill", color: .brandSoft, top: true)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: Radius.hero, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.hero, style: .continuous).strokeBorder(.hairline, lineWidth: 0.5))
    }
}

/// Types example questions into the field one character at a time, then clears and moves on.
private struct TypingPrompt: View {
    let prompts: [String]
    @Binding var current: String?
    @State private var shown = ""
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 1) {
            Text(shown)
                .font(.body)
                .foregroundStyle(.ink)
                .lineLimit(1)
                .truncationMode(.head)
            Capsule()
                .fill(.tint)
                .frame(width: 2, height: 22)
        }
        .accessibilityHidden(true)
        .task { await run() }
    }

    private func run() async {
        var index = 0
        while !Task.isCancelled {
            let prompt = prompts[index]
            current = prompt
            if reduceMotion {
                shown = prompt
                guard await pause(3) else { return }
            } else {
                for character in prompt {
                    shown.append(character)
                    guard await pause(0.05) else { return }
                }
                guard await pause(2) else { return }
                while !shown.isEmpty {
                    shown.removeLast()
                    guard await pause(0.015) else { return }
                }
                guard await pause(0.35) else { return }
            }
            index = (index + 1) % prompts.count
        }
    }

    /// Sleeps for the given seconds; returns false once the view is gone.
    private func pause(_ seconds: Double) async -> Bool {
        do {
            try await Task.sleep(for: .seconds(seconds))
            return true
        } catch {
            return false
        }
    }
}

private struct VideoCarousel: View {
    let videos: [Video]
    let onPlay: (Video) -> Void

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(alignment: .top, spacing: Spacing.m) {
                ForEach(videos) { video in
                    VideoCard(video: video) { onPlay(video) }
                        .containerRelativeFrame(.horizontal) { width, _ in width * 0.82 }
                        .scrollTransition(.interactive, axis: .horizontal) { content, phase in
                            content
                                .scaleEffect(phase.isIdentity ? 1 : 0.96)
                                .opacity(phase.isIdentity ? 1 : 0.8)
                        }
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollIndicators(.hidden)
        .contentMargins(.horizontal, Spacing.l, for: .scrollContent)
        .padding(.horizontal, -Spacing.l)
    }
}

private struct QuizCard: View {
    let onStart: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("Test what you know")
                    .font(.cardTitle)
                    .foregroundStyle(.ink)
                Text("10 questions · about 3 minutes")
                    .font(.subheadline)
                    .foregroundStyle(.inkMuted)
            }
            .padding(.trailing, Spacing.xxl)

            Button("Start Quiz", action: onStart)
                .buttonStyle(.primary)
                .accessibilityHint("Starts a 10 question quiz")
        }
        .padding(Spacing.l)
        .background(alignment: .bottomTrailing) {
            ZStack(alignment: .topTrailing) {
                FeatureBackground(base: .brandSoft, highlight: .card, shade: .brandPrimary)
                CornerGlyph(systemImage: "checkmark.seal.fill", color: .brandPrimary.opacity(0.14), top: true)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: Radius.hero, style: .continuous))
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
    .environmentObject(UserStore())
    .environmentObject(FavoritesManager())
    .environmentObject(AppRouter())
    .environmentObject(ChatSession())
}
