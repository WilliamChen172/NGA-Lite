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
    case homeBannerRecm
    /// nuke.php 推荐帖子（最新数据，需 auth + app_id=1001）
    case appInterRecmdTopic

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

    // Favor
    case forumFavorGet  // nuke.php, __lib=forum_favor2, __act=get

    // Login (nuke.php)
    case login
    case logout
    case iflogin

    var lib: String {
        switch self {
        case .homeCategory, .homeHasNew, .homeTagForums, .homeRecmThreads, .homeBannerRecm: return "home"
        case .appInterRecmdTopic: return "app_inter"
        case .subjectList, .subjectTopped, .subjectSearch, .subjectHot: return "subject"
        case .postList, .postNew, .postReply: return "post"
        case .userDetail, .userDetailName: return "user"
        case .forumFavorGet: return "forum_favor2"
        case .login, .logout, .iflogin: return "login"
        }
    }

    var act: String {
        switch self {
        case .homeCategory: return "category"
        case .homeHasNew: return "hasnew"
        case .homeTagForums: return "tagforums"
        case .homeRecmThreads: return "recmthreads"
        case .homeBannerRecm: return "bannerrecm"
        case .appInterRecmdTopic: return "recmd_topic"
        case .subjectList: return "list"
        case .subjectTopped: return "topped"
        case .subjectSearch: return "search"
        case .subjectHot: return "hot"
        case .postList: return "list"
        case .postNew: return "new"
        case .postReply: return "reply"
        case .userDetail: return "detail"
        case .userDetailName: return "detailname"
        case .forumFavorGet: return "get"
        case .login: return "login"      // wolfcon 10.3 客户端登录: __act=login
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
        case .subjectList, .postList, .postNew, .postReply, .login, .logout, .forumFavorGet, .appInterRecmdTopic: return true
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

    /// Use __output=14 (standard JSON) for app_api.php and nuke login per NGA doc.
    var useOutput14: Bool {
        switch self {
        case .logout: return false
        case .login, .iflogin: return true  // JSON 响应，否则返回 HTML
        default: return true
        }
    }
}
