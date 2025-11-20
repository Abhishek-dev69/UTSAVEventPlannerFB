import Foundation

struct UserProfile: Codable {
    let id: String
    let fullName: String?
    let email: String?
    let phone: String?
    let businessName: String?
    let businessAddress: String?
    let profileImageUrl: String?
    let createdAt: String?
    let updatedAt: String?
}

struct UserProfileInsert: Encodable {
    let id: String
    let full_name: String?
    let email: String?
    let phone: String?
    let business_name: String?
    let business_address: String?
    let profile_image_url: String?
}

