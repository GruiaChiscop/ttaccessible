## v1.7.0 (build 42) — 2026-07-08

This is the stable release that brings everything from the 1.7.0 beta line to everyone. If you were on 1.6.0, here is what has changed.

### Highlights
- **A brand-new per-user Channel Mixer.** Every person in your channel gets their own voice volume, media volume, left/right placement, mute, and solo — all reachable from the keyboard and VoiceOver.
- **Sign in with a BearWare account.** Use a free bearware.dk login to connect to servers that support it, without creating a separate account on each one.
- **A rebuilt, faster, steadier audio engine.** Connecting is near-instant again, switching headphones or speakers no longer freezes the sound, and crowded channels stay smooth.

### The Channel Mixer
- Each user in the channel has their own strip: **voice volume, media volume, stereo placement (pan), mute, and solo**.
- Drive it entirely from the keyboard while focused on a person: Up/Down for voice volume, Command+Up/Down for their media volume, Left/Right to move them in the stereo field, and V, P, M, S to hear or reset volume, pan, mute, and solo.
- **New: press Command+5 to jump straight to the mixer** — it joins the Command+1 to Command+4 area shortcuts as a fifth focus target. (Thanks to Matthew Whitaker for the suggestion.)
- Each person's settings are remembered and come back the next time they join.

### Audio
- **Switching your output device no longer freezes the sound.** Change headphones or speakers while connected and the audio simply follows.
- **Connecting is quick again.** On Macs with a lot of audio gear, opening a connection used to stall for around 13 seconds while every device was checked — that scan is gone, and it is now baked into every build for good.
- **Crowded and high-quality channels stay smooth.** Channels using larger audio packets could sound choppy for everyone; the playback path was reworked so it holds up under load.
- **Your chosen microphone and output are remembered reliably**, surviving unplugging, replugging, and restarts instead of quietly landing on the wrong device.
- **Standalone noise reduction.** A new Microphone processing setting (Preferences › Audio) lets you pick None, Noise reduction, or Echo cancellation with noise reduction — and it applies live, even mid-transmission.
- **You can now hear your own streamed media** when you play an audio or video file into a channel.
- **Per-user volumes are now kept per server**, so volumes set on one server no longer bleed into another. A new setting lets you choose whether these are remembered always, only for the session, or not at all.

### Accessibility
- The app is now named **tt-Accessible** so VoiceOver and speech synthesizers pronounce it correctly.
- **Press VoiceOver+Space to join** the selected server or channel.
- **Sliders and the microphone button now speak their values** as you change them — gain, output volume, and the various Preferences sliders.
- Preferences reads more cleanly in VoiceOver: no duplicate labels, each section is a proper heading, scroll areas are named, and Escape closes the window.

### Fixes
- **BearWare web login connects reliably** on servers that respond in slightly non-standard ways.
- **An empty nickname** now falls back to your default instead of failing to connect.
- The app **launches faster**.

### Install

tt-Accessible will install this update for you automatically. To install by hand:

1. Download `ttaccessible-1.7.0-42.zip` below.
2. Unzip and drag `ttaccessible.app` into your `/Applications` folder, replacing the previous version.
3. Double-click — no Gatekeeper warning thanks to notarization.

### Download
[ttaccessible-1.7.0-42.zip](https://github.com/math65/ttaccessible/releases/download/v1.7.0/ttaccessible-1.7.0-42.zip)
