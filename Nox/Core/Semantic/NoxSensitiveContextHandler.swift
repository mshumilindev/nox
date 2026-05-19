import Foundation

enum NoxSensitiveContextHandler {
  private static let adultHosts: Set<String> = [
    "pornhub.com", "xvideos.com", "xhamster.com", "redtube.com",
    "onlyfans.com", "chaturbate.com"
  ]

  private static let bankingHosts: Set<String> = [
    "chase.com", "bankofamerica.com", "wellsfargo.com", "revolut.com",
    "monobank.ua", "privatbank.ua", "paypal.com", "wise.com", "stripe.com"
  ]

  private static let healthHosts: Set<String> = [
    "patient.info", "webmd.com", "mayoclinic.org", "mychart.", "healthline.com"
  ]

  private static let legalHosts: Set<String> = [
    "docusign.com", "hellosign.com", "legalzoom.com", "rocketlawyer.com"
  ]

  private static let identitySecurityHosts: Set<String> = [
    "icloud.com", "account.apple.com", "accounts.google.com", "login.microsoftonline.com",
    "1password.com", "bitwarden.com", "lastpass.com", "auth0.com"
  ]

  private static let datingHosts: Set<String> = [
    "tinder.com", "bumble.com", "hinge.co", "badoo.com"
  ]

  static func sensitivity(
    domain: String?,
    title: String?,
    bundleId: String?
  ) -> NoxSensitivityLevel {
    let host = normalizedHost(domain) ?? normalizedHost(fromTitle: title)
    guard let host else {
      if isMessagesApp(bundleId) { return .privateContext }
      return .normal
    }

    if adultHosts.contains(where: { host.contains($0) }) { return .privateContext }
    if bankingHosts.contains(where: { host.contains($0) }) { return .sensitive }
    if healthHosts.contains(where: { host.contains($0) }) { return .sensitive }
    if legalHosts.contains(where: { host.contains($0) }) { return .sensitive }
    if identitySecurityHosts.contains(where: { host.contains($0) }) { return .sensitive }
        if datingHosts.contains(where: { host.contains($0) }) { return .personal }
        if host.contains("password") || host.contains("login") || host.contains("signin") {
          return .sensitive
        }
    return .normal
  }

  static func sanitizedTitle(
    _ title: String?,
    sensitivity: NoxSensitivityLevel
  ) -> String? {
    switch sensitivity {
    case .normal:
      return title
    case .personal:
      return title.map { _ in "Personal browsing" }
    case .sensitive:
      return "Sensitive context"
    case .privateContext:
      return "Private context"
    }
  }

  static func genericMemoryTitle(sensitivity: NoxSensitivityLevel) -> String {
    switch sensitivity {
    case .privateContext: "Private context"
    case .sensitive: "Sensitive context"
    case .personal: "Personal context"
    case .normal: "Context"
    }
  }

  private static func normalizedHost(_ domain: String?) -> String? {
    guard var domain, !domain.isEmpty else { return nil }
    domain = domain.lowercased()
    if domain.hasPrefix("www.") { domain = String(domain.dropFirst(4)) }
    return domain
  }

  private static func normalizedHost(fromTitle title: String?) -> String? {
    guard let title else { return nil }
    let pattern = #"([a-z0-9-]+\.)+[a-z]{2,}"#
    guard let range = title.lowercased().range(of: pattern, options: .regularExpression) else {
      return nil
    }
    return String(title.lowercased()[range])
  }

  private static func isMessagesApp(_ bundleId: String?) -> Bool {
    bundleId == "com.apple.MobileSMS" || bundleId == "com.apple.iChat"
  }
}
