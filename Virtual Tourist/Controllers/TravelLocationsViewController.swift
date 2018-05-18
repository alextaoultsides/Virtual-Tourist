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
    
    var maxTouchValue: CGFloat = CGFloat.init()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        setUpFetchedResultsController()
        loadPins()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadPins()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
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
        mapView.addAnnotation(annotation)
        let pin = Pin(context: dataController.viewContext)
        pin.latitude = Double(newCoordinate.latitude)
        pin.longitude = Double(newCoordinate.longitude)
        print("\(pin.latitude) \(pin.longitude)")
        try? dataController.viewContext.save()
        
        FlickrPhotoDownloader().imageFromURL(latitude: pin.latitude, longitude: pin.longitude) { (result, error) in
            
            print(result?.count)
        }
    }
    
    func loadPins() {
        
        for i in fetchedResultsController.fetchedObjects! {
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D.init(latitude: i.latitude, longitude: i.longitude)
            print("\(annotation.coordinate)")
            mapView.addAnnotation(annotation)
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
            pinView!.canShowCallout = true
            pinView!.pinTintColor = .red
            pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            pinView?.animatesDrop = true
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        print("okwhatever")
        print(mapView.centerCoordinate)
        
    }
}


extension TravelLocationViewController:NSFetchedResultsControllerDelegate {
    
}
