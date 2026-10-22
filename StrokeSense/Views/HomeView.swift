//
//  HomeView.swift
//  StrokeSense
//
//  Created by Sohail Guller on 10/20/24.
//

import SwiftUI

/// The Today tab: emergency signs first, then the expert, videos, quiz and reading.
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
                DateEyebrowFallback()

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
        .navigationTitle("Today")
        .modifier(DateSubtitle())
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

// MARK: - Date

private let todayDate = Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day())

/// iOS 26 shows the date under the large title.
private struct DateSubtitle: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.navigationSubtitle(todayDate)
        } else {
            content
        }
    }
}

/// Earlier versions show the date at the top of the content instead.
private struct DateEyebrowFallback: View {
    var body: some View {
        if #available(iOS 26.0, *) {
            EmptyView()
        } else {
            Text(todayDate).kicker()
        }
    }
}

// MARK: - Cards

/// Emergency signs, styled as the most prominent card on the screen.
private struct BeFastHeroCard: View {
    private let letters = ["B", "E", "F", "A", "S", "T"]
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// Side by side normally; stacked at accessibility text sizes so labels never truncate.
    private var buttonLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: Spacing.s))
            : AnyLayout(HStackLayout(spacing: Spacing.s))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            Label("Know the signs of stroke", systemImage: "bolt.heart.fill")
                .kicker(.white.opacity(0.9))
                .symbolEffect(.breathe, options: .repeat(3))

            HStack(spacing: 0) {
                ForEach(letters, id: \.self) { letter in
                    Text(letter)
                        .font(.letterMark)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                }
            }
            .accessibilityElement()
            .accessibilityLabel("B E F A S T")

            Text("Balance · Eyes · Face · Arms · Speech · Time")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.9))
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)

            buttonLayout {
                NavigationLink(value: "befast") {
                    Text("Learn the Signs")
                        .font(.headline)
                        .foregroundStyle(.brandPrimary)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(.white, in: Capsule())
                }
                .buttonStyle(.plain)

                EmergencyCallButton()
            }
            .padding(.top, Spacing.xs)
        }
        .padding(Spacing.l)
        .background(.brandPrimary, in: RoundedRectangle(cornerRadius: Radius.hero, style: .continuous))
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
