import Foundation

struct PaymentRecord: Codable {
    let id: String
    let event_id: String?
    let event_name: String?      // Added for persistence
    let vendor_id: String?
    let vendor_name: String?     // Added for persistence
    let total_contracted_amount: Double? // Added for snapshots
    let amount: Double
    let method: String
    let received_on: String
    let payer_type: String
    let created_at: String?
}

struct PaymentInsert: Encodable {
    let planner_id: String      
    let event_id: String?
    let event_name: String?
    let vendor_id: String?
    let vendor_name: String?
    let total_contracted_amount: Double? 
    let amount: Double
    let method: String
    let received_on: String
    let payer_type: String
}
