//
//  Label.swift
//  GiikuCamp_vol3
//
//  Created by SLJ-156 on 2025/05/20.
//

import SwiftUI

struct Label: View {
    let systemEmviroment = SystemEmviroment()
    let text: String
    let systemImage: String
    
    init(_ text: String, systemImage: String) {
        self.text = text
        self.systemImage = systemImage
    }
    
    var body: some View {
            HStack {
                Image(systemName: systemImage)
                    .frame(width: systemEmviroment.imageSize)
                Text(text).font(.headline)
            }
        }
    }
