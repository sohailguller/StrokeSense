//
//  UserStore.swift
//  StrokeSense
//
//  Created by Sohail Guller on 2/8/25.
//

import Foundation


@MainActor
class UserStore: ObservableObject {
    @Published var user: User = User.default
    
    private static func fileURL() throws -> URL {
        try FileManager.default.url(for: .documentDirectory,
                                    in: .userDomainMask,
                                    appropriateFor: nil,
                                    create: false)
        .appendingPathComponent("user.data")
    }
    
    func load() async throws {
        let task = Task<User, Error> {
            let fileURL = try Self.fileURL()
            guard let data = try? Data(contentsOf: fileURL) else {
                return User.default
            }
            let userInfo = try JSONDecoder().decode(User.self, from: data)
            return userInfo
        }
        let user = try await task.value
        self.user = user
    }
    
    func save(user: User) async throws {
        let task = Task {
            let data = try JSONEncoder().encode(user)
            let outfile = try Self.fileURL()
            try data.write(to: outfile)
        }
        _ = try await task.value
    }
}
