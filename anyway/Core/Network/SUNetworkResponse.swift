//
//  SUNetworkResponse.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import Foundation

/// 统一网络请求响应包装模型
struct SUNetworkResponse<T: Decodable & Sendable>: Decodable, Sendable {
    let code: Int
    let message: String
    let data: T?
    let timestamp: Int?

    var isSuccess: Bool {
        return code == 200
    }
}

/// 空数据返回载荷 (用于只需要判断成功与否的接口)
struct SUEmptyData: Decodable, Sendable {}

/// 统一网络请求错误枚举
enum SUNetworkError: LocalizedError, Sendable {
    case invalidURL
    case serverError(code: Int, message: String)
    case decodingError(String)
    case unauthorized
    case timeout
    case networkUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的接口请求地址"
        case .serverError(let code, let message):
            return "服务端异常 [\(code)]: \(message)"
        case .decodingError(let details):
            return "数据解析失败: \(details)"
        case .unauthorized:
            return "认证过期或未登录"
        case .timeout:
            return "网络请求超时"
        case .networkUnavailable:
            return "当前网络不可用"
        }
    }
}
