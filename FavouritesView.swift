//
//  FavouritesView.swift
//  StockApp
//
//  Created by Haoyu Liu on 4/17/24.
//

import SwiftUI
import Foundation
import Combine



struct WatchlistStock: Identifiable, Decodable {
    var id: String { _id }
    let _id: String
    let ticker: String
    let name: String
    var quote: StockQuote?
}

class FavouritesViewModel: ObservableObject {
    @Published var watchlist: [WatchlistStock] = []
    let apiUrl = "https://haoyuliu-csci571-hw3.wl.r.appspot.com/api/"
    
    var appViewModel: AppViewModel
    init(appViewModel: AppViewModel) {
        self.appViewModel = appViewModel
    }
    
    func moveStocks(from source: IndexSet, to destination: Int) {
        watchlist.move(fromOffsets: source, toOffset: destination)
    }
    
    func deleteStock(at offsets: IndexSet) {
        let indices = Array(offsets)
        for index in indices {
            let stock = watchlist[index]
            guard let url = URL(string: apiUrl + "watchlist/\(stock.ticker)") else { return }
            var request = URLRequest(url: url)
            request.httpMethod = "DELETE"

            URLSession.shared.dataTask(with: request) { data, response, error in
                guard let httpURLResponse = response as? HTTPURLResponse,
                      httpURLResponse.statusCode == 200 else {
                    print("Error deleting stock: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                DispatchQueue.main.async {
                    self.watchlist.remove(atOffsets: offsets)
                }
            }.resume()
        }
    }
    
    func fetchWatchlist() {
//        self.appViewModel.isLoading = true
        guard let url = URL(string: apiUrl + "watchlist") else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
            guard let data = data else {
                self?.appViewModel.isLoading = false
                print("No data in response: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            do {
                var fetchedStocks = try JSONDecoder().decode([WatchlistStock].self, from: data)
                let group = DispatchGroup()
                
                for index in fetchedStocks.indices {
                    group.enter()
                    self?.fetchQuote(for: fetchedStocks[index].ticker) { quote in
                        fetchedStocks[index].quote = quote
                        group.leave()
                    }
                }
                
                group.notify(queue: .main) {
                    self?.watchlist = fetchedStocks
                    self?.appViewModel.isLoading = false
                }
                
            } catch {
                DispatchQueue.main.async {
                    print("Error decoding watchlist: \(error)")
                    self?.appViewModel.isLoading = false
                }
            }
        }.resume()
    }

    func fetchQuote(for ticker: String, completion: @escaping (StockQuote) -> Void) {
        let quoteURL = apiUrl+"quote/\(ticker)"
        guard let url = URL(string: quoteURL) else {
            print("Invalid URL for ticker: \(ticker)")
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                guard let data = data, error == nil else {
                    print("Network error fetching quote for \(ticker): \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
//                print(String(data: data, encoding: .utf8) ?? "Invalid JSON data")

                do {
                    let quote = try JSONDecoder().decode(StockQuote.self, from: data)
                    completion(quote)
                } catch {
                    print("Error decoding quote for \(ticker): \(error)")
                }
            }
        }.resume()
    }

}

struct FavouritesView: View {
//    @EnvironmentObject var favVM: FavouritesViewModel
//    @EnvironmentObject var porVM: PortfolioViewModal
    @ObservedObject var porVM: PortfolioViewModal
    @ObservedObject var favVM: FavouritesViewModel
    var body: some View {
        Section(header: Text("FAVOURITES").font(.caption)) {
            ForEach(favVM.watchlist) { stock in
                WatchlistStockRow(porVM:porVM, favVM: favVM, stock: stock)
            }
            .onMove(perform: favVM.moveStocks)
            .onDelete(perform: favVM.deleteStock)
        }
    }
    
}

struct WatchlistStockRow: View {
    @ObservedObject var porVM: PortfolioViewModal
    @ObservedObject var favVM: FavouritesViewModel
    var stock: WatchlistStock

    var body: some View {
        NavigationLink(destination: StockDetailView(ticker: stock.ticker)) {
            HStack {
                stockInfo
                Spacer()
                priceInfo
            }
        }
    }

    private var stockInfo: some View {
        VStack(alignment: .leading) {
            Text(stock.ticker)
                .font(.title2)
                .bold()
            Text(stock.name)
                .foregroundStyle(.secondary)
        }
        .layoutPriority(0.5)
    }

    private var priceInfo: some View {
        VStack(alignment: .trailing) {
            Text("$" + String(format: "%.2f", (stock.quote?.c ?? 0.0)))
                .font(.headline)
                .bold()
            priceChangeInfo
        }
        .layoutPriority(1)
    }

    private var priceChangeInfo: some View {
        HStack {
            Image(systemName: priceDirectionIcon)
                .font(.headline)
                .foregroundColor(priceDirectionColor)
            Text(priceChangeString)
                .multilineTextAlignment(.trailing)
                .foregroundColor(priceDirectionColor)
        }
    }

    private var priceDirectionIcon: String {
        guard let change = stock.quote?.d else { return "minus" }
        return change > 0 ? "arrow.up.right" : (change < 0 ? "arrow.down.right" : "minus")
    }

    private var priceDirectionColor: Color {
        guard let change = stock.quote?.d else { return .gray }
        return change > 0 ? .green : (change < 0 ? .red : .gray)
    }

    private var priceChangeString: String {
        let change = stock.quote?.d ?? 0.0
        let percentChange = stock.quote?.dp ?? 0.0
        return String(format: "$%.2f (%.2f%%)", change, percentChange)
    }
}
