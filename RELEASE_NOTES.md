## v1.7.0-beta.9 (build 40) — 2026-07-06

This is a **beta** release, for testing new changes before they ship to everyone. To receive beta updates, turn on **Include beta versions** in Preferences › General.

### Highlights
- **Clearer voices on busy servers.** Channels tuned to save bandwidth (with larger voice packets, common on big community servers) could sound choppy and hard to follow — that's fixed, playback is smooth again.
- **Per-user volumes stay where you put them.** The volume, balance and pan you set for individual people no longer bleed across servers — or onto someone else who happens to share the same login.
- **You decide what gets remembered.** A new setting lets you keep per-user volumes forever, only for the current session, or not at all.

### What's new

**Smoother playback on high-traffic channels.** Some community servers set up their channels with larger voice packets to save bandwidth. On those, voices could come through choppy — buffery and hard to understand — while ordinary channels were fine. Playback now adapts to the channel's packet size, so it stays clean whatever the server's settings. Crowded channels also hold up better: incoming audio is handled on its own dedicated path, so a channel full of people can no longer make everyone's sound stutter at once.

**Per-user volumes are now tied to the server.** Some people noticed users showing up at odd volumes — loud or quiet — without ever having touched them. The cause: a level you'd set for one account name was being reused for anyone with that same name, including on completely different servers. (Public servers often share generic logins like `guest`.) Volumes, stereo balance and pan are now scoped to the server they were set on, so a level you set on one server stays there.

**Choose how per-user volumes are remembered.** Preferences › Audio has a new **Per-user volume memory** setting with three options:

- **Off** — nothing is remembered; reconnecting puts everyone back to 50%, like the official client.
- **This session only** — your adjustments last while the app is open, then reset when you quit.
- **Always** (default) — adjustments are remembered across launches, per server.

You can switch modes anytime and it takes effect right away.

### Worth knowing
Because of the per-user volume fix above, any per-user volumes you had saved are cleared once on this update and start fresh at 50% — those old values were exactly the cross-server data being cleaned up. You'll just need to re-set the few users you care about.

## Install

If you have beta updates enabled, tt-Accessible will install this update for you — no action needed.

Manual install:

1. Download `ttaccessible-1.7.0-beta.9-40.zip` below.
2. Unzip and drag `ttaccessible.app` into your `/Applications` folder, replacing the previous version.
3. Double-click — no Gatekeeper warning thanks to notarization.
