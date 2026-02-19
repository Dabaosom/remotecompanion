-- RemoteCompanion Lua Dynamic Bridge Demo

-- 1. Helper Function for Logging
function print(msg)
    log("[Lua Demo] " .. tostring(msg))
end

print("Starting Lua Bridge Demo...")

-- 2. Basic Utility: Delay
print("Waiting 1 second...")
delay(1.0)
print("Done waiting.")

-- 3. Dynamic Library Loading (dlopen)
-- Example: Load libsqlite3 (just to prove it works, even if we don't use it directly here)
local success, err = dlopen("/usr/lib/libsqlite3.dylib")
if success then
    print("✅ Successfully loaded libsqlite3.dylib")
else
    print("❌ Failed to load libsqlite3: " .. tostring(err))
end

-- 4. Objective-C Method Calls (objc_call)
-- PRO TIP: You can call ANY Objective-C class method or instance method.

-- Example A: Get Battery Level via UIDevice
-- [UIDevice currentDevice]
local device = objc_call("UIDevice", "currentDevice")
if device then
    -- [device setBatteryMonitoringEnabled:YES]
    objc_call("UIDevice", "currentDevice", "setBatteryMonitoringEnabled:", true)
    
    -- [device batteryLevel]
    local level = objc_call("UIDevice", "currentDevice", "batteryLevel")
    print("🔋 Battery Level: " .. (level * 100) .. "%")
else
    print("❌ Failed to get UIDevice")
end

-- Example B: Toggle Flashlight via SpringBoard (AVCaptureDevice)
-- Note: This is a bit complex in raw ObjC, so let's stick to simple property reading for the demo.
-- Let's check if the device is locked via SBLockScreenManager (SpringBoard specific)

local isLocked = objc_call("SBLockScreenManager", "sharedInstance", "isUILocked")
print("🔒 Device Locked Status: " .. tostring(isLocked))

-- Example C: Trigger Haptic (Native Binding)
print("📳 Triggering Haptic...")
haptic()

print("Demo Completed.")
