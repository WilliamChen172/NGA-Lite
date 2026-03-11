//
//  Endpoint.swift
//  NGA
//
//  Created by William Chen on 3/10/26.
//

import Foundation

enum Endpoint {
    // Home / Category
    case homeCategory
    case homeHasNew
    case homeTagForums
    case homeRecmThreads

    // Subject (forum threads)
    case subjectList
    case subjectTopped
    case subjectSearch
    case subjectHot

    // Post
    case postList
    case postNew
    case postReply

    // User
    case userDetail
    case userDetailName

    // Favor / FavorForum
    case favorForumSync

    // Login (nuke.php)
    case login
    case logout

    var lib: String {
        switch self {
        case .homeCategory, .homeHasNew, .homeTagForums, .homeRecmThreads: return "home"
        case .subjectList, .subjectTopped, .subjectSearch, .subjectHot: return "subject"
        case .postList, .postNew, .postReply: return "post"
        case .userDetail, .userDetailName: return "user"
        case .favorForumSync: return "favorforum"
        case .login, .logout: return "login"
        }
    }

    var act: String {
        switch self {
        case .homeCategory: return "category"
        case .homeHasNew: return "hasnew"
        case .homeTagForums: return "tagforums"
        case .homeRecmThreads: return "recmthreads"
        case .subjectList: return "list"
        case .subjectTopped: return "topped"
        case .subjectSearch: return "search"
        case .subjectHot: return "hot"
        case .postList: return "list"
        case .postNew: return "new"
        case .postReply: return "reply"
        case .userDetail: return "detail"
        case .userDetailName: return "detailname"
        case .favorForumSync: return "sync"
        case .login: return "account"
        case .logout: return "account"
        }
    }

    var baseURL: String {
        switch self {
        case .login, .logout: return Constants.API.nukeURL
        default: return Constants.API.appAPIURL
        }
    }

    var requiresPost: Bool {
        switch self {
        case .subjectList, .postList, .postNew, .postReply, .login, .logout: return true
        default: return false
        }
    }

    var version: Int? {
        switch self {
        case .homeCategory: return 2
        case .homeRecmThreads: return 3
        default: return nil
        }
    }

    /// Use __output=14 (standard JSON) for app_api.php per NGA doc.
    var useOutput14: Bool {
        switch self {
        case .login, .logout: return false
        default: return true
        }
    }
}
