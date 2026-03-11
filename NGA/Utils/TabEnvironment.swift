//
//  TabEnvironment.swift
//  NGA
//
//  Created by William Chen on 3/12/26.
//

import SwiftUI

private struct CurrentTabIndexKey: EnvironmentKey {
    static let defaultValue: Int = 0
}

extension EnvironmentValues {
    var currentTabIndex: Int {
        get { self[CurrentTabIndexKey.self] }
        set { self[CurrentTabIndexKey.self] = newValue }
    }
}
