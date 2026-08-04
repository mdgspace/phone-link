# Phone Link

Phone Link connects an Android phone to a desktop computer over the local network,
so the desktop can receive clipboard text, SMS, files, and notifications from the
phone. It's split into two independent apps that talk to each other over a small
JSON-over-TCP protocol, discovered via mDNS — there's no cloud server, no account,
and no internet connection required. Everything happens on your LAN.

```
mobile/flutter_ui/   Android client (Flutter) — connects out, sends data
desktop/             Desktop server (Qt 6 / QML / C++) — listens, receives data
```

## How it works

1. **Discovery.** The desktop advertises itself on the LAN via mDNS
   (`_phonelink._tcp`), with `id`, `proto`, and `plat` in its TXT record. The
   phone browses for that service type and lists whatever it finds.
2. **Connection.** The phone opens a plain TCP socket to the port advertised by
   mDNS (the desktop is always the server; the phone is always the client).
3. **Handshake.** Phone sends `hello`, desktop replies `hello_ack`.
4. **Pairing.** If the phone isn't already trusted, it sends a `pairing_request`
   containing a PIN it generated. The desktop shows that PIN in a dialog; once
   the user confirms, the desktop echoes it back as `pairing_pin`. The phone
   confirms the PIN matches and sends `pairing_accepted`; the desktop persists
   the device as trusted and replies with its own `pairing_accepted`.
5. **Steady state.** Clipboard pushes, SMS, file transfers, and notifications
   flow over the same socket as further JSON packets. A `heartbeat` /
   `heartbeat_ack` pair every 20s detects a dead connection.

Every message is a single JSON object followed by `\n` (newline-delimited
framing), shaped like:

```json
{ "type": "hello", "from": "device-id", "payload": { "device_name": "..." }, "timestamp": 1710000000 }
```

Note: the device id is carried in the top-level `from` field, not inside
`payload` — this tripped up an earlier version of the desktop code (see
[Known issues](#known-issues--things-worth-double-checking) below for what to
watch out for if you touch this code).

### Message types

| Purpose          | Type(s)                                                                  |
| ----------------- | -------------------------------------------------------------------------- |
| Handshake        | `hello`, `hello_ack`                                                      |
| Keepalive        | `heartbeat`, `heartbeat_ack`                                              |
| Pairing          | `pairing_request`, `pairing_pin`, `pairing_accepted`, `pairing_rejected`   |
| Disconnect       | `disconnect`                                                              |
| Clipboard        | `clipboard_push`                                                          |
| Messaging (SMS)  | `sms_list`, `sms_send`, `sms_received`                                    |
| File transfer    | `file_offer`, `file_accept`, `file_reject`, `file_chunk`, `file_done`      |
| Notifications    | `notification_posted`, `notification_dismissed`                          |

These strings must match exactly between `desktop/protocol/protocoltypes.h`
and `mobile/flutter_ui/lib/core/packet.dart` (`PacketType`). If you add a new
message type, add it in both places.

## Building the desktop app

Requires Qt **6.10.1** (Gui, Quick, DBus, Network) and CMake 3.16+.

```bash
cd desktop
mkdir build && cd build
cmake ..
cmake --build . -j$(nproc)
./app_phone_link
```

On Linux, mDNS uses Avahi (`libavahi-client`) — make sure `avahi-daemon` is
running, or discovery/advertising will silently do nothing.

Trusted devices are persisted via `QSettings` under the `PhoneLink` /
`PhoneLinkDesktop` org/app name (set in `main.cpp`), so pairing only needs to
happen once per phone.

## Building the Android app

Requires Flutter (stable channel).

```bash
cd mobile/flutter_ui
flutter pub get
flutter run            # or: flutter build apk
```

The desktop's port is never hardcoded on the phone — it always connects to
whatever port the discovered mDNS record advertises, so there's nothing to
configure by hand as long as both devices are on the same network and mDNS
traffic isn't blocked (some routers/VLANs block multicast — same network,
same subnet, is the safe bet).

## Current status

- **Desktop**: builds cleanly against Qt 6.10.1 and has been verified to
  compile and link end-to-end. Pairing, hello/heartbeat handshakes, file
  offer/accept/reject, disconnect handling, and a notification listener are
  all implemented server-side.
- **Mobile**: not verified against a real Flutter toolchain in this pass —
  reviewed manually (brace-balanced, payload keys cross-checked line-by-line
  against the desktop implementation) but not built. Run `flutter analyze`
  and a debug build before shipping.
- **Native desktop notifications** (showing an OS-level toast for
  `notification_posted`) are intentionally not implemented yet — see
  `tasks.md`. The desktop currently just parses and logs them.
- **Transport is plain TCP, not encrypted.** Fine on a trusted home LAN;
  don't rely on it over an untrusted network.

## Known issues / things worth double-checking

- The phone has a "Start advertising" option (`home.dart`) that lets it also
  register itself on `_phonelink._tcp`. Since only the desktop is meant to
  run a TCP server, this is likely either dead-end UI or the start of a
  future phone-hosts-server mode — worth a deliberate decision either way
  rather than leaving it live by accident.
- If you're extending the pairing flow: the PIN is generated by the **phone**
  (`PairingService.generatePin`) and sent in `pairing_request{pin}`. The
  desktop's job is only to display and echo it back — it should never
  generate its own PIN.
- Timestamps are **seconds** since Unix epoch on the wire (matches Flutter's
  `Packet` default), not milliseconds. Keep this in sync if you touch either
  side's timestamp handling.