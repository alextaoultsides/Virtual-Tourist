//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by atao1 on 5/14/18.
//  Copyright © 2018 atao. All rights reserved.
//

import Foundation
import CoreData
import UIKit
import MapKit

class PhotoAlbumViewController:UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var photoCollection: UICollectionView!
    @IBOutlet weak var photoLabel: UILabel!
    @IBOutlet weak var newAlbumButton: UIBarButtonItem!
    
    var pin: Pin!
    var dataController: DataController!
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    var screenSize: CGRect!
    var navBar: UINavigationBar!
    var navItem: UINavigationItem!
    var checkValid: Bool!
    
    //MARK: View Override Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        addNavBar()
        setMapView()
        setUpFetchedResultsController()
        if pin.photos?.count == 0 { //If photos do not exist then a new collection will download
            loadNewPictures()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setUpFetchedResultsController()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        addNavBar()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil
    }
    
    //MARK: Adds Navigation bar and back button programatically
    func addNavBar() {
        screenSize = UIScreen.main.bounds
        navBar = UINavigationBar(frame: CGRect(x: 0, y: 0, width: screenSize.width, height: 64))
        
        let backButton = UIBarButtonItem(title: "OK", style: .plain, target: self,action: #selector(self.backButton))
        backButton.title = "OK"
        
        navItem = UINavigationItem()
        navItem.leftBarButtonItem = backButton
        navItem.title = ""
        
        navBar.setItems([navItem], animated: true)
        self.view.addSubview(navBar)
    }
    
    //MARK: Dismiss PhotoAlbumViewController
    @objc func backButton() {
        dismiss(animated: true, completion: nil)
    }
    
    //MARK: Button for new images
    @IBAction func newCollectionButton(_ sender: Any) {
        loadNewPictures()
    }
    
    //UI disabling for collection view while images are loading
    func waitForLoad() {
        performUIUpdatesOnMain {
            self.newAlbumButton.isEnabled = !(self.newAlbumButton.isEnabled)
            self.photoCollection.allowsSelection = !self.photoCollection.allowsSelection
        }
    }
    
    //MARK: Fetch Controller
    func setUpFetchedResultsController() {
        let fetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", pin)
        fetchRequest.predicate = predicate
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "photo \(pin.creationDate)")//creation date is unique id linking pins and photos
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch{
            fatalError("The Fetch Could Not Be Performed: \(error.localizedDescription)")
        }
    }
    //MARK: Sets mapview region and disables interaction capabilities
    func setMapView() {
        
        mapView.delegate = self
        mapView.isZoomEnabled = false;
        mapView.isScrollEnabled = false;
        mapView.isUserInteractionEnabled = false;
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D.init(latitude: pin.latitude, longitude: pin.longitude)
        
        var region = MKCoordinateRegion()
        
        region.center = annotation.coordinate
        region.span.latitudeDelta = 1.0
        region.span.longitudeDelta = 1.0
        
        performUIUpdatesOnMain {
            self.mapView.addAnnotation(annotation)
            self.mapView.setRegion(region, animated: true)
        }
    }
    //MARK: Creates and adds images to photo object context
    func addPhotoToDataController(image: Data) {
        let photo = Photo(context: dataController.viewContext)
        photo.creationDate = pin.creationDate!
        photo.image = image
        photo.pin = pin
        try? dataController.viewContext.save()
    }
    
    //MARK: Delete Photo from collection view and viewContext
    func deletePhoto(at indexPath: IndexPath) {
        if fetchedResultsController.fetchedObjects?.count != 0 {
            
            let photoToDelete = fetchedResultsController.object(at: indexPath)
            dataController.viewContext.delete(photoToDelete)
            try? dataController.viewContext.save()
            performUIUpdatesOnMain {
                self.photoCollection.reloadData()
            }
        }
    }
    
    //MARK: Gets new images
    @objc func loadNewPictures() {
        pin.photos = nil
        checkValid = true
        waitForLoad()
        FlickrPhotoDownloader().imagesFromURL(latitude: pin.latitude, longitude: pin.longitude) { (result, error, finished) in
            if error != nil {
                self.displayError(error?.localizedDescription)
                self.waitForLoad()
                self.checkValid = false
            }
            if let photo = result {
                self.addPhotoToDataController(image: photo)
                
                if finished == true {
                    self.checkValid = false
                    self.waitForLoad()
                }
            }
            performUIUpdatesOnMain {
                self.photoCollection.reloadData()
            }
        }
    }
    
    //MARK: Collection View delegate override
     func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            photoLabel.text = "No Images"
        }
        if checkValid == true {
            return 15
        } else {
            return fetchedResultsController.sections?[section].numberOfObjects ?? 0
        }
    }
    //add images to cell
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as! PhotoCell
        
        if (fetchedResultsController.fetchedObjects?.count)! > (indexPath as NSIndexPath).row {
    
            let aPhoto = fetchedResultsController.object(at: indexPath)
            photoLabel.text = ""
            if let image = aPhoto.image {
            cell.photoImage.image = UIImage(data: image)
            }
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            checkValid = false
            deletePhoto(at: indexPath)
        }
}
//MARK: MapView Delegate
extension PhotoAlbumViewController:MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = false
            pinView!.pinTintColor = .red
        }
        else {
            pinView!.annotation = annotation
        }
        return pinView
    }
}
//MARK: FetchController Delegate
extension PhotoAlbumViewController:NSFetchedResultsControllerDelegate {
    
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
