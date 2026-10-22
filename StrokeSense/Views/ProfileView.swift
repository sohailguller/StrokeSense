//
//  ProfileView.swift
//  StrokeSense
//
//  Created by Sohail Guller on 11/1/24.
//
import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var store: UserStore
    @State private var editUser: User = User.default
    @State private var isEditing: Bool = false
    @State private var showImagePicker: Bool = false
    @State private var selectedImage: UIImage? = nil

    var body: some View {
        NavigationView {
            VStack {
                ZStack {
                    if store.user.profilePicture == UIImage(systemName: "person.crop.circle.fill") {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                            .clipShape(Circle())
                            .foregroundColor(.gray)
                            .shadow(radius: 5)
                    } else {
                        Image(uiImage: store.user.profilePicture)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 200, height: 200)
                            .clipShape(Circle())
                            .shadow(radius: 5)
                    }
                    
                    if isEditing {
                        Circle()
                            .fill(Color.black.opacity(0.3))
                            .frame(width: 200, height: 200)
                            .overlay(
                                Image(systemName: "camera.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: 24))
                            )
                            .onTapGesture {
                                showImagePicker.toggle()
                            }
                    }
                }
                .padding()
                
                TextField("Enter name", text: $store.user.username)
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .padding(5)
                    .frame(maxWidth: 300, maxHeight: 50)
                    .background(Color.gray.opacity(0.15))
                    .cornerRadius(8)
                    .disabled(!isEditing)
                
                Spacer()
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $showImagePicker, onDismiss: loadImage) {
                ImagePicker(image: $selectedImage)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isEditing.toggle()
                    }) {
                        Text(isEditing ? "Done" : "Edit")
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
    }
    
    private func loadImage() {
        guard let selectedImage = selectedImage else { return }
        store.user.profilePicture = selectedImage
    }

}



struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(UserStore())
}
