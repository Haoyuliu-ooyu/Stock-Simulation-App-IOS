//
//  TradeSheetView.swift
//  StockApp
//
//  Created by Haoyu Liu on 4/21/24.
//

import SwiftUI

struct TradeSheetView: View {
    @ObservedObject var viewModel: DetailViewModel
    @State private var numberOfShares: Int? = nil
    @Binding var isPresented: Bool
    
    @State var noMoneyToast: Bool = false
    @State var validBuyInputToast: Bool = false
    @State var validSellInputToast: Bool = false
    @State var validInputToast: Bool = false
    @State var noShareToast: Bool = false
    
    @State private var showBuyMessage: Bool = false
    @State private var showSellMessage: Bool = false
    
    let availableBalance: Double
    
    init(viewModel: DetailViewModel, isPresented: Binding<Bool>) {
        self.viewModel = viewModel
        self._isPresented = isPresented
        self.availableBalance = viewModel.balance  // Accessing balance here since `self` is valid
    }
    
    var totalCost: Double {
        return Double(numberOfShares ?? 0) * (viewModel.quote?.c ?? 0)
    }
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: {
                    self.isPresented = false
                }) {
                    Image(systemName: "xmark")
                        .imageScale(.large)
                        .foregroundStyle(.primary)
                }
            }
            Text("Trade \(viewModel.profile?.name ?? "") Shares")
                .font(.title2)
                .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                .padding()
            Spacer()
            HStack(alignment: .bottom) {
                TextField("", value: $numberOfShares, format: .number, prompt: Text("0").foregroundStyle(.secondary))
                    .keyboardType(.numberPad)
                    .textFieldStyle(PlainTextFieldStyle())
                    .frame(width: 150) // Adjusted width for the TextField
                    .padding(.horizontal, 2) // Reduced padding
                    .font(.system(size: 100, weight: .light))
                    .padding(.leading, 10) // Adjusted padding
                
                Spacer()
                
                Text(numberOfShares == 1 || numberOfShares == 0 || numberOfShares == nil ? "Share" : "Shares")
                    .font(.title)
                    .padding(.trailing, 10) // Ensure padding does not force text to wrap
            }
            .padding(.horizontal)
            HStack {
                Spacer()
                Text("× $\(viewModel.quote?.c ?? 0, specifier: "%.2f")/share = $\(totalCost, specifier: "%.2f")")
                    .font(.callout)
                    .padding()
            }
            
            Spacer()
            Text("$\(availableBalance, specifier: "%.2f") available to buy \(viewModel.profile?.ticker ?? "")")
                .font(.headline)
                .padding(.bottom)
            
            HStack(spacing: 40) {
                Button(action: {
                    buyStocks()
                }, label: {
                    Text("Buy").padding(.horizontal, 45)
                })
                .buttonStyle(FilledButton())
                
                Button(action: {
//                    print("Sell \(String(describing: numberOfShares)) shares")
                    sellStocks()
                }, label: {
                    Text("Sell").padding(.horizontal, 45)
                })
                .buttonStyle(FilledButton())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .toast(isShowing: $noMoneyToast, text: Text("Not enough money to buy"))
        .toast(isShowing: $noShareToast, text: Text("Not enough shares to sell"))
        .toast(isShowing: $validInputToast, text: Text("Please enter a valid amount"))
        .toast(isShowing: $validBuyInputToast, text: Text("Cannot buy non-positive shares"))
        .toast(isShowing: $validSellInputToast, text: Text("Cannot sell non-positive shares"))
        .sheet(isPresented: $showBuyMessage) {
            VStack {
                Spacer()
                
                // Confirmation text
                Text("Congratulations!")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                // Details about the sale
                let shareDescription = (numberOfShares == 1 || numberOfShares == 0) ? "share" : "shares"
                Text("You have successfully bought \(numberOfShares ?? 0) \(shareDescription) of \(viewModel.profile?.name ?? "")")
                    .font(.caption)
                    .foregroundColor(.white)
                
                Spacer()
                
                // The 'Done' button at the bottom
                Button(action: {
                    // Your code to handle the action goes here
                    self.isPresented = false
                }) {
                    Text("Done")
                        .font(.headline)
                        .foregroundColor(.green)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .cornerRadius(30)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.green)
            .edgesIgnoringSafeArea(.all) // Make sure the green background extends to the edges of the screen
        }

        .sheet(isPresented: $showSellMessage) {
            VStack {
                Spacer()
                
                // Confirmation text
                Text("Congratulations!")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                // Details about the sale
                let shareDescription = (numberOfShares == 1 || numberOfShares == 0) ? "share" : "shares"
                Text("You have successfully sold \(numberOfShares ?? 0) \(shareDescription) of \(viewModel.profile?.name ?? "")")
                    .font(.caption)
                    .foregroundColor(.white)
                
                Spacer()
                
                // The 'Done' button at the bottom
                Button(action: {
                    // Your code to handle the action goes here
                    self.isPresented = false
                }) {
                    Text("Done")
                        .font(.headline)
                        .foregroundColor(.green)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .cornerRadius(30)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.green)
            .edgesIgnoringSafeArea(.all) // Make sure the green background extends to the edges of the screen
        }


    }
    
    private func buyStocks() {
        if (totalCost > viewModel.balance) {
            withAnimation {
                noMoneyToast.toggle()
            }
        } else if (numberOfShares == nil) {
            withAnimation {
                validInputToast.toggle()
            }
        } else if (numberOfShares! <= 0 ) {
            withAnimation {
                validBuyInputToast.toggle()
            }
        } else {
            print("Buy \(String(numberOfShares!)) shares")
            let newBalance = viewModel.balance - totalCost
            viewModel.updateBalance(newBalance: newBalance)
            if (!viewModel.inPortfolio) {
                viewModel.editPortfolio(ticker: viewModel.profile!.ticker, name: viewModel.profile!.name, totalCost: totalCost, quantity: numberOfShares!)
                
            } else {
                let cost = viewModel.portfolioInfo!.totalCost+totalCost
                let count = viewModel.portfolioInfo!.quantity+numberOfShares!
                viewModel.editPortfolio(ticker: viewModel.profile!.ticker, name: viewModel.profile!.name, totalCost: cost, quantity: count)
            }
            self.showBuyMessage = true;
//            self.isPresented = false;
        }
    }
    
    private func sellStocks() {
        let owned = viewModel.portfolioInfo?.quantity
        if (owned == nil) {
            withAnimation{
                noShareToast.toggle()
            }
        } else if (numberOfShares == nil) {
            withAnimation {
                validInputToast.toggle()
            }
        } else if (numberOfShares! > owned!) {
            withAnimation{
                noShareToast.toggle()
            }
        } else if (numberOfShares! <= 0 ) {
            withAnimation {
                validSellInputToast.toggle()
            }
        } else {
            print("Sell \(String(numberOfShares!)) shares")
            let newBalance = viewModel.balance + totalCost
            viewModel.updateBalance(newBalance: newBalance)
            if (viewModel.portfolioInfo?.quantity == numberOfShares) {
                viewModel.removeFromPortfolio(ticker: viewModel.profile!.ticker)
            } else {
                let cost = viewModel.portfolioInfo!.totalCost-totalCost
                let count = viewModel.portfolioInfo!.quantity-numberOfShares!
                viewModel.editPortfolio(ticker: viewModel.profile!.ticker, name: viewModel.profile!.name, totalCost: cost, quantity: count)
            }
            self.showSellMessage = true;
//            self.isPresented = false;
        }
    }
}

// Reusable button style for filled buttons
struct FilledButton: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding()
            .background(Color.green)
            .cornerRadius(20)
    }
}

struct CloseButton: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .foregroundColor(.green)
            .padding()
            .background(Color.white)
            .cornerRadius(20)
    }
}
