//
//  HeaderView.swift
//  StockApp
//
//  Created by Haoyu Liu on 4/21/24.
//

import SwiftUI
import Foundation
import Combine

struct HeaderView: View {
    let profile:CompanyProfile
    let quote:StockQuote
    var body: some View {
        VStack (alignment:.leading) {
            Text("\(profile.name)")
                .foregroundStyle(.secondary)
                .padding(.vertical)
            HStack (alignment:.bottom){
                Text("$"+String(format:"%.2f", (quote.c)))
                    .font(.system(size: 32))
                    .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                var dynamicColor: Color {
                    let change = quote.d
                    if change > 0 {
                        return .green
                    } else if change < 0 {
                        return .red
                    } else {
                        return .gray
                    }
                }
                if (quote.d > 0.0) {
                    Image(systemName: "arrow.up.right")
                        .font(.title3)
                        .foregroundColor(.green)
                } else if ((quote.d < 0.0)) {
                    Image(systemName: "arrow.down.right")
                        .font(.title3)
                        .foregroundColor(.red)
                } else {
                    Image(systemName: "minus")
                        .font(.title3)
                        .foregroundColor(.gray)
                }
                Text("$"+String(format: "%.2f", (quote.d))+" ("+String(format: "%.2f", (quote.dp))+"%)")
                    .foregroundColor(dynamicColor)
                    .font(.title3)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading)
        .padding(.bottom, 3.5)
    }
}
