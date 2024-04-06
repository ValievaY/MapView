//
//  ViewController.swift
//  MapView
//
//  Created by Apple Mac Air on 27.03.2024.
//

import UIKit
import MapKit
import CoreLocation

class MapViewController: UIViewController {
    
    private lazy var locationManager: CLLocationManager = {
        let locationManager = CLLocationManager()
        locationManager.delegate = self
        return locationManager
    }()
    
    private lazy var mapView: MKMapView = {
        let mapView = MKMapView()
       // mapView.mapType = .satellite
        mapView.mapType = .standard
        mapView.showsScale = true
        mapView.showsCompass = true
        mapView.showsUserLocation = true
        mapView.delegate = self
        // mapView.pointOfInterestFilter = points
        mapView.translatesAutoresizingMaskIntoConstraints = false
        return mapView
    }()
    
    private lazy var mapImage: UIImageView = {
        let mapImage = UIImageView()
        mapImage.image = UIImage(systemName: "map.fill")
        mapImage.tintColor = .gray
        mapImage.isUserInteractionEnabled = true
        mapImage.translatesAutoresizingMaskIntoConstraints = false
        return mapImage
    }()
    
    private lazy var pointImage: UIImageView = {
        let pointImage = UIImageView()
        pointImage.image = UIImage(systemName: "mappin.slash.circle.fill")
        pointImage.tintColor = .gray
        pointImage.isUserInteractionEnabled = true
        pointImage.translatesAutoresizingMaskIntoConstraints = false
        return pointImage
    }()
    
    private var counter = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupLayout()
        locationManager.requestWhenInUseAuthorization()
        addNewAnnotaionGesture()
        setupMapImageGesture()
        setupPointGesture()
    }
    
    private func setupLayout() {
        view.backgroundColor = .white
        view.addSubview(mapView)
        mapView.addSubview(mapImage)
        mapView.addSubview(pointImage)
        
        NSLayoutConstraint.activate ([
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            mapImage.topAnchor.constraint(equalTo: mapView.topAnchor, constant: 70),
            mapImage.trailingAnchor.constraint(equalTo: mapView.trailingAnchor, constant: -20),
            mapImage.heightAnchor.constraint(equalToConstant: 40),
            mapImage.widthAnchor.constraint(equalToConstant: 40),
            
            pointImage.topAnchor.constraint(equalTo: mapImage.bottomAnchor, constant: 10),
            pointImage.trailingAnchor.constraint(equalTo: mapView.trailingAnchor, constant: -20),
            pointImage.heightAnchor.constraint(equalToConstant: 40),
            pointImage.widthAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    private func addAnnotation(latitude: Double, longitude: Double) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        mapView.addAnnotation(annotation)
    }
    
    private func getDirection(coordinate: CLLocationCoordinate2D ) {
        let request = MKDirections.Request()
        request.source =  MKMapItem(placemark: MKPlacemark(coordinate: mapView.userLocation.coordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        request.transportType = .automobile
        
        let directions = MKDirections(request: request)
        directions.calculate {[weak self] response, error in
            guard let unwrappedResponse = response else { return }
            
            for route in unwrappedResponse.routes{
                self?.mapView.addOverlay(route.polyline)
                self?.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
            }
        }
    }
    
    private func addNewAnnotaionGesture() {
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(mapLongTap))
        mapView.addGestureRecognizer(longPressGesture)
    }
    
    private func setupMapImageGesture() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(changeMapView(_:)))
        tapGestureRecognizer.numberOfTapsRequired = 1
        mapImage.addGestureRecognizer(tapGestureRecognizer)
    }
    
    private func setupPointGesture() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapPoint(_:)))
        tapGestureRecognizer.numberOfTapsRequired = 1
        pointImage.addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc func mapLongTap(_ sender: UILongPressGestureRecognizer) {
        let point = sender.location(in: mapView)
        let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
        addAnnotation(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
    
    @objc func tapPoint(_ sender: UITapGestureRecognizer) {
        mapView.removeAnnotations(mapView.annotations)
        }
    
    @objc func changeMapView(_ sender: UITapGestureRecognizer) {
        switch counter{
        case 0:
            mapView.mapType = .hybrid
            counter += 1
        case 1:
            mapView.mapType = .satellite
            counter += 1
        case 2:
            mapView.mapType = .standard
            counter = 0
        default:
            break
        }
    }
}

extension MapViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        let coordinate2D = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        mapView.centerCoordinate = coordinate2D
       // addAnnotation(latitude: coordinate2D.latitude, longitude: coordinate2D.longitude)
//            mapView.setCenter(location.coordinate, animated: true)
//        addAnnotation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        case .denied, .restricted:
            print ("")
        case .notDetermined:
            print ("")
        default:
            fatalError()
        }
    }
}

extension MapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, didSelect annotation: MKAnnotation) {
        getDirection(coordinate: annotation.coordinate)
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            let render = MKPolylineRenderer(overlay: overlay)
            render.strokeColor = .blue
            render.lineWidth = 3
            return render
        }
        return MKOverlayRenderer()
    }
}

