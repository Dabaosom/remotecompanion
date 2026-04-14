# RemoteCompanion

RemoteCompanion provides fast, scriptable system control for modern rootless jailbreaks. It lets you bind physical gestures and hardware buttons, or send commands remotely from your computer, to trigger system actions, control media playback, and run custom scripts.

> [!IMPORTANT]
> **What's New in v3.0**
> - **Automations API**: A new high-performance system for remote control via `/api/triggers` and `/api/commands`, returning clean JSON for easy third-party integration.
> - **Web UI**: Desktop-class automation hub with iOS aesthetics, featuring **live search-enabled pickers** for apps, WiFi, and Bluetooth devices, full workflow engineering, and **one-tap API URL copying**.
> - **Scheduled Triggers**: Run action sequences at specific times and days of the week.
> - **Notification Triggers**: Bind actions to incoming notifications from any app with precision title and message filtering and a searchable app picker.
> - **Flashlight Intensity Control**: The `rc flashlight` command now supports values from 1-100 for fine-tuned intensity of the device torch (e.g., `rc flashlight 50`).
> - **Web UI CLI Control**: Manage the Web UI server status remotely via the new `rc webui [on|off|status]` command.



<p align="center">
  <img src="images/1.1-2.3.0.png" width="160" alt="Main Interface" />
  <img src="images/2.1-2.3.0.png" width="160" alt="Action Picker" />
  <img src="images/3.1-2.3.0.png" width="160" alt="Trigger Config" />
  <img src="images/4.1-2.3.0.png" width="160" alt="Design Engine" />
  <img src="images/5.1-2.3.0.png" width="160" alt="Settings & Backup" />
</p>

## Features
- **Premium Web UI**: Desktop-class automation hub with iOS aesthetics, allowing full workflow engineering, remote testing, and **one-tap API URL copying**.
- **Automations API v2**: Structured JSON discovery enables seamless integration with Home Assistant, Node-RED, or custom scripts.

- **Hardware Triggers**: Bind actions to Power/Volume buttons, Home button, Touch ID (Tap/Hold), or the Ringer Switch.
- **Visual Excellence**: Modern iOS aesthetics with Large Titles, SF Symbols, and a professional dark terminal editor.
- **Universal Search**: Instantly find actions, shortcuts, and devices with integrated search bars in every picker.
- **Cross-Version Support**: Full compatibility for iOS 14 through iOS 16+, supporting both Rootless and Rootful environments.
- **Advanced Automation**: Full support for NFC tags, custom Lua scripts (with `objc_call` support), and native Siri integration.
- **iPad Experience**: Native landscape orientation and optimized layouts for iPad power users.
- **Live Discovery**: Discovery-based live lists for nearby AirPlay and Bluetooth hardware.
- **Trigger Favorites**: Mark any trigger as a favorite for instant access at the top of the picker.
- **True Multitasking**: Concurrent server handling powered by GCD—zero battery drain, zero blocking.

## Web UI & Automations Hub

RemoteCompanion v3.0 introduces a desktop-class Web UI designed to mirror the native iOS experience while providing the speed and convenience of a desktop environment.

- **Location**: Access it at `http://[DEVICE_IP]:8080` from any computer or tablet on your local network.
- **Enable**: Toggle **Web UI** in the RemoteCompanion Settings (Gear icon) or use the command `rc webui on`.

### Key Features
- **Visual Workflow Editor**: Build complex action sequences with an intuitive drag-and-drop interface.
- **Live Device Discovery**: Dynamically search and select installed Apps, nearby Bluetooth hardware, and Wi-Fi networks using integrated search bars.
- **One-Tap API Integration**: Every trigger has a dedicated **Copy API Link** button that provides a pre-formatted URL to fire that trigger from third-party tools like **Home Assistant**, **Node-RED**, or custom scripts.
- **Remote Testing**: Trigger actions and troubleshoot sequences directly from your browser with live execution buttons.
- **Configuration Management**: Import and export your entire trigger database for easy backups and migration between devices.

## What you can do

### Media & Volume
- `rc play` / `rc pause` / `rc playpause` / `rc next` / `rc prev`
- `rc volume 0-100` - Set volume level.
- `rc mute [on|off|toggle|status]` - Control media mute state.
- `rc anc [on|off|transparency]` - Control headphone ANC (requires Sonitus).

### Device Control
- `rc lock` / `rc lock toggle`
- `rc unlock <pin>` - Wakes and unlocks the device.
- `rc button [power|lock|home|volup|voldown|mute]` - Simulate physical buttons.
- `rc brightness 0-100` - Set screen brightness.
- `rc flashlight [on|off|toggle]` - Control the torch.
- `rc rotate [lock|unlock|toggle]` - Orientation lock control.
- `rc dnd [on|off|toggle]` - Toggle Do Not Disturb.
- `rc low power mode [on|off|toggle]` - Toggle battery saver.
- `rc airplane [on|off|toggle]` - Control Airplane Mode.
- `rc haptic` / `rc screenshot` - Haptic feedback / Screenshot (or activate Snapper 3).
- `rc control-center` - Opens the system Control Center.
- `rc switcher` - Opens/toggles the App Switcher.
- `rc vibration [silent-toggle|ring-toggle]` - System "Vibrate on Silent/Ring" settings.

### Apps & Shortcuts
- `rc open <alias|bundleID>` (e.g., `youtube`, `spotify`, `settings`, `messages`, `home`, `photos`, `camera`, `clock`, `maps`, `calendar`, `weather`, `notes`, `reminders`, `appstore`, `mail`, `music`, `phone`, `stocks`, `calculator`, `tv`, `wallet`, `facetime`, `files`).
- `rc kill <alias|bundleID>` - Force close an app.
- `rc shortcut -r "Name" [-p "Input"]` - Run any Shortcut (requires SpringCuts).
- `rc url "https://google.com"` - Open any link (with smart unlock).
- `rc spotify <playlist|album|artist> <id>` - Play specific Spotify content.
- `rc spotify play` - Resume Spotify playback.

### Connectivity
- `rc wifi [on|off|toggle]` / `rc bluetooth [on|off|toggle]`
- `rc bluetooth [connect|disconnect] <name>` - Manage paired devices.
- `rc airplay list` - See speakers and their UIDs.
- `rc airplay connect <UID|Name>` / `rc airplay disconnect`

<details>
<summary><h3>Hardware Triggers (Tweak App)</h3></summary>

Configure these in the `RemoteCompanion` app for custom action sequences. Tip: **Long-press** any trigger in the app to instantly test and run its assigned actions.

- **Hardware Buttons**:
  - **Power**: Double-tap, Long-press, **Triple/Quadruple click**, or **Power + Volume Up/Down** combos.
  - **Volume**: Long hold Up/Down (0.3s) or **Volume Up + Down** combo.
  - **Home**: Double-tap (Touch ID), Double, Triple, or Quadruple click.
- **Touch ID Sensor**: **Single Tap** and **Hold (Rest Finger)** triggers.
- **NFC Triggers**: Scan physical NFC tags to run actions on screen wake (Optional toggle in Settings).
- **Ringer Switch**: Mute, Unmute, or Toggle triggers.
- **Gestures**: 
  - **Status Bar**: Hold (Left/Center/Right) or Swipe Left/Right.
  - **Edge Gestures**: Vertical swipe on left/right edges.
- **Motion Gestures**:
  - **Shake**: Fire actions when the device is physically shaken.
- **System Events**:
  - **Scheduled**: Run actions at specific times (e.g., Daily at 4 PM).
  - **WiFi/Bluetooth**: Trigger actions on network or device connectivity.
  - **App Launch**: Fire actions when a specific app is opened.

</details>

### Text & Notifications
- `rc type "Text"` - Type text (supports symbols).
- `rc paste "Text"` - Paste into clipboard.
- `rc key <hex>` - Specific keyboard keys (e.g., `0x04` for 'A', `0x28` for Enter).
- `rc log` - View the RemoteCompanion server logs.

### Status & Queries
Get instant feedback from your device state.

- `rc volume` - Returns current volume %.
- `rc app` - Returns foreground app bundle ID.
- `rc is-locked` / `rc lock status` - Returns `locked` or `unlocked`.
- `rc player status` - Returns detailed playback state (`Playing`, `Paused`, `Stopped`, etc.).
- `rc mute status` - Returns current media mute state and level.
- `rc logs` - Stream live debug logs from the device (tail `/tmp/remotecommand.log`).
- `rc vibration [silent-status|ring-status]` - Check current system vibration state (CLI only).
- `rc orientation status` - Returns `PORTRAIT` or `LANDSCAPE`.
- `rc rotate status` - Returns orientation lock state.
- `rc dnd status` - Returns Do Not Disturb state.
- `rc lpm status` - Returns Low Power Mode state.
- `rc airplane status` - Returns Airplane Mode state.
- `rc wifi status` / `rc bt status` - Returns connectivity states.
- `rc flashlight status` - Returns torch state.

<details>
<summary><h3>Conditional Actions</h3></summary>

Combine status queries with actions for smart automation:

- **Orientation-Awareness**: `If Orientation is Landscape` -> `Flashlight Toggle`.
- **Bluetooth/Wi-Fi State**: `If Wi-Fi is OFF` -> `Wi-Fi ON`.

</details>

### System & Diagnostics
- `rc uicache` - Refresh the icon cache.
- `rc respring` - Restart SpringBoard.
- `rc ldrestart` - Soft-reboot the device.
- `rc userspace-reboot` - Restart userspace.
- `rc webui [on|off|status]` - Enable, disable, or check the status of the Web UI server.


<details>
<summary><h3>Lua Scripting & Objective-C Bridge</h3></summary>

RemoteCompanion introduces a powerful Lua bridge that allows you to execute arbitrary Lua scripts within the tweak's process. The exact same context is available whether you run a script file from the CLI or paste code into the "Lua Script" action in the app.

### How to Run
- **From CLI**: `rc lua /path/to/script.lua`
- **From UI**: Add Action → System → **Custom Lua Script**. Paste your code directly into the prompt.

### API Bindings

| Function | Description |
| :--- | :--- |
| `log(msg)` | Writes to the system log (syslog). |
| `delay(seconds)` | Pauses execution for `seconds`. |
| `haptic()` | Triggers a standard haptic feedback. |
| `openURL(url)` | Opens a URL scheme (e.g. `prefs:root=General`). |
| `dlopen(path)` | Loads a dynamic library. Returns `true` on success. |
| `objc_call(target, selector, args...)` | Calls an Objective-C method. `target` can be a class name string or an instance. |

### Examples

**Trigger Haptic and Log**
```lua
log("Starting haptic engine...")
haptic()
delay(0.2)
haptic()
log("Finished haptic feedback.")
```

**Call a Class Method (get a shared instance)**
```lua
-- objc_call(className, selector) returns an instance
local device = objc_call("UIDevice", "currentDevice")
if device then
    objc_call(device, "setBatteryMonitoringEnabled:", true)
    local level = objc_call(device, "batteryLevel")
    log("Battery: " .. tostring(level * 100) .. "%")
end
```

**Load a Private Framework or Dylib**
```lua
-- Load your dylib first, then call methods on it
local ok = dlopen("/path/to/yourlibrary.dylib")
if ok then
    -- Use a shared accessor if the class provides one
    local instance = objc_call("YourClass", "sharedInstance")
    if instance then
        objc_call(instance, "yourMethod")
    else
        -- Or allocate a new instance
        local obj = objc_call(objc_call("YourClass", "alloc"), "init")
        objc_call(obj, "yourMethod")
    end
end
```

> [!NOTE]
> `objc_call` works like standard Objective-C messaging — it does not scan memory for existing instances. To call an instance method, you first need to obtain the instance via a class-level accessor (e.g. `sharedInstance`, `currentDevice`) or by allocating a new one with `alloc`/`init`.

</details>

<details>
<summary><h3>Blacklist (App Exclusion)</h3></summary>

RemoteCompanion includes a blacklist system to prevent hardware triggers and gestures from firing while specific apps are in the foreground. This is useful for avoiding conflicts with apps that use the same buttons or gestures (e.g. games, camera apps).

### CLI Commands
Use the `rc blacklist` command to manage the list:

*   `rc blacklist list`: View currently blacklisted bundle IDs.
*   `rc blacklist add <bundleID>`: Add an app to the blacklist (e.g. `rc blacklist add com.apple.camera`).
*   `rc blacklist remove <bundleID>`: Remove an app from the blacklist.
*   `rc blacklist reset`: Reset the blacklist to the factory defaults.

</details>

## Getting Started

<details>
<summary><h3>1. Requirements</h3></summary>

- A **Jailbroken Device** (iOS 14+). Supports both Rootless (iOS 15+) and Rootful (iOS 14) environments.
- The `RemoteCompanion` tweak installed.

</details>

### 2. Installation Options

#### Option 1: Repository (Recommended)
Add `https://saihgupr.github.io/remotecompanion` to Sileo or Zebra

Add to Zebra -> zbra://sources/add/https://saihgupr.github.io/remotecompanion

Add to Sileo -> sileo://source/https://saihgupr.github.io/remotecompanion

#### Option 2: Manual Install
Download the `.deb` from [Releases](https://github.com/saihgupr/remotecompanion/releases).

#### Option 3: Build from Source
`cd Tweak && make package install`.

<details>
<summary><h3>3. Usage Options</h3></summary>

Choose the control method that best fits your needs:

#### Option 1: CLI (Easiest)
Control your iPhone from your computer terminal using the `rc` script. It uses SSH to securely tunnel commands into a local UNIX socket on the device.

1. Copy the script to your path:
   ```bash
   chmod +x rc
   sudo cp rc /usr/local/bin/rc
   ```
2. Set your iPhone's IP (add this to your `~/.zshrc`):
   ```bash
   export RC_IPHONE_IP=iphone.local
   ```
3. Run the command:
   ```bash
   rc play
   ```

#### Option 2: SSH Direct (Secure)
Control the device directly via SSH using the `rc` command installed on the iPhone.
This method works even if the external "TCP Server" is disabled in settings.

```bash
ssh mobile@iphone.local "rc lock"
ssh mobile@iphone.local "rc volume 50"
ssh mobile@iphone.local "rc respring"
```

<details>
<summary><h4>Option 3: Shortcuts (External Triggers)</h4></summary>

Control your device using iOS Shortcuts. There are two primary ways:

**A. Using Native SSH (Localhost)**
The most reliable method without extra tweaks. Requires **OpenSSH**.
1. Add the **Run script over SSH** action.
2. Configure host settings:
   - **Host**: `localhost`
   - **Port**: `22`
   - **User**: `mobile` (or `root`)
   - **Password**: Your SSH password (default is `alpine`)
3. Enter your command:
   ```bash
   rc flashlight toggle
   rc dnd on
   ```

**B. Using Powercuts (Shell)**
If you have **Powercuts** installed, you can run `rc` commands directly via shell.
1. Add the **Run shell command** action.
2. Enter your command:
   ```bash
   rc open Music
   rc volume 50
   ```

</details>

<details>
<summary><h4>Option 4: HTTP API (Network Triggers)</h4></summary>

Control your device from any network-connected hardware via simple HTTP calls.

1. Enable **Web UI** in the RemoteCompanion Settings (Gear icon).
2. Send commands using `GET` or `POST`:

**Using GET (easiest for browser/simple callers):**
```bash
http://[device_ip]:8080/api/command?cmd=play
http://[device_ip]:8080/api/command?cmd=flashlight%20toggle
```

**Using POST (Query Parameters):**
*Allows sending commands via POST without a request body.*
```bash
curl -X POST "http://[device_ip]:8080/api/command?cmd=lock%20toggle"
```

**Using POST (JSON):**
```bash
curl -X POST "http://[device_ip]:8080/api/command" \
     -H "Content-Type: application/json" \
     -d '{"command": "respring"}'
```

**Using POST (Raw Text):**
```bash
curl -X POST "http://[device_ip]:8080/api/command" -d "haptic"
```

> [!TIP]
> This API is cross-platform and requires no special tools on the caller device, making it ideal for IoT integrations.

#### Performance & Security (API vs SSH)
The RemoteCommand HTTP API is designed for speed and compatibility.

*   **⚡ Speed**: Using the HTTP API is significantly faster than SSH (~0.1s faster per command). This is because it skips the heavy SSH handshake, public key exchange, and encryption overhead.
*   **⚠️ Security**: Unlike SSH, the HTTP API is **NOT SECURE**. All data, including device passcodes, is sent in **plain-text** over your local network. 

> [!CAUTION]
> **Use at your own risk.** It is highly recommended to only enable the Web UI/API on a trusted, isolated IoT network. **Never** send your passcode via the API over an untrusted or public WiFi network.

</details>

<details>
<summary><h4>Remote Command API</h4></summary>

You can control your device by sending commands directly to the Remote Command API.

**1. Discover Available Commands:**
Get a list of all supported commands and their descriptions via the discovery endpoint:
```bash
http://[device_ip]:8080/api/commands
```

**2. Execute a Command:**
Send the command string via the `cmd` parameter. 

```bash
# Example: Unlock device (Warning: Passcode sent in plain-text!)
http://[device_ip]:8080/api/command?cmd=unlock%201234

# Example: Lock orientation
http://[device_ip]:8080/api/command?cmd=rotate%20lock
```

</details>

<details>
<summary><h4>Running Automations via API</h4></summary>

You can also fire any multi-action automation sequence you've built in the app directly via their dedicated URLs.

**1. Discover your Automations:**
Call the discovery endpoint to see all configured triggers and their direct execution URLs:
```bash
http://[device_ip]:8080/api/triggers
```
Example Output:
```json
{
  "ok": true,
  "triggers": [
    {
      "id": "trigger_1",
      "name": "Good Night",
      "url": "/api/trigger/trigger_1"
    },
    {
      "id": "app_launch_com.apple.Music",
      "name": "Launch Music",
      "url": "/api/trigger/app_launch_com.apple.Music"
    }
  ]
}
```

**2. Execute the Automation:**
Simply perform a GET or POST request to the `url` provided in the discovery response:
```bash
# Example for trigger_1
http://[device_ip]:8080/api/trigger/trigger_1
```

> [!TIP]
> **Pro Tip:** In the Web UI, you can swipe any trigger or open the action editor and tap the **Copy** icon to instantly get the full URL (including your device's IP) for that specific trigger.

</details>

<details>
<summary><h3>Home Assistant Setup</h3></summary>

The most reliable way to control your device from Home Assistant is via SSH.

```yaml
shell_command:
  iphone_remote: >
    ssh -o "StrictHostKeyChecking=no" mobile@YOUR_IPHONE_IP "rc {{ cmd }}"
```
Then call it with:

```yaml
service: shell_command.iphone_remote
data:
  cmd: 'play'
```

</details>

</details>

## Security

RemoteCompanion implements several measures to ensure your device remains secure:

- **Local Access**: Local apps and the `rc` CLI on the device communicate directly with the socket file, ensuring zero network exposure.

<details>
<summary><h2>Troubleshooting</h2></summary>

### Apple Pay Issues
If you experience the "Updating Cards" screen or other conflicts with Apple Pay when waking your device, you can disable the background NFC scanning feature.
1. Go to the **Settings** tab (gear icon).
2. Toggle off **NFC Scanning**.

This ensures the tweak does not attempt to access the NFC controller on wake, resolving conflicts with system services.

### iOS 14 arm64e (A12+) Compatibility
Due to Pointer Authentication Code (PAC) changes in modern toolchains, iOS 14 on **arm64e (A12 and newer)** devices is currently unsupported and may cause a Safe Mode loop.
- **Supported**: iOS 14 on A11 and below (iPhone 8/X and older, iPad Air 2, etc.)
- **Supported**: iOS 15+ on all devices.
- **Workaround**: If you are on iOS 14 with a newer device, you may need to compile the tweak using **Xcode 15.4** or earlier to ensure correct PAC signatures.

</details>


## Support & Feedback

If you encounter any issues or have feature requests, please [open an issue](https://github.com/saihgupr/remotecompanion/issues) on GitHub.

RemoteCompanion is open-source and free. If you find it useful, consider giving it a star ⭐ or making a [donation](https://ko-fi.com/saihgupr) to support development.