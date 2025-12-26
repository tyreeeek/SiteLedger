import SwiftUI


// MARK: - Account Settings View
struct AccountSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthService
    @State private var showChangePassword = false
    @State private var showChangeEmail = false
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var newEmail = ""
    @State private var emailPassword = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    @State private var successMessage = ""
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            ModernDesign.Colors.background.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: ModernDesign.Spacing.lg) {
                    ModernCard(shadow: true) {
                        VStack(alignment: .leading, spacing: ModernDesign.Spacing.md) {
                            ModernSectionHeader(title: "Email")
                            
                            HStack(spacing: ModernDesign.Spacing.md) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: ModernDesign.Radius.small)
                                        .fill(ModernDesign.Colors.primary.opacity(0.1))
                                        .frame(width: 40, height: 40)
                                    Image(systemName: "envelope.fill")
                                        .foregroundColor(ModernDesign.Colors.primary)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(authService.currentUser?.email ?? "No email")
                                        .font(ModernDesign.Typography.body)
                                        .foregroundColor(ModernDesign.Colors.textPrimary)
                                    Text("Your account email")
                                        .font(ModernDesign.Typography.caption)
                                        .foregroundColor(ModernDesign.Colors.textTertiary)
                                }
                                Spacer()
                            }
                            
                            Divider()
                                .padding(.vertical, ModernDesign.Spacing.xs)
                            
                            Button(action: { showChangeEmail = true }) {
                                HStack(spacing: ModernDesign.Spacing.md) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: ModernDesign.Radius.small)
                                            .fill(ModernDesign.Colors.primary.opacity(0.1))
                                            .frame(width: 40, height: 40)
                                        Image(systemName: "envelope.badge.fill")
                                            .foregroundColor(ModernDesign.Colors.primary)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Change Email")
                                            .font(ModernDesign.Typography.body)
                                            .foregroundColor(ModernDesign.Colors.textPrimary)
                                        Text("Update your email address")
                                            .font(ModernDesign.Typography.caption)
                                            .foregroundColor(ModernDesign.Colors.textTertiary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(ModernDesign.Colors.textTertiary)
                                }
                            }
                        }
                    }
                    
                    // Only show password change for users with passwords (not Apple Sign-In)
                    if authService.currentUser?.hasPassword != false {
                        ModernCard(shadow: true) {
                            VStack(alignment: .leading, spacing: ModernDesign.Spacing.md) {
                                ModernSectionHeader(title: "Password")
                                
                                Button(action: { showChangePassword = true }) {
                                    HStack(spacing: ModernDesign.Spacing.md) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: ModernDesign.Radius.small)
                                                .fill(ModernDesign.Colors.primary.opacity(0.1))
                                                .frame(width: 40, height: 40)
                                            Image(systemName: "lock.fill")
                                                .foregroundColor(ModernDesign.Colors.primary)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Change Password")
                                                .font(ModernDesign.Typography.body)
                                                .foregroundColor(ModernDesign.Colors.textPrimary)
                                            Text("Update your password")
                                                .font(ModernDesign.Typography.caption)
                                                .foregroundColor(ModernDesign.Colors.textTertiary)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(ModernDesign.Colors.textTertiary)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, ModernDesign.Spacing.lg)
                .padding(.top, ModernDesign.Spacing.md)
            }
        }
        .navigationTitle("Account Settings")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showChangePassword) {
            ChangePasswordSheet(
                currentPassword: $currentPassword,
                newPassword: $newPassword,
                confirmPassword: $confirmPassword,
                isLoading: $isLoading,
                onSave: changePassword
            )
        }
        .sheet(isPresented: $showChangeEmail) {
            ChangeEmailSheet(
                newEmail: $newEmail,
                password: $emailPassword,
                currentEmail: authService.currentUser?.email ?? "",
                isLoading: $isLoading,
                onSave: changeEmail
            )
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .alert("Success", isPresented: $showSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(successMessage.isEmpty ? "Changes saved successfully" : successMessage)
        }
    }
    
    private func changePassword() {
        guard newPassword == confirmPassword else {
            errorMessage = "Passwords don't match"
            showError = true
            return
        }
        guard newPassword.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            showError = true
            return
        }
        
        isLoading = true
        
        Task {
            do {
                // Call backend API to change password
                try await APIService.shared.changePassword(
                    currentPassword: currentPassword,
                    newPassword: newPassword
                )
                
                await MainActor.run {
                    isLoading = false
                    showChangePassword = false
                    currentPassword = ""
                    newPassword = ""
                    confirmPassword = ""
                    successMessage = "Password changed successfully"
                    showSuccess = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    private func changeEmail() {
        guard !newEmail.isEmpty else {
            errorMessage = "Please enter a new email"
            showError = true
            return
        }
        guard newEmail.contains("@") && newEmail.contains(".") else {
            errorMessage = "Please enter a valid email"
            showError = true
            return
        }
        guard !emailPassword.isEmpty else {
            errorMessage = "Please enter your password to confirm"
            showError = true
            return
        }
        
        isLoading = true
        
        Task {
            do {
                try await authService.changeEmail(newEmail: newEmail, password: emailPassword)
                
                await MainActor.run {
                    isLoading = false
                    showChangeEmail = false
                    newEmail = ""
                    emailPassword = ""
                    successMessage = "Email changed successfully"
                    showSuccess = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

// MARK: - Change Password Sheet
struct ChangePasswordSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var currentPassword: String
    @Binding var newPassword: String
    @Binding var confirmPassword: String
    @Binding var isLoading: Bool
    var onSave: () -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                ModernDesign.Colors.background.ignoresSafeArea()
                
                VStack(spacing: ModernDesign.Spacing.lg) {
                    ModernCard(shadow: true) {
                        VStack(spacing: ModernDesign.Spacing.md) {
                            SecureField("Current Password", text: $currentPassword)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(ModernDesign.Colors.background)
                                .cornerRadius(ModernDesign.Radius.medium)
                            
                            SecureField("New Password", text: $newPassword)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(ModernDesign.Colors.background)
                                .cornerRadius(ModernDesign.Radius.medium)
                            
                            SecureField("Confirm Password", text: $confirmPassword)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(ModernDesign.Colors.background)
                                .cornerRadius(ModernDesign.Radius.medium)
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, ModernDesign.Spacing.lg)
                .padding(.top, ModernDesign.Spacing.md)
            }
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        onSave()
                    } label: {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("Save")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(isLoading || currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty)
                }
            }
        }
    }
}

// MARK: - Change Email Sheet
struct ChangeEmailSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var newEmail: String
    @Binding var password: String
    let currentEmail: String
    @Binding var isLoading: Bool
    var onSave: () -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                ModernDesign.Colors.background.ignoresSafeArea()
                
                VStack(spacing: ModernDesign.Spacing.lg) {
                    // Current email display
                    ModernCard(shadow: true) {
                        VStack(alignment: .leading, spacing: ModernDesign.Spacing.sm) {
                            Text("Current Email")
                                .font(ModernDesign.Typography.caption)
                                .foregroundColor(ModernDesign.Colors.textSecondary)
                            
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(ModernDesign.Colors.textSecondary)
                                Text(currentEmail)
                                    .font(ModernDesign.Typography.body)
                                    .foregroundColor(ModernDesign.Colors.textPrimary)
                            }
                        }
                    }
                    
                    // New email input
                    ModernCard(shadow: true) {
                        VStack(spacing: ModernDesign.Spacing.md) {
                            VStack(alignment: .leading, spacing: ModernDesign.Spacing.xs) {
                                Text("New Email")
                                    .font(ModernDesign.Typography.caption)
                                    .foregroundColor(ModernDesign.Colors.textSecondary)
                                
                                TextField("Enter new email", text: $newEmail)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .textFieldStyle(.plain)
                                    .padding()
                                    .background(ModernDesign.Colors.background)
                                    .cornerRadius(ModernDesign.Radius.medium)
                            }
                            
                            VStack(alignment: .leading, spacing: ModernDesign.Spacing.xs) {
                                Text("Confirm Password")
                                    .font(ModernDesign.Typography.caption)
                                    .foregroundColor(ModernDesign.Colors.textSecondary)
                                
                                SecureField("Enter your password", text: $password)
                                    .textFieldStyle(.plain)
                                    .padding()
                                    .background(ModernDesign.Colors.background)
                                    .cornerRadius(ModernDesign.Radius.medium)
                            }
                        }
                    }
                    
                    // Info message
                    HStack(alignment: .top, spacing: ModernDesign.Spacing.sm) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: 16))
                        Text("For security, you must enter your password to change your email.")
                            .font(ModernDesign.Typography.caption)
                            .foregroundColor(ModernDesign.Colors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, ModernDesign.Spacing.md)
                    
                    Spacer()
                }
                .padding(.horizontal, ModernDesign.Spacing.lg)
                .padding(.top, ModernDesign.Spacing.md)
            }
            .navigationTitle("Change Email")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        onSave()
                    } label: {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("Save")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(isLoading || newEmail.isEmpty || password.isEmpty)
                }
            }
        }
    }
}

// MARK: - Workers List View
struct WorkersListView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = WorkersViewModel()
    @State private var showAddWorker = false
    
    var body: some View {
        ZStack {
            ModernDesign.Colors.background.ignoresSafeArea()
            
            if viewModel.isLoading {
                ProgressView().scaleEffect(1.2)
            } else if viewModel.workers.isEmpty {
                VStack(spacing: ModernDesign.Spacing.lg) {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 60))
                        .foregroundColor(ModernDesign.Colors.textTertiary)
                    Text("No Workers Yet")
                        .font(ModernDesign.Typography.title2)
                        .foregroundColor(ModernDesign.Colors.textPrimary)
                    Text("Add team members to help manage your jobs")
                        .font(ModernDesign.Typography.body)
                        .foregroundColor(ModernDesign.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                    
                    Button(action: { showAddWorker = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add First Worker")
                        }
                        .font(ModernDesign.Typography.label)
                        .foregroundColor(.white)
                        .padding(.horizontal, ModernDesign.Spacing.xl)
                        .padding(.vertical, ModernDesign.Spacing.md)
                        .background(ModernDesign.Colors.primary)
                        .cornerRadius(ModernDesign.Radius.large)
                    }
                }
                .padding()
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: ModernDesign.Spacing.md) {
                        ForEach(viewModel.workers, id: \.id) { worker in
                            WorkerRowCard(worker: worker) {
                                // Refresh workers list when worker is edited/deleted
                                Task { await viewModel.loadWorkers() }
                            }
                            .id(worker.id ?? UUID().uuidString)
                        }
                    }
                    .padding(.horizontal, ModernDesign.Spacing.lg)
                    .padding(.top, ModernDesign.Spacing.md)
                }
            }
        }
        .navigationTitle("Workers")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showAddWorker = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(ModernDesign.Colors.primary)
                }
            }
        }
        .sheet(isPresented: $showAddWorker) {
            AddWorkerView()
                .environmentObject(authService)
                .onDisappear {
                    // Refresh workers list when add worker sheet closes
                    Task { await viewModel.loadWorkers() }
                }
        }
        .onAppear {
            if authService.currentUser?.id != nil {
                Task { await viewModel.loadWorkers() }
            }
        }
        .refreshable {
            // Pull to refresh
            await viewModel.loadWorkers()
        }
    }
}

// MARK: - Worker Row Card
struct WorkerRowCard: View {
    let worker: User
    @State private var showEditSheet = false
    var onWorkerChanged: (() -> Void)?
    
    var body: some View {
        Button(action: { showEditSheet = true }) {
            ModernCard(shadow: true) {
                HStack(spacing: ModernDesign.Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(ModernDesign.Colors.primary.opacity(0.1))
                            .frame(width: 50, height: 50)
                        Text(worker.name.prefix(1).uppercased())
                            .font(ModernDesign.Typography.title2)
                            .foregroundColor(ModernDesign.Colors.primary)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(worker.name)
                            .font(ModernDesign.Typography.label)
                            .foregroundColor(ModernDesign.Colors.textPrimary)
                        Text(worker.email)
                            .font(ModernDesign.Typography.caption)
                            .foregroundColor(ModernDesign.Colors.textSecondary)
                        if let rate = worker.hourlyRate {
                            Text("$\(String(format: "%.2f", rate))/hr")
                                .font(ModernDesign.Typography.caption)
                                .foregroundColor(ModernDesign.Colors.primary)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 4) {
                        Circle()
                            .fill(worker.active ? Color.green : Color.gray)
                            .frame(width: 10, height: 10)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(ModernDesign.Colors.textTertiary)
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showEditSheet) {
            WorkerDetailView(worker: worker)
                .onDisappear {
                    // Refresh the workers list when edit sheet closes
                    onWorkerChanged?()
                }
        }
    }
}

// MARK: - Worker Detail/Edit View
// MARK: - Worker Detail View with ALL Features
struct WorkerDetailView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthService
    @State var worker: User
    
    // Basic Info
    @State private var name: String
    @State private var email: String
    @State private var hourlyRate: String
    @State private var isActive: Bool
    
    // Loading States
    @State private var isLoading = false
    @State private var isUploadingPhoto = false
    @State private var isSendingInvite = false
    @State private var isResettingPassword = false
    @State private var isDeletingWorker = false
    
    // Photo Upload
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    
    // Reset Password
    @State private var showResetPassword = false
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    
    // Alerts
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    @State private var successMessage = ""
    @State private var showInviteSuccess = false
    @State private var inviteDetails: (email: String, tempPassword: String)?
    @State private var showDeleteConfirmation = false
    
    init(worker: User) {
        self.worker = worker
        _name = State(initialValue: worker.name)
        _email = State(initialValue: worker.email)
        _hourlyRate = State(initialValue: worker.hourlyRate != nil ? String(format: "%.2f", worker.hourlyRate!) : "")
        _isActive = State(initialValue: worker.active)
    }
    
    // MARK: - Computed Properties
    private var profileImageView: some View {
        Group {
            if let selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
            } else if let photoURL = worker.photoURL, !photoURL.isEmpty {
                AsyncImage(url: URL(string: photoURL)) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill()
                    } else {
                        placeholderCircle
                    }
                }
                .frame(width: 80, height: 80)
                .clipShape(Circle())
            } else {
                placeholderCircle
            }
        }
    }
    
    private var placeholderCircle: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [ModernDesign.Colors.primary, ModernDesign.Colors.primaryLight],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 80, height: 80)
            .overlay(
                Text(name.prefix(1).uppercased())
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundColor(.white)
            )
    }
    
    private var profileSection: some View {
        ModernCard(shadow: true) {
            VStack(spacing: ModernDesign.Spacing.md) {
                ZStack(alignment: .bottomTrailing) {
                    profileImageView
                    
                    Button(action: { showImagePicker = true }) {
                        Circle()
                            .fill(ModernDesign.Colors.primary)
                            .frame(width: 32, height: 32)
                            .overlay(
                                Image(systemName: isUploadingPhoto ? "hourglass" : "camera.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                            )
                            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                    .disabled(isUploadingPhoto)
                }
                
                VStack(spacing: 4) {
                    Text(name)
                        .font(ModernDesign.Typography.title3)
                        .foregroundColor(ModernDesign.Colors.textPrimary)
                    Text(email)
                        .font(ModernDesign.Typography.caption)
                        .foregroundColor(ModernDesign.Colors.textSecondary)
                    Text(worker.role == .worker ? "Worker" : "Owner")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(ModernDesign.Colors.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(ModernDesign.Colors.primary.opacity(0.1))
                        .cornerRadius(12)
                }
            }
        }
    }
    
    private var editFormSection: some View {
        ModernCard(shadow: true) {
            VStack(spacing: ModernDesign.Spacing.md) {
                ModernSectionHeader(title: "Worker Information")
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Name")
                        .font(ModernDesign.Typography.caption)
                        .foregroundColor(ModernDesign.Colors.textSecondary)
                    TextField("Worker name", text: $name)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(ModernDesign.Colors.background)
                        .cornerRadius(ModernDesign.Radius.medium)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email")
                        .font(ModernDesign.Typography.caption)
                        .foregroundColor(ModernDesign.Colors.textSecondary)
                    TextField("Email address", text: $email)
                        .textFieldStyle(.plain)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disabled(true)
                        .padding()
                        .background(ModernDesign.Colors.background.opacity(0.5))
                        .cornerRadius(ModernDesign.Radius.medium)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(ModernDesign.Colors.textTertiary)
                            .font(.system(size: 11))
                        Text("Email cannot be changed. Delete and recreate worker to change email.")
                            .font(.system(size: 11))
                            .foregroundColor(ModernDesign.Colors.textTertiary)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Hourly Rate")
                        .font(ModernDesign.Typography.caption)
                        .foregroundColor(ModernDesign.Colors.textSecondary)
                    HStack {
                        Text("$")
                            .font(ModernDesign.Typography.label)
                            .foregroundColor(ModernDesign.Colors.textSecondary)
                        TextField("0.00", text: $hourlyRate)
                            .textFieldStyle(.plain)
                            .keyboardType(.decimalPad)
                    }
                    .padding()
                    .background(ModernDesign.Colors.background)
                    .cornerRadius(ModernDesign.Radius.medium)
                }
                
                Divider()
                
                Toggle(isOn: $isActive) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Active Status")
                            .font(ModernDesign.Typography.label)
                            .foregroundColor(ModernDesign.Colors.textPrimary)
                        Text(isActive ? "Worker can clock in/out" : "Worker is deactivated")
                            .font(ModernDesign.Typography.caption)
                            .foregroundColor(ModernDesign.Colors.textSecondary)
                    }
                }
                .tint(ModernDesign.Colors.primary)
            }
        }
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: ModernDesign.Spacing.md) {
            Button(action: saveChanges) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Save Changes")
                    }
                    .font(ModernDesign.Typography.label)
                    .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(ModernDesign.Colors.primary)
            .cornerRadius(ModernDesign.Radius.large)
            .disabled(isLoading || name.isEmpty || email.isEmpty)
            .opacity((isLoading || name.isEmpty || email.isEmpty) ? 0.5 : 1.0)
            
            Button(action: sendInvite) {
                if isSendingInvite {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    HStack {
                        Image(systemName: "envelope.badge.fill")
                        Text("Send Invitation Email")
                    }
                    .font(ModernDesign.Typography.label)
                    .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(ModernDesign.Colors.success)
            .cornerRadius(ModernDesign.Radius.large)
            .disabled(isSendingInvite)
            
            Button(action: { showResetPassword = true }) {
                HStack {
                    Image(systemName: "key.fill")
                    Text("Reset Password")
                }
                .font(ModernDesign.Typography.label)
                .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.orange)
            .cornerRadius(ModernDesign.Radius.large)
            
            Button(action: { showDeleteConfirmation = true }) {
                if isDeletingWorker {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    HStack {
                        Image(systemName: "trash.fill")
                        Text("Delete Worker")
                    }
                    .font(ModernDesign.Typography.label)
                    .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(ModernDesign.Colors.error)
            .cornerRadius(ModernDesign.Radius.large)
            .disabled(isDeletingWorker)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                ModernDesign.Colors.background.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: ModernDesign.Spacing.xl) {
                        profileSection
                        editFormSection
                        actionButtonsSection
                    }
                    .padding(.horizontal, ModernDesign.Spacing.lg)
                }
            }
            .navigationTitle("Edit Worker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedImage)
            }
            .sheet(isPresented: $showResetPassword) {
                ResetPasswordSheet(
                    isPresented: $showResetPassword,
                    newPassword: $newPassword,
                    confirmPassword: $confirmPassword,
                    isResetting: $isResettingPassword,
                    onReset: resetPassword
                )
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .alert("Success", isPresented: $showSuccess) {
                Button("OK", role: .cancel) {
                    if successMessage.contains("deleted") {
                        dismiss()
                    }
                }
            } message: {
                Text(successMessage)
            }
            .alert("Invitation Sent", isPresented: $showInviteSuccess) {
                Button("Copy Password", action: {
                    if let details = inviteDetails {
                        UIPasteboard.general.string = details.tempPassword
                    }
                })
                Button("OK", role: .cancel) { }
            } message: {
                if let details = inviteDetails {
                    Text("Invitation sent to \(details.email)\n\nTemporary Password: \(details.tempPassword)\n\nWorker will receive an email with login instructions.")
                }
            }
            .alert("Delete Worker", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteWorker()
                }
            } message: {
                Text("Are you sure you want to delete \(name)? This action cannot be undone. All their timesheets and data will be removed.")
            }
            .onChange(of: selectedImage) { _, newImage in
                if newImage != nil {
                    uploadPhoto()
                }
            }
        }
    }
    
    // MARK: - Save Changes
    private func saveChanges() {
        guard !name.isEmpty, !email.isEmpty else {
            errorMessage = "Please fill in all required fields"
            showError = true
            return
        }
        
        // Validate hourly rate
        var rateValue: Double? = nil
        if !hourlyRate.isEmpty {
            guard let rate = Double(hourlyRate), rate >= 0 else {
                errorMessage = "Please enter a valid hourly rate"
                showError = true
                return
            }
            rateValue = rate
        }
        
        isLoading = true
        
        Task {
            do {
                // Update worker via API
                var updatedWorker = worker
                updatedWorker.name = name
                updatedWorker.email = email
                updatedWorker.hourlyRate = rateValue
                updatedWorker.active = isActive
                
                try await APIService.shared.updateWorker(updatedWorker)
                
                await MainActor.run {
                    // Update the local worker state so changes persist in the UI
                    worker.name = name
                    worker.hourlyRate = rateValue
                    worker.active = isActive
                    
                    isLoading = false
                    successMessage = "Worker updated successfully"
                    showSuccess = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    // MARK: - Upload Photo
    private func uploadPhoto() {
        guard let image = selectedImage,
              let imageData = image.jpegData(compressionQuality: 0.7),
              let workerID = worker.id else {
            errorMessage = "Failed to process image"
            showError = true
            return
        }
        
        isUploadingPhoto = true
        
        Task {
            do {
                let filename = "worker_\(workerID)_\(UUID().uuidString).jpg"
                let response = try await APIService.shared.uploadProfilePhoto(imageData: imageData, filename: filename)
                
                // Update worker with new photo URL
                var updatedWorker = worker
                updatedWorker.photoURL = response.url
                try await APIService.shared.updateWorker(updatedWorker)
                
                await MainActor.run {
                    worker.photoURL = response.url
                    isUploadingPhoto = false
                    successMessage = "Photo uploaded successfully"
                    showSuccess = true
                }
            } catch {
                await MainActor.run {
                    isUploadingPhoto = false
                    selectedImage = nil
                    errorMessage = "Failed to upload photo: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
    
    // MARK: - Send Invite
    private func sendInvite() {
        guard let workerID = worker.id else {
            errorMessage = "Worker ID not found"
            showError = true
            return
        }
        
        isSendingInvite = true
        
        Task {
            do {
                let details = try await APIService.shared.sendWorkerInvite(workerID: workerID)
                
                await MainActor.run {
                    isSendingInvite = false
                    inviteDetails = details
                    showInviteSuccess = true
                }
            } catch {
                await MainActor.run {
                    isSendingInvite = false
                    errorMessage = "Failed to send invite: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
    
    // MARK: - Reset Password
    private func resetPassword() {
        guard !newPassword.isEmpty, !confirmPassword.isEmpty else {
            errorMessage = "Please fill in all password fields"
            showError = true
            return
        }
        
        guard newPassword == confirmPassword else {
            errorMessage = "Passwords do not match"
            showError = true
            return
        }
        
        guard newPassword.count >= 8 else {
            errorMessage = "Password must be at least 8 characters"
            showError = true
            return
        }
        
        // Validate password requirements (uppercase, lowercase, number)
        let hasUppercase = newPassword.range(of: "[A-Z]", options: .regularExpression) != nil
        let hasLowercase = newPassword.range(of: "[a-z]", options: .regularExpression) != nil
        let hasNumber = newPassword.range(of: "[0-9]", options: .regularExpression) != nil
        
        guard hasUppercase && hasLowercase && hasNumber else {
            errorMessage = "Password must contain uppercase, lowercase, and number"
            showError = true
            return
        }
        
        guard let workerID = worker.id else {
            errorMessage = "Worker ID not found"
            showError = true
            return
        }
        
        isResettingPassword = true
        
        Task {
            do {
                try await APIService.shared.resetWorkerPassword(workerID: workerID, newPassword: newPassword)
                
                await MainActor.run {
                    isResettingPassword = false
                    showResetPassword = false
                    newPassword = ""
                    confirmPassword = ""
                    successMessage = "Password reset successfully"
                    showSuccess = true
                }
            } catch {
                await MainActor.run {
                    isResettingPassword = false
                    errorMessage = "Failed to reset password: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
    
    // MARK: - Delete Worker
    private func deleteWorker() {
        guard let workerID = worker.id else {
            errorMessage = "Worker ID not found"
            showError = true
            return
        }
        
        isDeletingWorker = true
        
        Task {
            do {
                _ = try await APIService.shared.deleteWorker(id: workerID)
                
                await MainActor.run {
                    isDeletingWorker = false
                    successMessage = "Worker deleted successfully"
                    showSuccess = true
                }
            } catch {
                await MainActor.run {
                    isDeletingWorker = false
                    errorMessage = "Failed to delete worker: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
}

// MARK: - Reset Password Sheet
struct ResetPasswordSheet: View {
    @Binding var isPresented: Bool
    @Binding var newPassword: String
    @Binding var confirmPassword: String
    @Binding var isResetting: Bool
    let onReset: () -> Void
    
    @State private var showPassword = false
    
    var passwordStrength: (String, Color) {
        let hasUppercase = newPassword.range(of: "[A-Z]", options: .regularExpression) != nil
        let hasLowercase = newPassword.range(of: "[a-z]", options: .regularExpression) != nil
        let hasNumber = newPassword.range(of: "[0-9]", options: .regularExpression) != nil
        let hasSpecial = newPassword.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil
        
        if newPassword.isEmpty {
            return ("", .clear)
        } else if newPassword.count < 8 {
            return ("Weak", ModernDesign.Colors.error)
        } else if hasUppercase && hasLowercase && hasNumber && hasSpecial {
            return ("Strong", ModernDesign.Colors.success)
        } else if hasUppercase && hasLowercase && hasNumber {
            return ("Good", Color.orange)
        } else {
            return ("Weak", ModernDesign.Colors.error)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                ModernDesign.Colors.background.ignoresSafeArea()
                
                VStack(spacing: ModernDesign.Spacing.xl) {
                    // Info Card
                    ModernCard(backgroundColor: Color.orange.opacity(0.1), shadow: false) {
                        HStack(spacing: ModernDesign.Spacing.sm) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.system(size: 22))
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Password Requirements")
                                    .font(ModernDesign.Typography.label)
                                    .foregroundColor(ModernDesign.Colors.textPrimary)
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 4) {
                                        Image(systemName: newPassword.count >= 8 ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(newPassword.count >= 8 ? .green : .gray)
                                            .font(.system(size: 10))
                                        Text("At least 8 characters")
                                            .font(.system(size: 11))
                                            .foregroundColor(ModernDesign.Colors.textSecondary)
                                    }
                                    HStack(spacing: 4) {
                                        let hasUpper = newPassword.range(of: "[A-Z]", options: .regularExpression) != nil
                                        Image(systemName: hasUpper ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(hasUpper ? .green : .gray)
                                            .font(.system(size: 10))
                                        Text("One uppercase letter")
                                            .font(.system(size: 11))
                                            .foregroundColor(ModernDesign.Colors.textSecondary)
                                    }
                                    HStack(spacing: 4) {
                                        let hasLower = newPassword.range(of: "[a-z]", options: .regularExpression) != nil
                                        Image(systemName: hasLower ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(hasLower ? .green : .gray)
                                            .font(.system(size: 10))
                                        Text("One lowercase letter")
                                            .font(.system(size: 11))
                                            .foregroundColor(ModernDesign.Colors.textSecondary)
                                    }
                                    HStack(spacing: 4) {
                                        let hasNumber = newPassword.range(of: "[0-9]", options: .regularExpression) != nil
                                        Image(systemName: hasNumber ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(hasNumber ? .green : .gray)
                                            .font(.system(size: 10))
                                        Text("One number")
                                            .font(.system(size: 11))
                                            .foregroundColor(ModernDesign.Colors.textSecondary)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    ModernCard(shadow: true) {
                        VStack(spacing: ModernDesign.Spacing.md) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("New Password")
                                        .font(ModernDesign.Typography.caption)
                                        .foregroundColor(ModernDesign.Colors.textSecondary)
                                    Spacer()
                                    if !newPassword.isEmpty {
                                        Text(passwordStrength.0)
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(passwordStrength.1)
                                    }
                                }
                                
                                HStack {
                                    if showPassword {
                                        TextField("Enter new password", text: $newPassword)
                                            .textFieldStyle(.plain)
                                    } else {
                                        SecureField("Enter new password", text: $newPassword)
                                            .textFieldStyle(.plain)
                                    }
                                    
                                    Button(action: { showPassword.toggle() }) {
                                        Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                            .foregroundColor(ModernDesign.Colors.textTertiary)
                                            .font(.system(size: 14))
                                    }
                                }
                                .padding()
                                .background(ModernDesign.Colors.background)
                                .cornerRadius(ModernDesign.Radius.medium)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Confirm Password")
                                    .font(ModernDesign.Typography.caption)
                                    .foregroundColor(ModernDesign.Colors.textSecondary)
                                SecureField("Confirm new password", text: $confirmPassword)
                                    .textFieldStyle(.plain)
                                    .padding()
                                    .background(ModernDesign.Colors.background)
                                    .cornerRadius(ModernDesign.Radius.medium)
                                
                                if !confirmPassword.isEmpty && confirmPassword != newPassword {
                                    HStack(spacing: 6) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(ModernDesign.Colors.error)
                                            .font(.system(size: 11))
                                        Text("Passwords do not match")
                                            .font(.system(size: 11))
                                            .foregroundColor(ModernDesign.Colors.error)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Button(action: onReset) {
                        if isResetting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            HStack {
                                Image(systemName: "key.fill")
                                Text("Reset Password")
                            }
                            .font(ModernDesign.Typography.label)
                            .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.orange)
                    .cornerRadius(ModernDesign.Radius.large)
                    .padding(.horizontal)
                    .disabled(isResetting || newPassword.isEmpty || confirmPassword.isEmpty || newPassword != confirmPassword)
                    .opacity((isResetting || newPassword.isEmpty || confirmPassword.isEmpty || newPassword != confirmPassword) ? 0.5 : 1.0)
                    
                    Spacer()
                }
                .padding(.top, ModernDesign.Spacing.xl)
            }
            .navigationTitle("Reset Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
            }
        }
    }
}
// MARK: - Add Worker View
struct AddWorkerView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthService
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var hourlyRate = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showWarning = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                ModernDesign.Colors.background.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: ModernDesign.Spacing.lg) {
                        // Info Card - Invitation Details
                        ModernCard(backgroundColor: ModernDesign.Colors.primary.opacity(0.08), shadow: false) {
                            VStack(alignment: .leading, spacing: ModernDesign.Spacing.md) {
                                HStack(spacing: ModernDesign.Spacing.sm) {
                                    Image(systemName: "envelope.badge.fill")
                                        .foregroundColor(ModernDesign.Colors.primary)
                                        .font(.system(size: 22))
                                    Text("Invitation Email")
                                        .font(ModernDesign.Typography.label)
                                        .foregroundColor(ModernDesign.Colors.textPrimary)
                                }
                                
                                VStack(alignment: .leading, spacing: ModernDesign.Spacing.xs) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(ModernDesign.Colors.success)
                                            .font(.system(size: 12))
                                        Text("Login credentials sent via email")
                                            .font(ModernDesign.Typography.caption)
                                            .foregroundColor(ModernDesign.Colors.textSecondary)
                                    }
                                    HStack(spacing: 6) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(ModernDesign.Colors.success)
                                            .font(.system(size: 12))
                                        Text("App download instructions included")
                                            .font(ModernDesign.Typography.caption)
                                            .foregroundColor(ModernDesign.Colors.textSecondary)
                                    }
                                    HStack(spacing: 6) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(ModernDesign.Colors.success)
                                            .font(.system(size: 12))
                                        Text("Worker can change password after login")
                                            .font(ModernDesign.Typography.caption)
                                            .foregroundColor(ModernDesign.Colors.textSecondary)
                                    }
                                }
                            }
                        }
                        
                        ModernCard(shadow: true) {
                            VStack(spacing: ModernDesign.Spacing.md) {
                                VStack(alignment: .leading, spacing: ModernDesign.Spacing.xs) {
                                    Text("Name")
                                        .font(ModernDesign.Typography.caption)
                                        .foregroundColor(ModernDesign.Colors.textSecondary)
                                    TextField("Worker name", text: $name)
                                        .textFieldStyle(.plain)
                                        .padding()
                                        .background(ModernDesign.Colors.background)
                                        .cornerRadius(ModernDesign.Radius.medium)
                                }
                                
                                VStack(alignment: .leading, spacing: ModernDesign.Spacing.xs) {
                                    Text("Email")
                                        .font(ModernDesign.Typography.caption)
                                        .foregroundColor(ModernDesign.Colors.textSecondary)
                                    TextField("worker@example.com", text: $email)
                                        .textFieldStyle(.plain)
                                        .textInputAutocapitalization(.never)
                                        .keyboardType(.emailAddress)
                                        .padding()
                                        .background(ModernDesign.Colors.background)
                                        .cornerRadius(ModernDesign.Radius.medium)
                                }
                                
                                // Password will be auto-generated
                                ModernCard(backgroundColor: ModernDesign.Colors.success.opacity(0.1), shadow: false) {
                                    HStack(spacing: ModernDesign.Spacing.sm) {
                                        Image(systemName: "lock.shield.fill")
                                            .foregroundColor(ModernDesign.Colors.success)
                                            .font(.system(size: 18))
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Secure Password")
                                                .font(ModernDesign.Typography.labelSmall)
                                                .foregroundColor(ModernDesign.Colors.textPrimary)
                                            Text("A temporary password will be auto-generated and sent via email")
                                                .font(.system(size: 11))
                                                .foregroundColor(ModernDesign.Colors.textSecondary)
                                        }
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: ModernDesign.Spacing.xs) {
                                    Text("Hourly Rate (Optional)")
                                        .font(ModernDesign.Typography.caption)
                                        .foregroundColor(ModernDesign.Colors.textSecondary)
                                    TextField("$0.00", text: $hourlyRate)
                                        .textFieldStyle(.plain)
                                        .keyboardType(.decimalPad)
                                        .padding()
                                        .background(ModernDesign.Colors.background)
                                        .cornerRadius(ModernDesign.Radius.medium)
                                }
                            }
                        }
                        
                        Button(action: { showWarning = true }) {
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                HStack {
                                    Image(systemName: "envelope.badge.person.crop")
                                    Text("Add Worker & Send Invite")
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, ModernDesign.Spacing.md)
                        .background(formIsValid ? ModernDesign.Colors.primary : ModernDesign.Colors.textTertiary)
                        .foregroundColor(.white)
                        .font(ModernDesign.Typography.label)
                        .cornerRadius(ModernDesign.Radius.large)
                        .disabled(!formIsValid || isLoading)
                    }
                    .padding(.horizontal, ModernDesign.Spacing.lg)
                    .padding(.top, ModernDesign.Spacing.md)
                }
            }
            .navigationTitle("Add Worker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .alert("Create Worker Account?", isPresented: $showWarning) {
                Button("Cancel", role: .cancel) { }
                Button("Create & Send Invite") {
                    addWorker()
                }
            } message: {
                Text("This will create the worker account and send them an invitation email to set up their password.")
            }
        }
    }
    
    private var formIsValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && 
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        // Password will be auto-generated, so no validation needed
    }
    
    private func generateSecurePassword() -> String {
        // Generate a secure random password: 10 characters + uppercase + digit
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let randomString = String((0..<10).compactMap { _ in characters.randomElement() })
        return randomString + "A1" // Ensure it meets requirements (uppercase + digit)
    }
    
    private func addWorker() {
        isLoading = true
        Task {
            do {
                guard let ownerID = authService.currentUser?.id else {
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not signed in"])
                }
                
                // Parse hourly rate if provided
                let hourlyRateValue: Double? = {
                    let trimmed = hourlyRate.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return nil }
                    // Remove $ and commas
                    let cleaned = trimmed.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")
                    return Double(cleaned)
                }()
                
                // Auto-generate a secure temporary password
                let autoGeneratedPassword = generateSecurePassword()
                
                // Step 1: Create worker account with auto-generated password
                try await authService.createWorker(
                    email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                    password: autoGeneratedPassword,
                    name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                    ownerID: ownerID,
                    hourlyRate: hourlyRateValue
                )
                
                // Step 2: Fetch the newly created worker to get their ID
                let workers = try await APIService.shared.fetchWorkers()
                if let newWorker = workers.first(where: { $0.email.lowercased() == email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }),
                   let workerID = newWorker.id {
                    
                    // Step 3: Send invitation email
                    do {
                        let inviteDetails = try await APIService.shared.sendWorkerInvite(workerID: workerID)
                        
                        await MainActor.run {
                            isLoading = false
                            // Show success with temp password
                            errorMessage = "✅ Worker added and invitation sent!\n\nEmail: \(inviteDetails.email)\nTemp Password: \(inviteDetails.tempPassword)\n\nThey will receive an email with login instructions."
                            showError = true  // Reuse error alert to show success message
                        }
                    } catch {
                        // Worker created but email failed - still show success
                        await MainActor.run {
                            isLoading = false
                            errorMessage = "Worker added successfully, but failed to send invitation email. You can resend it from the Edit Worker screen."
                            showError = true
                        }
                    }
                } else {
                    // Worker created but couldn't find to send email
                    await MainActor.run {
                        isLoading = false
                        errorMessage = "Worker added successfully! You can send an invitation from the Edit Worker screen."
                        showError = true
                    }
                }
                
                // Dismiss after showing message
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                await MainActor.run { 
                    dismiss() 
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Alert History View
struct AlertHistoryView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = AlertsViewModel()
    
    var body: some View {
        ZStack {
            ModernDesign.Colors.background.ignoresSafeArea()
            
            if viewModel.isLoading {
                ProgressView().scaleEffect(1.2)
            } else if viewModel.allAlerts.isEmpty {
                VStack(spacing: ModernDesign.Spacing.lg) {
                    Image(systemName: "bell.slash.fill")
                        .font(.system(size: 60))
                        .foregroundColor(ModernDesign.Colors.textTertiary)
                    Text("No Alerts")
                        .font(ModernDesign.Typography.title2)
                        .foregroundColor(ModernDesign.Colors.textPrimary)
                    Text("You're all caught up!")
                        .font(ModernDesign.Typography.body)
                        .foregroundColor(ModernDesign.Colors.textSecondary)
                }
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: ModernDesign.Spacing.md) {
                        ForEach(viewModel.allAlerts, id: \.id) { alert in
                            AlertRowCard(alert: alert)
                                .id(alert.id ?? UUID().uuidString)
                        }
                    }
                    .padding(.horizontal, ModernDesign.Spacing.lg)
                    .padding(.top, ModernDesign.Spacing.md)
                }
            }
        }
        .navigationTitle("Alerts")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            if let userID = authService.currentUser?.id {
                viewModel.loadAlerts(forOwnerID: userID)
            }
        }
    }
}

// MARK: - Alert Row Card
struct AlertRowCard: View {
    let alert: Alert
    
    var body: some View {
        ModernCard(shadow: true) {
            HStack(spacing: ModernDesign.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(alertColor.opacity(0.1))
                        .frame(width: 44, height: 44)
                    Image(systemName: alertIcon)
                        .font(.system(size: 18))
                        .foregroundColor(alertColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(alert.title)
                        .font(ModernDesign.Typography.label)
                        .foregroundColor(ModernDesign.Colors.textPrimary)
                    Text(alert.message)
                        .font(ModernDesign.Typography.caption)
                        .foregroundColor(ModernDesign.Colors.textSecondary)
                        .lineLimit(2)
                    Text(alert.createdAt, style: .relative)
                        .font(ModernDesign.Typography.captionSmall)
                        .foregroundColor(ModernDesign.Colors.textTertiary)
                }
                
                Spacer()
                
                if !alert.read {
                    Circle()
                        .fill(ModernDesign.Colors.primary)
                        .frame(width: 8, height: 8)
                }
            }
        }
    }
    
    private var alertColor: Color {
        switch alert.type {
        case .budget: return .orange
        case .payment: return .green
        case .timesheet: return .blue
        case .labor: return .purple
        case .receipt: return .pink
        case .document: return .cyan
        }
    }
    
    private var alertIcon: String {
        switch alert.type {
        case .budget: return "exclamationmark.triangle.fill"
        case .payment: return "dollarsign.circle.fill"
        case .timesheet: return "clock.fill"
        case .labor: return "person.2.fill"
        case .receipt: return "receipt.fill"
        case .document: return "doc.fill"
        }
    }
}

// MARK: - AI Insights View
struct AIInsightsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = AIInsightsViewModel()
    
    var body: some View {
        ZStack {
            ModernDesign.Colors.background.ignoresSafeArea()
            
            if viewModel.isLoading {
                VStack(spacing: ModernDesign.Spacing.md) {
                    ProgressView().scaleEffect(1.2)
                    Text("Loading insights...")
                        .font(ModernDesign.Typography.body)
                        .foregroundColor(ModernDesign.Colors.textSecondary)
                }
            } else if viewModel.insights.isEmpty {
                VStack(spacing: ModernDesign.Spacing.lg) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 60))
                        .foregroundColor(ModernDesign.Colors.textTertiary)
                    Text("No Insights Yet")
                        .font(ModernDesign.Typography.title2)
                        .foregroundColor(ModernDesign.Colors.textPrimary)
                    Text("Add more data to get AI insights")
                        .font(ModernDesign.Typography.body)
                        .foregroundColor(ModernDesign.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: ModernDesign.Spacing.md) {
                        ForEach(viewModel.insights, id: \.id) { insight in
                            InsightCard(insight: insight)
                                .id(insight.id ?? UUID().uuidString)
                        }
                    }
                    .padding(.horizontal, ModernDesign.Spacing.lg)
                    .padding(.top, ModernDesign.Spacing.md)
                }
            }
        }
        .navigationTitle("AI Insights")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            if let ownerID = authService.currentUser?.id {
                Task { await viewModel.loadInsights(ownerID: ownerID) }
            }
        }
    }
}

// MARK: - Insight Card
struct InsightCard: View {
    let insight: AIInsight
    
    var body: some View {
        ModernCard(shadow: true) {
            HStack(alignment: .top, spacing: ModernDesign.Spacing.md) {
                Image(systemName: iconForCategory)
                    .font(.system(size: 20))
                    .foregroundColor(colorForSeverity)
                
                VStack(alignment: .leading, spacing: ModernDesign.Spacing.xs) {
                    Text(insight.insight)
                        .font(ModernDesign.Typography.body)
                        .foregroundColor(ModernDesign.Colors.textPrimary)
                    
                    HStack {
                        Text(insight.category.capitalized)
                            .font(ModernDesign.Typography.caption)
                            .foregroundColor(ModernDesign.Colors.textSecondary)
                        
                        Spacer()
                        
                        Text(insight.createdAt, style: .relative)
                            .font(ModernDesign.Typography.caption)
                            .foregroundColor(ModernDesign.Colors.textTertiary)
                    }
                }
            }
        }
    }
    
    private var iconForCategory: String {
        switch insight.category {
        case "cost": return "dollarsign.circle.fill"
        case "profit": return "chart.line.uptrend.xyaxis"
        case "labor": return "person.2.fill"
        case "efficiency": return "gauge.high"
        default: return "lightbulb.fill"
        }
    }
    
    private var colorForSeverity: Color {
        switch insight.severity {
        case "critical": return .red
        case "warning": return .orange
        default: return .yellow
        }
    }
}

// MARK: - All Timesheets View
struct AllTimesheetsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = TimesheetViewModel()
    @State private var workerNames: [String: String] = [:]  // workerID -> name
    
    // Group timesheets by workerID
    private var groupedTimesheets: [(workerID: String, timesheets: [Timesheet], totalHours: Double)] {
        let grouped = Dictionary(grouping: viewModel.timesheets) { $0.workerID ?? "unknown" }
        return grouped.map { workerID, timesheets in
            let totalHours = timesheets.reduce(0) { $0 + ($1.hours ?? 0) }
            return (workerID: workerID, timesheets: timesheets, totalHours: totalHours)
        }.sorted { $0.totalHours > $1.totalHours }  // Sort by most hours first
    }
    
    var body: some View {
        ZStack {
            ModernDesign.Colors.background.ignoresSafeArea()
            
            if viewModel.isLoading {
                ProgressView().scaleEffect(1.2)
            } else if viewModel.timesheets.isEmpty {
                VStack(spacing: ModernDesign.Spacing.lg) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 60))
                        .foregroundColor(ModernDesign.Colors.textTertiary)
                    Text("No Timesheets")
                        .font(ModernDesign.Typography.title2)
                        .foregroundColor(ModernDesign.Colors.textPrimary)
                    Text("Time entries will appear here")
                        .font(ModernDesign.Typography.body)
                        .foregroundColor(ModernDesign.Colors.textSecondary)
                }
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: ModernDesign.Spacing.lg, pinnedViews: []) {
                        ForEach(groupedTimesheets, id: \.workerID) { group in
                            VStack(alignment: .leading, spacing: ModernDesign.Spacing.md) {
                                // Worker Header
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(workerNames[group.workerID] ?? "Worker")
                                            .font(ModernDesign.Typography.title3)
                                            .foregroundColor(ModernDesign.Colors.textPrimary)
                                        Text("\(group.timesheets.count) entries • \(String(format: "%.2f", group.totalHours)) hours")
                                            .font(ModernDesign.Typography.caption)
                                            .foregroundColor(ModernDesign.Colors.textSecondary)
                                    }
                                    Spacer()
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(ModernDesign.Colors.primary)
                                        .padding(12)
                                        .background(ModernDesign.Colors.primary.opacity(0.1))
                                        .cornerRadius(ModernDesign.Radius.medium)
                                }
                                .padding(.horizontal, ModernDesign.Spacing.lg)
                                
                                // Timesheets for this worker
                                ForEach(group.timesheets, id: \.id) { timesheet in
                                    TimesheetRowCard(timesheet: timesheet)
                                        .padding(.horizontal, ModernDesign.Spacing.lg)
                                        .id(timesheet.id ?? UUID().uuidString)
                                }
                            }
                        }
                    }
                    .padding(.top, ModernDesign.Spacing.md)
                }
            }
        }
        .navigationTitle("All Timesheets")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            if let userID = authService.currentUser?.id {
                viewModel.loadAllTimesheetsForOwner(ownerID: userID)
                loadWorkerNames()
            }
        }
    }
    
    // Load worker names from API
    private func loadWorkerNames() {
        let uniqueWorkerIDs = Set(viewModel.timesheets.map { $0.workerID })
        
        Task {
            for workerID in uniqueWorkerIDs {
                do {
                    if let workerID = workerID, let user = try await APIService.shared.fetchUser(userID: workerID) {
                        await MainActor.run {
                            workerNames[workerID] = user.name
                        }
                    }
                } catch {
                }
            }
        }
    }
}

// MARK: - Timesheet Row Card
struct TimesheetRowCard: View {
    let timesheet: Timesheet
    
    var body: some View {
        ModernCard(shadow: true) {
            VStack(alignment: .leading, spacing: ModernDesign.Spacing.sm) {
                HStack {
                    Text(timesheet.clockIn ?? Date(), style: .date)
                        .font(ModernDesign.Typography.label)
                        .foregroundColor(ModernDesign.Colors.textPrimary)
                    Spacer()
                    Text(String(format: "%.2f hrs", timesheet.hours ?? 0))
                        .font(ModernDesign.Typography.label)
                        .foregroundColor(ModernDesign.Colors.primary)
                }
                
                HStack {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 12))
                        .foregroundColor(ModernDesign.Colors.textTertiary)
                    Text("\(timesheet.clockIn ?? Date(), style: .time) - \(timesheet.clockOut ?? Date(), style: .time)")
                        .font(ModernDesign.Typography.caption)
                        .foregroundColor(ModernDesign.Colors.textSecondary)
                }
                
                if !(timesheet.notes ?? "").isEmpty {
                    Text(timesheet.notes ?? "")
                        .font(ModernDesign.Typography.caption)
                        .foregroundColor(ModernDesign.Colors.textSecondary)
                        .lineLimit(2)
                }
            }
        }
    }
}

// MARK: - Notification Settings View
struct NotificationSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("pushNotificationsEnabled") private var pushEnabled = true
    @AppStorage("emailNotificationsEnabled") private var emailEnabled = false
    @AppStorage("budgetAlertsEnabled") private var budgetAlerts = true
    @AppStorage("paymentRemindersEnabled") private var paymentReminders = true
    
    var body: some View {
        ZStack {
            ModernDesign.Colors.background.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: ModernDesign.Spacing.lg) {
                    ModernCard(shadow: true) {
                        VStack(alignment: .leading, spacing: ModernDesign.Spacing.md) {
                            ModernSectionHeader(title: "General")
                            
                            Toggle(isOn: $pushEnabled) {
                                HStack(spacing: ModernDesign.Spacing.md) {
                                    Image(systemName: "bell.fill")
                                        .foregroundColor(ModernDesign.Colors.primary)
                                    Text("Push Notifications")
                                        .font(ModernDesign.Typography.body)
                                        .foregroundColor(ModernDesign.Colors.textPrimary)
                                }
                            }
                            .tint(ModernDesign.Colors.primary)
                            
                            Divider()
                            
                            Toggle(isOn: $emailEnabled) {
                                HStack(spacing: ModernDesign.Spacing.md) {
                                    Image(systemName: "envelope.fill")
                                        .foregroundColor(ModernDesign.Colors.primary)
                                    Text("Email Notifications")
                                        .font(ModernDesign.Typography.body)
                                        .foregroundColor(ModernDesign.Colors.textPrimary)
                                }
                            }
                            .tint(ModernDesign.Colors.primary)
                        }
                    }
                    
                    ModernCard(shadow: true) {
                        VStack(alignment: .leading, spacing: ModernDesign.Spacing.md) {
                            ModernSectionHeader(title: "Alert Types")
                            
                            Toggle(isOn: $budgetAlerts) {
                                Text("Budget Alerts")
                                    .font(ModernDesign.Typography.body)
                                    .foregroundColor(ModernDesign.Colors.textPrimary)
                            }
                            .tint(ModernDesign.Colors.primary)
                            
                            Divider()
                            
                            Toggle(isOn: $paymentReminders) {
                                Text("Payment Reminders")
                                    .font(ModernDesign.Typography.body)
                                    .foregroundColor(ModernDesign.Colors.textPrimary)
                            }
                            .tint(ModernDesign.Colors.primary)
                        }
                    }
                }
                .padding(.horizontal, ModernDesign.Spacing.lg)
                .padding(.top, ModernDesign.Spacing.md)
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - App Settings View
struct AppSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("hapticFeedback") private var hapticFeedback = true
    
    var body: some View {
        ZStack {
            ModernDesign.Colors.background.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: ModernDesign.Spacing.lg) {
                    ModernCard(shadow: true) {
                        VStack(alignment: .leading, spacing: ModernDesign.Spacing.md) {
                            ModernSectionHeader(title: "Appearance")
                            
                            Toggle(isOn: $isDarkMode) {
                                HStack(spacing: ModernDesign.Spacing.md) {
                                    Image(systemName: "moon.fill")
                                        .foregroundColor(ModernDesign.Colors.primary)
                                    Text("Dark Mode")
                                        .font(ModernDesign.Typography.body)
                                        .foregroundColor(ModernDesign.Colors.textPrimary)
                                }
                            }
                            .tint(ModernDesign.Colors.primary)
                        }
                    }
                    
                    ModernCard(shadow: true) {
                        VStack(alignment: .leading, spacing: ModernDesign.Spacing.md) {
                            ModernSectionHeader(title: "Behavior")
                            
                            Toggle(isOn: $hapticFeedback) {
                                HStack(spacing: ModernDesign.Spacing.md) {
                                    Image(systemName: "waveform")
                                        .foregroundColor(ModernDesign.Colors.primary)
                                    Text("Haptic Feedback")
                                        .font(ModernDesign.Typography.body)
                                        .foregroundColor(ModernDesign.Colors.textPrimary)
                                }
                            }
                            .tint(ModernDesign.Colors.primary)
                        }
                    }
                    
                    ModernCard(shadow: true) {
                        VStack(alignment: .leading, spacing: ModernDesign.Spacing.md) {
                            ModernSectionHeader(title: "About")
                            
                            HStack {
                                Text("Version")
                                    .font(ModernDesign.Typography.body)
                                    .foregroundColor(ModernDesign.Colors.textPrimary)
                                Spacer()
                                Text("1.0.0")
                                    .font(ModernDesign.Typography.body)
                                    .foregroundColor(ModernDesign.Colors.textSecondary)
                            }
                        }
                    }
                }
                .padding(.horizontal, ModernDesign.Spacing.lg)
                .padding(.top, ModernDesign.Spacing.md)
            }
        }
        .navigationTitle("App Settings")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - FAQ View
struct FAQView: View {
    @Environment(\.dismiss) var dismiss
    
    private let faqs = [
        ("How do I add a new job?", "Tap Jobs tab, then tap + button."),
        ("How do I add receipts?", "Go to Receipts tab and tap + to add."),
        ("How is profit calculated?", "Profit = Project Value - Labor Cost."),
        ("Can I add workers?", "Yes! Go to More > Workers and tap +.")
    ]
    
    var body: some View {
        ZStack {
            ModernDesign.Colors.background.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: ModernDesign.Spacing.md) {
                    ForEach(faqs, id: \.0) { faq in
                        FAQCard(question: faq.0, answer: faq.1)
                    }
                }
                .padding(.horizontal, ModernDesign.Spacing.lg)
                .padding(.top, ModernDesign.Spacing.md)
            }
        }
        .navigationTitle("FAQ")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - FAQ Card
struct FAQCard: View {
    let question: String
    let answer: String
    @State private var isExpanded = false
    
    var body: some View {
        ModernCard(shadow: true) {
            VStack(alignment: .leading, spacing: ModernDesign.Spacing.sm) {
                Button(action: { withAnimation { isExpanded.toggle() } }) {
                    HStack {
                        Text(question)
                            .font(ModernDesign.Typography.label)
                            .foregroundColor(ModernDesign.Colors.textPrimary)
                            .multilineTextAlignment(.leading)
                        Spacer()
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(ModernDesign.Colors.primary)
                    }
                }
                
                if isExpanded {
                    Divider()
                    Text(answer)
                        .font(ModernDesign.Typography.body)
                        .foregroundColor(ModernDesign.Colors.textSecondary)
                }
            }
        }
    }
}

// MARK: - Support View
struct SupportView: View {
    @Environment(\.dismiss) var dismiss
    @State private var subject = ""
    @State private var message = ""
    @State private var showSuccess = false
    
    var body: some View {
        ZStack {
            ModernDesign.Colors.background.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: ModernDesign.Spacing.lg) {
                    ModernCard(shadow: true) {
                        VStack(alignment: .leading, spacing: ModernDesign.Spacing.md) {
                            ModernSectionHeader(title: "Contact Us")
                            
                            Button(action: { openEmail() }) {
                                HStack(spacing: ModernDesign.Spacing.md) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: ModernDesign.Radius.small)
                                            .fill(ModernDesign.Colors.primary.opacity(0.1))
                                            .frame(width: 40, height: 40)
                                        Image(systemName: "envelope.fill")
                                            .foregroundColor(ModernDesign.Colors.primary)
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Email Support")
                                            .font(ModernDesign.Typography.body)
                                            .foregroundColor(ModernDesign.Colors.textPrimary)
                                        Text("support@siteledger.ai")
                                            .font(ModernDesign.Typography.caption)
                                            .foregroundColor(ModernDesign.Colors.textSecondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14))
                                        .foregroundColor(ModernDesign.Colors.textTertiary)
                                }
                            }
                        }
                    }
                    
                    ModernCard(shadow: true) {
                        VStack(alignment: .leading, spacing: ModernDesign.Spacing.md) {
                            ModernSectionHeader(title: "Send a Message")
                            
                            VStack(alignment: .leading, spacing: ModernDesign.Spacing.xs) {
                                Text("Subject")
                                    .font(ModernDesign.Typography.caption)
                                    .foregroundColor(ModernDesign.Colors.textSecondary)
                                TextField("What's this about?", text: $subject)
                                    .textFieldStyle(.plain)
                                    .padding()
                                    .background(ModernDesign.Colors.background)
                                    .cornerRadius(ModernDesign.Radius.medium)
                            }
                            
                            VStack(alignment: .leading, spacing: ModernDesign.Spacing.xs) {
                                Text("Message")
                                    .font(ModernDesign.Typography.caption)
                                    .foregroundColor(ModernDesign.Colors.textSecondary)
                                TextEditor(text: $message)
                                    .frame(minHeight: 120)
                                    .padding(ModernDesign.Spacing.sm)
                                    .background(ModernDesign.Colors.background)
                                    .cornerRadius(ModernDesign.Radius.medium)
                            }
                            
                            Button(action: sendMessage) {
                                Text("Send Message")
                                    .frame(maxWidth: .infinity)
                            }
                            .padding(.vertical, ModernDesign.Spacing.md)
                            .background(formIsValid ? ModernDesign.Colors.primary : ModernDesign.Colors.textTertiary)
                            .foregroundColor(.white)
                            .font(ModernDesign.Typography.label)
                            .cornerRadius(ModernDesign.Radius.large)
                            .disabled(!formIsValid)
                        }
                    }
                }
                .padding(.horizontal, ModernDesign.Spacing.lg)
                .padding(.top, ModernDesign.Spacing.md)
            }
        }
        .navigationTitle("Support")
        .navigationBarTitleDisplayMode(.large)
        .alert("Message Sent", isPresented: $showSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("We'll get back to you within 24 hours.")
        }
    }
    
    private var formIsValid: Bool {
        !subject.isEmpty && !message.isEmpty
    }
    
    private func openEmail() {
        if let url = URL(string: "mailto:support@siteledger.ai") {
            UIApplication.shared.open(url)
        }
    }
    
    private func sendMessage() {
        showSuccess = true
        subject = ""
        message = ""
    }
}
