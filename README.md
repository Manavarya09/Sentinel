# Sentinel Hybrid

A privacy-first, offline-only hybrid iOS/macOS architecture: Objective-C core for business logic and persistence; Swift for UI and ergonomics.

## Architecture Overview
- **Hybrid MVC + MVVM:**
  - **Objective-C Core (MVC):** Event capture, Core Data persistence, analytics, security/keychain, threading. UI-agnostic, testable, stable.
  - **Swift UI Layer (MVVM):** SwiftUI views, ViewModels, immutable UI models, presentation logic and mapping.
- **Module Boundaries:** Swift never touches Core Data or business rules; it calls clean ObjC APIs. ObjC core exposes headers with `NS_SWIFT_NAME` to feel native in Swift.

## Why Objective-C Owns the Core
- **Runtime Stability:** Mature ARC, predictable ownership, low-level control over threading and Core Data.
- **Core Data:** Deep ObjC integrations, performance tuning via `NSManagedObjectContext` and faulting; programmatic models with fetch-indexes.
- **Interoperability:** Clean Objective-C API surface to multiple UI stacks (UIKit/SwiftUI/macOS AppKit) without leaking UI concerns.

## Why Swift Owns the UI
- **Value Semantics & Safety:** `struct` UI models and `@Published` ViewModel state; main-thread enforcement.
- **Ergonomics:** Declarative SwiftUI, protocol-oriented design for presentation.
- **Boundary Discipline:** Swift composes results from ObjC services without implementing business logic.

## Why Not Rewrite Everything in Swift
- **Long-Lived Core:** ObjC ABI stability and proven runtime for persistence/analytics; minimal churn.
- **Core Data Expertise:** Avoid re-creating mature patterns; leverage ObjC’s thorough Core Data API surface.
- **Clarity of Responsibility:** UI evolves rapidly; core remains stable.

## Project Structure
```
SentinelHybrid/
├── ObjCCore/
│   ├── EventCapture/
│   ├── Persistence/
│   ├── Analytics/
│   ├── Security/
│   └── Models/
├── SwiftUI/
│   ├── Views/
│   ├── ViewModels/
│   └── UIModels/
├── App/
│   ├── AppDelegate/
│   └── SceneDelegate/
├── Resources/
└── Tests/
```
- **Split Rationale:** Keeps ObjC services testable and reusable across platforms; Swift UI can iterate independently.

## Core Modules
- **Event Capture Manager (ObjC):**
  - Observes app/scene lifecycle via `NSNotificationCenter` using app-posted custom notifications.
  - Singleton with controlled ownership; records events into persistence.
- **Persistence Engine (ObjC):**
  - Programmatic Core Data model with `ActivityEvent` entity.
  - Background contexts, merge policy `NSMergeByPropertyObjectTrumpMergePolicy`, batched saves, faulting enabled.
- **Analytics Engine (ObjC):**
  - Aggregation, time-based metrics, session analysis.
  - Runs off main on a serial queue with Utility QoS; returns dictionaries via callbacks.
- **Security Layer (ObjC):**
  - Keychain abstraction (`kSecClassGenericPassword`), device-only accessibility.
  - File protection via `NSFileProtectionComplete`.

## Data Model: ActivityEvent
- **Properties:**
  - `eventID: UUID` (primary id) — strong.
  - `timestamp: NSDate` — strong.
  - `eventType: NSString` — copy (defensive against mutable strings; ensures immutability at the boundary).
  - `sourceApp: NSString` — copy (same rationale).
  - `duration: NSTimeInterval?` — stored as `NSNumber` double (optional).
- **Indexing & Faulting:**
  - Fetch index on `timestamp` + `eventType` for fast time-range aggregations.
  - Faults enabled to avoid over-materialization in analytics scans.

## Swift ↔ ObjC Interop
- **Shared Framework:** ObjCCore headers expose APIs; `NS_SWIFT_NAME` applied to classes/methods for clean Swift use.
- **Example:**
  - ObjC: `- (void)dailySummaryWithCompletion:(void (^)(NSDictionary *))completion NS_SWIFT_NAME(dailySummary(completion:));`
  - Swift: `AnalyticsEngine.shared().dailySummary { ... }`
- **No Leaking Internals:** Swift consumes immutable dictionaries and maps to `struct` models.

## Concurrency
- **Objective-C:**
  - Core Data via `performBlock` on private-queue contexts.
  - Analytics on serial GCD queue with Utility QoS.
  - No thread-hopping bugs: completion returns from background; Swift ViewModel marshals to main.
- **Swift:**
  - Main-thread UI updates via `DispatchQueue.main.async` in ViewModel.
  - Structured concurrency is not forced: core services predate async/await and rely on stable GCD + callbacks. Boundary enforces correctness without unnecessary conversion.

## Memory Management
- **Objective-C:**
  - Ownership: `strong` for objects, `weak` for delegates, `assign` for primitives, `copy` for strings/blocks.
  - Retain cycles avoided via `__weak typeof(self)` in blocks inside managers.
  - Delegates are `weak` to prevent cycles.
- **Swift:**
  - ARC automatically manages references; closures use `[weak self]` to avoid cycles.
  - Value semantics in UI models (`struct`) prevent accidental shared mutable state.

## Testing Strategy
- **ObjC XCTest:** In-memory Core Data tests for persistence; deterministic analytics aggregation tests.
- **Swift Tests:** ViewModel unit tests validate mapping and basic state updates.
- **No UI automation:** Focus on correctness and determinism at the core and ViewModel layers.

## Scalability & Future
- **macOS Support:** Shared ObjC core is platform-agnostic; swap SwiftUI views/AppKit shells as needed.
- **SwiftUI Migration:** UIKit SceneDelegate present; can evolve to pure SwiftUI App while keeping the core intact.
- **Plugin Analytics:** Add new analytics services behind stable ObjC interfaces; preserve binary compatibility.
- **Maintainability:** Clear boundaries; ObjC core has minimal churn; Swift UI iterates quickly without destabilizing persistence or analytics.

## Xcode Setup
To integrate into Xcode for iOS/macOS development:

1. **Create Xcode Project:**
   - Open Xcode, select "File > New > Project".
   - Choose "App" for iOS (or macOS), name it "SentinelHybrid", select SwiftUI interface, SwiftUI App lifecycle.
   - Save the project in `/Users/manavaryasingh/Sentinel/SentinelHybrid`.

2. **Add ObjCCore Framework Target:**
   - In Xcode, select "File > New > Target".
   - Choose "Framework" (iOS or macOS), name it "ObjCCore".
   - Add all files from `ObjCCore/` to the framework target.
   - Ensure "Defines Module" is enabled in build settings for modular imports.

3. **Configure Bridging Header for App Target:**
   - In the SentinelHybrid app target, go to Build Settings.
   - Search for "Objective-C Bridging Header".
   - Set it to `SentinelHybrid/SentinelHybrid-Bridging-Header.h` (the file created above).
   - This allows Swift code to import ObjCCore seamlessly.

4. **Link Frameworks:**
   - In the app target, go to "General" tab.
   - Under "Frameworks, Libraries, and Embedded Content", add "ObjCCore.framework" and embed it.

5. **Add SwiftUI and App Files:**
   - Add `SwiftUI/Views/`, `SwiftUI/ViewModels/`, `SwiftUI/UIModels/`, `App/SentinelHybridApp.swift` to the app target.
   - Replace the default `ContentView.swift` with `ActivitySummaryView.swift` and update the app struct accordingly.

6. **Add Test Targets:**
   - Create unit test targets for ObjC (link to ObjCCore) and Swift (link to app).
   - Add test files from `Tests/ObjC/` and `Tests/Swift/`.

7. **Build and Run:**
   - Ensure Core Data model is compiled; add any necessary entitlements for Keychain access.
   - Run on simulator/device; the app will start event capture and display analytics summaries.

This setup maintains clean separation: ObjCCore as a modular framework, Swift UI consuming it via bridging header.

## Privacy & Offline-Only Guarantees
- No network clients; all data local.
- Keychain and file protection enforced; explicit accessibility attributes.
# Sentinel
# Sentinel
