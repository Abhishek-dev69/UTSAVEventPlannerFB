import UIKit

final class InventoryViewController: UIViewController {

    @IBOutlet weak var stack: UIStackView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var sectionLabel: UILabel!
    @IBOutlet weak var imageCard: UIView!
    @IBOutlet weak var heroImageView: UIImageView!
    @IBOutlet weak var emptyTitleLabel: UILabel!
    @IBOutlet weak var emptyBodyLabel: UILabel!

    private var inventoryItems: [InventoryItemRecord] = []

    override func loadView() {
        let nib = UINib(nibName: "InventoryViewController", bundle: .main)
        guard let root = nib.instantiate(withOwner: self, options: nil).first as? UIView else {
            fatalError("InventoryViewController.xib must have a top-level UIView")
        }
        view = root
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        Task { await loadInventory() }
    }

    private func loadInventory() async {
        guard let eventId = EventSession.shared.currentEventId else {
            print("❌ No event selected")
            return
        }

        do {
            inventoryItems = try await InventoryDataManager.shared.fetchInventory(eventId: eventId)

            if inventoryItems.isEmpty {
                showEmptyState()
            } else {
                showInventory()
            }

        } catch {
            print("❌ Failed to load inventory:", error)
        }
    }

    private func showEmptyState() {
        stack.isHidden = false
        emptyTitleLabel.text = "No Inventory Items"
        emptyBodyLabel.text = "Add inventory for this event."
    }

    private func showInventory() {
        stack.isHidden = false
        emptyTitleLabel.text = "Inventory Items"
        emptyBodyLabel.text = "Total items: \(inventoryItems.count)"
    }
}

