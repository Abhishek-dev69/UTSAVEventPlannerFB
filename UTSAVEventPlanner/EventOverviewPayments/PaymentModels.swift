import Foundation

struct PaymentRecord: Codable {
    let id: String
    let event_id: String?
    let vendor_id: String?
    let amount: Double
    let method: String
    let received_on: String
    let payer_type: String
    let created_at: String?
}

struct PaymentInsert: Encodable {
    let event_id: String?
    let vendor_id: String?
    let amount: Double
    let method: String
    let received_on: String
    let payer_type: String
}
