//
//  DetailViewModel.swift
//  StockApp
//
//  Created by Haoyu Liu on 5/1/24.
//

import SwiftUI
import Combine
import Foundation

struct CompanyProfile: Decodable {
    let country: String
    let currency: String
    let estimateCurrency: String
    let exchange: String
    let finnhubIndustry: String
    let ipo: String
    let logo: String
    let marketCapitalization: Double
    let name: String
    let phone: String
    let shareOutstanding: Double
    let ticker: String
    let weburl: String
    
    enum CodingKeys: String, CodingKey {
        case country, currency, estimateCurrency, exchange, finnhubIndustry, ipo, logo, marketCapitalization, name, phone, shareOutstanding, ticker, weburl
    }
}

struct InsiderSentiment: Decodable {
    let symbol: String
    let year: Int
    let month: Int
    let change: Double
    let mspr: Double
}

struct SentimentResponse: Decodable {
    let data: [InsiderSentiment]
    let symbol: String
}

struct NewsArticle: Decodable, Identifiable {
    let id: Int
    let category: String
    let datetime: Int
    let headline: String
    let image: String
    let related: String
    let source: String
    let summary: String
    let url: String
}

struct TradingData: Codable {
    struct Result: Codable {
        var v: Double   // Volume
        var vw: Double  // Volume Weighted Average Price
        var o: Double  // Open Price
        var c: Double   // Close Price
        var h: Double   // High Price
        var l: Double   // Low Price
        var t: Int64    // Timestamp
        var n: Int      // Number of Transactions
    }
    
    var results: [Result]
}

struct RecoResult: Codable {
    let buy, hold, sell, strongBuy, strongSell: Int
    let period: String
    let symbol: String

    enum CodingKeys: String, CodingKey {
        case buy, hold, sell, strongBuy, strongSell, period, symbol
    }
}

struct EarningsData: Codable {
    let actual: Double
    let estimate: Double
    let period: String
    let quarter: Int
    let surprise: Double
    let surprisePercent: Double
    let symbol: String
    let year: Int

    enum CodingKeys: String, CodingKey {
        case actual, estimate, period, quarter, surprise, surprisePercent, symbol, year
    }
}

typealias NewsResponse = [NewsArticle]

class DetailViewModel: ObservableObject {
    var ticker: String
    @Published var isLoading = true
    
    @Published var isWatching = false
    @Published var inPortfolio = false
    
    @Published var showingTradeSheet = false
    
    @Published var portfolioInfo: PortfolioStock?
    @Published var profile: CompanyProfile?
    @Published var quote: StockQuote?
    @Published var peers: [String]?
    @Published var totalChange: Double = 0
    @Published var totalMspr: Double = 0
    @Published var positiveMspr: Double = 0
    @Published var negativeMspr: Double = 0
    @Published var positiveChange: Double = 0
    @Published var negativeChange: Double = 0
    @Published var newsArticles: [NewsArticle] = []
    @Published var balance: Double = 0
    @Published var hourlyData:[TradingData.Result]=[]
    @Published var historyData:[TradingData.Result]=[]
    @Published var recoData:[RecoResult] = []
    @Published var earningData:[EarningsData] = []
    
    init(ticker: String) {
        self.ticker = ticker
    }
    
    let apiUrl = "https://haoyuliu-csci571-hw3.wl.r.appspot.com/api/"
    private var cancellables = Set<AnyCancellable>()
    
    func fetchDetails(ticker: String) {
        isLoading = true
        fetchCompanyProfile(ticker: ticker)
        //        fetchStockQuote(ticker: ticker)
        fetchWatchlist(ticker: ticker)
        fetchPortfolio(ticker: ticker)
        fetchPeers(ticker: ticker)
        fetchInsights(ticker: ticker)
        fetchNews(ticker: ticker)
        fetchBalance()
        fetchHourly(ticker: ticker)
        fetchHistory(ticker: ticker)
        fetchReco(ticker: ticker)
        fetchEarning(ticker: ticker)
        updateLoadingState()
    }
    
    func fetchHourly(ticker: String) {
        let lastClose = lastClosedDate()
        let dayBefore = getOneDayBefore(dateString: lastClose)
        guard let url = URL(string: apiUrl+"hourly/"+ticker+"/"+dayBefore+"/"+lastClose) else {
            print("Invalid URL")
            return
        }
        URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: TradingData.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("Failed to fetch hourly data: \(error)")
                }
            }, receiveValue: { [weak self] hourlyData in
                self?.hourlyData = hourlyData.results
                
                self?.updateLoadingState()
            })
            .store(in: &cancellables)
    }
    
    func fetchHistory(ticker: String) {
        guard let url = URL(string: apiUrl+"history/"+ticker) else {
            print("Invalid URL")
            return
        }
        URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: TradingData.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("Failed to fetch history data: \(error)")
                }
            }, receiveValue: { [weak self] historyData in
                self?.historyData = historyData.results
                self?.updateLoadingState()
            })
            .store(in: &cancellables)
    }
    
    func fetchReco(ticker: String) {
        guard let url = URL(string: apiUrl+"recommendation-trends/"+ticker) else {
            print("Invalid URL")
            return
        }
        URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: [RecoResult].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("Failed to fetch reco data: \(error)")
                }
            }, receiveValue: { [weak self] recoData in
                self?.recoData = recoData
                self?.updateLoadingState()
            })
            .store(in: &cancellables)
    }
    
    func fetchEarning(ticker: String) {
        guard let url = URL(string: apiUrl+"earning/"+ticker) else {
            print("Invalid URL")
            return
        }
        URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: [EarningsData].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("Failed to fetch reco data: \(error)")
                }
            }, receiveValue: { [weak self] earningData in
                self?.earningData = earningData
                self?.updateLoadingState()
            })
            .store(in: &cancellables)
    }
    
    func fetchBalance() {
        guard let url = URL(string: apiUrl + "balance") else { return }
        URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: Double.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("Failed to fetch company profile: \(error)")
                }
            }, receiveValue: { [weak self] balance in
                self?.balance = balance
                self?.updateLoadingState()
            })
            .store(in: &cancellables)
    }
    
    func updateBalance(newBalance: Double) {
        guard let url = URL(string: apiUrl + "balance") else { return }
        let body: [String: Any] = ["balance":newBalance]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body, options: []) else {
            print("Failed to encode body")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Failed to updateBalance: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            DispatchQueue.main.async {
                self.balance = newBalance
                print("updatedBalance")
            }
        }.resume()
    }
    
    func addToPortfolio(ticker: String, name: String, totalCost:Double, quantity: Int) {
        guard let url = URL(string: apiUrl + "portfolio") else { return }
        let body: [String: Any] = ["ticker":ticker, "name":name, "totalCost":totalCost, "quantity":quantity]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body, options: []) else {
            print("Failed to encode body")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Failed to add to portfolio: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            DispatchQueue.main.async {
                self.fetchPortfolio(ticker: ticker)
                print("add to Balance")
            }
        }.resume()
    }
    
    func editPortfolio(ticker: String, name: String, totalCost:Double, quantity: Int) {
        guard let url = URL(string: apiUrl + "portfolio") else { return }
        let body: [String: Any] = ["ticker":ticker, "name":name, "totalCost":totalCost, "quantity":quantity]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body, options: []) else {
            print("Failed to encode body")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Failed to edit portfolio: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            DispatchQueue.main.async {
                self.fetchPortfolio(ticker: ticker)
                print("edit portfolio")
            }
        }.resume()
    }
    
    func removeFromPortfolio(ticker:String) {
        guard let url = URL(string: apiUrl + "portfolio/"+ticker) else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Failed to delte portfolio: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            DispatchQueue.main.async {
                self.fetchPortfolio(ticker: ticker)
                print("removed from portfolio")
            }
        }.resume()
    }
    
    
    func addToWatchlist(ticker: String) {
        guard let url = URL(string: apiUrl + "watchlist") else { return }
        let body: [String: Any] = ["ticker": ticker, "name": self.profile?.name ?? ""]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body, options: []) else {
            print("Failed to encode body")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Failed to add to watchlist: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            DispatchQueue.main.async {
                self.isWatching = true
                print("Added to watchlist successfully")

            }
        }.resume()
    }
    
    func removeFromWatchlist(ticker: String) {
        guard let url = URL(string: apiUrl + "watchlist/" + ticker) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Failed to remove from watchlist: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            DispatchQueue.main.async {
                self.isWatching = false
                print("Removed from watchlist successfully")
            }
        }.resume()
    }
    
    private func fetchCompanyProfile(ticker: String) {
        guard let url = URL(string: apiUrl + "profile/\(ticker)") else { return }
        URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: CompanyProfile.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("Failed to fetch company profile: \(error)")
                }
            }, receiveValue: { [weak self] profile in
                self?.profile = profile
                self?.updateLoadingState()
            })
            .store(in: &cancellables)
    }

    private func fetchStockQuote(ticker: String) {
        guard let url = URL(string: apiUrl + "quote/\(ticker)") else { return }
        URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: StockQuote.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("Failed to fetch stock quote: \(error)")
                }
            }, receiveValue: { [weak self] quote in
                self?.quote = quote
                self?.updateLoadingState()
            })
            .store(in: &cancellables)
    }
    
    private func fetchWatchlist(ticker: String) {
        guard let url = URL(string: apiUrl + "watchlist") else { return }
        URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: [WatchlistStock].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("Failed to fetch stock quote: \(error)")
                }
            }, receiveValue: { [weak self] watchlist in
                self?.isWatching = watchlist.contains{ $0.ticker == ticker }
                self?.updateLoadingState()
            })
            .store(in: &cancellables)
    }
    
    private func fetchPortfolio(ticker: String) {
        guard let portfolioURL = URL(string: apiUrl + "portfolio") else { return }
        
        URLSession.shared.dataTaskPublisher(for: portfolioURL)
            .map(\.data)
            .decode(type: [PortfolioStock].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    print("Failed to fetch portfolio: \(error)")
                    self.isLoading = false
                case .finished:
                    break
                }
            }, receiveValue: { [weak self] portfolio in
                guard let self = self else { return }
                
                // Nested call to fetch quote after fetching portfolio
                guard let quoteURL = URL(string: self.apiUrl + "quote/\(ticker)") else { return }
                
                URLSession.shared.dataTaskPublisher(for: quoteURL)
                    .map(\.data)
                    .decode(type: StockQuote.self, decoder: JSONDecoder())
                    .receive(on: DispatchQueue.main)
                    .sink(receiveCompletion: { completion in
                        switch completion {
                        case .failure(let error):
                            print("Failed to fetch stock quote: \(error)")
                        case .finished:
                            break
                        }
                    }, receiveValue: { quote in
                        self.quote = quote
                        if let index = portfolio.firstIndex(where: { $0.ticker == ticker }) {
                            var stockPortfolio = portfolio[index]
                            let avgCost = stockPortfolio.totalCost / Double(stockPortfolio.quantity)
                            stockPortfolio.marketValue = quote.c * Double(stockPortfolio.quantity)
                            stockPortfolio.changeCost = (quote.c - avgCost) * Double(stockPortfolio.quantity)
                            self.portfolioInfo = stockPortfolio
                            self.inPortfolio = true
                        } else {
                            self.inPortfolio = false
                            self.portfolioInfo = nil
                        }
                        self.updateLoadingState()
                    })
                    .store(in: &self.cancellables)
            })
            .store(in: &cancellables)
    }
    
    private func fetchPeers(ticker: String) {
        guard let url = URL(string: apiUrl + "peers/"+ticker) else { return }
        URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: [String].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("Failed to fetch stock quote: \(error)")
                }
            }, receiveValue: { [weak self] peers in
                let unique = Array(Set(peers))
                self?.peers = unique
                self?.updateLoadingState()
            })
            .store(in: &cancellables)
    }
    
    private func fetchInsights(ticker: String) {
        guard let url = URL(string: apiUrl + "insider-sentiment/\(ticker)") else { return }
        URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: SentimentResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("Failed to fetch insider sentiment: \(error)")
                }
            }, receiveValue: { [weak self] response in
                let changes = response.data.map { $0.change }
                let msprs = response.data.map { $0.mspr }
                self?.totalChange = changes.reduce(0, +)
                self?.totalMspr = msprs.reduce(0, +)
                self?.positiveMspr = msprs.filter { $0 > 0 }.reduce(0, +)
                self?.negativeMspr = msprs.filter { $0 < 0 }.reduce(0, +)
                self?.positiveChange = changes.filter { $0 > 0 }.reduce(0, +)
                self?.negativeChange = changes.filter { $0 < 0 }.reduce(0, +)

                self?.updateLoadingState()
            })
            .store(in: &cancellables)
    }
    
    private func fetchNews(ticker: String) {
        guard let url = URL(string: apiUrl + "news/\(ticker)") else {
            print("Invalid URL for news.")
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let error = error {
                print("Error fetching news: \(error)")
                return
            }
            
            guard let data = data else {
                print("No data received for news.")
                return
            }
            
            do {
                let articles = try JSONDecoder().decode(NewsResponse.self, from: data)
                // Filter the articles to include only those with all the required info
                let filteredArticles = articles
                    .filter { !$0.source.isEmpty && !$0.url.isEmpty && !$0.headline.isEmpty && !$0.summary.isEmpty && !$0.image.isEmpty}
                    .prefix(20)  // Take only the top 20
                
                DispatchQueue.main.async {
                    self?.newsArticles = Array(filteredArticles)
                    self?.updateLoadingState()
                }
            } catch {
                print("Error decoding news: \(error)")
            }
        }.resume()
    }

    private func updateLoadingState() {
        DispatchQueue.main.async {
            self.isLoading = self.profile == nil || self.quote == nil || self.peers == nil || self.newsArticles.isEmpty || self.hourlyData.isEmpty || self.historyData.isEmpty || self.recoData.isEmpty || self.earningData.isEmpty
        }
    }
}
