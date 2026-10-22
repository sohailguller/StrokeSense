//
//  ProfileView.swift
//  StrokeSense
//
//  Created by Sohail Guller on 11/1/24.
//
import SwiftUI
import PhotosUI

/// Profile and app information, presented as a sheet from Today.
struct ProfileView: View {
    @EnvironmentObject private var store: UserStore
    @Environment(\.dismiss) private var dismiss
    @State private var photoItem: PhotosPickerItem?
    @State private var openURL: URL?

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }

    var body: some View {
        let hasPhoto = !store.user.profilePicture.isSymbolImage
        NavigationStack {
            Form {
                Section {
                    VStack(spacing: Spacing.s) {
                        AvatarView(image: store.user.profilePicture, size: 96)
                        PhotosPicker(selection: $photoItem, matching: .images) {
                            Text(hasPhoto ? "Change Photo" : "Add Photo")
                                .font(.subheadline.weight(.semibold))
                        }
                        .tint(.accentColor)
                    }
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                }

                Section("Name") {
                    TextField("Your name", text: $store.user.username)
                        .textContentType(.givenName)
                        .submitLabel(.done)
                }

                Section {
                    LabeledContent("Version", value: appVersion)
                    Button("Where our information comes from") { openURL = Source.nhlbiOverview.url }
                } header: {
                    Text("About")
                } footer: {
                    Text("StrokeSense provides general education, not medical advice. Questions you ask the Stroke Expert are sent to OpenAI to generate answers and may be used to improve their models. Don't share personal health details. In an emergency, call an ambulance.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(.surface)
            .tint(.accentColor)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
            .onChange(of: photoItem) { _, item in
                Task { await loadPhoto(item) }
            }
            .safariSheet(url: $openURL)
        }
    }

    private func loadPhoto(_ item: PhotosPickerItem?) async {
        guard let item,
              let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        // Keep the stored profile small while preserving the aspect ratio.
        let scale = min(1, 512 / max(image.size.width, image.size.height))
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let thumbnail = image.preparingThumbnail(of: size) ?? image
        store.user.profilePicture = thumbnail
        store.objectWillChange.send()
    }
}

#Preview {
    ProfileView()
        .environmentObject(UserStore())
}
