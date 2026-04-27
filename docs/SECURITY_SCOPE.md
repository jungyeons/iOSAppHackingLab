# Security Scope

This project is an intentionally vulnerable local lab for defensive iOS and Apple platform security study.

## In Scope

- Running and modifying this repository's SwiftUI lab app.
- Inspecting local storage created by this lab app.
- Reading the source code to understand weak patterns.
- Using LLDB or Frida to observe this lab app's simulator process and lab-only probe.
- Capturing screenshots, console output, and notes for a personal study report.
- Replacing weak patterns with safer platform-native alternatives.

## Out of Scope

- Testing third-party apps, production services, or apps from the App Store.
- Attaching runtime instrumentation to third-party apps or services outside this lab.
- Accessing accounts, devices, or data that you do not own or have explicit permission to test.
- Bypassing paywalls, device protections, or authorization checks outside this lab.
- Collecting or publishing real user secrets, tokens, passwords, or personal data.

## Practice Rule

Every exercise should answer three questions:

1. What local behavior made the weakness observable?
2. What evidence proves the weakness inside this lab?
3. What design change would reduce the risk in a real app?
