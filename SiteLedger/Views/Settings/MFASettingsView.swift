import SwiftUI

struct MFASettingsView: View {
    @State private var showEnrollmentSheet = false
    
    var body: some View {
        List {
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Two-Factor Authentication")
                            .font(.headline)
                        Text("Coming Soon")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "shield.slash")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 8)
            }
            
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Label {
                        Text("Enhanced Security")
                    } icon: {
                        Image(systemName: "lock.shield.fill")
                            .foregroundColor(.blue)
                    }
                    
                    Text("Two-factor authentication adds an extra layer of security. This feature will be available in a future update.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            } header: {
                Text("About MFA")
            }
        }
        .navigationTitle("Security")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEnrollmentSheet) {
            MFAEnrollmentView()
        }
    }
}

#Preview {
    NavigationStack {
        MFASettingsView()
    }
}
