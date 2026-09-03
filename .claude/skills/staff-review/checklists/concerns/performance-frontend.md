# Frontend Performance (technology agnostic)

Applies to any client UI. React and React Native specifics live in the platform checklists.

## Loading
- Is the initial download size reasonable for what the screen actually shows?
- Code, styles, images, fonts and other assets optimized and correctly formatted.
- Non-critical resources lazy-loaded, critical ones prioritized.
- Does the change add a render-blocking resource?
- Caching headers and cache busting configured correctly.
- Does the page stay usable on a slow network, not just on the reviewer's connection?

## Rendering and responsiveness
- Unnecessary rendering or repeated computation on every update.
- Long-running work blocking user interaction on the main thread.
- Large lists, tables and feeds virtualized or paginated.
- Scroll, resize, search and pointer handlers throttled or debounced.
- Animations smooth, and driven by cheap properties rather than layout-triggering ones.
- Acceptable on a lower-end device, not only the developer's machine.
- **Memory leaks through listeners, timers, subscriptions or retained objects.** Every one of them needs a cleanup path.

## Network usage
- Duplicate, unnecessary or oversized requests.
- Independent requests running concurrently instead of in a waterfall.
- Repeated requests cached or deduplicated.
- Responses paginated or loaded incrementally.
- Stale or abandoned requests cancelled.
- Retry behavior bounded, and never on a non-idempotent call.
- Uploads and downloads compressed or chunked where the payload justifies it.

## User-perceived performance
- Useful content shown as early as possible, rather than one spinner over the whole screen.
- Loading states meaningful and non-blocking.
- Layout stable while content loads. No shift when the image or the data arrives.
- The interface responds immediately to a tap or click, even when the result takes time.
- Optimistic updates safe and reversible when the server disagrees.
- Regressions measured against a baseline, not judged by feel.
- The metrics that matter for this screen are actually monitored.
