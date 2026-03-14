//
//  Endpoint.swift
//  NGA
//
//  Created by William Chen on 3/10/26.
//

import Foundation

enum Endpoint {
    // Home
    case homeCategory

    // Subject (帖子/主题列表)
    case subjectList
    case subjectHot

    // Post (帖子详情/楼层)
    case postList
    case postNew
    case postReply

    // Favor (nuke.php)
    case forumFavorGet
    case appInterRecmdTopic

    // Login (nuke.php)
    case login
    case logout
    case iflogin

    var lib: String {
        switch self {
        case .homeCategory: return "home"
        case .subjectList, .subjectHot: return "subject"
        case .postList, .postNew, .postReply: return "post"
        case .forumFavorGet: return "forum_favor2"
        case .appInterRecmdTopic: return "app_inter"
        case .login, .logout, .iflogin: return "login"
        }
    }

    var act: String {
        switch self {
        case .homeCategory: return "category"
        case .subjectList: return "list"
        case .subjectHot: return "hot"
        case .postList: return "list"
        case .postNew: return "new"
        case .postReply: return "reply"
        case .forumFavorGet: return "get"
        case .appInterRecmdTopic: return "recmd_topic"
        case .login: return "login"
        case .logout: return "account"
        case .iflogin: return "iflogin"
        }
    }

    var baseURL: String {
        switch self {
        case .login, .logout, .iflogin, .forumFavorGet, .appInterRecmdTopic: return Constants.API.nukeURL
        default: return Constants.API.appAPIURL
        }
    }

    var requiresPost: Bool {
        switch self {
        case .subjectList, .postList, .postNew, .postReply, .forumFavorGet, .appInterRecmdTopic, .login: return true
        default: return false
        }
    }

    var version: Int? {
        switch self {
        case .homeCategory: return 2
        default: return nil
        }
    }

    var useOutput14: Bool {
        switch self {
        case .logout: return false
        case .login, .iflogin: return true
        default: return true
        }
    }
}
