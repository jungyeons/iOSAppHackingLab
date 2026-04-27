# Runtime Instrumentation Lab

This project includes a local-only runtime observation exercise for LLDB and Frida. The target is the simulator build of this repository's app:

```text
com.jungyeons.iosapphackinglab
```

Do not use these notes against third-party apps, production services, or devices you do not own or have explicit permission to test.

## Lab Probe

The stable observation target is `LabObservationProbe`. It is intentionally exposed to Objective-C so LLDB and Frida can find predictable selectors:

- `startObservationWithAccount:token:`
- `recordCheckpointWithLabel:secret:`
- `finishObservationWithResult:`

The in-app transcript redacts secrets and records only metadata such as length, labels, and a stable account fingerprint.

## LLDB Flow

Build and run the simulator target first, then attach to the lab app process:

```bash
lldb
(lldb) process attach --name iOSAppHackingLab
(lldb) image lookup -rn 'LabObservationProbe|runRuntimeObservation'
(lldb) breakpoint set --func-regex 'LabObservationProbe.*startObservation'
(lldb) breakpoint set --func-regex 'LabObservationProbe.*recordCheckpoint'
(lldb) breakpoint set --func-regex 'LabObservationProbe.*finishObservation'
(lldb) continue
```

Return to the app and press **Run Observation Scenario**. Capture the breakpoint hits and map them back to `LabStore.runRuntimeObservation(account:)`.

## Frida Flow

The observer script lives at:

```text
tools/frida/observe-lab-state.js
```

If Frida is installed and the simulator app process is visible:

```bash
frida-ps | rg iOSAppHackingLab
frida -n iOSAppHackingLab -l tools/frida/observe-lab-state.js
```

Then press **Run Observation Scenario** in the app. The script observes the probe selectors and logs redacted argument metadata. It does not modify behavior or return values.

## Evidence Checklist

- Confirm the target process is `iOSAppHackingLab`.
- Capture one runtime event in the app transcript.
- Capture one LLDB breakpoint or symbol lookup.
- Capture one Frida observer log line.
- Redact raw secrets before publishing screenshots, notes, or reports.
