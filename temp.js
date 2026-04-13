    const triggerNames = {
        "shake": "Shake Device",
        "volume_up_hold": "Volume Up Hold",
        "volume_down_hold": "Volume Down Hold",
        "volume_both_press": "Volume Up + Down (Both)",
        "power_double_tap": "Power Double-Tap",
        "power_long_press": "Power Long Press",
        "power_triple_click": "Power Triple Click",
        "power_quadruple_click": "Power Quadruple Click",
        "power_volume_up": "Power + Volume Up",
        "power_volume_down": "Power + Volume Down",
        "trigger_statusbar_left_hold": "Status Bar Left Hold",
        "trigger_statusbar_center_hold": "Status Bar Center Hold",
        "trigger_statusbar_right_hold": "Status Bar Right Hold",
        "trigger_statusbar_swipe_left": "Status Bar Swipe Left",
        "trigger_statusbar_swipe_right": "Status Bar Swipe Right",
        "trigger_home_triple_click": "Home Button (Triple)",
        "trigger_home_quadruple_click": "Home Button (Quad)",
        "trigger_home_double_click": "Home Button (Double)",
        "touchid_hold": "Touch ID Hold",
        "touchid_tap": "Touch ID Tap",
        "trigger_edge_left_swipe_up": "Left Edge Swipe Up",
        "trigger_edge_left_swipe_down": "Left Edge Swipe Down",
        "trigger_edge_right_swipe_up": "Right Edge Swipe Up",
        "trigger_edge_right_swipe_down": "Right Edge Swipe Down",
        "trigger_ringer_mute": "Ringer Muted",
        "trigger_ringer_unmute": "Ringer Unmuted",
        "trigger_ringer_toggle": "Ringer Toggled",
        "trigger_bottombar_swipe_left": "Bottom Bar Swipe Left",
        "trigger_bottombar_swipe_right": "Bottom Bar Swipe Right"
    };

    const actionCategories = [
        {
            title: "Media",
            items: [
                {"name": "Play", "command": "play"},
                {"name": "Pause", "command": "pause"},
                {"name": "Play/Pause Toggle", "command": "playpause"},
                {"name": "Next Track", "command": "next"},
                {"name": "Previous Track", "command": "prev"},
                {"name": "Volume Up", "command": "volume up"},
                {"name": "Volume Down", "command": "volume down"},
                {"name": "Set Volume...", "command": "__SET_VOLUME__"},
                {"name": "Set Brightness...", "command": "__SET_BRIGHTNESS__"}
            ]
        },
        {
            title: "Device Controls",
            items: [
                {"name": "Set Flashlight...", "command": "__SET_FLASHLIGHT__"},
                {"name": "Flashlight Toggle", "command": "flashlight toggle"},
                {"name": "Flashlight On", "command": "flashlight on"},
                {"name": "Flashlight Off", "command": "flashlight off"},
                {"name": "Rotate Lock", "command": "rotate lock"},
                {"name": "Rotate Unlock", "command": "rotate unlock"},
                {"name": "Rotate Toggle", "command": "rotate toggle"}
            ]
        },
        {
            title: "Connectivity",
            items: [
                {"name": "WiFi On", "command": "wifi on"},
                {"name": "WiFi Off", "command": "wifi off"},
                {"name": "WiFi Toggle", "command": "wifi toggle"},
                {"name": "Bluetooth On", "command": "bluetooth on"},
                {"name": "Bluetooth Off", "command": "bluetooth off"},
                {"name": "Bluetooth Toggle", "command": "bluetooth toggle"},
                {"name": "Airplane Mode On", "command": "airplane on"},
                {"name": "Airplane Mode Off", "command": "airplane off"},
                {"name": "Airplane Mode Toggle", "command": "airplane toggle"},
                {"name": "Connect Bluetooth...", "command": "__BT_CONNECT__"},
                {"name": "Disconnect Bluetooth...", "command": "__BT_DISCONNECT__"},
                {"name": "Connect AirPlay...", "command": "__AIRPLAY_CONNECT__"},
                {"name": "Disconnect AirPlay", "command": "airplay disconnect"}
            ]
        },
        {
            title: "System",
            items: [
                {"name": "Haptic Feedback", "command": "haptic"},
                {"name": "Screenshot", "command": "screenshot"},
                {"name": "Run Shortcut...", "command": "__SHORTCUT_PICKER__"},
                {"name": "Open App...", "command": "__OPEN_APP__"},
                {"name": "Lock Device", "command": "lock"},
                {"name": "Unlock Device", "command": "unlock"},
                {"name": "Do Not Disturb On", "command": "dnd on"},
                {"name": "Do Not Disturb Off", "command": "dnd off"},
                {"name": "Do Not Disturb Toggle", "command": "dnd toggle"},
                {"name": "Activate Siri", "command": "siri"},
                {"name": "Home Button", "command": "home"},
                {"name": "App Switcher", "command": "switcher"},
                {"name": "Open Control Center", "command": "open control center"},
                {"name": "Respring Device", "command": "respring"},
                {"name": "Soft Reboot (ldrestart)", "command": "ldrestart"},
                {"name": "Userspace Reboot", "command": "userspace-reboot"},
                {"name": "Refresh Icon Cache (uicache)", "command": "uicache"},
                {"name": "Lock Status", "command": "lock status"},
                {"name": "Orientation Status", "command": "orientation status"},
                {"name": "Silent Vibrate Toggle", "command": "vibration silent-toggle"},
                {"name": "Ring Vibrate Toggle", "command": "vibration ring-toggle"},
                {"name": "Low Power Mode On", "command": "low power on"},
                {"name": "Low Power Mode Off", "command": "low power off"},
                {"name": "Low Power Mode Toggle", "command": "low power toggle"}
            ]
        },
        {
            title: "Audio",
            items: [
                {"name": "ANC On", "command": "anc on"},
                {"name": "ANC Off", "command": "anc off"},
                {"name": "Transparency Mode", "command": "anc transparency"}
            ]
        },
        {
            title: "Scripting & Logic",
            items: [
                {"name": "Custom Lua Script", "command": "__LUA_SCRIPT__"},
                {"name": "If Condition...", "command": "__IF_CONDITION__"},
                {"name": "Delay", "command": "__DELAY__"},
                {"name": "Terminal Command", "command": "__CUSTOM__"}
            ]
        }
    ];

    let config = {};
    let currentTriggerKey = null;
    let pendingCommand = null;

    async function loadConfig() {
      try {
        const res = await fetch('/api/config');
        config = await res.json();
        document.getElementById('loading').style.display = 'none';
        renderList();
      } catch (e) {
        document.getElementById('loading').innerText = 'Failed to load. Is the server running?';
      }
    }

    async function saveConfig() {
      try {
        await fetch('/api/config', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(config)
        });
        renderList();
      } catch (e) {
        alert('Failed to save config');
      }
    }

    function renderList() {
      const list = document.getElementById('triggers-list');
      list.innerHTML = '';
      if (!config.triggers) return;

      for (const [key, trigger] of Object.entries(config.triggers)) {
        const name = triggerNames[key] || key;
        const statusClass = trigger.enabled ? 'on' : 'off';
        const statusText = trigger.enabled ? 'Enabled' : 'Disabled';
        
        const item = document.createElement('a');
        item.className = 'item';
        item.onclick = () => openDetail(key);
        item.innerHTML = `
          <div class="item-title">${name}</div>
          <div class="item-after"><span class="badge ${statusClass}">${statusText}</span> ›</div>
        `;
        list.appendChild(item);
      }
    }

    function openDetail(key) {
      currentTriggerKey = key;
      const trigger = config.triggers[key];
      document.getElementById('detail-title').innerText = triggerNames[key] || key;
      document.getElementById('trigger-enabled').checked = !!trigger.enabled;
      
      renderActions();
      
      document.getElementById('view-list').style.display = 'none';
      document.getElementById('view-picker').style.display = 'none';
      document.getElementById('view-detail').style.display = 'block';
    }

    function showList() {
      currentTriggerKey = null;
      document.getElementById('view-detail').style.display = 'none';
      document.getElementById('view-picker').style.display = 'none';
      document.getElementById('view-list').style.display = 'block';
    }

    function formatActionName(cmd) {
        if (typeof cmd !== 'string') return cmd.type || 'Unknown';
        
        if (cmd.startsWith("root ")) return "[root] " + cmd.substring(5);
        if (cmd.startsWith("exec-root ")) return "[root] " + cmd.substring(10);
        if (cmd.startsWith("exec ")) return cmd.substring(5);
        if (cmd.startsWith("delay ")) return "Delay " + cmd.substring(6) + "s";
        if (cmd.startsWith("bt connect ")) return "Connect " + cmd.substring(11);
        if (cmd.startsWith("bt disconnect ")) return "Disconnect " + cmd.substring(14);
        if (cmd.startsWith("set-vol ")) return "Set Volume " + cmd.substring(8);
        if (cmd.startsWith("brightness ")) return "Set Brightness " + cmd.substring(11);
        if (cmd.startsWith("flashlight ") && !cmd.endsWith("on") && !cmd.endsWith("off") && !cmd.endsWith("toggle")) return "Flashlight " + cmd.substring(11) + "%";
        if (cmd.startsWith("flash ") && !cmd.endsWith("on") && !cmd.endsWith("off") && !cmd.endsWith("toggle")) return "Flashlight " + cmd.substring(6) + "%";
        if (cmd.startsWith("shortcut:")) return "Run " + cmd.substring(9);
        if (cmd.startsWith("uiopen ")) return "Open App: " + cmd.substring(7);
        
        for (const cat of actionCategories) {
            for (const item of cat.items) {
                if (item.command === cmd) return item.name;
            }
        }
        return cmd;
    }

    function renderActions() {
      const list = document.getElementById('actions-list');
      list.innerHTML = '';
      const trigger = config.triggers[currentTriggerKey];
      if (!trigger.actions || trigger.actions.length === 0) {
        list.innerHTML = '<div class="item" style="cursor:default"><span class="item-title" style="color:#8e8e93">No actions configured</span></div>';
        return;
      }
      
      trigger.actions.forEach((action, idx) => {
        const actionName = formatActionName(action);
        const item = document.createElement('div');
        item.className = 'item';
        item.style.cursor = 'default';
        item.innerHTML = `
          <div>
              <div class="item-title">${actionName}</div>
              ${typeof action === 'string' && action !== actionName ? `<div class="item-subtitle">${action}</div>` : ''}
          </div>
          <div class="item-after"><a href="#" style="color:var(--danger);text-decoration:none;font-weight:600;" onclick="removeAction(${idx})">Remove</a></div>
        `;
        list.appendChild(item);
      });
    }

    function toggleEnabled() {
      config.triggers[currentTriggerKey].enabled = document.getElementById('trigger-enabled').checked;
      saveConfig();
    }

    function removeAction(idx) {
      if (confirm('Remove this action?')) {
        config.triggers[currentTriggerKey].actions.splice(idx, 1);
        saveConfig();
        renderActions();
      }
    }

    // Action Picker Logic
    function openPicker() {
      document.getElementById('view-detail').style.display = 'none';
      document.getElementById('view-picker').style.display = 'block';
      
      const container = document.getElementById('picker-container');
      if (container.innerHTML !== '') return; // Already rendered
      
      let html = '';
      actionCategories.forEach(cat => {
          html += `<div class="section-title">${cat.title}</div>`;
          html += `<div class="list">`;
          cat.items.forEach(item => {
              html += `
                <div class="item" onclick="selectAction('${item.command}')">
                    <span class="item-title" style="color:var(--primary)">${item.name}</span>
                </div>
              `;
          });
          html += `</div>`;
      });
      container.innerHTML = html;
    }

    function closePicker() {
      document.getElementById('view-picker').style.display = 'none';
      document.getElementById('view-detail').style.display = 'block';
    }

    function selectAction(cmd) {
        pendingCommand = cmd;
        if (cmd === '__SET_VOLUME__' || cmd === '__SET_BRIGHTNESS__' || cmd === '__SET_FLASHLIGHT__') {
            document.getElementById('modal-title').innerText = cmd === '__SET_VOLUME__' ? 'Set Volume' : (cmd === '__SET_BRIGHTNESS__' ? 'Set Brightness' : 'Set Flashlight');
            document.getElementById('modal-input').value = '';
            document.getElementById('modal-input').placeholder = 'Enter value (0-100)';
            document.getElementById('value-modal').style.display = 'block';
        } else if (cmd === '__SHORTCUT_PICKER__') {
            document.getElementById('modal-title').innerText = 'Run Shortcut';
            document.getElementById('modal-input').value = '';
            document.getElementById('modal-input').placeholder = 'Exact shortcut name';
            document.getElementById('value-modal').style.display = 'block';
        } else if (cmd === '__BT_CONNECT__' || cmd === '__BT_DISCONNECT__') {
            document.getElementById('modal-title').innerText = 'Bluetooth Device';
            document.getElementById('modal-input').value = '';
            document.getElementById('modal-input').placeholder = 'Device MAC or Name';
            document.getElementById('value-modal').style.display = 'block';
        } else if (cmd === '__OPEN_APP__') {
            document.getElementById('modal-title').innerText = 'Open App';
            document.getElementById('modal-input').value = '';
            document.getElementById('modal-input').placeholder = 'App Bundle ID (e.g. com.apple.mobilesafari)';
            document.getElementById('value-modal').style.display = 'block';
        } else if (cmd === '__DELAY__') {
            document.getElementById('modal-title').innerText = 'Delay (Seconds)';
            document.getElementById('modal-input').value = '';
            document.getElementById('modal-input').placeholder = 'e.g. 5';
            document.getElementById('value-modal').style.display = 'block';
        } else if (cmd === '__CUSTOM__') {
            document.getElementById('modal-title').innerText = 'Terminal Command';
            document.getElementById('modal-input').value = '';
            document.getElementById('modal-input').placeholder = 'e.g. killall SpringBoard';
            document.getElementById('value-modal').style.display = 'block';
        } else if (cmd === '__LUA_SCRIPT__' || cmd === '__IF_CONDITION__') {
            alert('This complex action must be configured from the iOS app.');
            closePicker();
        } else if (cmd === '__AIRPLAY_CONNECT__') {
             document.getElementById('modal-title').innerText = 'AirPlay Connect';
            document.getElementById('modal-input').value = '';
            document.getElementById('modal-input').placeholder = 'AirPlay Device Name';
            document.getElementById('value-modal').style.display = 'block';
        } else {
            addAction(cmd);
            closePicker();
        }
    }

    function closeModal() {
        document.getElementById('value-modal').style.display = 'none';
        pendingCommand = null;
    }

    function submitModal() {
        const val = document.getElementById('modal-input').value.trim();
        if (!val) { closeModal(); return; }
        
        let finalCmd = pendingCommand;
        if (pendingCommand === '__SET_VOLUME__') finalCmd = `set-vol ${val}`;
        else if (pendingCommand === '__SET_BRIGHTNESS__') finalCmd = `brightness ${val}`;
        else if (pendingCommand === '__SET_FLASHLIGHT__') finalCmd = `flashlight ${val}`;
        else if (pendingCommand === '__SHORTCUT_PICKER__') finalCmd = `shortcut:${val}`;
        else if (pendingCommand === '__BT_CONNECT__') finalCmd = `bt connect ${val}`;
        else if (pendingCommand === '__BT_DISCONNECT__') finalCmd = `bt disconnect ${val}`;
        else if (pendingCommand === '__OPEN_APP__') finalCmd = `uiopen ${val}`;
        else if (pendingCommand === '__DELAY__') finalCmd = `delay ${val}`;
        else if (pendingCommand === '__CUSTOM__') finalCmd = `exec ${val}`;
        else if (pendingCommand === '__AIRPLAY_CONNECT__') finalCmd = `airplay connect ${val}`;
        
        addAction(finalCmd);
        closeModal();
        closePicker();
    }

    function addAction(cmd) {
        if (!config.triggers[currentTriggerKey].actions) {
            config.triggers[currentTriggerKey].actions = [];
        }
        config.triggers[currentTriggerKey].actions.push(cmd);
        saveConfig();
        renderActions();
    }

    async function executeTrigger() {
      try {
        await fetch('/api/trigger/' + currentTriggerKey, { method: 'POST' });
      } catch (e) {
        alert('Failed to execute trigger');
      }
    }

    loadConfig();
