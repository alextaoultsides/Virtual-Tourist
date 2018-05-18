//
//  FlickrPhotoDownloader.swift
//  Virtual Tourist
//
//  Created by atao1 on 5/17/18.
//  Copyright © 2018 atao. All rights reserved.
//

import Foundation
import UIKit

class FlickrPhotoDownloader: NSObject {
    let session = URLSession.shared
    
    let apiKey = "fcbce5f0c0d654abadee950a053e1dad"
    
    // search method for Flickr download by lat and long
    func searchFlickrByLatLong(latitude: Double, longitude: Double, withPageNumber: Int? = nil, completion: @escaping(_ result: AnyObject?, _ error: NSError?) -> Void){
        
        var method = "https://api.flickr.com/services/rest?method=flickr.photos.search&api_key=\(apiKey)&safe_search=1&extras=url_m&format=json&lat=\(latitude)&lon=\(longitude)&nojsoncallback=1"
        
        if let pageNumber = withPageNumber {
            method = "\(method)&page=\(pageNumber)"
        }
        
        let request = URLRequest(url: URL(string: method)!)
        
        let task = session.dataTask(with: request) { (data, response, error) in
            
            if error != nil {
                print("error")
                completion(nil, error as NSError?)
            }
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                print("Your request returned a status code other than 2xx!")
                return
            }
            
            guard let data = data else {
                print("No data was returned by the request!")
                return
            }
            
            self.convertDataWithCompletion(data, completion: completion)
            
        }
        task.resume()
    }
    func imageFromURL(latitude: Double, longitude: Double, completion: @escaping(_ results: [UIImage]?, _ error: NSError?) -> Void ) {
        var urlForPhoto:[UIImage] = []
        
        FlickrPhotoDownloader().searchFlickrByLatLong(latitude: latitude, longitude: longitude) { (result, error) in
            
            if error != nil {
                completion(nil, error)
            } else {
                //print(result)
                let results = result!["photos"] as? [String:AnyObject]
                //print(results)
                if let pagesTotal = results!["pages"]{
                    if Int(truncating: pagesTotal as! NSNumber) < 1{
                        completion(nil, error)
                    } else {
                    let randomPage = Int(arc4random_uniform(UInt32( pagesTotal as! Double))) + 1
                   // print(randomPage)
                        FlickrPhotoDownloader().searchFlickrByLatLong(latitude: latitude, longitude: longitude, withPageNumber: randomPage) { (result, error) in
                            if error != nil {
                                completion(nil, error)
                            } else {
                                
                                let results = result!["photos"] as? [String:AnyObject]
                                
                                if let photoArray = results!["photo"] as? [[String: AnyObject]]{
                                    print(photoArray[0]["url_m"])
                                    let photoCount = UInt32(photoArray.count)
                                    for _ in 0...min(photoCount, 14) {
                                        let randomPhoto = Int(arc4random_uniform(photoCount))
                                        if randomPhoto == nil{
                                            completion(nil, error)
                                        }else {
                                            let photoUrl = photoArray[randomPhoto]["url_m"] as! String
                                            //print(photoDetails)
//                                            let photoURL = URL(string: photoDetails["url_m"])
//
                                            if let imageData = try? Data(contentsOf: URL(string: photoUrl)!){
                                                urlForPhoto.append(UIImage(data: imageData)!)
                                            }
                                        }
                                    }
                                }
                                completion(urlForPhoto, nil)
                            }
                        }
                    }
                } else {
                    completion(nil, error)
                }
            }
        }
    }
    func convertDataWithCompletion(_ data: Data, completion: (_ result: AnyObject?, _ error: NSError?) -> Void) {
        
        var parsedResult: AnyObject! = nil
        do {
            parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as AnyObject
 
        } catch {
            let userInfo = [NSLocalizedDescriptionKey : "Could not parse the data as JSON: '\(data)'"]
            completion(nil, NSError(domain: "convertDataWithCompletionHandler", code: 1, userInfo: userInfo))
        }
        
        completion(parsedResult, nil)
    }
    
    class func sharedInstance() -> FlickrPhotoDownloader {
        struct Singleton {
            static var sharedInstance = FlickrPhotoDownloader()
        }
        return Singleton.sharedInstance
    }
}
