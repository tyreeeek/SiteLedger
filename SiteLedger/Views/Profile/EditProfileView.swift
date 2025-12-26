import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthService
    
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    
    // Photo selection
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var showingPhotoOptions = false
    
    private let apiService = APIService.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                ModernDesign.Colors.background.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: ModernDesign.Spacing.lg) {
                        // Profile Avatar
                        VStack(spacing: ModernDesign.Spacing.md) {
                            Button(action: { showingPhotoOptions = true }) {
                                ZStack {
                                    profileImageView
                                    
                                    // Edit Badge
                                    Circle()
                                        .fill(ModernDesign.Colors.cardBackground)
                                        .frame(width: 32, height: 32)
                                        .overlay(
                                            Image(systemName: "camera.fill")
                                                .font(.system(size: 14))
                                                .foregroundColor(ModernDesign.Colors.primary)
                                        )
                                        .offset(x: 35, y: 35)
                                }
                            }
                            
                            Text("Tap to change photo")
                                .font(ModernDesign.Typography.caption)
                                .foregroundColor(ModernDesign.Colors.textTertiary)
                        }
                        .padding(.vertical, ModernDesign.Spacing.lg)
                        
                        // Personal Information
                        ModernCard(shadow: true) {
                            VStack(spacing: ModernDesign.Spacing.lg) {
                                ModernSectionHeader(title: "Personal Information")
                                
                                VStack(spacing: ModernDesign.Spacing.md) {
                                    EditProfileField(
                                        label: "Full Name",
                                        placeholder: "Enter your name",
                                        text: $name,
                                        icon: "person.fill"
                                    )
                                    
                                    EditProfileField(
                                        label: "Email",
                                        placeholder: "Enter your email",
                                        text: $email,
                                        icon: "envelope.fill",
                                        keyboardType: .emailAddress,
                                        disabled: true
                                    )
                                    
                                    EditProfileField(
                                        label: "Phone",
                                        placeholder: "Enter phone number",
                                        text: $phone,
                                        icon: "phone.fill",
                                        keyboardType: .phonePad
                                    )
                                }
                            }
                        }
                        
                        // Error/Success Messages
                        if showError {
                            HStack(spacing: ModernDesign.Spacing.sm) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(ModernDesign.Colors.error)
                                Text(errorMessage)
                                    .font(ModernDesign.Typography.body)
                                    .foregroundColor(ModernDesign.Colors.error)
                            }
                            .padding(ModernDesign.Spacing.md)
                            .background(ModernDesign.Colors.error.opacity(0.1))
                            .cornerRadius(ModernDesign.Radius.medium)
                        }
                        
                        if showSuccess {
                            HStack(spacing: ModernDesign.Spacing.sm) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(ModernDesign.Colors.success)
                                Text("Profile updated successfully!")
                                    .font(ModernDesign.Typography.body)
                                    .foregroundColor(ModernDesign.Colors.success)
                            }
                            .padding(ModernDesign.Spacing.md)
                            .background(ModernDesign.Colors.success.opacity(0.1))
                            .cornerRadius(ModernDesign.Radius.medium)
                        }
                        
                        // Save Button
                        ModernButton(
                            title: "Save Changes",
                            icon: "checkmark.circle.fill",
                            style: .primary,
                            size: .large,
                            action: saveProfile,
                            isLoading: isLoading
                        )
                    }
                    .padding(ModernDesign.Spacing.lg)
                    .padding(.bottom, ModernDesign.Spacing.xxxl)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        HapticsManager.shared.light()
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(ModernDesign.Colors.textTertiary)
                    }
                }
            }
            .onAppear {
                loadUserData()
            }
            .confirmationDialog("Change Photo", isPresented: $showingPhotoOptions, titleVisibility: .visible) {
                Button("Take Photo") { showingCamera = true }
                Button("Choose from Library") { showingImagePicker = true }
                Button("Cancel", role: .cancel) { }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $selectedImage, sourceType: .photoLibrary)
            }
            .sheet(isPresented: $showingCamera) {
                ImagePicker(image: $selectedImage, sourceType: .camera)
            }
        }
    }
    
    private var defaultAvatar: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [ModernDesign.Colors.primary, ModernDesign.Colors.primary.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 100, height: 100)
            .overlay(
                Text(initials)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            )
    }
    
    @ViewBuilder
    private var profileImageView: some View {
        if let image = selectedImage {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 100, height: 100)
                .clipShape(Circle())
        } else if let photoURL = authService.currentUser?.photoURL,
                  let url = URL(string: photoURL) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                default:
                    defaultAvatar
                }
            }
        } else {
            defaultAvatar
        }
    }
    
    var initials: String {
        let components = name.components(separatedBy: " ")
        let initials = components.compactMap { $0.first }.prefix(2)
        return initials.isEmpty ? "?" : String(initials).uppercased()
    }
    
    private func loadUserData() {
        if let user = authService.currentUser {
            name = user.name
            email = user.email
            phone = user.phone ?? ""
        }
    }
    
    private func saveProfile() {
        guard !name.isEmpty else {
            HapticsManager.shared.error()
            errorMessage = "Please enter your name"
            showError = true
            return
        }
        
        guard let userID = authService.currentUser?.id else {
            HapticsManager.shared.error()
            errorMessage = "User not found"
            showError = true
            return
        }
        
        isLoading = true
        showError = false
        
        Task {
            do {
                var photoURL: String? = authService.currentUser?.photoURL
                
                // Upload new photo if selected
                if let selectedImage = selectedImage {
                    photoURL = try await apiService.uploadImage(selectedImage, type: "profile", id: userID)
                }
                
                // Update user via API
                var updatedUser = authService.currentUser!
                updatedUser.name = name
                updatedUser.phone = phone.isEmpty ? nil : phone
                updatedUser.photoURL = photoURL
                try await apiService.updateUser(updatedUser)
                
                // Update local user state
                await MainActor.run {
                    authService.currentUser = updatedUser
                    
                    HapticsManager.shared.success()
                    showSuccess = true
                    isLoading = false
                    
                    // Auto dismiss after success
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        dismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    HapticsManager.shared.error()
                    errorMessage = error.localizedDescription
                    showError = true
                    isLoading = false
                }
            }
        }
    }
}

struct EditProfileField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    let icon: String
    var keyboardType: UIKeyboardType = .default
    var disabled: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: ModernDesign.Spacing.xs) {
            Text(label)
                .font(ModernDesign.Typography.labelSmall)
                .foregroundColor(ModernDesign.Colors.textSecondary)
            
            HStack(spacing: ModernDesign.Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(disabled ? ModernDesign.Colors.textTertiary : ModernDesign.Colors.primary)
                    .frame(width: 24)
                
                TextField(placeholder, text: $text)
                    .font(ModernDesign.Typography.body)
                    .keyboardType(keyboardType)
                    .disabled(disabled)
                    .foregroundColor(disabled ? ModernDesign.Colors.textTertiary : ModernDesign.Colors.textPrimary)
            }
            .padding(ModernDesign.Spacing.md)
            .background(disabled ? ModernDesign.Colors.border.opacity(0.5) : ModernDesign.Colors.background)
            .cornerRadius(ModernDesign.Radius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: ModernDesign.Radius.medium)
                    .stroke(ModernDesign.Colors.border, lineWidth: 1)
            )
        }
    }
}
