//
//  LanguageView.swift
//  StrokeSense
//
//  Created by Sohail Guller on 10/25/26.
//
import SwiftUI

/// First launch: pick the app's language before anything else. Modeled on the iPhone's own
/// setup screen: a greeting writes itself on in each language in turn, above a plain list of
/// languages in their own scripts. The text switches to each language as it's picked, so
/// people can tell they chose the right one.
struct LanguageWelcomeView: View {
    @EnvironmentObject private var languageSettings: LanguageSettings
    /// Called once the user confirms their choice.
    let onContinue: () -> Void

    @State private var selection = AppLanguage.current
    /// Whether the user has picked a row yet; until then the greeting cycles through languages.
    @State private var hasPicked = false
    @State private var greetingIndex = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var greetingLanguage: AppLanguage {
        hasPicked || reduceMotion ? selection : AppLanguage.allCases[greetingIndex]
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                header
                CardList(items: AppLanguage.allCases, dividerInset: Spacing.m) { language in
                    LanguageRow(language: language, isSelected: language == selection) {
                        hasPicked = true
                        withAnimation(.spring(duration: 0.6, bounce: 0.2)) { selection = language }
                    }
                }
            }
            .padding(.horizontal, Spacing.l)
            .padding(.bottom, Spacing.l)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .background(.surface)
        .sensoryFeedback(.selection, trigger: selection)
        .bottomBar {
            Button {
                languageSettings.language = selection
                onContinue()
            } label: {
                Text(verbatim: selection.localizedString("Continue"))
                    .contentTransition(.opacity)
            }
            .buttonStyle(.primary)
            .environment(\.locale, selection.locale)
            .padding(.horizontal, Spacing.l)
            .padding(.bottom, Spacing.s)
            .frame(maxWidth: 560)
        }
        .task {
            // Start with the device's language, then greet in each of the others in turn.
            greetingIndex = AppLanguage.allCases.firstIndex(of: selection) ?? 0
            while !Task.isCancelled && !hasPicked {
                try? await Task.sleep(for: .seconds(2.4))
                guard !Task.isCancelled, !hasPicked, !reduceMotion else { continue }
                withAnimation(.spring(duration: 0.6, bounce: 0.2)) {
                    greetingIndex = (greetingIndex + 1) % AppLanguage.allCases.count
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: Spacing.s) {
            Greeting(language: greetingLanguage)

            VStack(spacing: Spacing.xxs) {
                Text(verbatim: selection.localizedString("Choose your language"))
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.ink)
                    .accessibilityAddTraits(.isHeader)
                Text(verbatim: selection.localizedString("You can change it anytime in Profile."))
                    .font(.subheadline)
                    .foregroundStyle(.inkMuted)
            }
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .contentTransition(.opacity)
            .environment(\.locale, selection.locale)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Spacing.xxl)
    }
}

/// "Hello" in one language. Each new greeting pulls up from below as the last one is pushed out
/// the top, inside a clipped window, with no fade. Changes in place with Reduce Motion.
private struct Greeting: View {
    let language: AppLanguage
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .largeTitle) private var size: CGFloat = 68

    var body: some View {
        ZStack {
            // Every greeting laid out invisibly, so the header keeps one height for all of them.
            ForEach(AppLanguage.allCases) { language in
                Text(verbatim: language.greeting).hidden()
            }
            Text(verbatim: language.greeting)
                .foregroundStyle(.brandPrimary)
                .environment(\.locale, language.locale)
                .id(language)
                .transition(reduceMotion ? .identity : .asymmetric(
                    insertion: .move(edge: .bottom),
                    removal: .move(edge: .top)
                ))
        }
        // The window the words rise into and leave through.
        .padding(.vertical, Spacing.xs)
        .clipped()
        .font(.system(size: size, weight: .heavy, design: .rounded))
        .lineLimit(1)
        .minimumScaleFactor(0.4)
        .frame(maxWidth: .infinity)
        .accessibilityHidden(true)
    }
}

/// Profile > Language. Picking a row changes the app's language straight away.
struct LanguageListView: View {
    @EnvironmentObject private var languageSettings: LanguageSettings

    var body: some View {
        Form {
            Section {
                ForEach(AppLanguage.allCases) { language in
                    LanguageRow(
                        language: language,
                        isSelected: language == languageSettings.language,
                        subtitle: language == languageSettings.language ? nil : language.name(in: languageSettings.language),
                        inset: 0
                    ) {
                        withAnimation(.snappy) { languageSettings.language = language }
                    }
                }
            } footer: {
                Text("The Stroke Expert answers in this language. Podcast episodes, news and articles stay in their original language.")
            }
        }
        .scrollContentBackground(.hidden)
        .background(.surface)
        .sensoryFeedback(.selection, trigger: languageSettings.language)
        .localizedNavigationTitle("Language")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// A language written in its own script, with a checkmark when it's the chosen one.
private struct LanguageRow: View {
    let language: AppLanguage
    let isSelected: Bool
    /// The language's name in the app's language, shown under its own name.
    var subtitle: String?
    /// Side padding; zero inside a Form, which pads its rows already.
    var inset: CGFloat = Spacing.m
    let action: () -> Void
    @ScaledMetric(relativeTo: .body) private var minHeight: CGFloat = 52

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.m) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: language.nativeName)
                        .font(.body.weight(isSelected ? .semibold : .regular))
                        .foregroundStyle(.ink)
                        // So VoiceOver reads the name in its own language's voice.
                        .environment(\.locale, language.locale)
                    if let subtitle {
                        Text(verbatim: subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.inkMuted)
                    }
                }
                Spacer(minLength: Spacing.xs)
                Image(systemName: "checkmark")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.tint)
                    .opacity(isSelected ? 1 : 0)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, inset)
            .frame(maxWidth: .infinity, minHeight: minHeight.rounded(), alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview("Welcome") {
    LanguageWelcomeView {}
        .environmentObject(LanguageSettings())
}

#Preview("Profile list") {
    NavigationStack {
        LanguageListView()
    }
    .environmentObject(LanguageSettings())
}
