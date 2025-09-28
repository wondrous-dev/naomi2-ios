//
//  RealtimeChatService.swift
//  naomi-ios
//
//  Created by Assistant on 9/19/25.
//

import Foundation
import Combine
import Ably

public enum RealtimeEvent {
	case habitsCreated
}

public protocol RealtimeChatListening: AnyObject {
	func start(userId: String?)
	func stop()
	var messagePublisher: AnyPublisher<ChatMessage, Never> { get }
	var eventPublisher: AnyPublisher<RealtimeEvent, Never> { get }
}

public final class RealtimeChatService: RealtimeChatListening {
	private let subject = PassthroughSubject<ChatMessage, Never>()
	public var messagePublisher: AnyPublisher<ChatMessage, Never> { subject.eraseToAnyPublisher() }

	private let eventSubject = PassthroughSubject<RealtimeEvent, Never>()
	public var eventPublisher: AnyPublisher<RealtimeEvent, Never> { eventSubject.eraseToAnyPublisher() }

	private var isStarted = false

	public init() {}

	public func start(userId: String?) {
		print("[RealtimeChatService] start(userId: \(userId ?? "nil")) called; isStarted=\(isStarted)")
		guard !isStarted else { return }
		isStarted = true
		#if canImport(Ably)
		print("[RealtimeChatService] Initializing Ably client...")
		startAbly(userId: userId)
		#else
		print("[RealtimeChatService] Ably SDK not available. Realtime disabled.")
		#endif
	}

	public func stop() {
		#if canImport(Ably)
		stopAbly()
		#endif
		isStarted = false
	}

	#if canImport(Ably)
	private var realtime: ARTRealtime?
	private var channel: ARTRealtimeChannel?

    private func startAbly(userId: String?) {
		print("[RealtimeChatService] startAbly: preparing options")
		let apiKey = ProcessInfo.processInfo.environment["ABLY_API_KEY"]
		let options = ARTClientOptions()
		options.autoConnect = true
		if let apiKey, !apiKey.isEmpty {
			options.key = apiKey
			print("[RealtimeChatService] Using Ably API key")
		} else if let token = ProcessInfo.processInfo.environment["ABLY_TOKEN"] {
			options.token = token
			print("[RealtimeChatService] Using Ably token")
		} else {
			print("[RealtimeChatService] No Ably credentials found in environment")
		}

		realtime = ARTRealtime(options: options)
		print("[RealtimeChatService] ARTRealtime created")
		let uid = (userId ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
		guard !uid.isEmpty else {
			print("[RealtimeChatService] Cannot subscribe: userId is empty")
			return
		}
		let channelName = "companion_message:\(uid)"
		print("[RealtimeChatService] Getting channel: \(channelName)")
		channel = realtime?.channels.get(channelName)

		channel?.subscribe { [weak self] message in
			print("[RealtimeChatService] Ably received: name=\(message.name ?? "nil") dataType=\(type(of: message.data))")
			if message.name == "message" {
				guard let data = message.data as? String else {
					print("[RealtimeChatService] Ably message payload is not String; ignoring")
					return
				}
				print("[RealtimeChatService] Incoming payload (prefix 200): \(data.prefix(200))")
				self?.handleIncomingJSON(data)
			} else if message.name == "habits_created" {
				print("[RealtimeChatService] habits_created event received")
				self?.eventSubject.send(.habitsCreated)
			} else {
				// Ignore other events for now
			}
		}
		print("[RealtimeChatService] Subscribed to \(channelName)")
	}

	private func stopAbly() {
		channel?.unsubscribe()
		channel = nil
		realtime?.close()
		realtime = nil
	}
	#endif

	private func handleIncomingJSON(_ jsonString: String) {
		guard let data = jsonString.data(using: .utf8) else { return }
		do {
			let dto = try JSONDecoder.api.decode(ChatMessageDTO.self, from: data)
			let msg = dto.toDomain()
			subject.send(msg)
		} catch {
			print("[RealtimeChatService] Failed to decode incoming message: \(error)")
		}
	}
}

private extension JSONDecoder {
	static var api: JSONDecoder {
		let d = JSONDecoder()
		d.dateDecodingStrategy = .iso8601
		return d
	}
}
