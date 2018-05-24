//
//  ViewController.swift
//  Virtual Tourist
//
//  Created by atao1 on 5/14/18.
//  Copyright © 2018 atao. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TravelLocationViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    var dataController: DataController!
    var fetchedResultsController:NSFetchedResultsController<Pin>!
    var lastMap: Bool = false
    var maxTouchValue: CGFloat = CGFloat.init()
    var imageData = ImageData()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        
        if lastMap == true {
            mapView.region = getLastMapView()
        }else {
            lastMap = UserDefaults.standard.bool(forKey: "lastMap")
        }
        
        setUpFetchedResultsController()
        loadPins()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setUpFetchedResultsController()
        if lastMap == true {
            mapView.region = getLastMapView()
        }else {
            lastMap = UserDefaults.standard.bool(forKey: "lastMap")
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil
    }
    
    func getLastMapView() -> MKCoordinateRegion{
        var mapRegion = MKCoordinateRegion()
        mapRegion.center.latitude = UserDefaults.standard.double(forKey: "mapCenterLatitude")
        mapRegion.center.longitude = UserDefaults.standard.double(forKey: "mapCenterLongitude")
        mapRegion.span.latitudeDelta = UserDefaults.standard.double(forKey: "mapCenterLatitudeDelta")
        mapRegion.span.longitudeDelta = UserDefaults.standard.double(forKey: "mapCenterLongitudeDelta")
        
        return mapRegion
        
    }
    
    func setLastMapView() {
        UserDefaults.standard.set(true, forKey: "lastMap")
        UserDefaults.standard.set(mapView.centerCoordinate.latitude,forKey: "mapCenterLatitude")
        UserDefaults.standard.set(mapView.centerCoordinate.longitude,forKey: "mapCenterLongitude")
        UserDefaults.standard.set(mapView.region.span.latitudeDelta,forKey: "mapCenterLatitudeDelta")
        UserDefaults.standard.set(mapView.region.span.longitudeDelta,forKey: "mapCenterLongitudeDelta")
        UserDefaults.standard.synchronize()
    }
    
    func setUpFetchedResultsController() {
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "pin")
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch{
            fatalError("The Fetch Could Not Be Performed: \(error.localizedDescription)")
        }
    }

    func addPin(_ pinPoint: CGPoint) {
        let newCoordinate = mapView.convert(pinPoint, toCoordinateFrom: mapView)
        let annotation = MKPointAnnotation()
        annotation.coordinate = newCoordinate
        
        let pin = Pin(context: dataController.viewContext)
        pin.latitude = Double(newCoordinate.latitude)
        pin.longitude = Double(newCoordinate.longitude)
        pin.creationDate = Date()
        
        annotation.title = String(describing: pin.creationDate)
        mapView.addAnnotation(annotation)
        try? dataController.viewContext.save()
        
    }
    
    func loadPins() {
        
        for i in fetchedResultsController.fetchedObjects! {
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D.init(latitude: i.latitude, longitude: i.longitude)
            annotation.title = String(describing: i.creationDate)
            //print("\(annotation.coordinate)")
            
            performUIUpdatesOnMain {
                self.mapView.addAnnotation(annotation)
            }
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        maxTouchValue = 0.0
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            if touch.force > CGFloat.init(3.0) {
                maxTouchValue = touch.force
            }
        }
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            if maxTouchValue > CGFloat.init(3.0) {
                addPin(touch.location(in: self.view))
            }
        }
    }
    
    @IBAction func setPin(_ gestureRecognizer: UILongPressGestureRecognizer){
        
        if gestureRecognizer.state == .began {
            self.becomeFirstResponder()
            addPin(gestureRecognizer.location(in: self.view))
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = false
            pinView!.pinTintColor = .red
            pinView!.rightCalloutAccessoryView?.isHidden = true
            pinView?.animatesDrop = true
        }
        else {
            pinView!.annotation = annotation
        }
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        setLastMapView()
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        if let annotationView = view.annotation?.title {
            let controller = storyboard!.instantiateViewController(withIdentifier: "albumView") as! PhotoAlbumViewController

            for i in fetchedResultsController.fetchedObjects! {
                if (view.annotation?.title)! == String(describing: i.creationDate) {
                    controller.pin = i
                    print("firstpin\(i.creationDate)")
                    if controller.pin.photos == nil {
                        controller.loadNewPictures()
                    }
                }
            }
            controller.dataController = dataController
            present(controller, animated: true)
        }
    }
}

extension TravelLocationViewController:NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            return
        case .delete:
            return
        default:
            break
        }
    }
}
