import SwiftUI

struct QuotationPDFView: View {

    let data: QuotationPDFData

    // Brand Colors
    private let purple = Color(red: 138/255, green: 73/255, blue: 246/255)
    private let lightGray = Color.gray.opacity(0.15)

    var body: some View {
        VStack(spacing: 22) {

            headerSection
            eventInfoSection
            itemsTable
            summaryBox

        }
        .padding(24)
        .frame(width: 595) // A4 width
        .background(Color.white)
    }

    // --------------------------------------------------
    // MARK: Header
    // --------------------------------------------------
    private var headerSection: some View {
        VStack(spacing: 6) {
            Text("UTSAV")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)

            Text("Where Events Flow, Not Fail")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.9))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(purple)
        .cornerRadius(12)
    }

    // --------------------------------------------------
    // MARK: Event Info
    // --------------------------------------------------
    private var eventInfoSection: some View {
        HStack {
            Text("Event:")
                .font(.system(size: 14, weight: .semibold))

            Text(data.eventName.isEmpty ? "—" : data.eventName)
                .font(.system(size: 14))

            Spacer()
        }
        .padding(.horizontal, 4)
    }

    // --------------------------------------------------
    // MARK: Items Table
    // --------------------------------------------------
    private var itemsTable: some View {
        VStack(spacing: 0) {

            // Header Row
            HStack {
                Text("Service")
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("Rate")
                    .frame(width: 70, alignment: .trailing)

                Text("Qty")
                    .frame(width: 40, alignment: .center)

                Text("Total")
                    .frame(width: 80, alignment: .trailing)
            }
            .font(.system(size: 12, weight: .semibold))
            .padding(10)
            .background(lightGray)

            Divider()

            // Data Rows
            ForEach(data.items, id: \.subserviceId) { item in
                HStack {
                    Text(item.subserviceName)
                        .font(.system(size: 13))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("₹\(Int(item.rate))")
                        .frame(width: 70, alignment: .trailing)

                    Text("\(item.quantity)")
                        .frame(width: 40, alignment: .center)

                    Text("₹\(Int(item.lineTotal))")
                        .frame(width: 80, alignment: .trailing)
                        .font(.system(size: 13, weight: .semibold))
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 10)

                Divider()
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(lightGray, lineWidth: 1)
        )
        .cornerRadius(8)
    }

    // --------------------------------------------------
    // MARK: Summary Box
    // --------------------------------------------------
    private var summaryBox: some View {
        VStack(spacing: 12) {

            summaryRow("Subtotal", data.subtotal)
            summaryRow("Tax", data.tax)
            summaryRow("Discount", -data.discount)

            Divider()

            summaryRow(
                "Grand Total",
                data.grandTotal,
                bold: true,
                highlight: true
            )
        }
        .padding(16)
        .background(purple.opacity(0.06))
        .cornerRadius(10)
    }

    private func summaryRow(
        _ title: String,
        _ value: Double,
        bold: Bool = false,
        highlight: Bool = false
    ) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 14, weight: bold ? .semibold : .regular))

            Spacer()

            Text("₹\(Int(value))")
                .font(.system(size: 14, weight: bold ? .bold : .regular))
                .foregroundColor(highlight ? purple : .black)
        }
    }
}

