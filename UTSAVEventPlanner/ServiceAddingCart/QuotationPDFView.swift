import SwiftUI

struct QuotationPDFView: View {

    let data: QuotationPDFData

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            Text("Quotation")
                .font(.largeTitle)
                .bold()

            Text("Event: \(data.eventName)")
                .font(.headline)

            Divider()

            ForEach(data.items, id: \.subserviceId) { item in
                HStack {
                    VStack(alignment: .leading) {
                        Text(item.subserviceName)
                            .bold()
                        Text("₹\(Int(item.rate)) × \(item.quantity)")
                            .font(.caption)
                    }
                    Spacer()
                    Text("₹\(Int(item.lineTotal))")
                }
            }

            Divider()

            totalRow("Subtotal", data.subtotal)
            totalRow("Tax", data.tax)
            totalRow("Discount", -data.discount)
            totalRow("Grand Total", data.grandTotal, bold: true)
        }
        .padding(24)
        .frame(width: 595) // A4 width
    }

    private func totalRow(_ title: String, _ value: Double, bold: Bool = false) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text("₹\(Int(value))")
                .fontWeight(bold ? .bold : .regular)
        }
    }
}

