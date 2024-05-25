//
//  PortfolioView.swift
//  StockApp
//
//  Created by Haoyu Liu on 4/17/24.
//

import SwiftUI

struct PortfolioStock: Identifiable, Decodable {
    var id: String { _id }
    let _id: String
    let ticker: String
    let quantity: Int
    let name: String
    let totalCost: Double
    var marketValue: Double?
    var changeCost: Double?
    var changePercentage: Double?
}

class PortfolioViewModal: ObservableObject {
    @Published var balance = 0.0
    @Published var networth = 0.0
    @Published var portfolio:[PortfolioStock] = []
    
    let apiUrl = "https://haoyuliu-csci571-hw3.wl.r.appspot.com/api/"
    
    var appViewModel: AppViewModel
    init(appViewModel: AppViewModel) {
        self.appViewModel = appViewModel
    }
    
    func moveStocks(from source: IndexSet, to destination: Int) {
        portfolio.move(fromOffsets: source, toOffset: destination)
    }
    
    func fetchPortfolio() {
//        self.appViewModel.isLoading = true
        let group = DispatchGroup()
        
        // Fetch balance
        group.enter()
        fetchBalance { balance in
            DispatchQueue.main.async {
                self.balance = balance
                self.networth = balance  // Start networth with the balance
                group.leave()
            }
        }

        // Fetch portfolio stocks
        guard let url = URL(string: apiUrl + "portfolio") else {
            self.appViewModel.isLoading = false
            return
        }

        group.enter()
        URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
            defer { group.leave() }  // Ensure that the group is left even if there's an early return
            
            guard let data = data, error == nil else {
                print("No data in response: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            do {
                var fetchedStocks = try JSONDecoder().decode([PortfolioStock].self, from: data)
                
                for index in fetchedStocks.indices {
                    group.enter()
                    self?.fetchQuote(for: fetchedStocks[index].ticker) { quote in
                        DispatchQueue.main.async {
                            let avgCost = fetchedStocks[index].totalCost / Double(fetchedStocks[index].quantity)
                            fetchedStocks[index].marketValue = quote.c * Double(fetchedStocks[index].quantity)
                            fetchedStocks[index].changeCost = (quote.c - avgCost) * Double(fetchedStocks[index].quantity)
                            fetchedStocks[index].changePercentage = 100 * (fetchedStocks[index].changeCost ?? 0) / fetchedStocks[index].totalCost
                            group.leave()
                        }
                    }
                }
                
                group.notify(queue: .main) {
                    // Calculate total cost of all fetched stocks and add to networth
                    let totalCost = fetchedStocks.reduce(0) { $0 + $1.totalCost }
                    self?.networth += totalCost
                    self?.portfolio = fetchedStocks
                }
                
            } catch {
                print("Error decoding portfolio: \(error)")
            }
        }.resume()
        
        // Set isLoading to false once all the group tasks are complete
        group.notify(queue: .main) {
            self.appViewModel.isLoading = false
        }
    }

    // Fetch balance from the "balance" API
    func fetchBalance(completion: @escaping (Double) -> Void) {
        guard let url = URL(string: apiUrl + "balance") else {
            completion(0)  // Provide a default or error case
            return
        }

        URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data, error == nil else {
                print("Error fetching balance: \(error?.localizedDescription ?? "Unknown error")")
                completion(0)  // Default case on error
                return
            }
            do {
                let balance = try JSONDecoder().decode(Double.self, from: data)
                DispatchQueue.main.async {
                    completion(balance)
                }
            } catch {
                print("Decoding error for balance: \(error)")
            }
        }.resume()
    }


    
    private func fetchQuote(for ticker: String, completion: @escaping (StockQuote) -> Void) {
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

struct PortfolioView: View {
//    @EnvironmentObject var porVM: PortfolioViewModal
//    @EnvironmentObject var favVM: FavouritesViewModel
    @ObservedObject var porVM: PortfolioViewModal
    @ObservedObject var favVM: FavouritesViewModel
    var body: some View {
        Section(header: Text("PORTFOLIO").font(.caption)) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Net Worth")
                        .font(.title2)
                        .foregroundColor(.primary)
                    Text("$"+String(format: "%.2f", (porVM.networth)))
                        .font(.title3)
                        .fontWeight(.bold)
                }
                Spacer()
                VStack(alignment: .leading) {
                    Text("Cash Balance")
                        .font(.title2)
                        .foregroundColor(.primary)
                    Text("$"+String(format: "%.2f", (porVM.balance)))
                        .font(.title3)
                        .fontWeight(.bold)
                }
                
            }
            ForEach(porVM.portfolio) { stock in
                PorfolioStockRow(porVM: porVM, favVM: favVM, stock: stock)
            }.onMove(perform: porVM.moveStocks)
            
        }
    }
}

struct PorfolioStockRow: View {
    @ObservedObject var porVM: PortfolioViewModal
    @ObservedObject var favVM: FavouritesViewModel
    var stock: PortfolioStock

    var body: some View {
        NavigationLink(destination: StockDetailView(ticker: stock.ticker)) {
            HStack {
                stockInfo
                Spacer()
                stockValueInfo
            }
        }
    }

    private var stockInfo: some View {
        VStack(alignment: .leading) {
            Text(stock.ticker)
                .font(.title2)
                .bold()
            Text("\(stock.quantity) shares")
                .foregroundStyle(.secondary)
        }
        .layoutPriority(0.5)
    }

    private var stockValueInfo: some View {
        VStack(alignment: .trailing) {
            Text("$" + String(format: "%.2f", (stock.marketValue ?? 0.0)))
                .font(.headline)
                .bold()
            changeInfo
        }
        .layoutPriority(1)
    }

    private var changeInfo: some View {
        HStack {
            Image(systemName: changeIcon)
                .font(.headline)
                .foregroundColor(changeColor)
            Text(changeText)
                .multilineTextAlignment(.trailing)
                .foregroundColor(changeColor)
        }
    }

    private var changeIcon: String {
        guard let change = stock.changeCost else { return "minus" }
        return change > 0 ? "arrow.up.right" : (change < 0 ? "arrow.down.right" : "minus")
    }

    private var changeColor: Color {
        guard let change = stock.changeCost else { return .gray }
        return change > 0 ? .green : (change < 0 ? .red : .gray)
    }

    private var changeText: String {
        let changeValue = stock.changeCost ?? 0.0
        let changePercentage = stock.changePercentage ?? 0.0
        return String(format: "$%.2f (%.2f%%)", changeValue, changePercentage)
    }
}

