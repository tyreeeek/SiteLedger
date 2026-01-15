import Foundation

/// Centralized date formatting utilities for consistent date display across the app
/// Addresses timezone issues by using local timezone for display
enum DateFormatters {
    
    /// Standard date formatter for API communication (ISO8601 UTC)
    static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    /// ISO8601 without fractional seconds (for compatibility)
    static let iso8601WithoutFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
    
    /// Date-only formatter for PostgreSQL DATE type (YYYY-MM-DD)
    static let dateOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0) // UTC
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    
    /// Display date formatter for local timezone
    static let displayDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.timeZone = .current // Use device's local timezone
        return formatter
    }()
    
    /// Display date and time formatter for local timezone
    static let displayDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.timeZone = .current // Use device's local timezone
        return formatter
    }()
    
    /// Short date formatter (e.g., "12/25/23")
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        formatter.timeZone = .current
        return formatter
    }()
    
    /// Long date formatter (e.g., "December 25, 2023")
    static let longDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        formatter.timeZone = .current
        return formatter
    }()
    
    /// Time only formatter (e.g., "3:30 PM")
    static let timeOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.timeZone = .current
        return formatter
    }()
    
    /// Relative date formatter (e.g., "Today", "Yesterday", "2 days ago")
    static let relative: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter
    }()
    
    /// Parse date from API string with multiple format fallbacks
    /// Handles: ISO8601 with/without fractional seconds, and PostgreSQL DATE format (YYYY-MM-DD)
    static func parseAPIDate(_ dateString: String) -> Date? {
        // Try ISO8601 with fractional seconds first
        if let date = iso8601.date(from: dateString) {
            return date
        }
        
        // Try ISO8601 without fractional seconds
        if let date = iso8601WithoutFractionalSeconds.date(from: dateString) {
            return date
        }
        
        // Try PostgreSQL DATE format (YYYY-MM-DD)
        if let date = dateOnly.date(from: dateString) {
            return date
        }
        
        // Try additional common formats
        let fallbackFormatters: [DateFormatter] = [
            {
                let f = DateFormatter()
                f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
                f.timeZone = TimeZone(secondsFromGMT: 0)
                f.locale = Locale(identifier: "en_US_POSIX")
                return f
            }(),
            {
                let f = DateFormatter()
                f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
                f.timeZone = TimeZone(secondsFromGMT: 0)
                f.locale = Locale(identifier: "en_US_POSIX")
                return f
            }(),
            {
                let f = DateFormatter()
                f.dateFormat = "yyyy-MM-dd HH:mm:ss"
                f.timeZone = TimeZone(secondsFromGMT: 0)
                f.locale = Locale(identifier: "en_US_POSIX")
                return f
            }()
        ]
        
        for formatter in fallbackFormatters {
            if let date = formatter.date(from: dateString) {
                return date
            }
        }
        
        return nil
    }
}

/// Extension for easy date string conversion
extension Date {
    /// Convert date to local display string (medium style)
    var localDateString: String {
        DateFormatters.displayDate.string(from: self)
    }
    
    /// Convert date to local date and time string
    var localDateTimeString: String {
        DateFormatters.displayDateTime.string(from: self)
    }
    
    /// Convert date to short format
    var shortDateString: String {
        DateFormatters.shortDate.string(from: self)
    }
    
    /// Convert date to long format
    var longDateString: String {
        DateFormatters.longDate.string(from: self)
    }
    
    /// Convert time only
    var timeString: String {
        DateFormatters.timeOnly.string(from: self)
    }
    
    /// Get relative date string (e.g., "2 hours ago")
    var relativeString: String {
        DateFormatters.relative.localizedString(for: self, relativeTo: Date())
    }
}
