import Foundation

enum RedactingLogger {
    static func loginSucceeded(account: String, token: String) -> String {
        let eventID = UUID().uuidString
        let message = """
        event=login_succeeded account=\(redact(account)) token=\(redact(token)) eventID=\(eventID)
        """
        NSLog("%@", message)
        return message
    }

    static func redact(_ value: String) -> String {
        guard !value.isEmpty else {
            return "<empty>"
        }

        return "<redacted:\(value.count)-chars>"
    }
}
