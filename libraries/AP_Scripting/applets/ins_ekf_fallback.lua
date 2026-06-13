local EXTERNAL = 11
local EKF3     = 3
local SRC_SET_FALLBACK = 1   -- 0-based: SRC2 (baro alt, no GPS/compass)
local MODE_ALT_HOLD    = 2

local DEBOUNCE_COUNT = 4
local LOOP_MS        = 20

local unhealthy_count = 0
local switched        = false

local function do_failover()
  ahrs:set_posvelyaw_source_set(SRC_SET_FALLBACK)
  local ok = param:set('AHRS_EKF_TYPE', EKF3)
  vehicle:set_mode(MODE_ALT_HOLD)
  if ok then
    switched = true
    gcs:send_text(0, "FALLBACK: External AHRS lost -> EKF3 + SRC2, ALT_HOLD")
  else
    gcs:send_text(0, "FALLBACK: FAILED to set AHRS_EKF_TYPE=3")
  end
end

function update()
  if not arming:is_armed() then
    unhealthy_count = 0
    return update, LOOP_MS
  end

  if switched then
    return update, 1000
  end

  if param:get('AHRS_EKF_TYPE') ~= EXTERNAL then
    return update, LOOP_MS
  end

  if ahrs:healthy() then
    unhealthy_count = 0
  else
    unhealthy_count = unhealthy_count + 1
    if unhealthy_count >= DEBOUNCE_COUNT then
      do_failover()
    end
  end

  return update, LOOP_MS
end

gcs:send_text(5, "ins_ekf_fallback.lua loaded")
return update, LOOP_MS
