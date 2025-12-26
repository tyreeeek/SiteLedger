import SwiftUI

/// Reusable SiteLedger Logo Component - Uses Image Asset
/// @deprecated Use SiteLedgerLogoView instead
struct SiteLedgerLogoView: View {
    /// Logo size: small (70px), medium (100px), large (120px)
    enum Size {
        case small      // 70x70
        case medium     // 100x100
        case large      // 120x120
        
        var dimensions: CGFloat {
            switch self {
            case .small: return 70
            case .medium: return 100
            case .large: return 120
            }
        }
    }
    
    let size: Size
    let showLabel: Bool
    
    init(_ size: Size = .small, showLabel: Bool = true) {
        self.size = size
        self.showLabel = showLabel
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Use image asset if available, otherwise show programmatic version
            Image("SiteLedgerLogo")
                .resizable()
                .scaledToFit()
                .frame(width: size.dimensions, height: size.dimensions)
                .shadow(
                    color: Color(hex: "3B82F6").opacity(0.4),
                    radius: 16,
                    x: 0,
                    y: 6
                )
            
            // Optional label
            if showLabel {
                VStack(spacing: 4) {
                    Text("SiteLedger")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(UIColor.label))
                    
                    Text("Smart contractor")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Color(UIColor.secondaryLabel))
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        SiteLedgerLogoView(.small)
        SiteLedgerLogoView(.medium)
        SiteLedgerLogoView(.large)
    }
    .padding()
    .background(Color(UIColor.systemBackground))
}
