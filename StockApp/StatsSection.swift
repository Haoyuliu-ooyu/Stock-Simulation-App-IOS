//
//  StatsSection.swift
//  StockApp
//
//  Created by Haoyu Liu on 4/21/24.
//

import SwiftUI
import Foundation
import Combine

struct StatSection: View {
    @ObservedObject var viewModel: DetailViewModel
    var body: some View {
        VStack(alignment: .leading) {
            Text("Stats")
                .font(.title2)
            HStack {
                VStack(alignment:.leading){
                    HStack {
                        Text("High Price: ")
                            .fontWeight(.bold)
                        Text(String(format:"$%.2f", viewModel.quote!.h))
                    }
                    .padding(.vertical, 3)
                    HStack {
                        Text("Low Price: ")
                            .fontWeight(.bold)
                        Text(String(format:"$%.2f", viewModel.quote!.l))
                    }
                    .padding(.vertical, 3)
                }
                .padding(.trailing)
                VStack(alignment:.leading){
                    HStack {
                        Text("Open Price: ")
                            .fontWeight(.bold)
                        Text(String(format:"$%.2f", viewModel.quote!.o))
                    }
                    .padding(.vertical, 3)
                    HStack {
                        Text("Prev. Close: ")
                            .fontWeight(.bold)
                        Text(String(format:"$%.2f", viewModel.quote!.pc))
                    }
                    .padding(.vertical, 3)
                }
            }
            .font(.caption)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading)
        .padding(.vertical, 3)
    }
}
