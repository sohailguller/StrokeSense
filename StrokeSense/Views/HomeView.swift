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
                        SectionHeader("Videos") {
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
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showProfile = true
                } label: {
                    AvatarView(image: store.user.profilePicture, size: 32)
                }
                .accessibilityLabel("Profile")
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
        Sign(letter: "B", name: "Balance", prompt: "Sudden dizziness or loss of balance", systemImage: "figure.fall"),
        Sign(letter: "E", name: "Eyes", prompt: "Sudden trouble seeing in one or both eyes", systemImage: "eye.fill"),
        Sign(letter: "F", name: "Face", prompt: "Ask them to smile. Does one side droop?", systemImage: "face.smiling"),
        Sign(letter: "A", name: "Arms", prompt: "Ask them to raise both arms. Does one drift down?", systemImage: "figure.arms.open"),
        Sign(letter: "S", name: "Speech", prompt: "Is their speech slurred or strange?", systemImage: "mouth.fill"),
        Sign(letter: "T", name: "Time", prompt: "Call an ambulance right away", systemImage: "clock.fill")
    ]

    private static let motion = Animation.smooth(duration: 0.45)

    @State private var index = 0
    @State private var forward = true
    @State private var taps = 0
    @Namespace private var indicator
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .largeTitle) private var symbolSize: CGFloat = 64

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
                .frame(width: symbolSize * 1.25, height: symbolSize * 1.1)
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
            Text("Know the signs of stroke")
                .kicker(.white.opacity(0.9))

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

            NavigationLink(value: "befast") {
                Text("Learn the Signs")
                    .font(.headline)
                    .foregroundStyle(.brandPrimary)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(.white, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(Spacing.l)
        .background(.brandPrimary)
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

/// Entry point to the Stroke Expert. Each question switches to Ask and sends it.
private struct AskExpertCard: View {
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var session: ChatSession

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            Label {
                Text("Stroke Expert")
            } icon: {
                ExpertMark(font: .subheadline)
            }
            .kicker(.accentColor)
            Text("Have a question about stroke?")
                .font(.cardTitle)
                .foregroundStyle(.ink)

            ScrollView(.horizontal) {
                HStack(spacing: Spacing.xs) {
                    ForEach(ChatSession.suggestions, id: \.self) { question in
                        Button(question) {
                            session.ask(question)
                            router.selectedTab = .ask
                        }
                        .buttonStyle(.chip)
                    }
                }
                .padding(.horizontal, Spacing.l)
            }
            .scrollIndicators(.hidden)
            .padding(.horizontal, -Spacing.l)
        }
        .padding(Spacing.l)
        .cardStyle(radius: Radius.hero)
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
        Button(action: onStart) {
            HStack(spacing: Spacing.m) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.largeTitle)
                    .symbolRenderingMode(.monochrome)
                    .foregroundStyle(.tint)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("Test what you know")
                        .font(.cardHeadline)
                        .foregroundStyle(.ink)
                    Text("10 questions · about 3 minutes")
                        .font(.subheadline)
                        .foregroundStyle(.inkMuted)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.inkMuted)
            }
            .padding(Spacing.l)
            .cardStyle()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint("Starts a 10 question quiz")
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
