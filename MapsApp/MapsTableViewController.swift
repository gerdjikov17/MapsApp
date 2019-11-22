import UIKit
import MapsWrapper

class MapsTableViewController: UITableViewController {

    @IBOutlet weak var searchBar: UISearchBar!
    var mapsApi = MapsAPI()
    var entities: [MapEntityModel] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.searchBar.delegate = self
        self.tableView.dataSource = self
        self.tableView.delegate = self
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return entities.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "mapImageCell") as! MapsImageTableViewCell
        cell.mapImage.image = self.entities[indexPath.row].image
        cell.textLabel?.text = self.entities[indexPath.row].title
        return cell
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
                self.mapsApi.getStaticImage(lon: lon, lat: lat, completion: { (imageData) in
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
