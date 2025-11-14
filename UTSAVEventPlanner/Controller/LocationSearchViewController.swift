import UIKit
import MapKit

struct LocationSelection {
    let displayName: String
    let coordinate: CLLocationCoordinate2D
}

final class LocationSearchViewController: UITableViewController, UISearchResultsUpdating, MKLocalSearchCompleterDelegate {

    var onSelect: ((LocationSelection) -> Void)?

    private let completer = MKLocalSearchCompleter()
    private var results: [MKLocalSearchCompletion] = []
    private let searchController = UISearchController(searchResultsController: nil)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Search Location"
        navigationItem.rightBarButtonItem = .init(barButtonSystemItem: .close, target: self, action: #selector(close))

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.keyboardDismissMode = .onDrag

        completer.delegate = self
        completer.resultTypes = .address // leaner suggestions

        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search places"
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }

    @objc private func close() { dismiss(animated: true) }

    // MARK: Search
    func updateSearchResults(for searchController: UISearchController) {
        completer.queryFragment = searchController.searchBar.text ?? ""
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        results = completer.results
        tableView.reloadData()
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        // Ignore; just clear results
        results = []
        tableView.reloadData()
    }

    // MARK: Table
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { results.count }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let r = results[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        var cfg = cell.defaultContentConfiguration()
        cfg.text = r.title
        cfg.secondaryText = r.subtitle
        cell.contentConfiguration = cfg
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let comp = results[indexPath.row]
        let req = MKLocalSearch.Request(completion: comp)
        let search = MKLocalSearch(request: req)
        search.start { [weak self] response, _ in
            guard
                let self = self,
                let item = response?.mapItems.first
            else { return }
            let display = [item.name, item.placemark.locality, item.placemark.administrativeArea]
                .compactMap { $0 }
                .joined(separator: ", ")
            let sel = LocationSelection(displayName: display.isEmpty ? comp.title : display,
                                        coordinate: item.placemark.coordinate)
            self.onSelect?(sel)
            self.dismiss(animated: true)
        }
    }
}
