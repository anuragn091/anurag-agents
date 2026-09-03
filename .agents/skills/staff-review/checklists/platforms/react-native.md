# React Native

Load only when the diff touches a React Native app. Sits on top of `platforms/react.md` and `platforms/javascript-typescript.md`, under `concerns/security.md` and `concerns/performance-frontend.md`.

## Cross-platform behavior
- **Has the change been checked on both iOS and Android?** A screenshot from one platform is half the evidence.
- Platform differences explicit and minimal. `Platform.select` where behavior truly differs, not to paper over a layout bug.
- Works on the supported OS versions and device sizes, not only the newest simulator.
- Tablet, landscape, notch, safe area and foldable layouts considered.
- Platform-specific files (`.ios.tsx`, `.android.tsx`) used only when the behavior genuinely diverges.
- Runtime permissions requested and denied-path handled on both platforms.

## Navigation and lifecycle
- Route params typed and validated. A deep link can supply anything.
- Back navigation correct on both platforms, including the Android hardware back button.
- Deep links, universal links and app links handled, including the cold-start case.
- Screen state refreshed on focus where the data can go stale, and not refetched on every focus where it cannot.
- Listeners removed when a screen loses focus or unmounts.
- Correct after backgrounding and resuming, including a token that expired while backgrounded.
- Transient state that matters preserved across process termination.

## Rendering and lists
- `FlatList`, `SectionList` or another virtualized list for any large collection. Never `map` over a long array inside a `ScrollView`.
- Keys stable.
- Item renderers lightweight, and defined outside the parent render or memoized.
- `getItemLayout`, batching and window size settings justified rather than copied from a blog post.
- Nested scroll views avoided where they break virtualization.
- Inline object and callback allocations in the render path causing measurable rerenders.
- Animations on the UI or native thread, `useNativeDriver` where the animated property allows it.

## Native performance
- Expensive work kept off the JavaScript thread.
- Synchronous native calls that can block rendering.
- Large JSON payloads or chatty bridge traffic avoided.
- Images resized, cached and decoded efficiently. A full-resolution photo in a 48pt avatar is a defect.
- Memory released for listeners, media players, maps and other native resources.
- **Tested on a lower-end device or a throttled environment**, not only on the newest phone.
- Effect on launch time and binary size considered.

## Touch and accessibility
- Touch targets large enough and adequately separated.
- Feedback on tap, and on long-running actions.
- `accessibilityLabel`, `accessibilityRole`, state and hints correct.
- Works with VoiceOver and TalkBack.
- Dynamic font sizing supported without clipping.
- Color contrast sufficient, reduced-motion respected.
- Keyboard does not cover the input or the submit button.

## Networking and offline
- Slow, failed, duplicated and out-of-order requests handled.
- Connectivity loss handled gracefully, with a path back once it returns.
- Retry and sync operations idempotent.
- Optimistic updates rolled back correctly when the server disagrees.
- Cached data scoped per user and invalidated on logout or account switch.
- Uploads and downloads safe when the app is backgrounded or killed.
- Requests cancelled when the screen is gone.

## Storage and mobile security
- **Tokens and secrets in Keychain or Keystore, never `AsyncStorage`.**
- Personal data minimized and encrypted where the sensitivity warrants it.
- Sensitive information excluded from logs, crash reports and screenshots (the app switcher snapshot included).
- Deep-link input treated as untrusted.
- WebView origins, navigation and injected JavaScript restricted.
- Certificate pinning or device integrity only where the threat model actually calls for it, not by default.
- **Logout clears cached and persisted sensitive data**, not just the token.

## Native dependencies and releases
- Is the new native dependency necessary, maintained, and compatible with the project's React Native architecture?
- iOS pods, Android Gradle config and permission manifests updated correctly.
- Native build and release configuration unaffected, or the change is explained.
- Does this need a store release, or can it ship over the air?
- Compatible with users still running an older native binary.
- Feature flag and rollback path available for anything risky, since a bad native release cannot be pulled back quickly.

## Tests
- Component interactions tested.
- Native modules mocked at their boundary only.
- Navigation, deep links, permissions and lifecycle transitions covered.
- Critical flows exercised on both iOS and Android.
- Device-level tests for high-risk workflows.
- Accessibility and performance checked on a real device, not only the simulator.
