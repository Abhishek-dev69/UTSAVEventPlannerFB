import Foundation

struct VendorEventLiability: Codable {
    let eventId: String
    let eventName: String
    var totalOwed: Double
    var totalPaid: Double
    
    var remaining: Double {
        max(0, totalOwed - totalPaid)
    }
}
