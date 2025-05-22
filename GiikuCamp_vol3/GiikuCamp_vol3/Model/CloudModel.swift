//
//  CloudModel.swift
//  GiikuCamp_vol3
//
//  Created by tknooa on 2025/05/21.
//

import Foundation
import FirebaseFirestore

struct Cloud{
    @DocumentID var DocumentID: String?
    var isAgree: Bool
    var born: Int
    var language: String
    var favorite: [String: [String: Bool]]
    var email: String?
}
