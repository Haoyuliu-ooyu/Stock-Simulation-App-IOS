//
//  PortfolioSection.swift
//  StockApp
//
//  Created by Haoyu Liu on 4/21/24.
//

import SwiftUI
import Foundation
import Combine

struct PortfolioSection: View {
    @ObservedObject var viewModel: DetailViewModel
    
    @State private var showingTradeSheet = false
    // Computed property for dynamic color outside of the view's body
    private var dynamicColor: Color {
        if let change = viewModel.portfolioInfo?.changeCost {
            return change > 0 ? .green : change < 0 ? .red : .gray
        } else {
            return .gray // No change data available
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text("Portfolio")
                .font(.title2)
            HStack {
                VStack(alignment: .leading) {
                    if viewModel.inPortfolio, let portfolioInfo = viewModel.portfolioInfo {
                        Group {
                            HStack {
                                Text("Shares Owned: ").bold()
                                Text("\(portfolioInfo.quantity)")
                            }
                            .padding(.vertical, 3)

                            HStack {
                                Text("Avg. Cost / Share: ").bold()
                                Text(String(format: "$%.2f", portfolioInfo.totalCost / Double(portfolioInfo.quantity)))
                            }
                            .padding(.vertical, 3)

                            HStack {
                                Text("Total Cost: ").bold()
                                Text(String(format: "$%.2f", portfolioInfo.totalCost))
                            }
                            .padding(.vertical, 3)

                            HStack {
                                Text("Change: ").bold()
                                Text(String(format: "$%.2f", portfolioInfo.changeCost ?? 0))
                                    .foregroundColor(dynamicColor)
                            }
                            .padding(.vertical, 3)

                            HStack {
                                Text("Market Value: ").bold()
                                Text(String(format: "$%.2f", portfolioInfo.marketValue ?? 0))
                                    .foregroundColor(dynamicColor)
                            }
                            .padding(.vertical, 3)
                        }
                    } else {
                        VStack(alignment:.leading) {
                            Text("You have 0 share of " + viewModel.profile!.ticker)
                            Text("Start trading!")
                        }
                    }
                }
                .font(.caption)
                Spacer()

                Button(action: {
                    showingTradeSheet = true
                }) {
                    Text("Trade")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(20)
                }
                .padding(.horizontal, 20)
                .sheet(isPresented: $showingTradeSheet) {
                    TradeSheetView(viewModel: viewModel, isPresented: $showingTradeSheet)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading)
        .padding(.vertical, 3)
    }
}
