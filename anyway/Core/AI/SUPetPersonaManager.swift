//
//  SUPetPersonaManager.swift
//  anyway
//
//  Created by Antigravity on 2026/10/8.
//

import Foundation
import os

/// 宠物人格管理中心 —— 统一负责读取、切换与持久化当前宠物人格
final class SUPetPersonaManager: @unchecked Sendable {

    static let shared = SUPetPersonaManager()

    private let userDefaultsManager: SUUserDefaultsManager
    private let lock = NSLock()

    /// 人格切换通知回调
    var onPersonaChanged: (@Sendable (SUPetPersona) -> Void)?

    init(userDefaultsManager: SUUserDefaultsManager = .shared) {
        self.userDefaultsManager = userDefaultsManager
    }

    /// 获取当前生效的宠物人格
    var currentPersona: SUPetPersona {
        lock.lock()
        defer { lock.unlock() }
        let id = userDefaultsManager.activePetPersonaId
        return SUPetPersona.from(id: id)
    }

    /// 切换宠物人格并持久化
    func selectPersona(_ persona: SUPetPersona) {
        lock.lock()
        let oldId = userDefaultsManager.activePetPersonaId
        guard oldId != persona.rawValue else {
            lock.unlock()
            return
        }
        userDefaultsManager.activePetPersonaId = persona.rawValue
        lock.unlock()

        SULogger.business.info("Pet persona changed to: \(persona.displayName, privacy: .public)")
        onPersonaChanged?(persona)
    }

    /// 所有可用人格列表
    var availablePersonas: [SUPetPersona] {
        return SUPetPersona.allCases
    }
}
