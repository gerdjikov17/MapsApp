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
    
    @IBAction func stepperValueChanged(_ sender: Any) {
        zoom = stepper.value
        setButtonTitle()
    }
    
    func setButtonTitle() {
//        button.isEnabled = false
        
        button.setTitle(String(self.zoom), for: .normal)
    }
}

extension MapsTableViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.entities = []
        guard let text = searchBar.text else { return }
        mapsApi.getGeoCoordinates(search: text, completion: { (json) in
            guard let json = json else { return }
            guard let features = json["features"] as? [[String: Any]] else { return }
            for feature in features {
                guard let center = feature["center"] as? [Double] else { break }
                let lon = center[0]
                let lat = center[1]
                let title = feature["matching_place_name"] as? String
                self.mapsApi.getStaticImage(lon: lon, lat: lat, zoom: self.zoom, completion: { (imageData) in
                    if let imageData = imageData, let image = UIImage.init(data: imageData) {
                        self.entities.append(MapEntityModel(image: image, title: title))
                        print("image found and set")
                    }
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                }) { (error) in
                    print(error)
                }
            }
            
        }) { (error) in
            if error != nil {
                print(error)
            }
        }
        
    }
}
