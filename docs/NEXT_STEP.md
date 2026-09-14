# Next step: qualify the first portable preview

Asteria identity/rebranding and native x64/ARM64 build and packaging work are implemented. The next gate is real Windows 11 ARM64 device qualification, followed by x64 smoke testing from the same release commit. Profiles, new session workflows, performance changes, and Apollo extensions remain roadmap work and are not required for this first preview.

Track device evidence in [GitHub issue #3](https://github.com/Unitron07/Asteria-Windows/issues/3).

## Implemented baseline

- M0 preserves Moonlight PC source history, notices, licenses, and submodules.
- PRs #5 and #6 established x64/ARM64 target selection, pinned dependencies, and upstream/candidate CI.
- PR #8 corrected ARM64 portable-package CRT contamination; the final ZIP architecture gate checks all packaged EXE/DLL files, including Qt plugins.
- PR #9 implemented Asteria application, settings, pairing, logs, artwork, and Windows package identity.
- All four upstream/candidate x64/ARM64 jobs passed in [run 34797782854](https://github.com/Unitron07/Asteria-Windows/actions/runs/34797782854) at `ab69dc3f76ff6b163ab91c35c3795d4da478f022`, including final-ZIP architecture validation.

See [BUILD_WINDOWS.md](BUILD_WINDOWS.md) for commands and [BASELINE.md](BASELINE.md) for evidence limits. CI does not establish native device execution or streaming compatibility.

## Remaining preview qualification

Use the [validation checklist and result template](VALIDATION.md) to record:

- Exact candidate commit, portable ZIP hash, and matching package-architecture report.
- Windows 11 ARM64 device/SoC/GPU, driver, OS build, native process architecture, and selected decoder; launch without development tools or x64 emulation.
- Discovery/manual host, pair/unpair, launch/resume/disconnect/quit, H.264 1080p60 SDR, audio, keyboard, relative/direct mouse, gamepad, focus/capture release, DPI changes, sleep/resume, and a 30-minute soak.
- Separate Sunshine and Apollo host versions and standard-streaming results. This does not qualify Apollo-specific extensions.
- Available HEVC/AV1/HDR paths and fallback behavior; mark unsupported or untested paths explicitly.
- Settings persistence, portable data location, and side-by-side use with Moonlight.
- A same-device upstream ARM64 comparison and an x64 smoke test from the same release commit.

Missing hardware or host access remains an open gate. Do not mark M0A complete solely because CI passes.

## Release wording after testing

Once the ARM64 test passes, replace “pending real Windows 11 ARM64 device qualification” with a statement tied to the recorded device, Windows build, host versions, and tested paths. Update README, BASELINE, PORTING_PLAN, and VALIDATION together and link the hardware report from release notes. Preserve untested limitations.

Publish separate x64 and ARM64 portable preview ZIPs with exact versions, hashes, symbols, corresponding source/submodules, notices, and known issues. Installer distribution/signing and new Asteria-specific features follow later qualification.
