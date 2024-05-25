//
//  LoadingView.swift
//  StockApp
//
//  Created by Haoyu Liu on 4/18/24.
//

import SwiftUI

struct LoadingView: View {
    var title: String
    
    var body: some View {
        VStack {
            HStack {
                Text(title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()
                Spacer()
            }
            
            Spacer()
            
            ProgressView("Fetching Data...")
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1)
            
            Spacer()
        }
    }
}


