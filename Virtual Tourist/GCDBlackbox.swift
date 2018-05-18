//
//  GCDBlackbox.swift
//  Virtual Tourist
//
//  Created by atao1 on 5/17/18.
//  Copyright © 2018 atao. All rights reserved.
//

import Foundation

func performUIUpdatesOnMain(_ updates: @escaping () -> Void) {
    DispatchQueue.main.async {
        updates()
    }
}
