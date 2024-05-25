//
//  ContentView.swift
//  StockApp
//
//  Created by Haoyu Liu on 4/16/24.
//

import SwiftUI
import Combine

struct StockQuote: Decodable {
    let c: Double // Current price
    let d: Double // Change
    let dp: Double // Percent change
    let h: Double // High
    let l: Double // Low
    let o: Double // Open
    let pc: Double // Previous close
    let t: Int // Timestamp
}

struct AutocompleteResponse: Decodable {
    let count: Int
    let result: [AutocompleteResult]
}

struct AutocompleteResult: Decodable, Identifiable {
    let id: UUID = UUID()
    let description: String
    let displaySymbol: String
    let symbol: String
    let type: String
    enum CodingKeys: String, CodingKey {
        case description, displaySymbol, symbol, type
    }
}

let apiUrl = "https://haoyuliu-csci571-hw3.wl.r.appspot.com/api/"

class AppViewModel: ObservableObject {
    @Published var isLoading = true
    @Published var searchResults: [AutocompleteResult] = []
    @Published var searchText: String = "" {
        didSet {
            searchResults = [] // Clear previous results when search text changes
            searchCancellable?.cancel() // Cancel any existing search task
            searchCancellable = $searchText
                .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
                .removeDuplicates()
                .sink { [weak self] text in
                    if !text.isEmpty {
                        self?.fetchAutocomplete(searchQuery: text)
                    }
                }
        }
    }
    
    private var searchCancellable: AnyCancellable?
    
    func fetchAutocomplete(searchQuery: String) {
            guard let url = URL(string: apiUrl+"autocomplete/\(searchQuery)") else { return }
            URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
                guard let data = data, error == nil else {
                    print("Network error: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                DispatchQueue.main.async {
                    do {
                        let response = try JSONDecoder().decode(AutocompleteResponse.self, from: data)
                        self?.searchResults = response.result.filter { !$0.displaySymbol.contains(".") }
                    } catch {
                        print("Decoding error: \(error)")
                    }
                }
            }.resume()
        }
}

struct ContentView: View {
    @StateObject var appViewModel = AppViewModel()
    @StateObject var favouritesViewModel: FavouritesViewModel
    @StateObject var portfolioViewModel: PortfolioViewModal

    @State private var key = UUID()
    @State private var currentDate = ""
    @State private var searchText = ""
    
    init() {
        let appVM = AppViewModel()
        _appViewModel = StateObject(wrappedValue: appVM)
        _favouritesViewModel = StateObject(wrappedValue: FavouritesViewModel(appViewModel: appVM))
        _portfolioViewModel = StateObject(wrappedValue: PortfolioViewModal(appViewModel: appVM))
    }

    var body: some View {
        NavigationView {
            Group {
                if appViewModel.isLoading {
                    ProgressView("Fetching Data...")
                } else {
                    List {
                        if !appViewModel.searchText.isEmpty {
                            searchResultsView
                        } else {
                            mainContentView
                        }
                    }
                    .navigationTitle("Stocks")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            EditButton()
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                    .searchable(text: $appViewModel.searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search")
                }
            }
            .onAppear {
                print("ContentView appeared - reloading necessary data.")
                currentDate = formatDate(Date())  // Update the date to ensure view refresh
                favouritesViewModel.fetchWatchlist()
                portfolioViewModel.fetchPortfolio()
            }
        }
        
    }

    private var searchResultsView: some View {
        ForEach(appViewModel.searchResults) { result in
            NavigationLink(destination: StockDetailView(ticker: result.symbol)) {
                VStack(alignment: .leading) {
                    Text(result.symbol)
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(result.description)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var mainContentView: some View {
        Group {
            Text(currentDate)
                .multilineTextAlignment(.leading)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
                .padding(.vertical, 5.0)
                .cornerRadius(10)
                .background(Color(.systemBackground))
////            PortfolioView().environmentObject(portfolioViewModel)
//            PortfolioView(porVM: portfolioViewModel, favVM: favouritesViewModel)
////            FavouritesView().environmentObject(favouritesViewModel)
//            FavouritesView(porVM: portfolioViewModel, favVM: favouritesViewModel)
            PortfolioView(porVM: portfolioViewModel, favVM: favouritesViewModel)
            FavouritesView(porVM: portfolioViewModel, favVM: favouritesViewModel)
            HStack {
                Spacer()
                Text("[Powered by Finnhub.io](https://finnhub.io/)")
                    .font(.footnote)
                    .fontWeight(.light)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .accentColor(.secondary)
                Spacer()
            }
        }
    }

    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM dd, yyyy"
        return formatter.string(from: date)
    }
}

extension View {
    func toast(isShowing: Binding<Bool>, text: Text) -> some View {
        Toast(isShowing: isShowing,
              presenting: { self },
              text: text)
    }
}

struct Toast<Presenting>: View where Presenting: View {
    @Binding var isShowing: Bool
    let presenting: () -> Presenting
    let text: Text

    var body: some View {
        if self.isShowing {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation{
                    self.isShowing = false
                }
            }
        }
        return ZStack(alignment: Alignment(horizontal: .center, vertical: .bottom)) {
            presenting()
            if isShowing {
                text
                    .padding()
                    .background(Color.gray)
                    .foregroundColor(Color.primary)
                    .cornerRadius(20)
//                    .onAppear {
//                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
//                            withAnimation {
//                                self.isShowing = false
//                            }
//                        }
//                    }
                    .padding(.bottom, 50) // Adjust bottom padding to elevate the toast
            }
        }
    }
}

