import SwiftUI
import UIKit

final class PDFGenerator {

    static func generate(
        view: QuotationPDFView,
        fileName: String
    ) throws -> URL {
        _ = view.environment(\.colorScheme, .light)
        let controller = UIHostingController(rootView: view)
        controller.view.frame = CGRect(x: 0, y: 0, width: 595, height: 842) // A4
        controller.view.layoutIfNeeded()

        let renderer = UIGraphicsPDFRenderer(bounds: controller.view.bounds)

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(fileName)

        try renderer.writePDF(to: url) { ctx in
            ctx.beginPage()
            controller.view.drawHierarchy(
                in: controller.view.bounds,
                afterScreenUpdates: true   // ✅ FIXES BLANK PDF
            )
        }

        return url
    }
}

