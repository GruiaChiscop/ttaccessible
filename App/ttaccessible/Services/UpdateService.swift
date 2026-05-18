//
//  UpdateService.swift
//  ttaccessible
//

import Foundation

struct UpdateRelease: Equatable {
    let tagName: String
    let displayVersion: String
    let releaseName: String
    let releaseNotes: String
    let htmlURL: URL
    let zipAsset: UpdateAsset
}

struct UpdateAsset: Equatable {
    let name: String
    let downloadURL: URL
    let size: Int64
}

enum UpdateCheckResult {
    case upToDate(currentVersion: String)
    case updateAvailable(UpdateRelease)
}

enum UpdateError: LocalizedError {
    case invalidResponse
    case noZipAsset
    case network(Error)
    case cancelled

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return L10n.text("update.error.invalidResponse")
        case .noZipAsset:
            return L10n.text("update.error.noZipAsset")
        case .network(let error):
            return error.localizedDescription
        case .cancelled:
            return L10n.text("update.error.cancelled")
        }
    }
}

final class UpdateService: NSObject {
    static let shared = UpdateService()

    private let releasesURL = URL(string: "https://api.github.com/repos/math65/ttaccessible/releases/latest")!
    private let session: URLSession

    private override init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        self.session = URLSession(configuration: config)
        super.init()
    }

    var currentVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"
    }

    // MARK: - Check

    func checkForUpdate(completion: @escaping (Result<UpdateCheckResult, UpdateError>) -> Void) {
        var request = URLRequest(url: releasesURL)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")

        let task = session.dataTask(with: request) { [weak self] data, response, error in
            guard let self else { return }
            if let error {
                DispatchQueue.main.async { completion(.failure(.network(error))) }
                return
            }
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode),
                  let data else {
                DispatchQueue.main.async { completion(.failure(.invalidResponse)) }
                return
            }
            do {
                let release = try Self.parseRelease(from: data)
                let cmp = Self.compareVersions(self.currentVersion, release.displayVersion)
                if cmp == .orderedAscending {
                    DispatchQueue.main.async { completion(.success(.updateAvailable(release))) }
                } else {
                    DispatchQueue.main.async { completion(.success(.upToDate(currentVersion: self.currentVersion))) }
                }
            } catch let err as UpdateError {
                DispatchQueue.main.async { completion(.failure(err)) }
            } catch {
                DispatchQueue.main.async { completion(.failure(.network(error))) }
            }
        }
        task.resume()
    }

    // MARK: - Download

    /// Downloads the release zip to ~/Downloads. Returns a handle that can cancel the download.
    @discardableResult
    func downloadRelease(
        _ release: UpdateRelease,
        progress: @escaping (Double) -> Void,
        completion: @escaping (Result<URL, UpdateError>) -> Void
    ) -> UpdateDownloadHandle {
        let delegate = UpdateDownloadDelegate(
            expectedSize: release.zipAsset.size,
            fileName: release.zipAsset.name,
            progress: progress,
            completion: completion
        )
        let downloadSession = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
        let task = downloadSession.downloadTask(with: release.zipAsset.downloadURL)
        delegate.task = task
        task.resume()
        return UpdateDownloadHandle(task: task)
    }

    // MARK: - Parsing

    private static func parseRelease(from data: Data) throws -> UpdateRelease {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let tag = json["tag_name"] as? String,
              let htmlString = json["html_url"] as? String,
              let html = URL(string: htmlString),
              let assets = json["assets"] as? [[String: Any]] else {
            throw UpdateError.invalidResponse
        }

        let zipAsset: UpdateAsset? = {
            for asset in assets {
                guard let name = asset["name"] as? String,
                      name.lowercased().hasSuffix(".zip"),
                      let urlString = asset["browser_download_url"] as? String,
                      let url = URL(string: urlString) else {
                    continue
                }
                let size = (asset["size"] as? Int64) ?? Int64((asset["size"] as? Int) ?? 0)
                return UpdateAsset(name: name, downloadURL: url, size: size)
            }
            return nil
        }()

        guard let zipAsset else { throw UpdateError.noZipAsset }

        let displayVersion = tag.hasPrefix("v") ? String(tag.dropFirst()) : tag
        let releaseName = (json["name"] as? String) ?? tag
        let releaseNotes = (json["body"] as? String) ?? ""

        return UpdateRelease(
            tagName: tag,
            displayVersion: displayVersion,
            releaseName: releaseName,
            releaseNotes: releaseNotes,
            htmlURL: html,
            zipAsset: zipAsset
        )
    }

    // MARK: - Version comparison

    /// Compares semantic-style versions like "1.0.0", "1.0.0-beta.12", or "v1.0.0-beta.2".
    /// Pre-release versions sort lower than the matching final version.
    static func compareVersions(_ lhs: String, _ rhs: String) -> ComparisonResult {
        let left = parseVersion(lhs)
        let right = parseVersion(rhs)
        let pairs = zip(left.numbers, right.numbers)
        for (l, r) in pairs {
            if l < r { return .orderedAscending }
            if l > r { return .orderedDescending }
        }
        if left.numbers.count < right.numbers.count { return .orderedAscending }
        if left.numbers.count > right.numbers.count { return .orderedDescending }

        switch (left.prerelease, right.prerelease) {
        case (nil, nil):
            return .orderedSame
        case (nil, _?):
            return .orderedDescending
        case (_?, nil):
            return .orderedAscending
        case (let l?, let r?):
            return comparePrereleases(l, r)
        }
    }

    private struct ParsedVersion {
        let numbers: [Int]
        let prerelease: String?
    }

    private static func parseVersion(_ raw: String) -> ParsedVersion {
        var stripped = raw
        if stripped.hasPrefix("v") || stripped.hasPrefix("V") {
            stripped.removeFirst()
        }
        let parts = stripped.split(separator: "-", maxSplits: 1, omittingEmptySubsequences: false)
        let numbers = parts[0].split(separator: ".").map { Int($0) ?? 0 }
        let prerelease: String? = parts.count > 1 ? String(parts[1]) : nil
        return ParsedVersion(numbers: numbers, prerelease: prerelease)
    }

    private static func comparePrereleases(_ lhs: String, _ rhs: String) -> ComparisonResult {
        let lParts = lhs.split(separator: ".").map(String.init)
        let rParts = rhs.split(separator: ".").map(String.init)
        let count = max(lParts.count, rParts.count)
        for i in 0..<count {
            let l = i < lParts.count ? lParts[i] : ""
            let r = i < rParts.count ? rParts[i] : ""
            if l == r { continue }
            if let lNum = Int(l), let rNum = Int(r) {
                return lNum < rNum ? .orderedAscending : .orderedDescending
            }
            return l < r ? .orderedAscending : .orderedDescending
        }
        return .orderedSame
    }
}

final class UpdateDownloadHandle {
    private weak var task: URLSessionDownloadTask?

    init(task: URLSessionDownloadTask) {
        self.task = task
    }

    func cancel() {
        task?.cancel()
    }
}

private final class UpdateDownloadDelegate: NSObject, URLSessionDownloadDelegate {
    weak var task: URLSessionDownloadTask?
    let expectedSize: Int64
    let fileName: String
    let progress: (Double) -> Void
    let completion: (Result<URL, UpdateError>) -> Void
    private var finished = false

    init(expectedSize: Int64,
         fileName: String,
         progress: @escaping (Double) -> Void,
         completion: @escaping (Result<URL, UpdateError>) -> Void) {
        self.expectedSize = expectedSize
        self.fileName = fileName
        self.progress = progress
        self.completion = completion
    }

    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        let expected = totalBytesExpectedToWrite > 0 ? totalBytesExpectedToWrite : expectedSize
        guard expected > 0 else { return }
        let fraction = Double(totalBytesWritten) / Double(expected)
        DispatchQueue.main.async { [weak self] in
            self?.progress(min(max(fraction, 0), 1))
        }
    }

    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        finished = true
        let fm = FileManager.default
        guard let downloads = fm.urls(for: .downloadsDirectory, in: .userDomainMask).first else {
            DispatchQueue.main.async { [weak self] in
                self?.completion(.failure(.invalidResponse))
            }
            return
        }
        var destination = downloads.appendingPathComponent(fileName)
        var counter = 1
        while fm.fileExists(atPath: destination.path) {
            let nameWithoutExt = (fileName as NSString).deletingPathExtension
            let ext = (fileName as NSString).pathExtension
            let candidate = "\(nameWithoutExt) (\(counter)).\(ext)"
            destination = downloads.appendingPathComponent(candidate)
            counter += 1
        }
        do {
            try fm.moveItem(at: location, to: destination)
            DispatchQueue.main.async { [weak self] in
                self?.completion(.success(destination))
            }
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.completion(.failure(.network(error)))
            }
        }
    }

    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didCompleteWithError error: Error?) {
        defer { session.invalidateAndCancel() }
        guard let error, !finished else { return }
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
            DispatchQueue.main.async { [weak self] in
                self?.completion(.failure(.cancelled))
            }
            return
        }
        DispatchQueue.main.async { [weak self] in
            self?.completion(.failure(.network(error)))
        }
    }
}
