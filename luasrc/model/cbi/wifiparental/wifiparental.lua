local m, s

function validate_time(self, value)
    if not value:match("^%d%d:%d%d$") then
        return nil, translate("Invalid time format. Use HH:MM.")
    else
        local hour = tonumber(value:sub(1, 2))
        local minute = tonumber(value:sub(4, 5))
        if hour >= 0 and hour <= 23 and minute >= 0 and minute <= 59 then
            return value
        else
            return nil, translate("Invalid time value. Hours (00-23), Minutes (00-59).")
        end
    end
end

function is_time_between(start_hour_str, start_minute_str, end_hour_str, end_minute_str, current_hour, current_minute)
  local start_hour = tonumber(start_hour_str)
  local start_minute = tonumber(start_minute_str)
  local end_hour = tonumber(end_hour_str)
  local end_minute = tonumber(end_minute_str)

  if not start_hour or not start_minute or not end_hour or not end_minute or
     start_hour < 0 or start_hour > 23 or end_hour < 0 or end_hour > 23 or
     start_minute < 0 or start_minute > 59 or end_minute < 0 or end_minute > 59 then
    return false, "Invalid time input"
  end

  local start_time_minutes = start_hour * 60 + start_minute
  local end_time_minutes = end_hour * 60 + end_minute

  local current_time_minutes = current_hour * 60 + current_minute

  if start_time_minutes < end_time_minutes then
    return current_time_minutes >= start_time_minutes and current_time_minutes <= end_time_minutes, nil
  else
    return current_time_minutes >= start_time_minutes or current_time_minutes <= end_time_minutes, nil
  end
end


m = Map("wifiparental", "WiFiParental")


--
--  SECTION: wifiparental - "Settings"
--


local s_settings = m:section(TypedSection, "settings", "Settings", "")
s_settings.anonymous = true

local global_enabled = s_settings:option(Flag, "enabled", translate("Enable"))


local ssid_list = s_settings:option(ListValue, "ssid_list", "Select the SSID")
local script_output = luci.sys.exec("/etc/wifiparental/wifiparental.sh list_ssids")

for line in script_output:gmatch("[^\n]+") do
    ssid_list:value(line, line)
end


--
--  SECTION: week_schedule - "Setup the Weekly Schedule"
--


local s = m:section(TypedSection, "week_schedule", translate("Weekly Schedule"))
s.template = "cbi/tblsection"
s:option(DummyValue, "day_name", "Day")
s:option(Flag, "enabled", "Enabled")
s:option(Value, "start_time", "Start Time").validate = validate_time
s:option(Value, "end_time", "End Time").validate = validate_time
s.anonymous = true


--
--  SUBMIT
--


m.on_after_commit = function(self)
    -- clear the current crons
    luci.sys.exec("/etc/wifiparental/wifiparental.sh cron_clear_selfscript_lines")

    local g_enabled = m:get("@settings[0]", "enabled")
    
    if tonumber(g_enabled) == 1 then
        local selected_ssid = m:get("@settings[0]", "ssid_list")

        local days_of_week = {"sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"}

        for index, value in ipairs(days_of_week) do
            local enabled = m:get(value, "enabled")
            local start_time = m:get(value, "start_time")
            local end_time = m:get(value, "end_time")

            local start_hour_str, start_minute_str = string.match(start_time, "(%d%d):(%d%d)")
            local end_hour_str, end_minute_str = string.match(end_time, "(%d%d):(%d%d)")

            if tonumber(enabled) == 1 then
                luci.sys.exec("/etc/wifiparental/wifiparental.sh cron_create_entry " .. (index - 1) .. " " .. start_hour_str .. " " .. start_minute_str .. " " .. end_hour_str .. " " .. end_minute_str .. " " .. selected_ssid)
            
                local now = os.date("*t")
                local day_of_week_0_6 = now.wday - 1

                if ((index - 1) == day_of_week_0_6) then 
                    local hour = now.hour
                    local minute = now.min

                    if is_time_between(start_hour_str, start_minute_str, end_hour_str, end_minute_str, hour, minute) then
                        luci.sys.exec("/etc/wifiparental/wifiparental.sh set_ssid_ability " .. selected_ssid .. " 1")
                    else
                        luci.sys.exec("/etc/wifiparental/wifiparental.sh set_ssid_ability " .. selected_ssid .. " 0")
                    end
                end
            end
        end
    else
        local selected_ssid = m:get("@settings[0]", "ssid_list")

        luci.sys.exec("/etc/wifiparental/wifiparental.sh set_ssid_ability " .. selected_ssid .. " 1")
    end
end


return m