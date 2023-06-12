//
//  BestsellersManager.swift
//  BookWorm
//
//  Created by Olga Królikowska on 06/04/2023.
//

import Foundation

class BestsellersManager: ObservableObject {
    
    @Published var bookData = [Book]()
    @Published var formattedListDate = ""
    @Published var showRequestsNumberExceededError = false
    @Published var showGeneralError = false
    var previousListDate = ""
    var nextListDate = ""
    var listDateData = ""
    
    func fetchBestsellers(listGenre: String, bestsellersListDate: String) {
        if let url = URL(string: "https://api.nytimes.com/svc/books/v3/lists/\(bestsellersListDate)/\(listGenre).json?api-key=1NLFuQmHxAXMm4A7BtJo3t6hAtE5WqjG") {
            let session = URLSession(configuration: .default)
            let task = session.dataTask(with: url) { data, response, error in // dodać obsługę błędów - general error dla status code'u innego niż 429
                if let response = response as? HTTPURLResponse {
                    DispatchQueue.main.async {
                        switch response.statusCode {
                        case 200...299 :
                            let decoder = JSONDecoder()
                            if let safedata = data {
                                do {
                                    let decodedData = try decoder.decode(BestsellersData.self, from: safedata)
                                    DispatchQueue.main.async {
                                        self.bookData = decodedData.results.books
                                        self.listDateData = decodedData.results.listPublishedDate
                                        let dateFormatter = DateFormatter()
                                        dateFormatter.dateFormat = "y-MM-dd"
                                        if let date = dateFormatter.date(from: self.listDateData) {
                                            dateFormatter.dateFormat = "MMM d, Y"
                                            self.formattedListDate = dateFormatter.string(from: date)
                                        }
                                        self.previousListDate = decodedData.results.previousPublishedDate
                                        self.nextListDate = decodedData.results.nextPublishedDate
                                    }
                                } catch {
                                    print(error.localizedDescription)
                                }
                            }
                        case 429 :
                            self.showRequestsNumberExceededError = true
                        default :
                            self.showGeneralError = true
                        }
                    }
                }
                if error != nil {
                    DispatchQueue.main.async {
                        self.showGeneralError = true
                    }
                }
            }
            task.resume()
        }
    }
}
