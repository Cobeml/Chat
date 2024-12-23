//
//  APIService.swift
//  ExyteChat
//

import Foundation

struct AcceptGroupInviteRequest: Codable {
    let userId: String
    let conversationId: String
}

struct AcceptGroupInviteResponse: Codable {
    let message: String?
}

enum APIServiceError: Error {
    case invalidURL
    case invalidResponse
    case decodingError
    case custom(message: String)
}

class APIService {
    static let shared = APIService()
    private init() {}

    func post<T: Codable, U: Codable>(urlString: String, requestBody: T, responseType: U.Type, completion: @escaping (Result<U, Error>) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(.failure(APIServiceError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            let jsonData = try JSONEncoder().encode(requestBody)
            request.httpBody = jsonData
        } catch {
            completion(.failure(error))
            return
        }

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data, let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                completion(.failure(APIServiceError.invalidResponse))
                return
            }

            do {
                let decodedResponse = try JSONDecoder().decode(responseType, from: data)
                completion(.success(decodedResponse))
            } catch {
                completion(.failure(APIServiceError.decodingError))
            }
        }
        task.resume()
    }
}

extension APIService {
    func acceptGroupInvite(groupId: String, userId: String, completion: @escaping (Result<AcceptGroupInviteResponse, Error>) -> Void) {
        let url = "https://us-central1-unity-harvard.cloudfunctions.net/addUserToConversation"
        let requestBody = AcceptGroupInviteRequest(userId: userId, conversationId: groupId)
        post(urlString: url, requestBody: requestBody, responseType: AcceptGroupInviteResponse.self, completion: completion)
    }
}

