import SwiftUI

struct QuotationPDFView: View {

    let data: QuotationPDFData

    // ✅ FIXED BRAND COLORS (NON-DYNAMIC)
    private let purple = Color(red: 138/255, green: 73/255, blue: 246/255)
    private let lightGray = Color(red: 235/255, green: 235/255, blue: 235/255)

    var body: some View {
        VStack(spacing: 22) {

            headerSection
            eventInfoSection
            itemsTable
            summaryBox

        }
        .padding(24)
        .frame(width: 595)                // A4 width
        .background(Color.white)          // ✅ FIXED BACKGROUND
        .environment(\.colorScheme, .light) // ✅ FORCE LIGHT MODE
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
        VStack(alignment: .leading, spacing: 6) {
            infoRow(title: "Event", value: data.eventName)
            infoRow(title: "Client", value: data.clientName)
            infoRow(title: "Location", value: data.location)
            infoRow(title: "Date", value: data.eventDate)
        }
        .padding(.horizontal, 4)
    }

    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text("\(title):")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.black)

            Text(value.isEmpty ? "—" : value)
                .font(.system(size: 14))
                .foregroundColor(.black)

            Spacer()
        }
    }

    // --------------------------------------------------
    // MARK: Items Table
    // --------------------------------------------------
    private var itemsTable: some View {
        VStack(spacing: 0) {

            HStack {
                tableHeader("Service", align: .leading, flex: true)
                tableHeader("Rate", width: 70)
                tableHeader("Qty", width: 40)
                tableHeader("Total", width: 80)
            }
            .padding(10)
            .background(lightGray)

            Divider()

            ForEach(data.items, id: \.subserviceId) { item in
                HStack {
                    Text(item.subserviceName)
                        .font(.system(size: 13))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("₹\(Int(item.rate))")
                        .font(.system(size: 13))
                        .foregroundColor(.black)
                        .frame(width: 70, alignment: .trailing)

                    Text("\(item.quantity)")
                        .font(.system(size: 13))
                        .foregroundColor(.black)
                        .frame(width: 40, alignment: .center)

                    Text("₹\(Int(item.lineTotal))")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(width: 80, alignment: .trailing)
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

    private func tableHeader(
        _ text: String,
        align: Alignment = .trailing,
        width: CGFloat? = nil,
        flex: Bool = false
    ) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.black)
            .frame(
                maxWidth: flex ? .infinity : nil,
                alignment: align
            )
            .frame(width: width)
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
        .background(Color(red: 245/255, green: 240/255, blue: 255/255))
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
                .foregroundColor(.black)

            Spacer()

            Text("₹\(Int(value))")
                .font(.system(size: 14, weight: bold ? .bold : .regular))
                .foregroundColor(highlight ? purple : .black)
        }
    }
}

