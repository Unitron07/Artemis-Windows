# Source layout

This is currently a planning-only repository.

The implementation will preserve the Moonlight PC fork's existing root layout:

- `app/gui/` — Qt/QML interface
- `app/settings/` — preferences and profiles
- `app/backend/` — hosts, pairing, HTTP, and Apollo integration
- `app/streaming/` — sessions, input, decoding, and rendering
- `moonlight-common-c/` — native protocol project and pinned submodule
- `scripts/`, `wix/`, and root qmake projects — upstream build/package infrastructure

Do not create a duplicate application under this `src/` directory. This placeholder can be removed when the upstream source import lands. See [the porting plan](../docs/PORTING_PLAN.md).
