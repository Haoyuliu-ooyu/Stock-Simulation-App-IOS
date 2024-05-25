//
//  TabSection.swift
//  StockApp
//
//  Created by Haoyu Liu on 4/29/24.
//

import SwiftUI
import WebKit

struct TabSection: View {
    @ObservedObject var viewModel: DetailViewModel

    var ticker: String {
        viewModel.ticker  // Directly access from viewModel
    }

    var lineColor: String {
        viewModel.quote!.d < 0 ? "#FF0000" : "#00FF00"
    }

    var hourlyJS: String {
        let encoder = JSONEncoder()
        guard let jsonData = try? encoder.encode(viewModel.hourlyData),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return "[]"
        }
        return """
        drawChart({
            ticker: "\(ticker)",
            lineColor: "\(lineColor)",
            data: \(jsonString)
        });
        """
    }
    
    var historyJS: String {
        let encoder = JSONEncoder()
        guard let jsonData = try? encoder.encode(viewModel.historyData),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return "[]"
        }
        return """
        drawChart({
            ticker: "\(ticker)",
            data: \(jsonString)
        });
        """
    }

    var body: some View {
        TabView {
            WebView(htmlFilename: "hourly", javascript: hourlyJS)
                .edgesIgnoringSafeArea(.all)
                .tabItem {
                    Image(systemName: "chart.xyaxis.line")
                    Text("Hourly")
                }
                .padding(0)
            WebView(htmlFilename: "history", javascript: historyJS)
                .edgesIgnoringSafeArea(.all)
                .tabItem {
                    Image(systemName: "clock.fill")
                    Text("Historical")
                }
                .padding(0)
        }
        .frame(minHeight: 450)
        .padding(0)
    }
}

