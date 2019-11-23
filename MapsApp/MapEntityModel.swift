import Foundation
import UIKit

class MapEntityModel {
    var image: UIImage
    var title: String?
    var lon, lat: Double
    
    init(image: UIImage, title: String?, lon: Double, lat: Double) {
        self.image = image
        self.title = title
        self.lon = lon
        self.lat = lat
    }
}
