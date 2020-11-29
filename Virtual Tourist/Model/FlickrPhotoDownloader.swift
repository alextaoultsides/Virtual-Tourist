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
    
    let apiKey = "your own"
    
    // search method for Flickr download by lat and long
    func searchFlickrByLatLong(latitude: Double, longitude: Double, withPageNumber: Int? = nil, completion: @escaping(_ result: AnyObject?, _ error: NSError?) -> Void){
        
        var method = "https://api.flickr.com/services/rest?method=flickr.photos.search&api_key=\(apiKey)&safe_search=1&extras=url_m&format=json&lat=\(latitude)&lon=\(longitude)&nojsoncallback=1"
        
        if let pageNumber = withPageNumber {
            method = "\(method)&page=\(pageNumber)"
        }
        
        let request = URLRequest(url: URL(string: method)!)
        
        let task = session.dataTask(with: request) { (data, response, error) in
            
            if error != nil {
                
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
    //MARK: Download images from Flickr
    func imagesFromURL(latitude: Double, longitude: Double, completion: @escaping(_ results: Data?, _ error: NSError?, _ finishedLoading: Bool?) -> Void ) {
        let finished = true
        
        FlickrPhotoDownloader().searchFlickrByLatLong(latitude: latitude, longitude: longitude) { (result, error) in
            
            if error != nil {
                completion(nil, error, nil)
            } else {
                
                let results = result!["photos"] as? [String:AnyObject]
                
                if let pagesTotal = results!["pages"]{
                    
                    if Int(truncating: pagesTotal as! NSNumber) < 1{
                        completion(nil, NSError.init(domain: "No Photos Found", code: 1), nil)
                    } else {
                    let randomPage = Int(arc4random_uniform(UInt32( pagesTotal as! Double))) + 1
                   
                        FlickrPhotoDownloader().searchFlickrByLatLong(latitude: latitude, longitude: longitude, withPageNumber: randomPage) { (result, error) in
                            if error != nil {
                                print("oops")
                                completion(nil, error, nil)
                            } else {
                                
                                let results = result!["photos"] as? [String:AnyObject]
                                
                                if let photoArray = results!["photo"] as? [[String: AnyObject]] {
                                    
                                    let photoCount = UInt32(photoArray.count)
                                    for i in 0...min(photoCount, 14) {
                                        let randomPhoto = Int(arc4random_uniform(photoCount))
                                        
                                        let photoUrl = photoArray[randomPhoto]["url_m"] as! String
                                        
                                        if let imageData = try? Data(contentsOf: URL(string: photoUrl)!) {
                                            if i == min(photoCount, 14) {
                                                completion(imageData, nil, finished)
                                            } else { completion(imageData, nil, nil)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                } else {
                    completion(nil, error, nil)
                }
            }
        }
    }
    //Convert to JSON
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

}
