//
//  AboutSection.swift
//  StockApp
//
//  Created by Haoyu Liu on 4/21/24.
//

import SwiftUI
import Foundation
import Combine

struct AboutSection: View {
    @ObservedObject var viewModel: DetailViewModel
    var body: some View {
        VStack(alignment: .leading) {
            Text("About")
                .font(.title2)
            HStack {
                // Left column for labels
                VStack(alignment: .leading) {
                    Text("IPO Start Date: ").bold().padding(.vertical, 3)
                    Text("Industry: ").bold().padding(.vertical, 3)
                    Text("Webpage: ").bold().padding(.vertical, 3)
                    Text("Company Peers: ").bold().padding(.vertical, 3)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Right column for values
                VStack(alignment: .leading) {
                    Text(viewModel.profile?.ipo ?? "N/A").padding(.vertical, 3)
                    Text(viewModel.profile?.finnhubIndustry ?? "N/A").padding(.vertical, 3)
                    // Safely unwrapping and creating a link
                    if let urlString = viewModel.profile?.weburl, let url = URL(string: urlString) {
                        Link(urlString, destination: url).padding(.vertical, 3)
                    } else {
                        Text("No URL").padding(.vertical, 3)
                    }
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(Array(viewModel.peers?.enumerated() ?? [].enumerated()), id: \.element) { (index, peer) in
                                HStack(spacing: 0) {
                                    NavigationLink(destination: StockDetailView(ticker: peer)) {
                                        Text(peer)
                                    }
                                    // Add a comma after the peer text if it's not the last item
                                    if index < (viewModel.peers?.count ?? 1) - 1 {
                                        Text(",")
                                            .padding(.leading, 1) // Add some spacing after the comma, if needed
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 3)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .font(.caption)
        }
        .padding(.leading)
        .padding(.vertical, 3)
    }
}
