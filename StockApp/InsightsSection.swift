//
//  InsightsSection.swift
//  StockApp
//
//  Created by Haoyu Liu on 4/21/24.
//

import SwiftUI
import Foundation
import Combine

struct InsightsSection: View {
    @ObservedObject var viewModel: DetailViewModel
    let titles = ["Apple Inc", "Total", "Positive", "Negative"]
    
    var ticker: String {
        viewModel.ticker  // Directly access from viewModel
    }
    
    var recoJS: String {
        let encoder = JSONEncoder()
        guard let jsonData = try? encoder.encode(viewModel.recoData),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return "[]"
        }
        return """
        drawChart({
            data: \(jsonString)
        });
        """
    }
    
    var earningJS: String {
        let encoder = JSONEncoder()
        guard let jsonData = try? encoder.encode(viewModel.earningData),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return "[]"
        }
        return """
        drawChart({
            data: \(jsonString)
        });
        """
    }
    
    var body: some View {
        VStack(alignment:.leading) {
            Text("Insights")
                .font(.title2)
                .padding(.vertical)
            VStack {
                Text("Insider Sentiments")
                    .font(.title2)
                    .padding(.bottom)
                HStack {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(titles.indices, id: \.self) { index in
                            Text(titles[index]).fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
//                                .padding(.vertical)
                            Divider()
                        }
                    }
                    Spacer() // Separates the VStacks

                    VStack(alignment: .leading, spacing: 10) {
                        Text("MSPR").fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                        Divider()
                        Text(String(format:"%.2f",viewModel.totalMspr))
                        Divider()
                        Text(String(format:"%.2f",viewModel.positiveMspr))
                        Divider()
                        Text(String(format:"%.2f",viewModel.negativeMspr))
                        Divider()
                    }

                    Spacer() // Separates the VStacks

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Change").fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                        Divider()
                        Text(String(format:"%.2f",viewModel.totalChange))
                        Divider()
                        Text(String(format:"%.2f",viewModel.positiveChange))
                        Divider()
                        Text(String(format:"%.2f",viewModel.negativeChange))
                        Divider()
                    }
                    
                    
                }
                .font(.callout)
            }
            WebView(htmlFilename: "reco", javascript: recoJS)
                .edgesIgnoringSafeArea(.all)
                .frame(minHeight: 370)
            WebView(htmlFilename: "earning", javascript: earningJS)
                .edgesIgnoringSafeArea(.all)
                .frame(minHeight: 370)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding([.leading, .trailing])
    }
}
