import SwiftUI

struct MFAEnrollmentView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()
                
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Two-Factor Authentication")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("MFA enrollment will be available in a future update.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
                
                Button("Close") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .padding(.bottom, 40)
            }
            .padding()
            .navigationTitle("Setup MFA")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    MFAEnrollmentView()
}
