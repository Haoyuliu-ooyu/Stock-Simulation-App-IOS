//
//  StockDetailView.swift
//  StockApp
//
//  Created by Haoyu Liu on 4/18/24.
//

import SwiftUI
import Foundation
import Combine
import Kingfisher

struct StockDetailView: View {
    @ObservedObject var viewModel: DetailViewModel
    let ticker: String
    
    init(ticker: String) {
        self.ticker = ticker
        self.viewModel = DetailViewModel(ticker: ticker)
//        self.viewModel.fetchDetails(ticker: ticker)  // Assuming you might want to fetch details right away
    }
    
    @State var addWatchlistToast: Bool = false
    @State var removeWatchlistToast: Bool = false

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Fetching Data...")
            } else {
                ScrollView {
                    if let profile = viewModel.profile {
                        let quote = viewModel.quote!
                        HeaderView(profile: profile, quote: quote)
                        TabSection(viewModel: viewModel)
                        PortfolioSection(viewModel: viewModel)
                        StatSection(viewModel: viewModel)
                        AboutSection(viewModel: viewModel)
                        InsightsSection(viewModel: viewModel)
                        NewsSection(viewModel: viewModel)
                    } else {
                        Spacer()
                        Text("No data found")
                        Spacer()
                    }
                }
                .toast(isShowing: $addWatchlistToast, text: Text("adding \(viewModel.profile?.ticker ?? "") to watchlist"))
                .toast(isShowing: $removeWatchlistToast, text: Text("removing \(viewModel.profile?.ticker ?? "") from watchlist"))
                .navigationBarTitle(Text(ticker), displayMode: .large)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            if viewModel.isWatching {
                                viewModel.removeFromWatchlist(ticker: ticker)
                                withAnimation{
                                    removeWatchlistToast.toggle()
                                }
                                
                                
                            } else {
                                viewModel.addToWatchlist(ticker: ticker)
                                withAnimation {
                                    addWatchlistToast.toggle()
                                }
                            }
                        } label: {
                            Image(systemName: viewModel.isWatching ? "plus.circle.fill" : "plus.circle")
                        }
                    }
                }
            }
        }.onAppear(){
            self.viewModel.fetchDetails(ticker: ticker)
        }
        
    }
    
}


func getOneDayBefore(dateString: String) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    
    guard let date = dateFormatter.date(from: dateString) else { return "" }
    
    let oneDayBefore = Calendar.current.date(byAdding: .day, value: -1, to: date)!
    return dateFormatter.string(from: oneDayBefore)
}

func lastClosedDate() -> String {
    let now = Date()
    var lastClosed = now
    
    if Calendar.current.component(.hour, from: now) < 6 ||
       (Calendar.current.component(.hour, from: now) == 6 &&
        Calendar.current.component(.minute, from: now) < 30) {
        lastClosed = Calendar.current.date(byAdding: .day, value: -1, to: lastClosed)!
    }
    
    if Calendar.current.component(.weekday, from: lastClosed) == 1 {
        lastClosed = Calendar.current.date(byAdding: .day, value: -2, to: lastClosed)!
    } else if Calendar.current.component(.weekday, from: lastClosed) == 7 {
        lastClosed = Calendar.current.date(byAdding: .day, value: -1, to: lastClosed)!
    } else if Calendar.current.component(.weekday, from: lastClosed) == 2 {
        lastClosed = Calendar.current.date(byAdding: .day, value: -3, to: lastClosed)!
    }
    
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    return dateFormatter.string(from: lastClosed)
}
