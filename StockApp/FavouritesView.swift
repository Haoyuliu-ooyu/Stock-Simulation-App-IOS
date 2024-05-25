//
//  FavrouritesView.swift
//  StockApp
//
//  Created by Haoyu Liu on 4/17/24.
//

import SwiftUI

struct FavouritesView: View {
    var body: some View {
        Section(header: Text("FAVOURITES").font(.caption)) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Net Worth")
                        .font(.body)
                        .foregroundColor(.primary)
                    Text("$25009.72")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                Spacer()
                VStack(alignment: .leading) {
                    Text("Cash Balance")
                        .font(.body)
                        .foregroundColor(.primary)
                    Text("$21747.26")
                        .font(.title2)
                        .fontWeight(.bold)
                }
            }
        }
    }
}

#Preview {
    FavouritesView()
}
