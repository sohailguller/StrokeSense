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
    @State private var cropImage: CropImage?
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
                        .buttonStyle(.borderless)
                        .tint(.accentColor)
                        if hasPhoto {
                            Button("Remove Photo", role: .destructive) {
                                store.user.profilePicture = User.default.profilePicture
                                store.objectWillChange.send()
                            }
                            .font(.subheadline)
                            .buttonStyle(.borderless)
                        }
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
            .fullScreenCover(item: $cropImage) { item in
                PhotoCropView(image: item.image) { cropped in
                    if let cropped {
                        store.user.profilePicture = cropped
                        store.objectWillChange.send()
                    }
                    cropImage = nil
                }
            }
            .safariSheet(url: $openURL)
        }
    }

    private func loadPhoto(_ item: PhotosPickerItem?) async {
        guard let item,
              let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        // Reset so picking the same photo again still triggers a change.
        photoItem = nil
        // Big enough to zoom in on, small enough to keep memory low while cropping.
        let scale = min(1, 2048 / max(image.size.width, image.size.height))
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        cropImage = CropImage(image: image.preparingThumbnail(of: size) ?? image)
    }
}

private struct CropImage: Identifiable {
    let id = UUID()
    let image: UIImage
}

/// Full-screen circular crop for the profile photo: drag to move, pinch to zoom.
private struct PhotoCropView: View {
    let image: UIImage
    /// Called with the cropped square image, or nil if cancelled.
    let onFinish: (UIImage?) -> Void

    @State private var zoom: CGFloat = 1
    @State private var lastZoom: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    private static let maxZoom: CGFloat = 5
    private static let outputSize: CGFloat = 512

    var body: some View {
        GeometryReader { geo in
            let side = max(1, min(geo.size.width, geo.size.height) - Spacing.l * 2)
            // Points on screen per image point when zoom is 1: the photo just covers the circle.
            let fill = side / max(1, min(image.size.width, image.size.height))

            ZStack {
                Color.black.ignoresSafeArea()

                Image(uiImage: image)
                    .resizable()
                    .frame(width: image.size.width * fill * zoom, height: image.size.height * fill * zoom)
                    .offset(offset)

                // Dim everything outside the circle.
                Rectangle()
                    .fill(.black.opacity(0.6))
                    .overlay {
                        Circle()
                            .frame(width: side, height: side)
                            .blendMode(.destinationOut)
                    }
                    .compositingGroup()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)

                Circle()
                    .strokeBorder(.white.opacity(0.7), lineWidth: 1)
                    .frame(width: side, height: side)
                    .allowsHitTesting(false)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { value in
                        offset = clamped(CGSize(width: lastOffset.width + value.translation.width,
                                                height: lastOffset.height + value.translation.height),
                                         zoom: zoom, side: side, fill: fill)
                    }
                    .onEnded { _ in lastOffset = offset }
                    .simultaneously(with:
                        MagnifyGesture()
                            .onChanged { value in
                                zoom = min(max(lastZoom * value.magnification, 1), Self.maxZoom)
                                offset = clamped(offset, zoom: zoom, side: side, fill: fill)
                            }
                            .onEnded { _ in
                                lastZoom = zoom
                                lastOffset = offset
                            }
                    )
            )
            .overlay(alignment: .top) {
                Text("Move and Scale")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.top, Spacing.m)
            }
            .overlay(alignment: .bottom) {
                HStack {
                    Button("Cancel") { onFinish(nil) }
                    Spacer()
                    Button("Choose") { onFinish(crop(side: side, fill: fill)) }
                        .fontWeight(.semibold)
                }
                .font(.body)
                .foregroundStyle(.white)
                .padding(.horizontal, Spacing.l)
                .padding(.bottom, Spacing.m)
            }
        }
        .environment(\.colorScheme, .dark)
        .statusBarHidden()
    }

    /// Keeps the photo covering the whole circle.
    private func clamped(_ proposed: CGSize, zoom: CGFloat, side: CGFloat, fill: CGFloat) -> CGSize {
        let maxX = max(0, (image.size.width * fill * zoom - side) / 2)
        let maxY = max(0, (image.size.height * fill * zoom - side) / 2)
        return CGSize(width: min(max(proposed.width, -maxX), maxX),
                      height: min(max(proposed.height, -maxY), maxY))
    }

    /// Renders the part of the photo inside the circle as a square image.
    private func crop(side: CGFloat, fill: CGFloat) -> UIImage {
        let pointsPerPixel = fill * zoom
        let cropSide = side / pointsPerPixel
        let originX = image.size.width / 2 - offset.width / pointsPerPixel - cropSide / 2
        let originY = image.size.height / 2 - offset.height / pointsPerPixel - cropSide / 2
        let scale = Self.outputSize / cropSide

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: Self.outputSize, height: Self.outputSize), format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(x: -originX * scale, y: -originY * scale,
                                  width: image.size.width * scale, height: image.size.height * scale))
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(UserStore())
}
