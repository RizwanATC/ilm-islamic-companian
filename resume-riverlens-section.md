**Riverlens Sdn. Bhd.** — Mobile Developer (Android & iOS) · Jan 2025 – Present

**Ommri Care — Patient App for a Multi-Branch Clinic Group (Native iOS & Android)**
*Swift 6, SwiftUI, Kotlin, Jetpack Compose, Hilt, Coroutines/Flow, Retrofit, OkHttp, Firebase, Stripe*

- Developed and maintained native iOS (Swift 6, SwiftUI, iOS 16+) and Android (Kotlin, Jetpack Compose, Android 10+) patient apps covering appointment booking, prescriptions, medical records, video consultations and bill payment, localised in English and Bahasa Melayu.
- Maintained feature parity across both platforms through a shared design system derived from the product prototype.
- Implemented biometric sign-in (Face ID, Touch ID, fingerprint) using per-device P-256 keys held in the Secure Enclave (iOS) and Android Keystore/StrongBox, authenticated with a signed one-time challenge against the backend; keys are invalidated on biometric change, with a secure password fallback.
- Built the authentication and security layer: email/password sign-up with email-code verification, password reset, app lock, encrypted on-device storage (Keychain; Tink AES-GCM on Android), sign-out of all devices, and session refresh/revocation handling.
- Integrated on-device eKYC: MyKad capture and OCR (ML Kit) with face matching (ONNX Runtime).
- Delivered clinical workflows: three-step booking with same-day slots, visit status and check-in, state-driven prescription actions (collect, same-day delivery, refill), allergies and health records, record sharing, and wellbeing sessions.
- Integrated Stripe payments (including GrabPay) and Firebase Cloud Messaging with deep links to specific items; added iOS Live Activities for clinic queue status and home-screen widgets.
- Improved accessibility and release readiness: VoiceOver/TalkBack support, Dynamic Type and large text, light/dark themes, and server-driven feature flags to hide unfinished features at launch.
- Wrote unit and UI tests (XCTest, Robolectric, Compose tests, MockWebServer) and local CI scripts for linting, formatting, multi-OS test runs and release builds.
- Shipped builds via TestFlight (self-hosted macOS runner), Firebase App Distribution, Google Play and Huawei AppGallery.
- Collaborated with backend (TypeScript API) and QA engineers on a task board, reviewed API contracts across iOS, Android and backend, and verified features on real devices against staging before release.

**Alafasy — Main App (Native Android)**
*Kotlin, MVVM, Jetpack, Coroutines/Flow/LiveData, Retrofit, Room, Hilt*

- Developed the Android app from scratch in Kotlin, owning the full SDLC from UI/UX implementation to production deployment.
- Applied MVVM with Jetpack components for a maintainable, scalable architecture, and Hilt for dependency injection to improve modularity and testability.
- Used Coroutines and Flow/LiveData for asynchronous work and reactive data handling across UI and data layers.
- Integrated RESTful APIs with Retrofit, covering JSON parsing, error handling, authentication flows and secure networking.
- Implemented Room for local persistence, enabling offline support and optimised caching.
- Optimised battery usage, memory management, background processing and network overhead.
