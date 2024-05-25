//
//  NewsSection.swift
//  StockApp
//
//  Created by Haoyu Liu on 4/21/24.
//

import SwiftUI
import Foundation
import Combine
import Kingfisher

struct NewsSection: View {
    @ObservedObject var viewModel: DetailViewModel
    @State private var showingDetail = false
    @State private var selectedArticle: NewsArticle?
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("News")
                .font(.title2)
                .padding(.vertical)
            
            if let firstArticle = viewModel.newsArticles.first {
                // Display the first article differently
                VStack(alignment: .leading, spacing: 8) {
                    // Display the image using Kingfisher
                    KFImage(URL(string: firstArticle.image))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 180)
                        .clipped()
                        .cornerRadius(15)
                    
                    // Display the source and time since published
                    HStack {
                        Text(firstArticle.source)
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)
                            .padding(.trailing, 4)
                        Text(timeSincePublished(from: TimeInterval(firstArticle.datetime)))
                            .foregroundStyle(.secondary)
                    }
                    .font(.caption)
                    
                    Text(firstArticle.headline)
                        .font(.title3)
                        .fontWeight(.bold)
                }
                .onTapGesture {
                    self.selectedArticle = firstArticle
                }
                Divider()
            }
            
            // Display the rest of the articles
            Group {
                ForEach(viewModel.newsArticles.dropFirst()) { article in
                    Button(action: {
                        self.selectedArticle = article
                    }) {
                        NewsRowView(article: article)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .sheet(item: $selectedArticle) { article in
            NewsDetailSheetView(article: article) {
                self.selectedArticle = nil
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding([.leading, .trailing])
        
    }
}

struct NewsRowView: View {
    let article: NewsArticle // Your NewsArticle model

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(article.source)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                    
                    Text(timeSincePublished(from: TimeInterval(article.datetime)))
                        .foregroundStyle(.secondary)
                }
                .font(.caption2)
                
                Text(article.headline)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.leading)
            }
            Spacer()
            let imageUrl = article.image
            let url = URL(string: imageUrl)
            KFImage(url)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 90, height: 90)
                .clipped()
                .cornerRadius(8)
        }
        .padding(.vertical, 8)
    }
}

func timeSincePublished(from timestamp: TimeInterval) -> String {
    let publishDate = Date(timeIntervalSince1970: timestamp)
    let currentDate = Date()
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .full
    let relativeDate = formatter.localizedString(for: publishDate, relativeTo: currentDate)
    return relativeDate
}
