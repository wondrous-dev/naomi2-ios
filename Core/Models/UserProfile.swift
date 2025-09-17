//
//  UserProfile.swift
//  naomi-ios
//
//  Created by Assistant on 9/12/25.
//

import Foundation

public struct UserProfile: Codable, Equatable {
    public var displayName: String

    public init(displayName: String = "") {
        self.displayName = displayName
    }
}


