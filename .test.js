'use strict';

// ── State ────────────────────────────────────────────────────────────────────
let config = { masterEnabled: true, nfcEnabled: true, webUIEnabled: false, triggers: {}, favoriteTriggers: [] };
let hasLoadedData = false;
let currentKey = null;
let dialogCallback = null;
let editMode = false;
let cachedApps = [];

// ── Scroll-linked small title ─────────────────────────────────────────────────
window.addEventListener('scroll', () => {
  const title = document.getElementById('main-large-title');
  if (!title) return;
  const rect = title.getBoundingClientRect();
  const navbarHeight = document.getElementById('main-navbar').offsetHeight;
  const small = document.getElementById('navbar-small-title');
  if (rect.bottom <= navbarHeight) {
    small.classList.add('visible');
  } else {
    small.classList.remove('visible');
  }
}, { passive: true });

// ── Edit mode ────────────────────────────────────────────────────────────────
function toggleEditMode() {
  editMode = !editMode;
  document.getElementById('edit-btn').textContent = editMode ? 'Done' : 'Edit';
  renderAll();
}

// ── Trigger metadata ──────────────────────────────────────────────────────────
const TRIGGER_SECTIONS = [
  { title: 'Favorites',              id: 'favorites', keys: [] },
  { title: 'Volume Buttons',         id: 'volume',    keys: ['volume_up_hold','volume_down_hold','volume_both_press'] },
  { title: 'Power Button',           id: 'power',     keys: ['power_double_tap','power_triple_click','power_quadruple_click','power_volume_up','power_volume_down','power_long_press'] },
  { title: 'Screen Gestures',        id: 'statusbar', keys: ['trigger_statusbar_left_hold','trigger_statusbar_center_hold','trigger_statusbar_right_hold','trigger_statusbar_swipe_left','trigger_statusbar_swipe_right'] },
  { title: 'Edge Gestures',          id: 'edge',      keys: ['trigger_edge_left_swipe_up','trigger_edge_left_swipe_down','trigger_edge_right_swipe_up','trigger_edge_right_swipe_down'] },
  { title: 'Bottom Bar Gestures',    id: 'bottombar', keys: ['trigger_bottombar_swipe_left','trigger_bottombar_swipe_right'] },
  { title: 'Home Button',            id: 'home',      keys: ['trigger_home_double_click','trigger_home_triple_click','trigger_home_quadruple_click','touchid_tap','touchid_hold'] },
  { title: 'Ringer Switch',          id: 'ringer',    keys: ['trigger_ringer_mute','trigger_ringer_unmute','trigger_ringer_toggle'] },
  { title: 'Motion Gestures',        id: 'motion',    keys: ['shake'] },
  { title: 'NFC Tags',               id: 'nfc',       keys: [], dynamic: true, prefix: 'nfc_',        deletable: true },
  { title: 'WiFi Network Triggers',  id: 'wifi',      keys: [], dynamic: true, prefix: 'wifi_',       deletable: true },
  { title: 'Bluetooth Device Triggers', id: 'bt',     keys: [], dynamic: true, prefix: 'bt_',         deletable: true },
  { title: 'Notification Triggers',  id: 'notif',     keys: [], dynamic: true, prefix: 'notif_',      deletable: true },
  { title: 'App Launch Triggers',    id: 'app',       keys: [], dynamic: true, prefix: 'app_launch_', deletable: true },
  { title: 'Scheduled Triggers',     id: 'sched',     keys: [], dynamic: true, prefix: 'sched_',      deletable: true },
];

const TRIGGER_NAMES = {
  shake:'Shake Device',
  volume_up_hold:'Volume Up Hold', volume_down_hold:'Volume Down Hold', volume_both_press:'Volume Up + Down (Both)',
  power_double_tap:'Power Double-Tap', power_long_press:'Power Long Press',
  power_triple_click:'Power Triple Click', power_quadruple_click:'Power Quadruple Click',
  power_volume_up:'Power + Volume Up', power_volume_down:'Power + Volume Down',
  trigger_statusbar_left_hold:'Status Bar Left Hold', trigger_statusbar_center_hold:'Status Bar Center Hold',
  trigger_statusbar_right_hold:'Status Bar Right Hold', trigger_statusbar_swipe_left:'Status Bar Swipe Left',
  trigger_statusbar_swipe_right:'Status Bar Swipe Right',
  trigger_home_double_click:'Home (Double Click)', trigger_home_triple_click:'Home (Triple Click)',
  trigger_home_quadruple_click:'Home (Quadruple Click)',
  touchid_tap:'Touch ID Tap', touchid_hold:'Touch ID Hold (Rest Finger)',
  trigger_edge_left_swipe_up:'Left Edge Swipe Up', trigger_edge_left_swipe_down:'Left Edge Swipe Down',
  trigger_edge_right_swipe_up:'Right Edge Swipe Up', trigger_edge_right_swipe_down:'Right Edge Swipe Down',
  trigger_ringer_mute:'Ringer Muted', trigger_ringer_unmute:'Ringer Unmuted', trigger_ringer_toggle:'Ringer Toggled',
  trigger_bottombar_swipe_left:'Bottom Bar Swipe Left', trigger_bottombar_swipe_right:'Bottom Bar Swipe Right',
};

const TRIGGER_ICONS = {
  shake:              { icon:'waveform_path_ecg',        cls:'icon-purple' },
  volume_up_hold:     { icon:'speaker_3_fill',           cls:'icon-blue' },
  volume_down_hold:   { icon:'speaker_1_fill',           cls:'icon-blue' },
  volume_both_press:  { icon:'speaker_3_fill',           cls:'icon-indigo' },
  power_double_tap:   { icon:'bolt_fill',                cls:'icon-orange' },
  power_long_press:   { icon:'power',                    cls:'icon-red' },
  power_triple_click: { icon:'power',                    cls:'icon-red' },
  power_quadruple_click:{ icon:'power',                  cls:'icon-red' },
  power_volume_up:    { icon:'plus_circle_fill',         cls:'icon-indigo' },
  power_volume_down:  { icon:'minus_circle_fill',        cls:'icon-indigo' },
  trigger_statusbar_left_hold:   { icon:'hand_draw',     cls:'icon-gray' },
  trigger_statusbar_center_hold: { icon:'hand_draw',     cls:'icon-gray' },
  trigger_statusbar_right_hold:  { icon:'hand_draw',     cls:'icon-gray' },
  trigger_statusbar_swipe_left:  { icon:'arrow_left_to_line', cls:'icon-gray' },
  trigger_statusbar_swipe_right: { icon:'arrow_right_to_line',cls:'icon-gray' },
  trigger_home_double_click:   { icon:'house_fill',      cls:'icon-blue' },
  trigger_home_triple_click:   { icon:'house_fill',      cls:'icon-blue' },
  trigger_home_quadruple_click:{ icon:'house_fill',      cls:'icon-blue' },
  touchid_tap:  { icon:'viewfinder',                     cls:'icon-pink' },
  touchid_hold: { icon:'viewfinder',                     cls:'icon-pink' },
  trigger_edge_left_swipe_up:   { icon:'arrow_up_to_line',   cls:'icon-gray' },
  trigger_edge_left_swipe_down: { icon:'arrow_down_to_line', cls:'icon-gray' },
  trigger_edge_right_swipe_up:  { icon:'arrow_up_to_line',   cls:'icon-gray' },
  trigger_edge_right_swipe_down:{ icon:'arrow_down_to_line', cls:'icon-gray' },
  trigger_bottombar_swipe_left: { icon:'square_stack_3d_up_fill', cls:'icon-gray' },
  trigger_bottombar_swipe_right:{ icon:'square_stack_3d_up_fill', cls:'icon-gray' },
  trigger_ringer_mute:   { icon:'bell_slash_fill', cls:'icon-red' },
  trigger_ringer_unmute: { icon:'bell_fill',       cls:'icon-green' },
  trigger_ringer_toggle: { icon:'bell_badge_fill', cls:'icon-orange' },
};

function iconForKey(key) {
  if (TRIGGER_ICONS[key]) return TRIGGER_ICONS[key];
  if (key.startsWith('nfc_'))        return { icon:'antenna_radiowaves_left_right', cls:'icon-cyan' };
  if (key.startsWith('wifi_connect_')) return { icon:'wifi', cls:'icon-green' };
  if (key.startsWith('wifi_disconnect_')) return { icon:'wifi_slash', cls:'icon-orange' };
  if (key.startsWith('wifi_'))       return { icon:'wifi',                          cls:'icon-blue' };
  if (key.startsWith('bt_connect_')) return { icon:'bolt_horizontal_fill', cls:'icon-green' };
  if (key.startsWith('bt_disconnect_')) return { icon:'bolt_horizontal', cls:'icon-orange' };
  if (key.startsWith('bt_'))         return { icon:'bolt_horizontal_fill',          cls:'icon-indigo' };
  if (key.startsWith('app_launch_')) return { icon:'app_badge_fill',                cls:'icon-pink' };
  if (key.startsWith('notif_'))      return { icon:'bell_circle_fill',              cls:'icon-red' };
  if (key.startsWith('sched_'))      return { icon:'clock_fill',                    cls:'icon-orange' };
  return { icon:'hand_tap', cls:'icon-gray' };
}

function nameForKey(key) {
  if (TRIGGER_NAMES[key]) return TRIGGER_NAMES[key];
  const t = config.triggers[key];
  if (t && t.name) return t.name;
  if (key.startsWith('nfc_'))        return `NFC: ${key.slice(4)}`;
  if (key.startsWith('wifi_connect_')) return `WiFi Connect: ${key.slice(13)}`;
  if (key.startsWith('wifi_disconnect_')) return `WiFi Disconnect: ${key.slice(16)}`;
  if (key.startsWith('wifi_'))       return `WiFi: ${key.slice(5)}`;
  if (key.startsWith('bt_connect_')) return `BT Connect: ${key.slice(11)}`;
  if (key.startsWith('bt_disconnect_')) return `BT Disconnect: ${key.slice(14)}`;
  if (key.startsWith('bt_'))         return `BT: ${key.slice(3)}`;
  if (key.startsWith('app_launch_')) return `Launch: ${key.slice(11)}`;
  if (key.startsWith('notif_'))      return `Notif: ${key.slice(6)}`;
  if (key.startsWith('sched_'))      return `Sched: ${key.slice(6)}`;
  return key;
}

const CMD_NAMES = {
  'play':'Play','pause':'Pause','playpause':'Play/Pause','next':'Next Track','prev':'Previous Track',
  'volume up':'Volume Up','volume down':'Volume Down',
  'flashlight':'Flashlight Toggle','flashlight on':'Flashlight On','flashlight off':'Flashlight Off','flashlight toggle':'Flashlight Toggle',
  'rotate lock':'Rotate Lock','rotate unlock':'Rotate Unlock','rotate toggle':'Rotate Toggle',
  'wifi on':'WiFi On','wifi off':'WiFi Off','wifi toggle':'WiFi Toggle',
  'bluetooth on':'Bluetooth On','bluetooth off':'Bluetooth Off','bluetooth toggle':'Bluetooth Toggle',
  'airplane on':'Airplane On','airplane off':'Airplane Off','airplane toggle':'Airplane Toggle',
  'haptic':'Haptic Feedback','screenshot':'Screenshot',
  'lock':'Lock Device','unlock':'Unlock Device',
  'dnd on':'Do Not Disturb On','dnd off':'Do Not Disturb Off','dnd toggle':'Do Not Disturb Toggle',
  'respring':'Respring','siri':'Activate Siri','home':'Home Button','switcher':'App Switcher',
  'open control center':'Control Center',
  'ldrestart':'Soft Reboot','userspace-reboot':'Userspace Reboot','uicache':'Refresh Icon Cache',
  'low power on':'Low Power On','low power off':'Low Power Off','low power toggle':'Low Power Toggle',
  'anc on':'Noise Cancellation On','anc off':'Noise Cancellation Off','anc transparency':'Transparency Mode',
  'airplay disconnect':'Disconnect AirPlay',
  'vibration silent-toggle':'Silent Vibrate Toggle','vibration ring-toggle':'Ring Vibrate Toggle',
  'mute toggle':'Mute Toggle',
  'haptic':'Haptic Feedback',
  'trigger_bottombar_swipe_left':'Bottom Bar Swipe Left',
  'trigger_bottombar_swipe_right':'Bottom Bar Swipe Right',
};

function nameForCmd(cmd) {
  if (!cmd) return 'Unknown';
  if (typeof cmd === 'object') {
    const t = (cmd.type||'').toLowerCase();
    if (t === 'if') return `If ${cmd.conditionTitle||'Condition'} is ${cmd.expectedTitle||'Value'}`;
    if (t === 'else') return 'Else';
    if (t === 'end_if' || t === 'end') return 'End If';
    if (t === 'repeat') return `Repeat ${cmd.count||''}`;
    return 'Block';
  }
  const lowCmd = cmd.toLowerCase();
  if (CMD_NAMES[lowCmd]) return CMD_NAMES[lowCmd];
  if (lowCmd.startsWith('flashlight ')) return `Flashlight ${cmd.slice(11)}%`;
  if (lowCmd.startsWith('lua:'))          return `Lua: ${cmd.slice(4)}`;
  if (lowCmd.startsWith('delay '))        return `Delay ${cmd.slice(6)}s`;
  if (lowCmd.startsWith('exec '))         return `Terminal: ${cmd.slice(5)}`;
  if (lowCmd.startsWith('root '))         return `[root] ${cmd.slice(5)}`;
  if (lowCmd.startsWith('bt connect '))   return `Connect ${cmd.slice(11)}`;
  if (lowCmd.startsWith('bt disconnect ')) return `Disconnect ${cmd.slice(14)}`;
  if (lowCmd.startsWith('airplay connect ')) return `AirPlay Connect ${cmd.slice(16)}`;
  if (lowCmd.startsWith('set-vol '))      return `Set Volume ${cmd.slice(8)}%`;
  if (lowCmd.startsWith('brightness '))   return `Set Brightness ${cmd.slice(11)}%`;
  if (lowCmd.startsWith('shortcut:'))     return `Shortcut: ${cmd.slice(9)}`;
  if (lowCmd.startsWith('uiopen '))       return `Open: ${cmd.slice(7)}`;
  // Touch gesture display names
  if (lowCmd.startsWith('tap '))   { const p=cmd.slice(4).trim().split(/\s+/); return `Tap (${p[0]||'?'}, ${p[1]||'?'})`; }
  if (lowCmd.startsWith('hold '))  { const p=cmd.slice(5).trim().split(/\s+/); return `Hold (${p[0]||'?'}, ${p[1]||'?'})${p[2]?` ${p[2]}ms`:''}`; }
  if (lowCmd.startsWith('swipe ')) { const p=cmd.slice(6).trim().split(/\s+/); return `Swipe (${p[0]||'?'},${p[1]||'?'})→(${p[2]||'?'},${p[3]||'?'})`; }
  if (lowCmd === 'swipeu' || lowCmd === 'swipeup')   return 'Swipe Up';
  if (lowCmd === 'swiped' || lowCmd === 'swipedown') return 'Swipe Down';
  if (lowCmd === 'swipel' || lowCmd === 'swipeleft') return 'Swipe Left';
  if (lowCmd === 'swiper' || lowCmd === 'swiperight') return 'Swipe Right';
  // Fallback: capitalize first letter
  return cmd.charAt(0).toUpperCase() + cmd.slice(1);
}

function iconForCmd(cmd) {
  if (!cmd) return { icon:'questionmark', cls:'icon-gray' };
  if (typeof cmd === 'object') {
    const t = (cmd.type||'').toLowerCase();
    if (t === 'if' || t === 'else') return { icon:'arrow_triangle_branch', cls:'icon-purple' };
    if (t === 'end_if' || t === 'end') return { icon:'arrow_turn_up_left', cls:'icon-purple' };
    return { icon:'repeat', cls:'icon-green' };
  }
  const map = {
    'play':'play_fill','pause':'pause_fill','playpause':'playpause_fill',
    'next':'forward_fill','prev':'backward_fill',
    'volume up':'speaker_3_fill','volume down':'speaker_1_fill',
    'flashlight':'bolt_fill','flashlight on':'bolt_fill','flashlight off':'bolt_slash_fill','flashlight toggle':'bolt_fill',
    'wifi on':'wifi','wifi off':'wifi_slash','wifi toggle':'wifi',
    'bluetooth on':'bolt_horizontal_fill','bluetooth off':'bolt_horizontal','bluetooth toggle':'bolt_horizontal_fill',
    'airplane on':'airplane','airplane off':'airplane','airplane toggle':'airplane',
    'lock':'lock_fill','unlock':'lock_open_fill',
    'dnd on':'moon_fill','dnd off':'moon','dnd toggle':'moon_circle_fill',
    'respring':'arrow_2_circlepath','siri':'mic_fill','home':'house_fill',
    'open control center':'gear',
    'low power on':'battery_25','low power off':'battery_100',
    'screenshot':'camera_fill','haptic':'hand_raised_fill',
  };
  const lowCmd = cmd.toLowerCase();
  if (map[lowCmd]) return { icon:map[lowCmd], cls:'icon-dark' };
  if (lowCmd.startsWith('flashlight ')) return { icon:'bolt_fill',       cls:'icon-orange' };
  if (lowCmd.startsWith('lua:'))          return { icon:'command',         cls:'icon-purple' };
  if (lowCmd.startsWith('delay '))        return { icon:'timer',           cls:'icon-orange' };
  if (lowCmd.startsWith('bt connect '))   return { icon:'link',            cls:'icon-indigo' };
  if (lowCmd.startsWith('airplay connect ')) return { icon:'airplayvideo',     cls:'icon-blue' };
  if (lowCmd.startsWith('set-vol '))      return { icon:'speaker_3_fill',  cls:'icon-blue' };
  if (lowCmd.startsWith('brightness '))   return { icon:'sun_max_fill',    cls:'icon-yellow' };
  if (lowCmd.startsWith('shortcut:'))     return { icon:'command',         cls:'icon-indigo' };
  if (lowCmd.startsWith('uiopen '))       return { icon:'app_badge_fill',  cls:'icon-pink' };
  if (lowCmd.startsWith('exec ') || lowCmd.startsWith('root ')) return { icon:'command', cls:'icon-dark' };
  if (lowCmd.startsWith('trigger_bottombar')) return { icon:'square_stack_3d_up_fill', cls:'icon-gray' };
  // Touch gestures
  if (lowCmd.startsWith('tap '))   return { icon:'hand_tap',         cls:'icon-teal' };
  if (lowCmd.startsWith('hold '))  return { icon:'hand_tap_fill',    cls:'icon-teal' };
  if (lowCmd.startsWith('swipe')) return { icon:'hand_draw',         cls:'icon-teal' };
  return { icon:'bolt_fill', cls:'icon-dark' };
}

// ── Action picker data ────────────────────────────────────────────────────────
const ACTION_SECTIONS = [
  { title:'Media', actions:[
    { name:'Play',              cmd:'play',         icon:'play_fill' },
    { name:'Pause',             cmd:'pause',        icon:'pause_fill' },
    { name:'Play/Pause',        cmd:'playpause',    icon:'playpause_fill' },
    { name:'Next Track',        cmd:'next',         icon:'forward_fill' },
    { name:'Previous Track',    cmd:'prev',         icon:'backward_fill' },
    { name:'Volume Up',         cmd:'volume up',    icon:'speaker_3_fill' },
    { name:'Volume Down',       cmd:'volume down',  icon:'speaker_1_fill' },
    { name:'Set Volume…',       cmd:'__SET_VOLUME__',icon:'speaker_3_fill', needs_input:true },
    { name:'Set Brightness…',   cmd:'__SET_BRIGHTNESS__',icon:'sun_max_fill', needs_input:true },
  ]},
  { title:'Device Controls', actions:[
    { name:'Flashlight Toggle', cmd:'flashlight toggle', icon:'bolt_fill' },
    { name:'Flashlight On',     cmd:'flashlight on',     icon:'bolt_fill' },
    { name:'Flashlight Off',    cmd:'flashlight off',    icon:'bolt_slash_fill' },
    { name:'Flashlight Intensity…', cmd:'__SET_FLASHLIGHT__', icon:'bolt_fill', needs_input:true },
    { name:'Rotate Lock',       cmd:'rotate lock',       icon:'lock_rotation' },
    { name:'Rotate Unlock',     cmd:'rotate unlock',     icon:'lock_rotation_open' },
    { name:'Rotate Toggle',     cmd:'rotate toggle',     icon:'lock_rotation' },
  ]},
  { title:'Connectivity', actions:[
    { name:'WiFi On',           cmd:'wifi on',      icon:'wifi' },
    { name:'WiFi Off',          cmd:'wifi off',     icon:'wifi_slash' },
    { name:'WiFi Toggle',       cmd:'wifi toggle',  icon:'wifi' },
    { name:'Bluetooth On',      cmd:'bluetooth on', icon:'bolt_horizontal_fill' },
    { name:'Bluetooth Off',     cmd:'bluetooth off',icon:'bolt_horizontal' },
    { name:'Bluetooth Toggle',  cmd:'bluetooth toggle',icon:'bolt_horizontal_fill' },
    { name:'Airplane Mode On',  cmd:'airplane on',  icon:'airplane' },
    { name:'Airplane Mode Off', cmd:'airplane off', icon:'airplane' },
    { name:'Airplane Toggle',   cmd:'airplane toggle',icon:'airplane' },
    { name:'Connect Bluetooth…',cmd:'__BT_CONNECT__',icon:'link', needs_input:true },
    { name:'Disconnect Bluetooth…',cmd:'__BT_DISCONNECT__',icon:'xmark_circle', needs_input:true },
    { name:'Connect AirPlay…',   cmd:'__AIRPLAY_CONNECT__',icon:'airplayaudio', needs_input:true },
    { name:'Disconnect AirPlay',cmd:'airplay disconnect',icon:'airplayaudio' },
  ]},
  { title:'System', actions:[
    { name:'Haptic Feedback',   cmd:'haptic',        icon:'hand_raised_fill' },
    { name:'Screenshot',        cmd:'screenshot',    icon:'camera_fill' },
    { name:'Run Shortcut…',     cmd:'__SHORTCUT__',  icon:'command', needs_input:true },
    { name:'Open App…',         cmd:'__OPEN_APP__',  icon:'square_grid_2x2_fill', needs_input:true },
    { name:'Lock Device',       cmd:'lock',          icon:'lock_fill' },
    { name:'Unlock Device',     cmd:'unlock',        icon:'lock_open_fill' },
    { name:'Do Not Disturb On', cmd:'dnd on',        icon:'moon_fill' },
    { name:'Do Not Disturb Off',cmd:'dnd off',       icon:'moon' },
    { name:'DND Toggle',        cmd:'dnd toggle',    icon:'moon_circle_fill' },
    { name:'Activate Siri',     cmd:'siri',          icon:'mic_fill' },
    { name:'Home Button',       cmd:'home',          icon:'house_fill' },
    { name:'App Switcher',      cmd:'switcher',      icon:'square_stack_3d_up_fill' },
    { name:'Control Center',    cmd:'open control center',icon:'gear' },
    { name:'Respring',          cmd:'respring',      icon:'arrow_2_circlepath' },
    { name:'Soft Reboot',       cmd:'ldrestart',     icon:'arrow_clockwise' },
    { name:'Low Power On',      cmd:'low power on',  icon:'battery_25' },
    { name:'Low Power Off',     cmd:'low power off', icon:'battery_100' },
    { name:'Low Power Toggle',  cmd:'low power toggle',icon:'battery_25' },
  ]},
  { title:'Touch Gestures', actions:[
    { name:'Tap…',              cmd:'__TAP__',       icon:'hand_tap', needs_input:true },
    { name:'Hold…',             cmd:'__HOLD__',      icon:'hand_tap_fill', needs_input:true },
    { name:'Swipe Up',          cmd:'swipeU',        icon:'arrow_up' },
    { name:'Swipe Down',        cmd:'swipeD',        icon:'arrow_down' },
    { name:'Swipe Left',        cmd:'swipeL',        icon:'arrow_left' },
    { name:'Swipe Right',       cmd:'swipeR',        icon:'arrow_right' },
    { name:'Custom Swipe…',     cmd:'__SWIPE__',     icon:'hand_draw', needs_input:true },
  ]},
  { title:'Scripting & Logic', actions:[
    { name:'If Condition…',     cmd:'__IF_CONDITION__',icon:'arrow_triangle_branch', needs_input:true },
    { name:'Delay…',            cmd:'__DELAY__',     icon:'timer', needs_input:true },
    { name:'Terminal Command…', cmd:'__CUSTOM__',    icon:'command', needs_input:true },
    { name:'Lua Script…',       cmd:'__LUA_SCRIPT__',icon:'command', needs_input:true },
    { name:'Set Volume…',       cmd:'__SET_VOLUME__',icon:'speaker_3_fill', needs_input:true },
  ]},
];

const CONDITION_DEFS = [
  { key:'lock',       title:'Lock Status',  values:[{value:'LOCKED',title:'Locked'},{value:'UNLOCKED',title:'Unlocked'}] },
  { key:'player',     title:'Player',       values:[{value:'PLAYING',title:'Playing'},{value:'PAUSED',title:'Paused'},{value:'STOPPED',title:'Stopped'}] },
  { key:'wifi',       title:'Wi-Fi',        values:[{value:'ON',title:'On'},{value:'OFF',title:'Off'}] },
  { key:'bluetooth',  title:'Bluetooth',    values:[{value:'ON',title:'On'},{value:'OFF',title:'Off'}] },
  { key:'airplane',   title:'Airplane Mode',values:[{value:'ON',title:'On'},{value:'OFF',title:'Off'}] },
  { key:'orientation',title:'Orientation',  values:[{value:'PORTRAIT',title:'Portrait'},{value:'LANDSCAPE',title:'Landscape'}] },
  { key:'frontApp',   title:'Front App is', values:null, freeText:true },
];

// ── API ───────────────────────────────────────────────────────────────────────
async function loadData() {
  try {
    const res = await fetch('/api/config');
    if (!res.ok) throw new Error();
    config = await res.json();
    if (!config.triggers) config.triggers = {};
    if (!config.favoriteTriggers) config.favoriteTriggers = [];
    document.getElementById('conn-banner').classList.remove('visible');
    hasLoadedData = true;
    renderAll();
  } catch(e) {
    document.getElementById('conn-banner').classList.add('visible');
  }
}

async function saveConfig() {
  if (!hasLoadedData) {
    console.warn("Attempted to save setting before configuration was loaded from server. Ignoring to prevent wipe.");
    showToast('⚠ Cannot save while offline');
    return;
  }
  try {
    const res = await fetch('/api/config', {
      method: 'POST',
      body: JSON.stringify(config),
      headers: { 'Content-Type': 'application/json' }
    });
    if (!res.ok) {
        showToast('⚠ Failed to save settings');
    }
  } catch(e) {
    showToast('⚠ Offline - unable to save');
  }
}

// ── Context Menu System ──────────────────────────────────────────────────────
function showContextMenu(e, items) {
  e.preventDefault();
  const menu = document.getElementById('context-menu');
  menu.innerHTML = '';
  
  items.forEach(item => {
    if (!item) return;
    const el = document.createElement('div');
    el.className = 'context-menu-item' + (item.destructive ? ' destructive' : '');
    el.innerHTML = `
      <span class="item-label">${item.label}</span>
      <i class="f7-icons">${item.icon}</i>
    `;
    el.addEventListener('click', (ev) => {
      ev.stopPropagation();
      hideContextMenu();
      item.action();
    });
    menu.appendChild(el);
  });

  menu.classList.add('show');
  
  // Position it
  let x = e.clientX;
  let y = e.clientY;
  
  // Collision detection
  const menuWidth = menu.offsetWidth || 220;
  const menuHeight = menu.offsetHeight || items.length * 44;
  if (x + menuWidth > window.innerWidth) x = window.innerWidth - menuWidth - 10;
  if (y + menuHeight > window.innerHeight) y = window.innerHeight - menuHeight - 10;
  
  menu.style.left = `${x}px`;
  menu.style.top = `${y}px`;
  menu.style.transformOrigin = (e.clientX > x) ? 'top right' : 'top left';
}

function hideContextMenu() {
  const menu = document.getElementById('context-menu');
  menu.classList.remove('show');
}

// Global dismissals for context menu
document.addEventListener('mousedown', (e) => {
  if (!document.getElementById('context-menu').contains(e.target)) hideContextMenu();
});
window.addEventListener('scroll', hideContextMenu, { passive: true });
document.addEventListener('wheel', hideContextMenu, { passive: true });

function triggerData(key) {
  if (!config.triggers[key]) config.triggers[key] = { enabled: false, actions: [] };
  return config.triggers[key];
}

// ── Render main list ──────────────────────────────────────────────────────────
function renderAll() {
  const root = document.getElementById('triggers-root');
  root.innerHTML = '';

  const allKeys = Object.keys(config.triggers);
  TRIGGER_SECTIONS.forEach(sec => {
    if (sec.dynamic) sec.keys = allKeys.filter(k => k.startsWith(sec.prefix));
    if (sec.id === 'favorites') sec.keys = (config.favoriteTriggers || []).filter(k => config.triggers[k]);
  });

  TRIGGER_SECTIONS.forEach(sec => {
    const favs = config.favoriteTriggers || [];
    let keys = sec.keys;
    if (sec.id !== 'favorites') keys = keys.filter(k => !favs.includes(k));
    if (sec.dynamic && keys.length === 0) return;
    if (sec.id === 'favorites' && keys.length === 0) return;

    // Section header
    const hdr = document.createElement('div');
    hdr.className = 'section-header' + (sec.id === 'favorites' ? ' favorites' : '');
    hdr.textContent = sec.title.toUpperCase();
    root.appendChild(hdr);

    // Card
    const card = document.createElement('div');
    card.className = 'list-card';
    keys.forEach(key => card.appendChild(renderTriggerRow(key, !!sec.deletable)));
    root.appendChild(card);
  });
}

// ── Trigger row (custom swipe — no Framework7 dependency) ─────────────────────
let _openRow = null; // currently open swipeout row

function closeOpenRow() {
  if (!_openRow) return;
  const inner = _openRow.querySelector('.trigger-row-inner');
  if (inner) inner.style.transform = '';
  _openRow.classList.remove('swiped-open');
  _openRow = null;
}

function renderTriggerRow(key, deletable) {
  const data = triggerData(key);
  const { icon, cls } = iconForKey(key);
  const name = nameForKey(key);
  const isFav = (config.favoriteTriggers || []).includes(key);
  const actions = data.actions || [];
  const subtitle = actions.length > 0
    ? actions.map(a => nameForCmd(a)).join(' › ')
    : 'Not configured';

  const row = document.createElement('div');
  row.className = 'trigger-row';
  row.dataset.key = key;

  // ── Swipe actions (Star, Play, [Delete]) ──
  const actionsEl = document.createElement('div');
  actionsEl.className = 'trigger-row-actions';

  const favBtn = document.createElement('div');
  favBtn.className = isFav ? 'swipe-action sa-unfav' : 'swipe-action sa-fav';
  favBtn.innerHTML = `<i class="f7-icons">${isFav ? 'star_slash_fill' : 'star_fill'}</i>`;
  favBtn.addEventListener('click', e => { e.stopPropagation(); toggleFavorite(key); closeOpenRow(); });

  const playBtn = document.createElement('div');
  playBtn.className = 'swipe-action sa-play';
  playBtn.innerHTML = `<i class="f7-icons">play_fill</i>`;
  playBtn.addEventListener('click', e => { e.stopPropagation(); runTrigger(key); closeOpenRow(); });

  const copyBtn = document.createElement('div');
  copyBtn.className = 'swipe-action sa-copy';
  copyBtn.innerHTML = `<i class="f7-icons">doc_on_doc</i>`;
  copyBtn.addEventListener('click', e => { e.stopPropagation(); copyTriggerUrl(key, copyBtn); closeOpenRow(); });

  actionsEl.appendChild(favBtn);
  actionsEl.appendChild(copyBtn);
  actionsEl.appendChild(playBtn);

  if (deletable) {
    const delBtn = document.createElement('div');
    delBtn.className = 'swipe-action sa-del';
    delBtn.innerHTML = `<i class="f7-icons">trash_fill</i>`;
    delBtn.addEventListener('click', e => { e.stopPropagation(); closeOpenRow(); deleteTrigger(key); });
    actionsEl.appendChild(delBtn);
  }

  row.appendChild(actionsEl);

  // ── Row content (slides left on swipe) ──
  const inner = document.createElement('div');
  inner.className = 'trigger-row-inner';
  inner.innerHTML = `
    <div class="row-icon ${cls}"><i class="f7-icons">${icon}</i></div>
    <div class="row-text">
      <div class="row-title">
        <span>${escHtml(name)}</span>
      </div>
      <div class="row-subtitle">${escHtml(subtitle)}</div>
    </div>
    <i class="f7-icons row-chevron">chevron_right</i>
  `;
  row.appendChild(inner);

  // ── Unified swipe handling (touch + mouse) ──
  let startX = 0, startY = 0, dx = 0, isSwipe = false, didMove = false, isTracking = false;
  let lastSwipeAt = 0;
  const ACTION_WIDTH = (deletable ? 4 : 3) * 60; // total px of actions (Fav, Copy, Play, [Del])

  function swipeStart(clientX, clientY) {
    if (_openRow && _openRow !== row) closeOpenRow();
    startX = clientX; startY = clientY;
    dx = 0; isSwipe = false; didMove = false; isTracking = true;
    
    // Add window moves for better tracking once started
    window.addEventListener('mousemove', onMouseMove);
    window.addEventListener('mouseup', onMouseUp);
  }

  function onMouseMove(e) { swipeMove(e.clientX, e.clientY, null); }
  function onMouseUp()    { swipeEnd(); window.removeEventListener('mousemove', onMouseMove); window.removeEventListener('mouseup', onMouseUp); }

  function swipeMove(clientX, clientY, preventDefaultFn) {
    if (!isTracking) return;
    dx = clientX - startX;
    const dy = clientY - startY;
    if (!didMove && Math.abs(dy) > Math.abs(dx)) { isTracking = false; return; }
    didMove = true;
    if (!isSwipe && Math.abs(dx) > 5) isSwipe = true;
    if (!isSwipe) return;
    if (preventDefaultFn) preventDefaultFn();
    const isOpen = row.classList.contains('swiped-open');
    let offset = isOpen ? -ACTION_WIDTH + dx : dx;
    offset = Math.max(-ACTION_WIDTH, Math.min(0, offset));
    inner.style.transition = 'none';
    inner.style.transform = `translateX(${offset}px)`;
    // Proportionally show action buttons
    const ratio = Math.min(1, Math.abs(offset) / ACTION_WIDTH);
    actionsEl.querySelectorAll('.swipe-action').forEach(el => {
      el.style.transition = 'none';
      el.style.width = `${ratio * (ACTION_WIDTH / actionsEl.children.length)}px`;
    });
  }

  function swipeEnd() {
    if (!isTracking) return;
    isTracking = false;
    inner.style.transition = '';

    if (!isSwipe) {
      inner.style.transform = row.classList.contains('swiped-open') ? `translateX(-${ACTION_WIDTH}px)` : '';
      return;
    }

    lastSwipeAt = Date.now();
    const isOpen = row.classList.contains('swiped-open');
    const threshold = 40; // Reduced from 35% to 40px for better feel
    
    if (!isOpen && dx < -threshold) {
      // Snap open
      row.classList.add('swiped-open');
      inner.style.transform = `translateX(-${ACTION_WIDTH}px)`;
      _openRow = row;
    } else if (isOpen && dx > 20) {
      // Swipe right to close
      row.classList.remove('swiped-open');
      inner.style.transform = '';
      if (_openRow === row) _openRow = null;
    } else {
      // Snap back to current state
      inner.style.transform = isOpen ? `translateX(-${ACTION_WIDTH}px)` : '';
    }

    // Clear inline widths AFTER class changes to allow CSS transitions to take over smoothly
    setTimeout(() => {
      actionsEl.querySelectorAll('.swipe-action').forEach(el => {
        el.style.transition = '';
        el.style.width = '';
      });
    }, 0);
  }

  // Touch events
  inner.addEventListener('touchstart', e => swipeStart(e.touches[0].clientX, e.touches[0].clientY), { passive: true });
  inner.addEventListener('touchmove',  e => swipeMove(e.touches[0].clientX, e.touches[0].clientY, () => e.preventDefault()), { passive: false });
  inner.addEventListener('touchend',   () => swipeEnd());

  // Mouse events (desktop testing)
  inner.addEventListener('mousedown', e => swipeStart(e.clientX, e.clientY));

  // ── Context menu (Right-click) ──
  inner.addEventListener('contextmenu', e => {
    const items = [
      { label: 'Run Trigger', icon: 'play_fill', action: () => runTrigger(key) },
      { label: 'Copy API Link', icon: 'doc_on_doc', action: () => copyTriggerUrl(key, null) },
      { label: isFav ? 'Unfavorite' : 'Favorite', icon: isFav ? 'star_slash_fill' : 'star_fill', action: () => toggleFavorite(key) }
    ];
    if (deletable) {
      items.push({ label: 'Delete', icon: 'trash_fill', action: () => deleteTrigger(key), destructive: true });
    }
    showContextMenu(e, items);
  });

  // ── Click handler with suppression ──
  inner.addEventListener('click', e => {
    // If we just finished a swipe drag, ignore the following click event
    if (Date.now() - lastSwipeAt < 150) return;
    
    if (row.classList.contains('swiped-open')) {
      closeOpenRow();
      return;
    }
    openActionsPanel(key);
  });

  // Close swipe if tapping elsewhere
  document.addEventListener('touchstart', e => {
    if (_openRow === row && !row.contains(e.target)) closeOpenRow();
  }, { passive: true });
  document.addEventListener('mousedown', e => {
    if (_openRow === row && !row.contains(e.target)) closeOpenRow();
  });

  return row;
}

function escHtml(s) {
  if (!s) return '';
  return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
}

// ── Action management ─────────────────────────────────────────────────────────
function toggleFavorite(key) {
  const favs = config.favoriteTriggers || [];
  const idx = favs.indexOf(key);
  if (idx > -1) favs.splice(idx, 1); else favs.push(key);
  config.favoriteTriggers = favs;
  saveConfig(); renderAll();
}

function deleteTrigger(key) {
  showSheet('Delete Trigger', [
    { label: `Delete "${nameForKey(key)}"`, destructive: true, action() {
      delete config.triggers[key];
      config.favoriteTriggers = (config.favoriteTriggers||[]).filter(k => k !== key);
      // Also remove from notificationTriggers array if applicable
      if (key.startsWith('notif_') && config.notificationTriggers) {
        config.notificationTriggers = config.notificationTriggers.filter(t => t.triggerKey !== key);
      }
      saveConfig(); renderAll();
    }}
  ]);
}

async function runTrigger(key) {
  try {
    const res = await fetch(`/api/trigger/${encodeURIComponent(key)}`, { method: 'POST' });
    if (res.status === 403) {
      showToast('⚠ Enable Web UI in Settings first');
    } else {
      showToast(res.ok ? '▶ Triggered' : '⚠ Server Error');
    }
  } catch(e) { showToast('⚠ Could not connect to device'); }
}

async function runSingleAction(action) {
  if (typeof action !== 'string') return;
  try {
    const res = await fetch(`/api/command?cmd=${encodeURIComponent(action)}`, { method: 'POST' });
    if (res.status === 403) {
      showToast('⚠ Enable Web UI in Settings first');
    } else {
      showToast(res.ok ? '▶ Action Sent' : '⚠ Server Error');
    }
  } catch(e) { showToast('⚠ Could not connect to device'); }
}

function copyTriggerUrl(key, btnEl) {
  const url = `${window.location.protocol}//${window.location.host}/api/trigger/${encodeURIComponent(key)}`;
  
  const performCopy = (text) => {
    // navigator.clipboard is preferred but requires secure context
    if (navigator.clipboard && window.isSecureContext) {
      return navigator.clipboard.writeText(text);
    } else {
      // Robust fallback
      const el = document.createElement('textarea');
      el.value = text;
      el.setAttribute('readonly', '');
      el.style.position = 'absolute';
      el.style.left = '-9999px';
      document.body.appendChild(el);
      const selected =
        document.getSelection().rangeCount > 0
          ? document.getSelection().getRangeAt(0)
          : false;
      el.select();
      document.execCommand('copy');
      document.body.removeChild(el);
      if (selected) {
        document.getSelection().removeAllRanges();
        document.getSelection().addRange(selected);
      }
      return Promise.resolve();
    }
  };

  performCopy(url).then(() => {
    showToast('✓ URL Copied');
    if (btnEl) {
      const icon = btnEl.querySelector('i');
      if (icon) {
        const originalIcon = icon.innerText;
        icon.innerText = 'checkmark';
        btnEl.style.color = '#34c759';
        setTimeout(() => {
          icon.innerText = originalIcon;
          btnEl.style.color = '';
        }, 1500);
      }
    }
  }).catch(err => {
    console.error('Copy failed:', err);
    showToast('⚠ Copy Failed');
  });
}

// ── Actions panel ─────────────────────────────────────────────────────────────
let editingTriggerKey = null;

function openActionsPanel(key) {
  currentKey = key;
  editingTriggerKey = null; // reset
  const data = triggerData(key);
  const name = nameForKey(key);
  document.getElementById('actions-panel-title').textContent = name;
  document.getElementById('actions-large-title').textContent = name;
  document.getElementById('trigger-enabled-toggle').checked = !!data.enabled;
  
  // Show/Hide edit settings button based on trigger type
  const editBtn = document.getElementById('edit-trigger-nav-btn');
  const isSched = key.startsWith('sched_');
  const isNotif = key.startsWith('notif_');
  const isWiFi = key.startsWith('wifi_');
  const isBT = key.startsWith('bt_');
  const isApp = key.startsWith('app_launch_');
  
  if (isSched || isNotif || isWiFi || isBT || isApp) {
    editBtn.style.display = 'flex';
  } else {
    editBtn.style.display = 'none';
  }

  renderActionList();
  document.getElementById('actions-panel').classList.add('active');
}

function onEditTriggerSettings() {
  if (!currentKey) return;
  const isSched = currentKey.startsWith('sched_');
  const isNotif = currentKey.startsWith('notif_');
  const isWiFi = currentKey.startsWith('wifi_');
  const isBT = currentKey.startsWith('bt_');
  
  if (isSched) promptSchedTrigger(currentKey);
  else if (isNotif) promptNotifTrigger(currentKey);
  else if (isWiFi) promptComplexTrigger('wifi', currentKey);
  else if (isBT) promptComplexTrigger('bt', currentKey);
  else if (isApp) promptAppEdit(currentKey);
}
function promptAppEdit(key) {
  const data = config.triggers[key];
  if (!data) return;
  const bid = key.replace('app_launch_', '');
  showDialog('Edit App Trigger', `Bundle ID: ${bid}\n\nDisplay Name:`, data.name, 'Save', val => {
    if (!val) return;
    data.name = val;
    saveConfig(); renderAll();
    openActionsPanel(key);
  });
}

function closeActionsPanel() {
  document.getElementById('actions-panel').classList.remove('active');
  setTimeout(renderAll, 350);
}

function onTriggerEnabledChange() {
  triggerData(currentKey).enabled = document.getElementById('trigger-enabled-toggle').checked;
  saveConfig();
}

function playCurrentTrigger() {
  if (currentKey) runTrigger(currentKey);
}

function copyCurrentTriggerUrl(btn) {
  if (currentKey) copyTriggerUrl(currentKey, btn);
}

// ── renderActionList ─────────────────────────────────────────────────────────
let _openActionRow = null;

function closeOpenActionRow() {
  if (!_openActionRow) return;
  const inner = _openActionRow.querySelector('.action-seq-inner');
  if (inner) inner.style.transform = '';
  _openActionRow.classList.remove('del-open');
  _openActionRow = null;
}

function renderActionList() {
  const card = document.getElementById('action-list-card');
  card.innerHTML = '';
  const actions = triggerData(currentKey).actions || [];

  if (actions.length === 0) {
    card.innerHTML = `<div style="padding:20px 16px;color:#636366;font-size:15px;font-style:italic">No actions — tap "+ Add Action" below</div>`;
    return;
  }

  let indent = 0;
  actions.forEach((action, idx) => {
    const isCtrl = typeof action === 'object';
    const type   = isCtrl ? (action.type||'').toLowerCase() : null;
    const isEnd  = type === 'end_if' || type === 'end';
    const isElse = type === 'else';
    const isIf   = type === 'if';
    const rowIndent = (isEnd || isElse) ? Math.max(0, indent - 1) : indent;
    const { icon, cls } = iconForCmd(action);

    // Outer wrapper
    const row = document.createElement('div');
    row.className = 'action-seq-row';

    // Delete button (behind the row)
    const delBtn = document.createElement('div');
    delBtn.className = 'action-del-btn';
    delBtn.innerHTML = `<i class="f7-icons">trash_fill</i>`;
    delBtn.addEventListener('click', e => { e.stopPropagation(); removeAction(idx); });
    row.appendChild(delBtn);

    // Sliding inner content
    const inner = document.createElement('div');
    inner.className = 'action-seq-inner';
    inner.style.paddingLeft = `${16 + rowIndent * 20}px`;
    inner.innerHTML = `
      <div class="action-row-icon ${cls}" style="width:24px;height:24px;border-radius:6px;margin-right:14px;flex-shrink:0">
        <i class="f7-icons" style="font-size:13px">${icon}</i>
      </div>
      <div style="flex:1;min-width:0;font-size:16px;color:#fff;white-space:nowrap;overflow:hidden;text-overflow:ellipsis">${escHtml(nameForCmd(action))}</div>
      <i class="f7-icons drag-handle" style="color:#3a3a3c;font-size:18px;flex-shrink:0;margin-left:8px;cursor:grab;">bars</i>
    `;
    row.appendChild(inner);

    // ── Unified swipe (touch + mouse) ────────────────────
    let startX, startY, dx, startedSwipe, currentlyTracking = false;
    let lastSwipeAt = 0;

    function onStart(clientX, clientY) {
      if (_openActionRow && _openActionRow !== row) closeOpenActionRow();
      startX = clientX; startY = clientY; dx = 0;
      startedSwipe = false; currentlyTracking = true;
    }
    function onMove(clientX, clientY, preventDefault) {
      if (!currentlyTracking) return;
      dx = clientX - startX;
      const dy = clientY - startY;
      if (!startedSwipe) {
        if (Math.abs(dy) > Math.abs(dx)) { currentlyTracking = false; return; }
        if (Math.abs(dx) > 5) startedSwipe = true;
      }
      if (!startedSwipe) return;
      if (preventDefault) preventDefault();
      const isOpen = row.classList.contains('del-open');
      let offset = isOpen ? -75 + dx : dx;
      offset = Math.max(-75, Math.min(0, offset));
      inner.style.transition = 'none';
      inner.style.transform = `translateX(${offset}px)`;
    }
    function onEnd() {
      if (!startedSwipe) { currentlyTracking = false; return; }
      lastSwipeAt = Date.now();
      inner.style.transition = ''; // Restore transition
      const isOpen = row.classList.contains('del-open');
      
      // Determine final state based on move distance
      if (!isOpen && dx < -20) {
        row.classList.add('del-open');
        inner.style.transform = 'translateX(-75px)';
        _openActionRow = row;
      } else if (isOpen && dx > 10) {
        row.classList.remove('del-open');
        inner.style.transform = 'translateX(0)';
        _openActionRow = null;
      } else {
        // Snap back to current state
        inner.style.transform = isOpen ? 'translateX(-75px)' : 'translateX(0)';
      }
      currentlyTracking = false;
    }

    // Touch
    inner.addEventListener('touchstart', e => onStart(e.touches[0].clientX, e.touches[0].clientY), { passive: true });
    inner.addEventListener('touchmove',  e => onMove(e.touches[0].clientX, e.touches[0].clientY, () => e.preventDefault()), { passive: false });
    inner.addEventListener('touchend',   () => onEnd());

    // Mouse (for desktop browser testing)
    const onMouseMove = e => { if (currentlyTracking) onMove(e.clientX, e.clientY, null); };
    const onMouseUp = () => {
      if (currentlyTracking) onEnd();
      window.removeEventListener('mousemove', onMouseMove);
      window.removeEventListener('mouseup', onMouseUp);
    };

    inner.addEventListener('mousedown', e => {
      onStart(e.clientX, e.clientY);
      window.addEventListener('mousemove', onMouseMove);
      window.addEventListener('mouseup', onMouseUp);
    });

    // ── Context menu (Right-click) ──
    inner.addEventListener('contextmenu', e => {
      const items = [];
      if (typeof action === 'string') {
        items.push({ label: 'Run Action', icon: 'play_fill', action: () => runSingleAction(action) });
      }
      items.push({ label: 'Delete Action', icon: 'trash_fill', action: () => removeAction(idx), destructive: true });
      showContextMenu(e, items);
    });

    // Click handler with suppression
    inner.addEventListener('click', e => {
      if (Date.now() - lastSwipeAt < 150) return;
      if (row.classList.contains('del-open')) { closeOpenActionRow(); e.stopPropagation(); }
    });

    card.appendChild(row);

    if (isIf || isElse) indent++;
    if (isEnd || isElse) indent = Math.max(0, indent - 1);
  });

  if (window._actionSortable) {
    window._actionSortable.destroy();
  }
  window._actionSortable = new Sortable(card, {
    handle: '.drag-handle',
    animation: 200,
    onEnd: function (evt) {
      if (evt.oldIndex === evt.newIndex) return;
      const arr = triggerData(currentKey).actions;
      const movedItem = arr.splice(evt.oldIndex, 1)[0];
      arr.splice(evt.newIndex, 0, movedItem);
      saveConfig();
      renderActionList();
    }
  });
}

function removeAction(idx) {
  const arr = triggerData(currentKey).actions;
  arr.splice(idx, 1);
  saveConfig(); renderActionList();
}

// ── Action picker ─────────────────────────────────────────────────────────────
function showActionPickerPanel() {
  document.getElementById('action-search').value = '';
  renderPickerSections();
  document.getElementById('picker-panel').classList.add('active');
}

function closePickerPanel() {
  document.getElementById('picker-panel').classList.remove('active');
}

function renderPickerSections() {
  const q = (document.getElementById('action-search').value || '').toLowerCase().trim();
  const content = document.getElementById('picker-content');
  content.innerHTML = '';

  let sections = ACTION_SECTIONS;
  if (q) {
    const all = ACTION_SECTIONS.flatMap(s => s.actions);
    const filtered = all.filter(a => a.name.toLowerCase().includes(q) || a.cmd.toLowerCase().includes(q));
    sections = [{ title:'Results', actions: filtered }];
  }

  sections.forEach(sec => {
    if (!sec.actions.length) return;
    const hdr = document.createElement('div');
    hdr.className = 'picker-section-header';
    hdr.textContent = sec.title.toUpperCase();
    content.appendChild(hdr);

    const card = document.createElement('div');
    card.className = 'action-list-card';
    sec.actions.forEach(a => {
      const row = document.createElement('div');
      row.className = 'picker-row';
      row.innerHTML = `
        <div class="picker-row-icon icon-dark"><i class="f7-icons">${a.icon}</i></div>
        <div class="picker-row-text">${escHtml(a.name)}</div>
        ${a.needs_input ? `<i class="f7-icons picker-row-chevron">chevron_right</i>` : ''}
      `;
      // Use the encoded JSON string safely
      row.addEventListener('click', () => selectAction(a));
      card.appendChild(row);
    });
    content.appendChild(card);
  });

  if (q && (!sections[0] || !sections[0].actions.length)) {
    content.innerHTML = `<div style="text-align:center;color:#636366;padding:40px">No results for "${escHtml(q)}"</div>`;
  }
}

async function selectAction(action) {
  const cmd = action.cmd;

  const needsText = {
    '__DELAY__':          { title:'Add Delay',        msg:'Seconds:', def:'1', type:'number', build: v => `delay ${v}` },
    '__SET_VOLUME__':     { title:'Set Volume',        msg:'Value (0-100):', def:'50', type:'number', build: v => `set-vol ${Math.max(0,Math.min(100,+v||50))}` },
    '__SET_BRIGHTNESS__': { title:'Set Brightness',    msg:'Value (0-100):', def:'50', type:'number', build: v => `brightness ${Math.max(0,Math.min(100,+v||50))}` },
    '__SET_FLASHLIGHT__': { title:'Flashlight %',      msg:'Value (0-100):', def:'50', type:'number', build: v => `flashlight ${Math.max(0,Math.min(100,+v||50))}` },
    '__BT_CONNECT__':     { title:'Connect BT Device', msg:'Device name:',   def:'',  type:'text',   build: v => `bt connect ${v}` },
    '__BT_DISCONNECT__':  { title:'Disconnect BT',     msg:'Device name:',   def:'',  type:'text',   build: v => `bt disconnect ${v}` },
    '__AIRPLAY_CONNECT__':{ title:'Connect AirPlay',  msg:'Device name:',   def:'',  type:'text',   build: v => `airplay connect ${v}` },
    '__SHORTCUT__':       { title:'Run Shortcut',      msg:'Shortcut name:', def:'',  type:'text',   build: v => `shortcut:${v}` },
    '__OPEN_APP__':       { title:'Open App',          msg:'Bundle ID:',     def:'',  type:'text',   build: v => `uiopen ${v}` },
    '__LUA_SCRIPT__':     { title:'Lua Script',        msg:'Lua code:',      def:'',  type:'text',   build: v => `Lua ${v}` },
    '__CUSTOM__':         { title:'Terminal Command',  msg:'Command:',       def:'',  type:'text',   build: v => `exec ${v}` },
    '__TAP__':            { title:'Tap at Coordinates', msg:'x y  (pixels, e.g. 195 422):', def:'195 422', type:'text', build: v => `tap ${v.trim()}` },
    '__HOLD__':           { title:'Hold at Coordinates', msg:'x y [ms]  (e.g. 195 422 800):', def:'195 422 800', type:'text', build: v => `hold ${v.trim()}` },
    '__SWIPE__':          { title:'Custom Swipe', msg:'x1 y1 x2 y2  (pixels, e.g. 195 700 195 200):', def:'195 700 195 200', type:'text', build: v => `swipe ${v.trim()}` },
  };

  if (needsText[cmd]) {
    const d = needsText[cmd];
    let listId = null;
    if (cmd === '__OPEN_APP__') listId = 'app-datalist';
    if (cmd === '__BT_CONNECT__' || cmd === '__BT_DISCONNECT__') listId = 'bt-datalist';
    if (cmd === '__AIRPLAY_CONNECT__') listId = 'airplay-datalist';
    
    // Ensure lists are fresh if we might use one
    if (listId) refreshDatalists();

    showDialog(d.title, d.msg, d.def, 'Add', val => {
      if (!val) return;
      addAction(d.build(val));
    }, d.type, listId);
    return;
  }

  if (cmd === '__IF_CONDITION__') {
    showConditionPicker();
    return;
  }

  addAction(cmd);
  closePickerPanel();
}

function addAction(cmd) {
  if (!currentKey) return;
  const data = triggerData(currentKey);
  if (!data.actions) data.actions = [];
  data.actions.push(cmd);
  if (!data.enabled) { data.enabled = true; document.getElementById('trigger-enabled-toggle').checked = true; }
  saveConfig();
  renderActionList();
  closePickerPanel();
}

function showConditionPicker() {
  const btns = CONDITION_DEFS.map(c => ({
    label: c.title,
    action: () => {
      if (c.freeText) {
        showDialog(`If ${c.title}`, 'App bundle ID (e.g. com.apple.Music):', '', 'Add', val => {
          if (!val) return;
          const ifAction = { type:'if', conditionKey:c.key, conditionTitle:c.title, expectedValue:val, expectedTitle:val };
          const data = triggerData(currentKey);
          if (!data.actions) data.actions = [];
          data.actions.push(ifAction, { type:'end_if' });
          saveConfig(); renderActionList(); closePickerPanel();
        });
      } else if (c.values) {
        showSheet(`${c.title} is…`, c.values.map(v => ({
          label: v.title,
          action: () => {
            const ifAction = { type:'if', conditionKey:c.key, conditionTitle:c.title, expectedValue:v.value, expectedTitle:v.title };
            const data = triggerData(currentKey);
            if (!data.actions) data.actions = [];
            data.actions.push(ifAction, { type:'end_if' });
            saveConfig(); renderActionList(); closePickerPanel();
          }
        })));
      }
    }
  }));
  showSheet('If Condition', btns);
}

// ── Add trigger ───────────────────────────────────────────────────────────────
function showAddTriggerSheet() {
  showSheet('New Trigger', [
    { label:'NFC Tag',           action:() => promptNewTrigger('nfc',        'NFC tag ID or name') },
    { label:'WiFi Network',      action:() => promptComplexTrigger('wifi') },
    { label:'Bluetooth Device',  action:() => promptComplexTrigger('bt') },
    { label:'App Launch',        action:() => promptAppLaunchTrigger() },
    { label:'Notification',      action:() => promptNotifTrigger() },
    { label:'Scheduled',         action:() => promptSchedTrigger() },
  ]);
}

function promptNewTrigger(prefix, placeholder) {
  showDialog('New Trigger', placeholder + ':', '', 'Create', val => {
    if (!val) return;
    const key = `${prefix}_${val.toLowerCase().replace(/[ \t\n\r]+/g,'_').replace(/[^a-z0-9_]/g,'')}`;
    config.triggers[key] = { enabled: true, actions: [], name: val };
    saveConfig(); renderAll();
  });
}

// ── App Launch Trigger Dialog ────────────────────────────────────────────────
let _appPickerData = []; // Cached full list for filtering

async function promptAppLaunchTrigger() {
  document.getElementById('app-picker-search').value = '';
  const listEl = document.getElementById('app-picker-list');
  listEl.innerHTML = '<div class="app-picker-loading" id="app-picker-loading">Loading apps…</div>';
  document.getElementById('app-launch-dialog-backdrop').classList.add('visible');
  setTimeout(() => document.getElementById('app-picker-search').focus(), 150);

  try {
    const data = await fetchDevices();
    _appPickerData = (data && data.apps) ? data.apps : [];
    renderAppPickerList(_appPickerData);
  } catch(e) {
    listEl.innerHTML = '<div class="app-picker-loading">Could not load apps from device.</div>';
  }
}

function closeAppLaunchDialog() {
  document.getElementById('app-launch-dialog-backdrop').classList.remove('visible');
  _appPickerData = [];
}

function filterAppPickerList() {
  const q = (document.getElementById('app-picker-search').value || '').toLowerCase().trim();
  const filtered = q
    ? _appPickerData.filter(a => a.name.toLowerCase().includes(q) || a.bundleId.toLowerCase().includes(q))
    : _appPickerData;
  renderAppPickerList(filtered);
}

function renderAppPickerList(apps) {
  const listEl = document.getElementById('app-picker-list');
  if (!apps || apps.length === 0) {
    listEl.innerHTML = '<div class="app-picker-loading">No apps found.</div>';
    return;
  }
  listEl.innerHTML = '';
  apps.forEach(app => {
    const row = document.createElement('div');
    row.className = 'app-picker-row';
    row.innerHTML = `
      <div class="app-picker-row-inner">
        <div class="app-picker-name">${escHtml(app.name)}</div>
        <div class="app-picker-bid">${escHtml(app.bundleId)}</div>
      </div>
      <i class="f7-icons" style="color:#3a3a3c;font-size:14px;flex-shrink:0">chevron_right</i>
    `;
    row.addEventListener('click', () => {
      closeAppLaunchDialog();
      // Use app name as display name, bundle ID as key suffix
      const name = app.name;
      const safeSuffix = app.bundleId; // keep full bundle ID as suffix for exact match in trigger hook
      const key = `app_launch_${safeSuffix}`;
      config.triggers[key] = { enabled: true, actions: [], name };
      saveConfig(); renderAll();
      setTimeout(() => openActionsPanel(key), 400);
    });
    listEl.appendChild(row);
  });
}

// ── Scheduled Trigger Dialog ─────────────────────────────────────────────────
function promptSchedTrigger(existingKey) {
  editingTriggerKey = existingKey || null;
  const data = editingTriggerKey ? config.triggers[editingTriggerKey] : null;
  const sched = data ? data.schedule : null;

  const now = new Date();
  const hh = sched ? String(sched.hour).padStart(2,'0') : String(now.getHours()).padStart(2,'0');
  const mm = sched ? String(sched.minute).padStart(2,'0') : String(now.getMinutes()).padStart(2,'0');
  
  document.getElementById('sched-name').value = data ? data.name : '';
  document.getElementById('sched-time').value = `${hh}:${mm}`;
  document.getElementById('sched-dialog-ok').textContent = editingTriggerKey ? 'Save' : 'Create';
  
  // Pre-check days
  const dayCbs = document.querySelectorAll('#sched-days input[type=checkbox]');
  dayCbs.forEach(cb => {
    if (sched && sched.days) {
      cb.checked = sched.days.includes(parseInt(cb.value));
    } else {
      cb.checked = true; // Default for new
    }
  });

  document.getElementById('sched-dialog-backdrop').classList.add('visible');
  if (!editingTriggerKey) setTimeout(() => document.getElementById('sched-name').focus(), 100);
}

function closeSchedDialog() {
  document.getElementById('sched-dialog-backdrop').classList.remove('visible');
}

function schedDialogOk() {
  const name = document.getElementById('sched-name').value.trim();
  const timeVal = document.getElementById('sched-time').value; // "HH:MM"
  const checkedDays = Array.from(document.querySelectorAll('#sched-days input[type=checkbox]:checked'))
                           .map(cb => parseInt(cb.value));
  if (!name) { showToast('⚠ Name required'); return; }
  if (!timeVal) { showToast('⚠ Time required'); return; }
  if (checkedDays.length === 0) { showToast('⚠ Select at least one day'); return; }
  const [hourStr, minStr] = timeVal.split(':');
  const hour = parseInt(hourStr);
  const minute = parseInt(minStr);

  if (editingTriggerKey) {
    // Update existing
    const data = config.triggers[editingTriggerKey];
    data.name = name;
    data.schedule = { hour, minute, days: checkedDays };
  } else {
    // Create new
    const key = `sched_${name.toLowerCase().replace(/[ \t\n\r]+/g,'_').replace(/[^a-z0-9_]/g,'')}`;
    config.triggers[key] = {
      enabled: true,
      actions: [],
      name: name,
      schedule: { hour, minute, days: checkedDays }
    };
    // Open the new trigger for editing
    setTimeout(() => openActionsPanel(key), 400);
  }

  closeSchedDialog();
  saveConfig(); renderAll();
}

// ── Notification Trigger Dialog ────────────────────────────────────────────────
function generateNotifName(bundleId, textMatch) {
  let appName = 'Any App';
  if (bundleId) {
    const app = cachedApps.find(a => a.bundleId === bundleId);
    appName = app ? app.name : bundleId;
  }
  
  if (bundleId) {
    if (textMatch) return `Notification from ${appName} containing '${textMatch}'`;
    return `Any Notification from ${appName}`;
  } else {
    if (textMatch) return `Any Notification containing '${textMatch}'`;
    return 'Any Notification';
  }
}

function promptNotifTrigger(existingKey) {
  editingTriggerKey = existingKey || null;
  let bundleId = '';
  let textMatch = '';
  
  if (editingTriggerKey && config.notificationTriggers) {
    const entry = config.notificationTriggers.find(t => t.triggerKey === editingTriggerKey);
    if (entry) {
      bundleId = entry.bundleId || '';
      textMatch = entry.textMatch || '';
    }
  }

  document.getElementById('notif-bundle').value = bundleId;
  document.getElementById('notif-text').value = textMatch;
  document.getElementById('notif-dialog-ok').textContent = editingTriggerKey ? 'Save' : 'Create';
  document.getElementById('notif-dialog-backdrop').classList.add('visible');
  
  refreshDatalists();
  if (!editingTriggerKey) setTimeout(() => document.getElementById('notif-bundle').focus(), 100);
}

function closeNotifDialog() {
  document.getElementById('notif-dialog-backdrop').classList.remove('visible');
}

function notifDialogOk() {
  const bundleId = document.getElementById('notif-bundle').value.trim();
  const textMatch = document.getElementById('notif-text').value.trim();
  const name = generateNotifName(bundleId, textMatch);

  let key = editingTriggerKey;
  if (!key) {
    // Generate unique random key (notif_ + 8 hex chars)
    const rand = Math.floor(Math.random() * 0xffffffff).toString(16).padStart(8, '0');
    key = `notif_${rand}`;
    config.triggers[key] = { enabled: true, actions: [], name };
  } else {
    config.triggers[key].name = name;
  }

  // Add/update entry in notificationTriggers array (read by backend hook)
  if (!config.notificationTriggers) config.notificationTriggers = [];
  
  // Remove any existing entry for this key
  config.notificationTriggers = config.notificationTriggers.filter(t => t.triggerKey !== key);
  
  const entry = { triggerKey: key, bundleId, enabled: true };
  if (textMatch) entry.textMatch = textMatch;
  config.notificationTriggers.push(entry);

  closeNotifDialog();
  saveConfig(); renderAll();
  
  if (!editingTriggerKey) {
    // Open the new trigger for editing
    setTimeout(() => openActionsPanel(key), 400); // Wait for dialog close animation
  }
}

// ── Complex Trigger (WiFi/BT) ────────────────────────────────────────────────
let complexTriggerType = null;
let complexTriggerSegment = 'connect';

async function fetchDevices() {
  try {
    const res = await fetch('/api/devices');
    const data = await res.json();
    console.log('API: fetchDevices returned:', data);
    return data;
  } catch (e) {
    console.error('API: fetchDevices FAILED:', e);
    return { wifi: [], bluetooth: [], apps: [] };
  }
}

async function refreshDatalists() {
  console.log('UI: refreshing datalists...');
  const data = await refreshDatalistsInternal();
  return data;
}

async function refreshDatalistsInternal() {
  const data = await fetchDevices();
  if (!data) return null;

  const appList = document.getElementById('app-datalist');
  if (appList && data.apps) {
    cachedApps = data.apps;
    appList.innerHTML = '';
    console.log(`UI: Populating app-datalist with ${data.apps.length} items`);
    data.apps.forEach(app => {
      const opt = document.createElement('option');
      opt.value = app.bundleId;
      opt.label = app.name; // Use label for better browser support
      opt.textContent = app.name;
      appList.appendChild(opt);
    });
  }

  const btList = document.getElementById('bt-datalist');
  if (btList && data.bluetooth) {
    btList.innerHTML = '';
    data.bluetooth.forEach(name => {
      const opt = document.createElement('option');
      opt.value = name;
      btList.appendChild(opt);
    });
  }

  const wifiList = document.getElementById('wifi-datalist');
  if (wifiList && data.wifi) {
    wifiList.innerHTML = '';
    data.wifi.forEach(name => {
      const opt = document.createElement('option');
      opt.value = name;
      wifiList.appendChild(opt);
    });
  }

  const airplayList = document.getElementById('airplay-datalist');
  if (airplayList && data.airplay) {
    airplayList.innerHTML = '';
    data.airplay.filter(n => n !== 'iPhone').forEach(name => {
      const opt = document.createElement('option');
      opt.value = name;
      airplayList.appendChild(opt);
    });
  }
  return data;
}

function setComplexSegment(seg) {
  complexTriggerSegment = seg;
  document.getElementById('complex-seg-connect').style.background = seg === 'connect' ? '#007aff' : 'transparent';
  document.getElementById('complex-seg-disconnect').style.background = seg === 'disconnect' ? '#007aff' : 'transparent';
}

async function promptComplexTrigger(type, existingKey) {
  editingTriggerKey = existingKey || null;
  complexTriggerType = type;
  
  let val = '';
  let seg = 'connect';
  
  if (editingTriggerKey) {
    const data = config.triggers[editingTriggerKey];
    val = data.name || '';
    if (editingTriggerKey.includes('_disconnect_')) seg = 'disconnect';
  }

  setComplexSegment(seg);
  document.getElementById('complex-dialog-title').textContent = editingTriggerKey ? (type === 'wifi' ? 'Edit WiFi Trigger' : 'Edit Bluetooth Trigger') : (type === 'wifi' ? 'New WiFi Trigger' : 'New Bluetooth Trigger');
  document.getElementById('complex-dialog-msg').textContent = type === 'wifi' ? 'Select or type Network SSID' : 'Select or type Device Name';
  document.getElementById('complex-dialog-input').value = val;
  document.getElementById('complex-dialog-input').placeholder = type === 'wifi' ? 'Network SSID' : 'Device Name';
  document.getElementById('complex-dialog-ok').textContent = editingTriggerKey ? 'Save' : 'Create';
  
  const datalist = document.getElementById('complex-dialog-datalist');
  datalist.innerHTML = '';
  document.getElementById('complex-dialog-backdrop').classList.add('visible');

  // Refresh and use data
  const data = await refreshDatalists();
  const list = type === 'wifi' ? (data ? data.wifi : []) : (data ? data.bluetooth : []);
  if (list && list.length) {
    list.forEach(name => {
      const opt = document.createElement('option');
      opt.value = name;
      datalist.appendChild(opt);
    });
  }
}

function closeComplexDialog() {
  document.getElementById('complex-dialog-backdrop').classList.remove('visible');
}

function complexDialogOk() {
  const val = document.getElementById('complex-dialog-input').value.trim();
  if (!val) {
    closeComplexDialog();
    return;
  }
  
  const prefix = complexTriggerType; 
  const newKey = `${prefix}_${complexTriggerSegment}_${val}`;

  if (editingTriggerKey) {
    // If the key changed (SSID/Device name or segment changed), we must migrate
    if (editingTriggerKey !== newKey) {
      config.triggers[newKey] = config.triggers[editingTriggerKey];
      delete config.triggers[editingTriggerKey];
      currentKey = newKey; // Update current view
    }
    config.triggers[newKey].name = val;
  } else {
    // Create new
    config.triggers[newKey] = { enabled: true, actions: [], name: val };
    // Open the new trigger for editing
    setTimeout(() => openActionsPanel(newKey), 400);
  }

  closeComplexDialog();
  saveConfig(); renderAll();
}

// ── Settings ──────────────────────────────────────────────────────────────────
function openSettings() {
  document.getElementById('setting-master').checked = !!config.masterEnabled;
  document.getElementById('setting-nfc').checked    = !!config.nfcEnabled;
  document.getElementById('setting-webui').checked  = !!config.webUIEnabled;
  document.getElementById('settings-panel').classList.add('active');
  document.getElementById('footer-settings-fixed').style.display = 'block';
}
function closeSettings() {
  document.getElementById('settings-panel').classList.remove('active');
  document.getElementById('footer-settings-fixed').style.display = 'none';
}

function exportConfig() {
  const blob = new Blob([JSON.stringify(config, null, 2)], { type:'application/json' });
  const url  = URL.createObjectURL(blob);
  const a = document.createElement('a');
  const d = new Date();
  a.href = url;
  a.download = `rc_config_${d.getFullYear()}${String(d.getMonth()+1).padStart(2,'0')}${String(d.getDate()).padStart(2,'0')}.json`;
  a.click();
  URL.revokeObjectURL(url);
}
function importConfig() { document.getElementById('import-file-input').click(); }
function handleImportFile(input) {
  const file = input.files[0];
  if (!file) return;
  const reader = new FileReader();
  reader.onload = e => {
    try {
      const imp = JSON.parse(e.target.result);
      if (imp.triggers) Object.assign(config.triggers, imp.triggers);
      if (imp.masterEnabled !== undefined) config.masterEnabled = imp.masterEnabled;
      if (imp.nfcEnabled !== undefined) config.nfcEnabled = imp.nfcEnabled;
      saveConfig(); renderAll();
      showToast('✓ Import successful');
    } catch { showToast('⚠ Invalid config file'); }
  };
  reader.readAsText(file);
  input.value = '';
}

// ── Sheet ─────────────────────────────────────────────────────────────────────
function showSheet(title, buttons) {
  document.getElementById('sheet-title').textContent = title;
  const container = document.getElementById('sheet-buttons');
  container.innerHTML = '';
  buttons.forEach(btn => {
    const b = document.createElement('button');
    b.className = 'sheet-btn' + (btn.destructive ? ' destructive' : '');
    b.textContent = btn.label;
    b.addEventListener('click', () => {
      closeSheet();
      // Delay action until after the sheet close animation finishes,
      // so no ghost-touch can dismiss a freshly-opened dialog on iOS.
      if (btn.action) setTimeout(btn.action, 350);
    });
    container.appendChild(b);
  });
  document.getElementById('sheet-backdrop').classList.add('visible');
  requestAnimationFrame(() => document.getElementById('sheet').classList.add('open'));
}
function closeSheet() {
  document.getElementById('sheet').classList.remove('open');
  setTimeout(() => document.getElementById('sheet-backdrop').classList.remove('visible'), 320);
}

// ── Dialog ────────────────────────────────────────────────────────────────────
function showDialog(title, msg, defaultVal, okLabel, callback, inputType='text', listId=null) {
  document.getElementById('dialog-title').textContent = title;
  document.getElementById('dialog-msg').textContent = msg;
  const input = document.getElementById('dialog-input');
  input.type = inputType === 'number' ? 'number' : 'text';
  if (listId) input.setAttribute('list', listId);
  else input.removeAttribute('list');
  input.value = defaultVal || '';
  document.getElementById('dialog-ok').textContent = okLabel || 'OK';
  dialogCallback = callback;
  document.getElementById('dialog-backdrop').classList.add('visible');
  setTimeout(() => input.focus(), 100);
}
function closeDialog() {
  document.getElementById('dialog-backdrop').classList.remove('visible');
  dialogCallback = null;
}
function dialogOk() {
  const val = document.getElementById('dialog-input').value.trim();
  const cb = dialogCallback;
  closeDialog();
  if (cb) cb(val);
}
document.getElementById('dialog-input').addEventListener('keydown', e => {
  if (e.key === 'Enter') dialogOk();
  if (e.key === 'Escape') closeDialog();
});

// ── Toast ─────────────────────────────────────────────────────────────────────
let _toastTimer;
function showToast(msg) {
  clearTimeout(_toastTimer);
  const el = document.getElementById('toast');
  el.textContent = msg;
  el.classList.add('show');
  _toastTimer = setTimeout(() => el.classList.remove('show'), 2000);
}

// ── Boot ──────────────────────────────────────────────────────────────────────
loadData();
