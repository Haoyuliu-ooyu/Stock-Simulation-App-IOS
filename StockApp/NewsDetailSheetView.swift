//
//  NewsDetailSheetView.swift
//  StockApp
//
//  Created by Haoyu Liu on 4/21/24.
//

import SwiftUI

struct NewsDetailSheetView: View {
    var article: NewsArticle
    var onClose: () -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Spacer()
                        Button(action: onClose) {
                            Image(systemName: "xmark")
                                .foregroundColor(.black)
                                .padding()
                                .accessibilityLabel(Text("Close"))
                        }
                    }
                    Text(article.source)
                        .font(.title)
                        .fontWeight(.bold)
                    Text(formatDate(from: TimeInterval(article.datetime)))
                        .foregroundColor(.secondary)
                    Divider()
                    VStack(alignment: .leading) {
                        Text(article.headline)
                            .font(.headline)
                            .fontWeight(.semibold)
                        Text(article.summary)
                        HStack {
                            Text("For more details click ")
                            Link("here", destination: URL(string: article.url)!)
                                .foregroundColor(.blue)
                        }
                        .foregroundStyle(.secondary)
                    }
                    .padding(.vertical)
                    // Social Media Icons, if necessary
                    HStack {
                        Button(action: {
                            let tweetText = article.headline
                            let tweetUrl = article.url // Use the actual URL from your article object

                            var components = URLComponents()
                            components.scheme = "https"
                            components.host = "twitter.com"
                            components.path = "/intent/tweet"
                            components.queryItems = [
                                URLQueryItem(name: "text", value: tweetText),
                                URLQueryItem(name: "url", value: tweetUrl)
                            ]

                            if let shareURL = components.url {
                                // open in safari
                                UIApplication.shared.open(shareURL)
                            }
                        }) {
                            Image("XIcon") // Use a system image for sharing
                                .resizable()
                                .scaledToFit()
                                .frame(width: 48, height: 48)
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: {
                            let shareURL = "https://www.facebook.com/sharer/sharer.php?u=\(encodeURIComponent(url: article.url))"

                            if let url = URL(string: shareURL) {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            Image("FacebookIcon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 48, height: 48)
                        }
                        .buttonStyle(.plain)
                    }
                    .font(.title)
                    .padding(.vertical)

                }
                .padding()
            }
            .navigationBarHidden(true)
        }
    }
    
    func encodeURIComponent(url: String) -> String {
        return url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
    }
    
    func formatDate(from unixTimestamp: TimeInterval) -> String {
        let date = Date(timeIntervalSince1970: unixTimestamp)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM dd, yyyy" // Format you want
        dateFormatter.timeZone = TimeZone.current // Or .autoupdatingCurrent
        dateFormatter.locale = Locale.current // Or specific Locale like Locale(identifier: "en_US")
        return dateFormatter.string(from: date)
    }
}
