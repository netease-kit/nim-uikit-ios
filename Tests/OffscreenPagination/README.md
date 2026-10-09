# Offscreen history pagination regression probe

This standalone UIKit fixture reproduces accessibility snapshots invoking
`tableView(_:willDisplay:forRowAt:)` for rows outside the viewport. It models
the chat controller's pagination condition and scroll restoration with 120
initial messages, a 100-message threshold and one delayed 50-message history
response. It does not require IM credentials, SDK dependencies or customer data.

The baseline and fixed modes differ only by the same row-rectangle/viewport
intersection guard added to the production controllers. This is a reduced
mechanism regression test, **not a test that instantiates ChatViewController**.
It cannot replace full IM Demo regression or verify the installed customer App.

## Run

Requires Xcode, Node.js 20+, an already booted iOS simulator and a running
WebDriverAgent session. Use a dedicated test simulator: the script installs and
launches `dev.midscene.offscreenpagination`. It does not change WDA settings.

```sh
SIMULATOR_UDID=<booted-simulator-uuid> \
WDA_URL=http://127.0.0.1:8101 \
WDA_SESSION_ID=<existing-session-id> \
node Tests/OffscreenPagination/run.mjs
```

The script builds and signs the simulator app, runs eight cases and retains
before/after screenshots plus native event logs in a printed temporary directory.
No generated files are written into this repository. Keep that directory for
diagnosis; it includes offscreen callback stacks, touch positions, pagination
requests and programmatic scrolls.

| Operation | Without viewport guard | With viewport guard |
| --- | --- | --- |
| Stationary W3C long press | Spurious history fetch and jump | Target selected, no jump |
| Legacy coordinate long press | Spurious history fetch and jump | Target selected, no jump |
| Accessibility source read, zero touches | Spurious history fetch and jump | No jump |
| Screenshot read, zero touches | No jump | Not needed |
| Actual drag bringing row 10 into view | Not needed | History still loads |

Also validate in the real IM Demo: enter a conversation with enough history,
long-press a visible message, inspect the accessibility hierarchy, and then
manually paginate history. Offscreen inspection must not change the viewport
or read state, while genuine visible rows must retain the existing behavior.
