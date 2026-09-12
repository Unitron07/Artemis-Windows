# Validation and release evidence

These are planned checks. No results have been recorded yet. Attach results to the relevant milestone PR and link them from release notes. A source inspection, CI build, and real hardware test establish different things; record which was performed.

## Functional checks

| Area | Required cases | Pass condition |
| --- | --- | --- |
| Standard hosts | Pinned Sunshine and Apollo builds independently; discovery/manual host, pair/unpair, app list, launch/resume/disconnect/quit | Baseline functions work; disconnect and quit have distinct effects |
| Session lifecycle | 20 connect/disconnect cycles; timeout, network interruption, sleep/resume, client crash/restart | No stuck input, stale requests, unintended host actions, or persistent new resource leak |
| Host changes | Switch between two paired hosts; reconnect after permissions change | No stale capability state or cross-host clipboard response |
| Keyboard/mouse | Relative/direct modes, wheel, Alt+Tab/capture release, non-US layout, dead keys; IME if claimed | Correct host input and reliable local escape; no stuck modifiers |
| Display | 100/150/200% DPI, two monitors of different scale, fullscreen/windowed, implemented scaling modes | Correct direct-pointer corner/center mapping, usable UI, safe monitor removal |
| Audio/gamepad | Output-device change, stereo baseline, controller hotplug/rumble | No crash or stuck controller state; negotiated features work |
| Clipboard | Both directions, Unicode/emoji/newlines/empty text, unsupported formats, size limit, denial, slow response, malformed/HTTP-200 error reply | Only authorized text applied; errors preserve clipboard; no echo loop or sensitive log content |
| Virtual display | Ready/missing driver, denied request, launch/resume, disconnect/crash/reconnect, existing host session | Host state and client status match the documented host behavior; no unrelated display reset |
| Server commands | Harmless command, deny permission, changed list, invalid index, disconnect during send | Correct indexed action, no unsolicited replay, no false execution-success claim |
| Identity/package | Moonlight side by side, portable directory, clean-machine launch, installer update/uninstall | No shared credentials/settings collisions or unintended data removal |
| Accessibility | Keyboard-only settings/actions, focus visibility, readable scale, accessible names | Included workflows remain operable without a mouse |

Use fixtures/unit tests for permission parsing, profiles/migrations, URL encoding, coordinate transforms, stale-session cancellation, and native command encoding. Use a bounded mock HTTP service for clipboard/error contracts. Run these in CI once implemented. Real Sunshine/Apollo sessions and GPU/input/display checks remain manual or hardware-lab tests; do not label hosted-runner builds as full compatibility coverage.

## Performance method

1. Build unmodified upstream and the Artemis candidate in Release configuration with the same dependencies. Record both SHAs.
2. Use the same client GPU/driver, host build/GPU/encoder, resolution, refresh rate, codec, bitrate, display, power mode, and network path.
3. Warm up for two minutes, then collect at least three five-minute runs of each build. Alternate their order and use the same reproducible workload. Start with wired LAN 1080p60 H.264 SDR, then test enabled extensions.
4. Record median and p95 decode/render/frame-queue times where available, frame drops, frame pacing, CPU/GPU load, memory trend, audio glitches, and connection failures. Keep raw logs and the workload description.
5. Measure input-to-photon latency with a high-speed camera or suitable hardware if reporting that metric. Internal decode/network stats are not an input-to-photon measurement.
6. Perform a 30-minute session soak and the connect/disconnect lifecycle test with clipboard/overlays enabled, if included.

**Proposed initial regression gate:** on baseline hardware, flag an increase in p95 decode-plus-render time greater than the larger of 1 ms or 10% of baseline, or a dropped-frame-rate increase greater than 0.5 percentage points. Investigate repeated failures before release; compare measurement variance and record any deliberate, feature-specific exception. These thresholds are engineering targets to calibrate from M0 results, not measured performance promises. Crashes, stuck input, cross-host data transfer, and broken baseline streaming are release blockers regardless of timing averages.

## Hardware coverage

Required for the first preview: the baseline H.264 SDR path on at least one recorded x64 Windows 11 client and both recorded host implementations. Retain upstream codec functionality and smoke-test each additional path available on that machine.

Before claiming broad stable support, test representative Intel, AMD, and NVIDIA clients; hybrid-GPU selection; supported HEVC/AV1/HDR paths; high refresh rate; and office-text quality with YUV 4:4:4 where both ends support it. List each tested GPU, driver, OS build, codec/chroma/HDR mode, and host version. Mark unavailable combinations untested; unsupported codec hardware should produce a clear fallback or error.

Windows 10 and ARM64 need their own declared minimum OS/runtime and hardware qualification. Local multi-monitor behavior does not establish support for simultaneous remote-monitor streams.

## Result template

- Date and tester:
- Upstream SHA / candidate SHA / dependency and submodule manifest:
- Client OS build, architecture, GPU, driver, display/DPI, power mode:
- Host product/version, OS, GPU/encoder, virtual-display driver:
- Network and stream settings:
- Workload and run duration:
- Functional cases: pass / fail / not tested:
- Performance baseline / candidate / variance:
- Raw evidence:
- Known limitations, blockers, and linked fixes:

## Release checklist

- [ ] M0 build instructions work from a clean checkout.
- [ ] Functional and regression gates pass for the advertised scope.
- [ ] Portable build runs with deployed runtimes on a clean machine; data-location behavior is documented.
- [ ] Exact versions, hashes, source, submodule contents, licenses/notices, and symbols are available.
- [ ] Stable executable/installer signing and installer lifecycle checks pass when those artifacts are offered.
- [ ] Release notes distinguish tested support, inherited-but-untested paths, deferred features, and known issues.
