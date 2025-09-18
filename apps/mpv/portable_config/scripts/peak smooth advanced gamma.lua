local target_contrast = 0
local current_contrast = 0
local target_gamma = 0
local current_gamma = 0

local easing_speed = 1
local last_update_time = mp.get_time()
local value_history = {}
local history_max_size = 100 -- 30 ~0.6 seconds @ 50Hz

-- Deadzone (noise tolerance)
local base_deadzone = 0.05
local max_deadzone = 0.05

-- Contrast config
local contrast_ref_value = 0.30
local contrast_range = 5.0         -- Max contrast swing
local contrast_max_offset = 0.05   -- Deviation before max contrast

-- Gamma config
local gamma_ref_value = 0.17
local gamma_range = 8.50            -- From 8 to -0.5
local gamma_max_offset = 0.06

-- Easing function for smooth updates
local function ease(current, target, delta_time, speed)
    local alpha = 1 - math.exp(-speed * delta_time)
    return current + (target - current) * alpha
end

-- Dynamically adjust deadzone based on history volatility
local function calculate_deadzone()
    if #value_history < 2 then
        return base_deadzone
    end
    local sum_diff = 0
    for i = 2, #value_history do
        sum_diff = sum_diff + math.abs(value_history[i] - value_history[i-1])
    end
    local avg_diff = sum_diff / (#value_history - 1)
    return math.min(base_deadzone + avg_diff * 5, max_deadzone)
end

-- Compute smoothed average from history
local function get_smoothed_value()
    if #value_history == 0 then return nil end
    local sum = 0
    for i = 1, #value_history do
        sum = sum + value_history[i]
    end
    return sum / #value_history
end

-- Clamp helper
local function clamp(val, min, max)
    return math.max(min, math.min(max, val))
end

-- Main callback for pq-y updates
local function check(name, raw_value)
    if raw_value == nil then return end

    -- Store raw value in history
    table.insert(value_history, raw_value)
    if #value_history > history_max_size then
        table.remove(value_history, 1)
    end

    -- Use average of history to avoid big jumps
    local value = get_smoothed_value()
    if value == nil then return end

    mp.msg.info("Smoothed avg-pq-y value: " .. string.format("%.4f", value))
    mp.msg.info("Current contrast value: " .. string.format("%.2f", current_contrast))
    mp.msg.info("Current gamma value: " .. string.format("%.2f", current_gamma))

    local deadzone = calculate_deadzone()

    -- Gradual Contrast Mapping
    local contrast_offset = value - contrast_ref_value
    local contrast_t = clamp(contrast_offset / contrast_max_offset, -1, 1)
    target_contrast = -0.5 * (contrast_t + 1) * contrast_range

    -- Gradual Gamma Mapping
    local gamma_offset = value - gamma_ref_value
    local gamma_t = clamp(gamma_offset / gamma_max_offset, -1, 1)
    target_gamma = 3.75 - gamma_t * (gamma_range / 2)
end

-- Smoothly apply contrast/gamma changes
local function update_properties()
    local now = mp.get_time()
    local delta_time = now - last_update_time
    last_update_time = now

    -- Smooth contrast
    local new_contrast = ease(current_contrast, target_contrast, delta_time, easing_speed)
    if math.abs(new_contrast - current_contrast) > 0.01 then
        current_contrast = new_contrast
        mp.set_property("contrast", string.format("%.2f", current_contrast))
    end

    -- Smooth gamma
    local new_gamma = ease(current_gamma, target_gamma, delta_time, easing_speed)
    if math.abs(new_gamma - current_gamma) > 0.01 then
        current_gamma = new_gamma
        mp.set_property("gamma", string.format("%.2f", current_gamma))
    end
end

-- Hook into mpv
mp.observe_property("video-out-params/avg-pq-y", "native", check)
mp.add_periodic_timer(0.02, update_properties)
