//
//  PhotoCell.swift
//  Virtual Tourist
//
//  Created by atao1 on 5/20/18.
//  Copyright © 2018 atao. All rights reserved.
//

import Foundation
import UIKit

class PhotoCell: UICollectionViewCell {
    
    @IBOutlet weak var photoImage: UIImageView!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        photoImage.image = #imageLiteral(resourceName: "VirtualTourist_152")
    }
}
