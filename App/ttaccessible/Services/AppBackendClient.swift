//
//  AppBackendClient.swift
//  ttaccessible
//

import Foundation

/// HTTP client for the shared app backend (https://mathieumartin.ovh).
/// Covers the feedback endpoints (error reports + contact messages) and the
/// launch announcements. Full contract: app-backend repo, docs/API.md.
///
/// The Bearer secret is NOT committed (public repo): it is loaded from
/// `AppBackendSecret.plist` (git-ignored, auto-bundled by the synchronized
/// group). Builds without that file simply report `isConfigured == false`
/// and the feedback UI is hidden.
final class AppBackendClient {
    enum ContactType: String, CaseIterable {
        // Raw values are the server-side contact_type values.
        case bug
        case suggestion
        case question
        case other

        var localizationKey: String {
            "feedback.type.\(rawValue)"
        }
    }

    enum BackendError: Error {
        case notConfigured
        case network
        case rateLimited
        case validation
        case server

        var localizedMessage: String {
            switch self {
            case .notConfigured:
                return L10n.text("feedback.error.notConfigured")
            case .network:
                return L10n.text("feedback.error.network")
            case .rateLimited:
                return L10n.text("feedback.error.rateLimited")
            case .validation:
                return L10n.text("feedback.error.validation")
            case .server:
                return L10n.text("feedback.error.server")
            }
        }
    }

    /// One section of a report email, in the backend's ordered-array form
    /// (`type: "kv"`). Arrays preserve order at both levels (sections and rows),
    /// so plain JSONSerialization is safe.
    struct ReportSection {
        let title: String
        let rows: [(label: String, value: String)]

        var jsonObject: [String: Any] {
            [
                "title": title,
                "type": "kv",
                "rows": rows.map { ["label": $0.label, "value": $0.value] },
            ]
        }
    }

    struct Announcement: Decodable {
        let id: String
        let title: String
        let body: String
        let style: String
        let mode: String
    }

    static let appID = "ttaccessible"

    private static let baseURL = URL(string: "https://mathieumartin.ovh")!

    private static let bearerSecret: String? = {
        guard let url = Bundle.main.url(forResource: "AppBackendSecret", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              let secret = plist["BearerSecret"] as? String,
              secret.isEmpty == false else {
            return nil
        }
        return secret
    }()

    static var isConfigured: Bool {
        bearerSecret != nil
    }

    private let session = URLSession(configuration: .ephemeral)

    // MARK: - Feedback

    func sendContact(
        email: String,
        type: ContactType,
        message: String,
        completion: @escaping (Result<Void, BackendError>) -> Void
    ) {
        let body: [String: Any] = [
            "app": Self.appID,
            "email": email,
            "contact_type": type.rawValue,
            "message": message,
            "app_version": Self.appVersion,
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: body) else {
            DispatchQueue.main.async { completion(.failure(.validation)) }
            return
        }
        var request = makeRequest(path: "/api/feedback/contact")
        request?.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request?.httpBody = data
        perform(request, completion: completion)
    }

    func sendReport(
        email: String,
        summary: String,
        subjectHint: String,
        sections: [ReportSection],
        logFile: (name: String, data: Data)?,
        completion: @escaping (Result<Void, BackendError>) -> Void
    ) {
        let report: [String: Any] = [
            "app": Self.appID,
            "email": email,
            "summary": summary,
            "subject_hint": subjectHint,
            "sections": sections.map(\.jsonObject),
        ]
        guard let reportData = try? JSONSerialization.data(withJSONObject: report) else {
            DispatchQueue.main.async { completion(.failure(.validation)) }
            return
        }
        let boundary = "ttaccessible-" + UUID().uuidString
        var request = makeRequest(path: "/api/feedback/report")
        request?.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request?.httpBody = multipartBody(boundary: boundary, reportJSON: reportData, logFile: logFile)
        perform(request, completion: completion)
    }

    // MARK: - Announcements

    func checkAnnouncement(
        installID: String,
        language: String,
        completion: @escaping (Result<Announcement?, BackendError>) -> Void
    ) {
        let body: [String: Any] = [
            "app": Self.appID,
            "install_id": installID,
            "lang": language,
        ]
        guard var request = makeRequest(path: "/api/announce/check"),
              let data = try? JSONSerialization.data(withJSONObject: body) else {
            DispatchQueue.main.async { completion(.failure(.notConfigured)) }
            return
        }
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = data

        session.dataTask(with: request) { data, response, error in
            let result: Result<Announcement?, BackendError>
            if error != nil {
                result = .failure(.network)
            } else if let http = response as? HTTPURLResponse, http.statusCode == 200,
                      let data,
                      let decoded = try? JSONDecoder().decode(AnnounceCheckResponse.self, from: data),
                      decoded.ok {
                result = .success(decoded.announcement)
            } else {
                result = .failure(.server)
            }
            DispatchQueue.main.async { completion(result) }
        }.resume()
    }

    /// Fire-and-forget: tells the backend the announcement was actually shown.
    func acknowledgeAnnouncement(installID: String, announcementID: String) {
        let body: [String: Any] = [
            "app": Self.appID,
            "install_id": installID,
            "id": announcementID,
        ]
        guard var request = makeRequest(path: "/api/announce/ack"),
              let data = try? JSONSerialization.data(withJSONObject: body) else {
            return
        }
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = data
        session.dataTask(with: request).resume()
    }

    // MARK: - Plumbing

    private struct AnnounceCheckResponse: Decodable {
        let ok: Bool
        let announcement: Announcement?
    }

    private struct APIResponse: Decodable {
        let ok: Bool
        let errorCode: String?

        private enum CodingKeys: String, CodingKey {
            case ok
            case errorCode = "error_code"
        }
    }

    static var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
    }

    private func makeRequest(path: String) -> URLRequest? {
        guard let secret = Self.bearerSecret else {
            return nil
        }
        var request = URLRequest(url: Self.baseURL.appendingPathComponent(path))
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("Bearer \(secret)", forHTTPHeaderField: "Authorization")
        return request
    }

    private func perform(_ request: URLRequest?, completion: @escaping (Result<Void, BackendError>) -> Void) {
        guard let request else {
            DispatchQueue.main.async { completion(.failure(.notConfigured)) }
            return
        }
        session.dataTask(with: request) { data, response, error in
            let result: Result<Void, BackendError>
            if error != nil {
                result = .failure(.network)
            } else if let http = response as? HTTPURLResponse {
                if http.statusCode == 200 {
                    result = .success(())
                } else {
                    let decoded = data.flatMap { try? JSONDecoder().decode(APIResponse.self, from: $0) }
                    switch decoded?.errorCode {
                    case "rate_limited":
                        result = .failure(.rateLimited)
                    case "validation_error", "invalid_json":
                        result = .failure(.validation)
                    default:
                        result = .failure(.server)
                    }
                }
            } else {
                result = .failure(.network)
            }
            DispatchQueue.main.async { completion(result) }
        }.resume()
    }

    private func multipartBody(boundary: String, reportJSON: Data, logFile: (name: String, data: Data)?) -> Data {
        var body = Data()
        func append(_ string: String) {
            body.append(Data(string.utf8))
        }
        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"report\"\r\n")
        append("Content-Type: application/json\r\n\r\n")
        body.append(reportJSON)
        append("\r\n")
        if let logFile {
            append("--\(boundary)\r\n")
            append("Content-Disposition: form-data; name=\"log_file\"; filename=\"\(logFile.name)\"\r\n")
            append("Content-Type: text/plain\r\n\r\n")
            body.append(logFile.data)
            append("\r\n")
        }
        append("--\(boundary)--\r\n")
        return body
    }
}
