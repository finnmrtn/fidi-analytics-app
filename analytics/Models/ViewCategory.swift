//
//  ViewCategory.swift
//  analytics
//
//  Created by Finn Garrels on 23.10.25.
//

import Foundation

struct ViewCategory: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let colorName: String
}
