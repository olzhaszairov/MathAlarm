import Foundation

// MARK: - PermissionAuthState

enum PermissionAuthState: Sendable, Equatable {
    case authorized
    case denied
    case notDetermined
    case unavailable
}
