import UIKit
import MapsWrapper

class MapsTableViewController: UITableViewController {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var stepper: UIStepper!
    @IBOutlet weak var button: UIButton!
    var zoom = 5.0
    var mapsApi = MapsAPI()
    var entities: [MapEntityModel] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.searchBar.delegate = self
        self.tableView.dataSource = self
        self.tableView.delegate = self
        setButtonTitle()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return entities.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "mapImageCell") as! MapsImageTableViewCell
        cell.mapImage.image = self.entities[indexPath.row].image
        cell.titleLabel?.text = self.entities[indexPath.row].title
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 200.0
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let entity = self.entities[indexPath.row]
        let coordinates = [(lon: 23.319941, lat: 42.698334), (lon: entity.lon, lat: entity.lat)]
        mapsApi.getDistance(coordinates: coordinates, completion: { (json) in
            guard let json = json else { return }
            if let durations = json["durations"] as? [[Double]]{
                let value1 = durations[0][0]
                let value2 = durations[0][1]
                let finalValue = (value1 != 0 ? value1 : value2) / 3600
                
                DispatchQueue.main.async {
                    self.showAlert(text: String(format: "Hours: %.2f", finalValue))
                }
            }
        }) { (error) in
            print(error?.localizedDescription ?? "no error")
        }
    }
    
    @IBAction func stepperValueChanged(_ sender: Any) {
        zoom = stepper.value
        setButtonTitle()
        if let text = self.searchBar.text, text.count > 2 {
            searchImage(text: text)
        }
    }
    
    func setButtonTitle() {
        button.setTitle(String(self.zoom), for: .normal)
    }
    
    private func showAlert(text: String) {
        let alert = UIAlertController(title: "Car travel time to place", message: text, preferredStyle: .actionSheet)
        self.present(alert, animated: true, completion: nil)
        let when = DispatchTime.now() + 3
        DispatchQueue.main.asyncAfter(deadline: when) {
          alert.dismiss(animated: true, completion: nil)
        }
    }
    
    func searchImage(text: String) {
        mapsApi.getGeoCoordinates(search: text, completion: { (json) in
            guard let json = json else { return }
            guard let features = json["features"] as? [[String: Any]] else { return }
            self.entities = []
            for feature in features {
                guard let center = feature["center"] as? [Double] else { break }
                let lon = center[0]
                let lat = center[1]
                let title = feature["matching_place_name"] as? String
                self.mapsApi.getStaticImage(lon: lon, lat: lat, zoom: self.zoom, completion: { (imageData) in
                    if let imageData = imageData, let image = UIImage.init(data: imageData) {
                        self.entities.append(MapEntityModel(image: image, title: title, lon: lon, lat: lat))
                    }
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                }) { (error) in
                    print(error?.localizedDescription ?? "no error")
                }
            }
        }) { (error) in
            if error != nil {
                print(error?.localizedDescription ?? "no error")
            }
        }
    }
}

extension MapsTableViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text else { return }
        self.searchImage(text: text)
    }
}
