-- cheat codes
--          a sample playground
--
-- ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ 
-- need help?
-- please see [?] menu
-- for in-app instruction manual
-- -------------------------------

local pattern_time = include 'lib/cc_pattern_time'
fileselect = require 'fileselect'
help_menus = include 'lib/help_menus'
main_menu = include 'lib/main_menu'
encoder_actions = include 'lib/encoder_actions'
arc_actions = include 'lib/arc_actions'
rightangleslice = include 'lib/zilchmos'
start_up = include 'lib/start_up'
grid_actions = include 'lib/grid_actions'
easingFunctions = include 'lib/easing'
midicontrol = include 'lib/midicheat'
arps = include 'lib/arp_actions'
rnd = include 'lib/rnd_actions'
--trackers = include 'lib/tracker'
rytm = include 'lib/euclid'
math.randomseed(os.time())

--all the .quantize stuff is irrelevant now. it's been replaced by .mode = "quantized"

function screenshot()
  --_norns.screen_export_png("/home/we/"..menu.."-"..os.time()..".png")
  local which_screen = string.match(string.match(string.match(norns.state.script,"/home/we/dust/code/(.*)"),"/(.*)"),"(.+).lua")
  _norns.screen_export_png("/home/we/"..which_screen.."-"..os.time()..".png")
end

function rerun()
  norns.script.load(norns.state.script)
end

tau = math.pi * 2
arc_param = {}
arc_switcher = {}
for i = 1,3 do
  arc_param[i] = 1
  --arc_switcher[i] = 0
  arc_switcher[i] = {}
end
arc_control = {}
for i = 1,3 do
  arc_control[i] = i
end

arc_offset = 0 --IMPORTANT TO REVISIT

clip = {}
for i = 1,3 do
  clip[i] = {}
  clip[i].length = 90
  clip[i].sample_length = 8
  clip[i].start_point = nil
  clip[i].end_point = nil
  clip[i].mode = 1
end

clip[1].min = 1
clip[1].max = 1 + clip[1].sample_length
clip[2].min = 33
clip[2].max = clip[2].min + clip[2].sample_length
clip[3].min = 65
clip[3].max = clip[3].min + clip[3].sample_length

live = {}
for i = 1,3 do
  live[i] = {}
end
live[1].min = 1
live[1].max = 9
live[2].min = 9
live[2].max = 17
live[3].min = 17
live[3].max = 25

help_menu = "welcome"

function f1()
  softcut.post_filter_lp(2,0)
  softcut.post_filter_hp(2,1)
  softcut.post_filter_fc(2,10)
  params:set("filter 1 cutoff",10)
end

function f2()
  softcut.post_filter_hp(2,0)
  softcut.post_filter_lp(2,1)
  softcut.post_filter_fc(2,12000)
  params:set("filter 1 cutoff",12000)
end

pattern_saver = {}
for i = 1,3 do
  pattern_saver[i] = metro.init()
  pattern_saver[i].time = 1
  pattern_saver[i].count = 1
  pattern_saver[i].event = function() test_save(i) end
  pattern_saver[i].source = i
  pattern_saver[i].save_slot = nil
  pattern_saver[i].load_slot = 0
  pattern_saver[i].saved = {}
  for j = 1,8 do
    pattern_saver[i].saved[j] = 0
  end
end

env_counter = {}
for i = 1,3 do
  env_counter[i] = metro.init()
  env_counter[i].time = 0.01
  env_counter[i].butt = 1
  env_counter[i].event = function() envelope(i) end
end

slew_counter = {}

for i = 1,3 do
  slew_counter[i] = metro.init()
  slew_counter[i].time = 0.01
  slew_counter[i].count = 100
  slew_counter[i].current = 0.00
  slew_counter[i].event = function() easing_slew(i) end
  slew_counter[i].ease = easingFunctions.inSine
  slew_counter[i].beginVal = 0
  slew_counter[i].endVal = 1
  slew_counter[i].change =  slew_counter[i].endVal - slew_counter[i].beginVal
  slew_counter[i].beginQ = 0
  slew_counter[i].endQ = 0
  slew_counter[i].changeQ = slew_counter[i].endQ - slew_counter[i].beginQ
  slew_counter[i].duration = (slew_counter[i].count/100)-0.01
  slew_counter[i].slewedVal = 0
  slew_counter[i].prev_tilt = 0
  slew_counter[i].next_tilt = 0
  slew_counter[i].prev_q = 0
  slew_counter[i].next_q = 0
end

quantize = 1
quantize_events = {}
for i = 1,3 do
  quantize_events[i] = {}
end

grid_pat_quantize = 1
grid_pat_quantize_events = {}
for i = 1,3 do
  grid_pat_quantize_events[i] = {}
end

--[[
grid_pat_quantizer = {}
for i = 1,3 do
  grid_pat_quantizer[i] = {}
  grid_pat_quantizer[i] = metro.init()
  grid_pat_quantizer[i].time = 0.25
  grid_pat_quantizer[i].count = -1
  --grid_pat_quantizer[i].event = function() grid_pat_q_clock(i) end
  grid_pat_quantizer[i].event = function() end
  grid_pat_quantizer[i]:start()
end
--]]

function cheat_clock_synced(i)
  if #quantize_events[i] > 0 then
    for k,e in pairs(quantize_events[i]) do
      cheat(i,e)
      grid_p[i] = {}
      grid_p[i].action = "pads"
      grid_p[i].i = i
      grid_p[i].id = selected[i].id
      grid_p[i].x = selected[i].x
      grid_p[i].y = selected[i].y
      grid_p[i].rate = bank[i][bank[i].id].rate
      grid_p[i].pause = bank[i][bank[i].id].pause
      grid_p[i].start_point = bank[i][bank[i].id].start_point
      grid_p[i].end_point = bank[i][bank[i].id].end_point
      grid_p[i].rate_adjusted = false
      grid_p[i].loop = bank[i][bank[i].id].loop
      grid_p[i].mode = bank[i][bank[i].id].mode
      grid_p[i].clip = bank[i][bank[i].id].clip
      grid_pat[i]:watch(grid_p[i])
    end
    quantize_events[i] = {}
  end
end

function how_many_bars(bank)
  local total_pattern_time = 0
  for i = 1,#grid_pat[bank].event do
    total_pattern_time = total_pattern_time + grid_pat[bank].time[i]
  end
  local time_per_bar = (60/bpm)*4
  local this_many_bars = math.floor((total_pattern_time/time_per_bar)+0.5)
  -- need at least ONE bar, so...
  if this_many_bars == 0 then this_many_bars = 1 end
  return this_many_bars
end

function better_grid_pat_q_clock(i)
  if grid_pat[i].rec == 1 then
    grid_pat[i]:rec_stop()
    midi_clock_linearize(i)
    grid_pat[i].loop = 1
    if grid_pat[i].count > 0 then
      grid_pat[i].tightened_start = 1
      if grid_pat[i].auto_snap == 1 then
        print("auto-snap")
        snap_to_bars(i,how_many_bars(i))
      end
    end
  elseif grid_pat[i].count == 0 then
    grid_pat[i]:rec_start()
  elseif grid_pat[i].play == 1 then
    grid_pat[i]:stop()
  elseif grid_pat[i].tightened_start == 1 then
    grid_pat[i].tightened_start = 0
    grid_pat[i].step = grid_pat[i].start_point
    quantized_grid_pat[i].current_step = grid_pat[i].start_point
    quantized_grid_pat[i].sub_step = 1
  else
    grid_pat[i].tightened_start = 1
  end
end

function snap_to_bars(bank,bar_count)
  if grid_pat[bank].rec == 0 and grid_pat[bank].count > 0 then 
    local total_time = 0
    for i = 1,#grid_pat[bank].event do
      total_time = total_time + grid_pat[bank].time[i]
    end
    print("before total: "..total_time)
    if old_pat_time == nil then
      old_pat_time = table.clone(grid_pat[bank].time)
    end
    local bar_time = (((60/bpm)*4)*bar_count)/total_time
    for k = 1,grid_pat[bank].count do
      grid_pat[bank].time[k] = grid_pat[bank].time[k] * bar_time
    end
    total_time = 0
    for i = 1,#grid_pat[bank].event do
      total_time = total_time + grid_pat[bank].time[i]
    end
    print("after total: "..total_time)
    snap_to_bars_midi(bank,bar_count)
  end
end

local snakes = 
{ [1] = { 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16 }
, [2] = { 1,2,3,4,8,7,6,5,9,10,11,12,16,15,14,13 }
, [3] = { 1,5,9,13,2,6,10,14,3,7,11,15,4,8,12,16 }
, [4] = { 1,5,9,13,14,10,6,2,3,7,11,15,16,12,8,4 }
, [5] = { 1,2,3,4,8,12,16,15,14,13,9,5,6,7,11,10 }
, [6] = { 13,14,15,16,12,8,4,3,2,1,5,9,10,11,7,6 }
, [7] = { 1,2,5,9,6,3,4,7,10,13,14,11,8,12,15,16 }
, [8] = { 1,6,11,16,15,10,5,2,7,12,8,3,9,14,13,4 }
}

function random_grid_pat(which,mode)

  local pattern = grid_pat[which]
  
  if mode == 1 then
    for i = #pattern.time,2,-1 do
      local j = math.random(i)
      pattern.time[i], pattern.time[j] = pattern.time[j], pattern.time[i]
    end
  elseif mode == 2 then
    stop_pattern(pattern)
    for i = #pattern.event,2,-1 do
      local j = math.random(i)
      local original, shuffled = pattern.event[i], pattern.event[j]
      if original ~= "pause" and shuffled ~= "pause" then
        original.id, shuffled.id = shuffled.id, original.id
        original.rate, shuffled.rate = shuffled.rate, original.rate
        original.loop, shuffled.loop = shuffled.loop, original.loop
        original.mode, shuffled.mode = shuffled.mode, original.mode
        original.pause, shuffled.pause = shuffled.pause, original.pause
        original.start_point, shuffled.start_point = shuffled.start_point, original.start_point
        original.clip, shuffled.clip = shuffled.clip, original.clip
        original.end_point = original.end_point
        original.rate_adjusted, shuffled.rate_adjusted = shuffled.rate_adjusted, original.rate_adjusted
        original.y, shuffled.y = shuffled.y, original.y
        original.x, shuffled.x = shuffled.x, original.x
        original.action, shuffled.action = shuffled.action, original.action
        original.i, shuffled.i = shuffled.i, original.i
        original.previous_rate, shuffled.previous_rate = shuffled.previous_rate, original.previous_rate
        original.row, shuffled.row = shuffled.row, original.row
        original.con, shuffled.con = shuffled.con, original.con
        original.bank, shuffled.bank = shuffled.bank, original.bank
      else
        original, shuffled = shuffled, original
      end
    end
  elseif mode == 3 then
    local auto_pat = params:get("random_patterning")
    if auto_pat ~= 1 then
      params:set("pattern_"..which.."_quantization", 2)
    end
    if pattern.playmode == 3 or pattern.playmode == 4 then
      --clock.sync(1/4)
      -- new stuff!
      pattern.playmode = 2
      -- /new stuff!
    end
    local count = auto_pat == 1 and math.random(2,24) or 16
    if pattern.count > 0 or pattern.rec == 1 then
      pattern:rec_stop()
      stop_pattern(pattern)
      pattern.tightened_start = 0
      pattern:clear()
      pattern_saver[which].load_slot = 0
    end
    for i = 1,count do
      pattern.event[i] = {}
      local constructed = pattern.event[i]
      constructed.id = auto_pat == 1 and math.random(1,16) or snakes[auto_pat-1][i]
      local assigning_pad = bank[which][constructed.id]
      local new_rates = 
      { [1] = math.pow(2,math.random(-3,-1))*((math.random(1,2)*2)-3)
      , [2] = math.pow(2,math.random(-1,1))*((math.random(1,2)*2)-3)
      , [3] = math.pow(2,math.random(1,2))*((math.random(1,2)*2)-3)
      , [4] = math.pow(2,math.random(-2,2))*((math.random(1,2)*2)-3)
      , [5] = assigning_pad.rate
      }
      constructed.rate = new_rates[pattern.random_pitch_range]
      local pre_rate = assigning_pad.rate
      assigning_pad.rate = constructed.rate
      local new_levels = 
      { [0.125] = 1.75
      , [0.25]  = 1.5
      , [0.5]   = 1.25
      , [1.0]   = 1.0
      , [2.0]   = 0.75
      , [4.0]   = 0.5
      }
      if pre_rate == assigning_pad.rate then
        assigning_pad.level = assigning_pad.level
      else
        assigning_pad.level = assigning_pad.level == 0 and 0 or new_levels[math.abs(constructed.rate)]
      end
      constructed.loop = assigning_pad.loop
      constructed.mode = assigning_pad.mode
      constructed.pause = assigning_pad.pause
      constructed.start_point = (math.random(10,75)/10)+(8*(assigning_pad.clip-1))
      constructed.clip = assigning_pad.clip
      constructed.end_point = constructed.start_point + (math.random(1,15)/10)
      constructed.rate_adjusted = false
      assigning_pad.fifth = false
      constructed.x = (5*(which-1)+1)+(math.ceil(constructed.id/4)-1)
      if (constructed.id % 4) ~= 0 then
        constructed.y = 9-(constructed.id % 4)
      else
        constructed.y = 5
      end
      constructed.action = "pads"
      constructed.i = which
      local tempo = clock.get_beat_sec()
      local divisors = { 4,2,1,0.5,0.25,math.pow(2,math.random(-2,2)) }
      local note_length = (tempo / divisors[params:get("rand_pattern_"..which.."_note_length")])
      pattern.time[i] = note_length
      --new stuff!
      pattern.time_beats[i] = pattern.time[i] / tempo
      pattern:calculate_quantum(i)
      --/new stuff!
    end
    pattern.count = count
    pattern.start_point = 1
    pattern.end_point = count
  end
  midi_clock_linearize(which)
  if pattern.quantize == 0 then
    if pattern.auto_snap == 1 then
      print("auto-snap")
      snap_to_bars(which,how_many_bars(which))
    end
    start_pattern(pattern)
    pattern.loop = 1
  else
    pattern.loop = 1
    if pattern.count > 0 then
      pattern.tightened_start = 1
      if pattern.auto_snap == 1 then
        print("auto-snap")
        snap_to_bars(which,how_many_bars(which))
      end
    end
  end
end

function print_my_g_p_q(bank)
  for i = #quantized_grid_pat[bank].event,1,-1 do
    print(i)
    tab.print(quantized_grid_pat[bank].event[i])
  end
end

function snap_to_bars_midi(bank,bar_count)
  local entry_count = 0
  local target_entry_count = bar_count*16
  for i = 1,#quantized_grid_pat[bank].event do
    entry_count = entry_count + #quantized_grid_pat[bank].event[i]
  end
  print("before trimming midi event count: "..entry_count)
  if entry_count < target_entry_count then
    for i = 1,target_entry_count-entry_count do
      table.insert(quantized_grid_pat[bank].event[#quantized_grid_pat[bank].event],"nothing")
    end
  elseif entry_count > target_entry_count then
    --print("subtracting...")
    local last_event = #quantized_grid_pat[bank].event
    local last_group = #quantized_grid_pat[bank].event
    --print("last event: "..last_event)
    local distance_count = entry_count - target_entry_count
    print("removing "..distance_count.." event")
    local current_count = 0
    
    while current_count < distance_count do
      if last_group > 0 then
        if #quantized_grid_pat[bank].event[last_group] > 1 and quantized_grid_pat[bank].event[last_group][#quantized_grid_pat[bank].event[last_group]] == "nothing" then
          local check_table = #quantized_grid_pat[bank].event
          --print("removing: "..quantized_grid_pat[bank].event[last_group][#quantized_grid_pat[bank].event[last_group]].." from group "..last_group..", entry "..#quantized_grid_pat[bank].event[last_group])
          table.remove(quantized_grid_pat[bank].event[last_group])
          current_count = current_count + 1
          if current_count == distance_count then print("done now!") break end
          --print("current count :" .. current_count)
        elseif #quantized_grid_pat[bank].event[last_group] == 1 and quantized_grid_pat[bank].event[last_group][#quantized_grid_pat[bank].event[last_group]] == "something" then
          --print("skipping: "..quantized_grid_pat[bank].event[last_group][#quantized_grid_pat[bank].event[last_group]].." from group "..last_group..", entry "..#quantized_grid_pat[bank].event[last_group])
          last_group = last_group - 1
        elseif #quantized_grid_pat[bank].event[last_group] == 1 and quantized_grid_pat[bank].event[last_group][#quantized_grid_pat[bank].event[last_group]] == "nothing" then
          --print("there's only nothing in group "..last_group..", but removing it")
          table.remove(quantized_grid_pat[bank].event[last_group])
          --print_my_g_p_q(1)
          current_count = current_count + 1
          if current_count == distance_count then print("done now!") break end
          --print("current count :" .. current_count)
          last_group = last_group - 1
        elseif quantized_grid_pat[bank].event[last_group][#quantized_grid_pat[bank].event[last_group]] == nil then
          --print("A NIL IN"..last_group)
          table.remove(quantized_grid_pat[bank].event,last_group)
          last_group = last_group - 1
          --break
        end
      elseif last_group == 0 then
        --print("still got some left!!!: "..current_count.." / "..distance_count)
        table.remove(quantized_grid_pat[bank].event)
        current_count = current_count + 1
      end
    end
    quantized_grid_pat[bank].current_step = grid_pat[bank].start_point
    quantized_grid_pat[bank].sub_step = 1
  end
  
  local entry_count = 0
  for i = 1,#quantized_grid_pat[bank].event do
    entry_count = entry_count + #quantized_grid_pat[bank].event[i]
  end
  print("after trimming midi event count: "..entry_count)
  if entry_count ~= target_entry_count then
    --doubletap? is this ok??
    snap_to_bars_midi(bank,bar_count)
  end
end

function save_external_timing(bank,slot)
  
  local dirname = _path.data.."cheat_codes/external-timing/"
  if os.rename(dirname, dirname) == nil then
    os.execute("mkdir " .. dirname)
  end
  
  local file = io.open(_path.data .. "cheat_codes/external-timing/pattern"..selected_coll.."_"..slot.."_external-timing.data", "w+")
  io.output(file)
  io.write("external clock timing for stored pad pattern: collection "..selected_coll.." + slot "..slot.."\n")
  local total_entry_count = 0
  local number_of_events = #quantized_grid_pat[bank].event
  for i = 1,number_of_events do
    total_entry_count = total_entry_count + #quantized_grid_pat[bank].event[i]
  end
  io.write(total_entry_count.."\n")
  io.write(number_of_events.."\n")
  for i = 1,number_of_events do
    io.write("event: "..i.."\n")
    io.write("total entries: "..#quantized_grid_pat[bank].event[i].."\n")
    for j = 1,#quantized_grid_pat[bank].event[i] do
      io.write(quantized_grid_pat[bank].event[i][j].."\n")
    end
  end
  io.close(file)
  print("saved external timing for pattern "..bank.." to slot "..slot)
end

function load_external_timing(bank,slot)
  local file = io.open(_path.data .. "cheat_codes/external-timing/pattern"..selected_coll.."_"..slot.."_external-timing.data", "r")
  if file then
    io.input(file)
    if io.read() == "external clock timing for stored pad pattern: collection "..selected_coll.." + slot "..slot then
      quantized_grid_pat[bank].event = {}
      local total_entry_count = tonumber(io.read())
      local number_of_events = tonumber(io.read())
      for i = 1,number_of_events do
        local event_id = tonumber(string.match(io.read(), '%d+'))
        local entry_count = tonumber(string.match(io.read(), '%d+'))
        quantized_grid_pat[bank].event[i] = {}
        for j = 1,entry_count do
          quantized_grid_pat[bank].event[i][j] = io.read()
        end
      end
    end
    io.close(file)
  else
    print("creating external timing file...")
    midi_clock_linearize(bank)
    save_external_timing(bank,slot)
  end
end

function copy_entire_pattern(bank)
  original_pattern = {}
  original_pattern[bank] = {}
  original_pattern[bank].time = table.clone(grid_pat[bank].time)
  original_pattern[bank].event = {}
  for i = 1,#grid_pat[bank].event do
    original_pattern[bank].event[i] = {}
    -- new stuff!
    if grid_pat[bank].event[i] ~= "pause" then
      for k,v in pairs(grid_pat[bank].event[i]) do
        original_pattern[bank].event[i][k] = v
      end
    else
      original_pattern[bank].event[i] = "pause"
    end
  end
  original_pattern[bank].quantum = {}
  for k,v in pairs(grid_pat[bank].quantum) do
    original_pattern[bank].quantum[k] = v
  end
  original_pattern[bank].time_beats = {}
  for k,v in pairs(grid_pat[bank].time_beats) do
    original_pattern[bank].time_beats[k] = v
  end
  -- /new stuff!
  original_pattern[bank].metro = {}
  original_pattern[bank].metro.props = {}
  original_pattern[bank].metro.props.time = grid_pat[bank].metro.props.time
  original_pattern[bank].prev_time = grid_pat[bank].prev_time
  original_pattern[bank].count = grid_pat[bank].count
  original_pattern[bank].start_point = grid_pat[bank].start_point
  original_pattern[bank].end_point = grid_pat[bank].end_point
  original_pattern[bank].mode = grid_pat[bank].mode
  if grid_pat[bank].playmode ~= nil then
    original_pattern[bank].playmode = grid_pat[bank].playmode
  else
    original_pattern[bank].playmode = 1
  end
end

function copy_metatable(obj)
  if type(obj) ~= 'table' then return obj end
  local res = setmetatable({}, getmetatable(obj))
  for k, v in pairs(obj) do res[copy_metatable(k)] = copy_metatable(v) end
  return res
end

function commit_midi_to_disk(target)

end

function update_pattern_bpm(bank)
  grid_pat[bank].time_factor = 1*(synced_to_bpm/bpm)
end

function table.clone(org)
  return {table.unpack(org)}
end

function unpack_quantized_table(target)
  for i = 1,#quantized_grid_pat[target].event do
    grid_pat[target].quantum[i] = #quantized_grid_pat[target].event[i] * 0.25
    grid_pat[target].time_beats[i] = grid_pat[target].time[i] / clock.get_beat_sec()
  end
end

function midi_clock_linearize(bank)
  quantized_grid_pat[bank].event = {}
  for i = 1,grid_pat[bank].count do
    quantized_grid_pat[bank].clicks[i] = math.floor((grid_pat[bank].time[i] / ((60/bpm)/4))+0.5)
    quantized_grid_pat[bank].event[i] = {} -- critical
    if grid_pat[bank].time[i] == 0 or quantized_grid_pat[bank].clicks[i] == 0 then
      quantized_grid_pat[bank].event[i][1] = "nothing"
    else
      for j = 1,quantized_grid_pat[bank].clicks[i] do
        if j == 1 then
          quantized_grid_pat[bank].event[i][1] = "something"
        else
          quantized_grid_pat[bank].event[i][j] = "nothing"
        end
      end
    end
  end
  quantized_grid_pat[bank].current_step = grid_pat[bank].start_point
  quantized_grid_pat[bank].sub_step = 1
end

function midi_clock_linearize_overdub(bank)
  local curr = quantized_grid_pat[bank].current_step + 1
  local sub = quantized_grid_pat[bank].sub_step
  local removed = #quantized_grid_pat[bank].event[quantized_grid_pat[bank].current_step] - quantized_grid_pat[bank].sub_step
  for i = quantized_grid_pat[bank].sub_step,#quantized_grid_pat[bank].event[quantized_grid_pat[bank].current_step] do
    table.remove(quantized_grid_pat[bank].event[curr-1],sub)
  end
  table.insert(quantized_grid_pat[bank].event,curr,{"something"})
  if removed ~= 0 then
    for i = 1,removed do
      table.insert(quantized_grid_pat[bank].event[curr],"nothing")
    end
  end
  if quantized_grid_pat[bank].current_step < grid_pat[bank].end_point then
    quantized_grid_pat[bank].current_step = quantized_grid_pat[bank].current_step + 1
  else
    quantized_grid_pat[bank].current_step = 1
  end
  quantized_grid_pat[bank].sub_step = 1
end

  --[[
  local c = self.step + 1
  local t = self.prev_time
  self.prev_time = util.time()
  local a = self.time[c-1]
  self.time[c-1] = self.prev_time - t
  table.insert(self.time, c, a - self.time[c-1])
  table.insert(self.event, c, e)
  self.step = self.step + 1
  self.count = self.count + 1
  self.end_point = self.count
  --]]

key1_hold = false
key1_hold_and_modify = false

grid.alt = 0
grid.alt_pp = 0
grid.loop_mod = 0

local function crow_flush()
  crow.reset()
  crow.clear()
end

local function crow_init()
  for i = 1,4 do
    crow.output[i].action = "{to(5,0),to(0,0.05)}"
    print("output["..i.."] initialized")
  end
  crow.input[2].mode("change",2,0.1,"rising")
  crow.input[2].change = buff_freeze
end

local lit = {}

function init()

  for i = 1,3 do
    norns.enc.sens(i,2)
  end
  
  grid_p = {}
  arc_p = {}
  midi_p = {}
  
  rec = {}
  rec.state = 1
  rec.clip = 1
  rec.start_point = 1
  rec.end_point = 9
  rec.loop = 1
  rec.clear = 0
  
  params:add_separator("cheat codes params")
  
  params:add_group("collections",4)
  
  params:add_number("collection", "collection", 1,100,1)
  params:add{type = "trigger", id = "load", name = "load", action = loadstate}
  params:add_option("collect_live","collect Live buffers?",{"no","yes"})
  params:add{type = "trigger", id = "save", name = "save", action = savestate}
  
  menu = 1
  
  for i = 1,4 do
    crow.output[i].action = "{to(5,0),to(0,0.05)}"
  end
  crow.count = {}
  crow.count_execute = {}
  for i = 1,3 do
    crow.count[i] = 1
    crow.count_execute[i] = 1
  end

  screen.line_width(1)

  local etap = 0
  local edelta = 1
  local prebpm = 110
  
  clock_counting = 0
  
  grid_pat = {}
  for i = 1,3 do
    grid_pat[i] = pattern_time.new()
    grid_pat[i].process = grid_pattern_execute
    grid_pat[i].tightened_start = 0
    grid_pat[i].auto_snap = 0
    grid_pat[i].quantize = 0
    grid_pat[i].playmode = 1
    grid_pat[i].random_pitch_range = 5
    grid_pat[i].rec_clock_time = 8
  end
  
  quantized_grid_pat = {}
  for i = 1,3 do
    quantized_grid_pat[i] = {}
    quantized_grid_pat[i].clicks = {}
    quantized_grid_pat[i].event = {}
    quantized_grid_pat[i].sub_step = 1
    quantized_grid_pat[i].current_step = grid_pat[i].start_point
  end
  
  step_seq = {}
  for i = 1,3 do
    step_seq[i] = {}
    step_seq[i].active = 1
    step_seq[i].current_step = 1
    step_seq[i].current_pat = nil
    step_seq[i].rate = 1
    step_seq[i].start_point = 1
    step_seq[i].end_point = 16
    step_seq[i].length = (step_seq[i].end_point - step_seq[i].start_point) + 1
    step_seq[i].meta_step = 1
    step_seq[i].meta_duration = 1
    step_seq[i].meta_meta_step = 1
    step_seq[i].held = 0
    for j = 1,16 do
      step_seq[i][j] = {}
      step_seq[i][j].meta_meta_duration = 4
      step_seq[i][j].assigned = 0 --necessary?
      step_seq[i][j].assigned_to = 0
      step_seq[i][j].loop_pattern = 1
    end
    step_seq[i].meta_meta_duration = 4
    step_seq[i].loop_held = 0
  end
  
  function internal_clocking_tightened(bank)
    local current = quantized_grid_pat[bank].current_step
    local sub_step = quantized_grid_pat[bank].sub_step
    if current == 0 then
      current = grid_pat[bank].start_point
    end
    if grid_pat[bank].tightened_start == 1 and grid_pat[bank].count > 0 and current <= grid_pat[bank].end_point and quantized_grid_pat[bank].event[current] ~= nil then
      if quantized_grid_pat[bank].event[current][sub_step] == "something" then
        --print(current, sub_step, "+++")
        if grid_pat[bank].step == 0 then
          grid_pat[bank].step = grid_pat[bank].start_point
        end
        if quantized_grid_pat[bank].current_step == 0 then
          quantized_grid_pat[bank].current_step = grid_pat[bank].start_point
        end
        grid_pattern_execute(grid_pat[bank].event[quantized_grid_pat[bank].current_step])
      elseif quantized_grid_pat[bank].event[current][sub_step] == "nothing" then
        -- nothing!
        if grid_pat[bank].step == 0 then
          grid_pat[bank].step = grid_pat[bank].start_point
        end
        if quantized_grid_pat[bank].current_step == 0 then
          print("if you see this message, tell dan!")
          quantized_grid_pat[bank].current_step = grid_pat[bank].start_point
        end
      elseif quantized_grid_pat[bank].event[current][sub_step] == nil and #quantized_grid_pat[bank].event == grid_pat[bank].end_point then
        print(current.." is nil!")
        table.remove(quantized_grid_pat[bank].event,current)
        grid_pat[bank].end_point = grid_pat[bank].end_point - 1
        quantized_grid_pat[bank].current_step = quantized_grid_pat[bank].current_step + 1
        quantized_grid_pat[bank].sub_step = 1
      elseif quantized_grid_pat[bank].event[current][sub_step] == nil then
        print("skipping bank "..bank..", step "..current..", sub "..sub_step.."...unsure what to do")
        quantized_grid_pat[bank].current_step = quantized_grid_pat[bank].current_step + 1
        quantized_grid_pat[bank].sub_step = 1
      end
      --increase sub_step now
      --if quantized_grid_pat[bank].current_step > #quantized_grid_pat[bank].event or quantized_grid_pat[bank].current_step > #grid_pat[bank].event then
      if quantized_grid_pat[bank].current_step > grid_pat[bank].end_point then
        quantized_grid_pat[bank].current_step = grid_pat[bank].start_point
      end
      if quantized_grid_pat[bank].sub_step == #quantized_grid_pat[bank].event[quantized_grid_pat[bank].current_step] then
        quantized_grid_pat[bank].sub_step = 0
        --if we're at the end of the events in this step, move to the next step
        if grid_pat[bank].step == grid_pat[bank].end_point then
          grid_pat[bank].step = 0
          --quantized_grid_pat[bank].current_step = 0
        end
        --if quantized_grid_pat[bank].current_step == #quantized_grid_pat[bank].event then
        if quantized_grid_pat[bank].current_step == grid_pat[bank].end_point then
          quantized_grid_pat[bank].current_step = grid_pat[bank].start_point - 1
        end
        grid_pat[bank].step = grid_pat[bank].step + 1
        quantized_grid_pat[bank].current_step = quantized_grid_pat[bank].current_step +1
        --quantized_grid_pat[bank].current_step = quantized_grid_pat[bank].current_step + 1
      end
      quantized_grid_pat[bank].sub_step = quantized_grid_pat[bank].sub_step + 1
    else
      quantized_grid_pat[bank].current_step = 1
    end
  end

  params:add_number("bpm", "bpm", 1, 480,80)
  bpm = params:get("bpm")
  params:hide("bpm")
  
  params:add_group("hidden [timing]",6)
  params:hide("hidden [timing]")
  params:add_option("quantize_pads", "(see [timing] menu)", { "no", "yes" })
  params:set_action("quantize_pads", function(x) quantize = x-1 end)
  params:add_option("quantize_pats", "(see [timing] menu)", { "no", "yes" })
  params:set_action("quantize_pats", function(x)
    grid_pat_quantize = x-1
    for i = 1,3 do
      grid_pat[i].quantize = x-1
    end
  end)
  params:add_number("quant_div", "(see [timing] menu)", 1, 5, 4)
  params:add_number("quant_div_pats", "(see [timing] menu)", 1, 5, 4)
  params:add_option("lock_pat", "(see [timing] menu)", {"no", "yes"} )
  params:add{type = "trigger", id = "sync_pat", name = "(see [timing] menu)"}

  params:default()
  
  grid_page = 0
  
  page = {}
  page.main_sel = 1
  page.loops_sel = 0
  page.levels_sel = 0
  page.panning_sel = 1
  page.filtering_sel = 0
  page.arc_sel = 0
  page.delay_sel = 0
  page.time_sel = 1
  page.time_page = {}
  page.time_page_sel = {}
  page.time_scroll = {}
  for i = 1,5 do
    page.time_page[i] = 1
    page.time_page_sel[i] = 1
    page.time_scroll[i] = 1
  end
  page.track_sel = {}
  page.track_page = 1
  page.track_page_section = {}
  for i = 1,4 do
    page.track_sel[i] = 1
    page.track_page_section[i] = 1
  end
  page.track_param_sel = {}
  for i = 1,3 do
    page.track_param_sel[i] = 1
  end
  page.arp_page_sel = 1
  page.arp_param_group = {}
  for i = 1,3 do
    page.arp_param_group[i] = 1
  end
  page.rnd_page = 1
  page.rnd_page_section = 1
  page.rnd_page_sel = {}
  page.rnd_page_edit = {}
  for i = 1,3 do
    page.rnd_page_sel[i] = 1
    page.rnd_page_edit[i] = 1
  end
  
  delay_rates = {2,(7/4),(5/3),(3/2),(4/3),(5/4),(1),(4/5),(3/4),(2/3),(3/5),(4/7),(1/2)}
  delay = {}
  for i = 1,2 do
    delay[i] = {}
    delay[i].id = 7
    delay[i].arc_rate_tracker = 7
    delay[i].arc_rate = 7
    delay[i].rate = delay_rates[7]
    delay[i].start_point = 41 + (30*(i-1))
    delay[i].end_point = delay[i].start_point + 0.5
    delay[i].divisor = 1
  end
  
  index = 0
  
  edit = "all"
  
  start_up.init()
  
  params:add_group("crow utils",2)
  params:hide("crow utils")
  
  params:add{type = "trigger", id = "init_crow", name = "initialize crow", action = crow_init}
  params:add{type = "trigger", id = "clear_crow", name = "(reset/clear crow)", action = crow_flush}

  bank = {}
  reset_all_banks(bank)
  
  params:bang()
  
  selected_coll = 0
  
  --GRID
  selected = {}
  fingers = {}
  counter_four = {}
  counter_three = {}
  counter_two = {}
  for i = 1,3 do
    selected[i] = {}
    selected[i].x = 1 + (5*(i-1))
    selected[i].y = 8
    selected[i].id = 1
    for k = 1,4 do
      fingers[k] = {}
      fingers[k].dt = 1
      fingers[k].t1 = 0
      fingers[k].t = 0
      fingers[k][i] = {}
      fingers[k][i].con = {}
    end
  end

  function record_the_zilchmo(prev,sel,row)
    grid_p[sel] = {}
    grid_p[sel].i = sel
    grid_p[sel].action = "zilchmo"
    grid_p[sel].con = fingers[row][sel].con
    grid_p[sel].row = row
    grid_p[sel].bank = sel
    grid_p[sel].id = selected[sel].id
    grid_p[sel].x = selected[sel].x
    grid_p[sel].y = selected[sel].y
    grid_p[sel].previous_rate = prev
    grid_p[sel].rate = prev
    grid_p[sel].start_point = bank[sel][bank[sel].id].start_point
    grid_p[sel].end_point = bank[sel][bank[sel].id].end_point
    grid_pat[sel]:watch(grid_p[sel])
  end

  counter_four.key_up = metro.init()
  counter_four.key_up.time = 0.05
  counter_four.key_up.count = 1
  counter_four.key_up.event = function()
    local previous_rate = bank[selected_zilchmo_bank][bank[selected_zilchmo_bank].id].rate
    zilchmo(4,selected_zilchmo_bank)
    record_the_zilchmo(previous_rate,selected_zilchmo_bank,4)
  end
  counter_four.key_up:stop()
  counter_three = {}
  counter_three.key_up = metro.init()
  counter_three.key_up.time = 0.05
  counter_three.key_up.count = 1
  counter_three.key_up.event = function()
    zilchmo(3,selected_zilchmo_bank)
  end
  counter_three.key_up:stop()
  counter_two = {}
  counter_two.key_up = metro.init()
  counter_two.key_up.time = 0.05
  counter_two.key_up.count = 1
  counter_two.key_up.event = function()
    zilchmo(2,selected_zilchmo_bank)
  end
  counter_two.key_up:stop()
  
  quantized_grid_pat = {}
  for i = 1,3 do
    quantized_grid_pat[i] = {}
    quantized_grid_pat[i].clicks = {}
    quantized_grid_pat[i].event = {}
    quantized_grid_pat[i].sub_step = 1
    quantized_grid_pat[i].current_step = 1
  end
  
  arc_pat = {}
  for i = 1,3 do
    arc_pat[i] = pattern_time.new()
    if i ~=4 then
      arc_pat[i].process = arc_pattern_execute
    else
      arc_pat[i].process = arc_delay_pattern_execute
    end
  end
  
  --if g then grid_redraw() end
  --/GRID
  for i=1,3 do
    cheat(i,bank[i].id)
  end
  
  hardware_redraw = metro.init(
    function()
      grid_redraw()
      arc_redraw()
    end
    , 0.02, -1)
  hardware_redraw:start()
  
  softcut.poll_start_phase()
  
  filter_types = {"lp", "hp", "bp", "lp/hp"}
  
  rec_state_watcher = metro.init()
  rec_state_watcher.time = 0.05
  rec_state_watcher.event = function()
    if rec.loop == 0 then
      if rec.state == 1 then
        if rec.end_point < poll_position_new[1] +0.015 then
          rec.state = 0
          rec_state_watcher:stop()
          redraw()
        end
      end
    end
  end
  rec_state_watcher.count = -1
  
  already_saved()
  
  params:add_group("OSC setup",3)
  params:add_text("osc_IP", "OSC IP", "192.168.")
  params:set_action("osc_IP", function() dest = {tostring(params:get("osc_IP")), tonumber(params:get("osc_port"))} end)
  params:add_text("osc_port", "OSC port", "9000")
  params:set_action("osc_port", function() dest = {tostring(params:get("osc_IP")), tonumber(params:get("osc_port"))} end)
  params:add{type = "trigger", id = "refresh_osc", name = "refresh OSC [K3]", action = function()
    params:set("osc_IP","none")
    params:set("osc_port","none")
    osc_communication = false
  end}

  params:add_group("MIDI setup",9)
  params:add_option("midi_control_enabled", "enable MIDI control?", {"no","yes"},1)
  params:set_action("midi_control_enabled", function() midi_state_save() end)
  params:add_option("midi_control_device", "MIDI control device",{"port 1", "port 2", "port 3", "port 4"},1)
  params:set_action("midi_control_device", function(x) m = midi.connect(x) midi_state_save() end)
  params:add_option("midi_echo_enabled", "enable MIDI echo?", {"no","yes"},1)
  params:set_action("midi_echo_enabled", function() midi_state_save() end)
  local bank_names = {"(a)","(b)","(c)"}
  for i = 1,3 do
    params:add_number("bank_"..i.."_midi_channel", "bank "..bank_names[i].." pad channel:",1,16,i)
    params:set_action("bank_"..i.."_midi_channel", function() midi_state_save() end)
  end
  for i = 1,3 do
    params:add_number("bank_"..i.."_pad_midi_base", "bank "..bank_names[i].." pad midi base:",0,111,53)
    params:set_action("bank_"..i.."_pad_midi_base", function() midi_state_save() end)
  end

  crow_init()
  
  task_id = clock.run(globally_clocked)
  pad_press_quant = clock.run(pad_clock)
  random_rec = clock.run(random_rec_clock)
  
  if params:string("clock_source") == "internal" then
    clock.internal.start(bpm)
  end

  midi_dev = {}
  for j = 1,4 do
    midi_dev[j] = midi.connect(j)
    midi_dev[j].event = function(data)
      local d = midi.to_msg(data)
      if params:get("midi_control_enabled") == 2 and j == params:get("midi_control_device") then
        for i = 1,3 do
          if d.ch == params:get("bank_"..i.."_midi_channel") then
            if d.note ~= nil then
              if d.note >= params:get("bank_"..i.."_pad_midi_base") and d.note <= params:get("bank_"..i.."_pad_midi_base") + (not midi_alt and 15 or 22) then
                if not midi_alt then
                  if d.type == "note_on" then
                    midi_cheat(d.note-(params:get("bank_"..i.."_pad_midi_base")-1), i)
                    if midi_pat[i].rec == 1 and midi_pat[i].count == 0 then
                      if midi_pat[i].playmode == 2 then
                        --clock.run(synced_pattern_record,midi_pat[i]) -- i think we'll want this in a separate function...
                      end
                    end
                    midi_pattern_watch(i, d.note-(params:get("bank_"..i.."_pad_midi_base")-1))
                    if menu == 9 then
                      page.arp_page_sel = i
                      arps.momentary(i, bank[i].id, "on")
                    end
                  elseif d.type == "note_off" then
                    if menu == 9 then
                      if not arp[i].hold and page.arp_page_sel == i  then
                        local targeted_pad = d.note-(params:get("bank_"..i.."_pad_midi_base")-1)
                        arps.momentary(i, targeted_pad, "off")
                      end
                    end
                  end
                elseif midi_alt then
                  if d.type == "note_on" then
                    midi_zilch(d.note-(params:get("bank_"..i.."_pad_midi_base")-1), i)
                  end
                end
              elseif d.note == params:get("bank_"..i.."_pad_midi_base") + 23 then
                if d.type == "note_on" then
                  midi_alt = true
                else
                  midi_alt = false
                end
              end
            end
            if d.type == "cc" then
              local pad = bank[i][bank[i].id]
              if d.cc == 1 then
                --local lo = 1+(8*(pad.clip-1))
                local lo = pad.mode == 1 and live[pad.clip].min or clip[pad.clip].min
                local hi = pad.end_point-0.1
                --local max = 9+(8*(pad.clip-1))
                local max = pad.mode == 1 and live[pad.clip].max or clip[pad.clip].max
                pad.start_point = util.clamp(util.linlin(0,127,lo,max,d.val),lo,hi)
                softcut.loop_start(i+1,pad.start_point)
              elseif d.cc == 2 then
                local lo = pad.start_point+0.1
                --local hi = 9+(8*(pad.clip-1))
                local hi = pad.mode == 1 and live[pad.clip].max or clip[pad.clip].max
                --local min = 1+(8*(pad.clip-1))
                local min = pad.mode == 1 and live[pad.clip].min or clip[pad.clip].min
                pad.end_point = util.clamp(util.linlin(0,127,min,hi,d.val),lo,hi)
                softcut.loop_end(i+1,pad.end_point)
              elseif d.cc == 3 then
                for j = 1,16 do
                  local target = bank[i][j]
                  if slew_counter[i] ~= nil then
                    slew_counter[i].prev_tilt = target.tilt
                  end
                  target.tilt = util.linlin(0,127,-1,1,d.val)
                end
                slew_filter(i,slew_counter[i].prev_tilt,pad.tilt,pad.q,pad.q,15)
              elseif d.cc == 4 then
                pad.level = util.linlin(0,127,0,2,d.val)
                softcut.level(i+1,pad.level)
              end
            end
          end
        end
      end
    end
  end

  midi_alt = false

  function midi_redraw(target)
    local pad = bank[target][bank[target].id]
    local duration = pad.mode == 1 and 8 or clip[pad.clip].sample_length
    local min = pad.mode == 1 and live[pad.clip].min or clip[pad.clip].min
    local max = pad.mode == 1 and live[pad.clip].max or clip[pad.clip].max
    local start_to_cc = util.round(util.linlin(min,max,0,127,pad.start_point))
    midi_dev[params:get("midi_control_device")]:cc(1,start_to_cc,params:get("bank_"..target.."_midi_channel"))
    local end_to_cc = util.round(util.linlin(min,max,0,127,pad.end_point))
    midi_dev[params:get("midi_control_device")]:cc(2,end_to_cc,params:get("bank_"..target.."_midi_channel"))
    local tilt_to_cc = util.round(util.linlin(-1,1,0,127,pad.tilt))
    midi_dev[params:get("midi_control_device")]:cc(3,tilt_to_cc,params:get("bank_"..target.."_midi_channel"))
    local level_to_cc = util.round(util.linlin(0,2,0,127,pad.level))
    midi_dev[params:get("midi_control_device")]:cc(4,level_to_cc,params:get("bank_"..target.."_midi_channel"))
  end


  midi_pat = {}
  for i = 1,3 do
    midi_pat[i] = pattern_time.new()
    midi_pat[i].process = midi_pattern_execute
    midi_pat[i].tightened_start = 0
    midi_pat[i].auto_snap = 0
    midi_pat[i].quantize = 0
    midi_pat[i].playmode = 1
    midi_pat[i].random_pitch_range = 5
    midi_pat[i].clock_time = 4
    midi_pat[i].rec_clock_time = 8
    midi_pat[i].first_touch = false
  end

  for i = 1,3 do
    arps.init(i)
  end

  for i = 1,3 do
    rnd.init(i)
  end

  rytm.init()

  if g then grid_redraw() end
  
  metro_midi_state_restore = metro.init(midi_state_restore, 0.1, 1)
  metro_midi_state_restore:start()

end

---

function midi_pattern_watch(target,note)
  if note ~= "pause" then
    midi_p[target] = {}
    midi_p[target].note = note
    midi_p[target].target = target
    midi_pat[target]:watch(midi_p[target])
  else
    midi_pat[target]:watch("pause")
  end
end

function grid_pattern_watch(target,pad)
  if pad ~= "pause" then
    grid_p[target] = {}
    grid_p[target].action = "pads"
    grid_p[target].i = target
    grid_p[target].id = selected[target].id
    grid_p[target].x = selected[target].x
    grid_p[target].y = selected[target].y
    grid_p[target].rate = bank[target][bank[target].id].rate
    grid_p[target].start_point = bank[target][bank[target].id].start_point
    grid_p[target].end_point = bank[target][bank[target].id].end_point
    grid_p[target].rate_adjusted = false
    grid_p[target].loop = bank[target][bank[target].id].loop
    grid_p[target].pause = bank[target][bank[target].id].pause
    grid_p[target].mode = bank[target][bank[target].id].mode
    grid_p[target].clip = bank[target][bank[target].id].clip
    --[[
    if grid_pat[target].rec == 1 and grid_pat[target].count == 0 then
      print("grid happening")
      clock.run(synced_pattern_record,grid_pat[target])
    end
    --]]
    grid_pat[target]:watch(grid_p[target])
  else
    grid_pat[target]:watch("pause")
  end
end

function midi_pattern_execute(entry)
  if entry ~= nil then
    if entry ~= "pause" then
      midi_cheat(entry.note, entry.target)
    end
  end
end

function midi_cheat(note,target)
  bank[target].id = note
  --if menu ~= 9 then
  if not arp[target].playing then
    selected[target].x = (5*(target-1)+1)+(math.ceil(bank[target].id/4)-1)
    if (bank[target].id % 4) ~= 0 then
      selected[target].y = 9-(bank[target].id % 4)
    else
      selected[target].y = 5
    end
    cheat(target,bank[target].id)
    if params:get("midi_echo_enabled") == 2 then
      midi_redraw(target)
    end
  end
end

function midi_zilch(note,target)
  if note == 1 or note == 2 then
    for i = (note == 1 and bank[target].id or 1), (note == 1 and bank[target].id or 16) do
      rightangleslice.actions[4]['134'][1](bank[target][i])
      rightangleslice.actions[4]['134'][2](bank[target][i],target)
    end
  elseif note == 3 or note == 4 then
    for i = (note == 3 and bank[target].id or 1), (note == 3 and bank[target].id or 16) do
      rightangleslice.actions[4]['14'][1](bank[target][i])
      rightangleslice.actions[4]['14'][2](bank[target][i],target)
    end
  elseif note == 5 or note == 6 then
    for i = (note == 5 and bank[target].id or 1), (note == 5 and bank[target].id or 16) do
      rightangleslice.actions[4]['124'][1](bank[target][i])
      rightangleslice.actions[4]['124'][2](bank[target][i],target)
    end
  elseif note == 8 or note == 9 then
    for i = (note == 8 and bank[target].id or 1), (note == 8 and bank[target].id or 16) do
      bank[target][i].loop = not bank[target][i].loop
    end
    softcut.loop(target+1,bank[target][bank[target].id].loop == true and 1 or 0)
  elseif note == 11 then
    toggle_buffer(rec.clip)
  elseif note == 13 or note == 14 then
    for i = (note == 13 and bank[target].id or 1), (note == 13 and bank[target].id or 16) do
      rightangleslice.actions[4]['12'][1](bank[target][i])
      rightangleslice.actions[4]['12'][2](bank[target][i],target)
    end
  elseif note == 15 or note == 16 then
    for i = (note == 15 and bank[target].id or 1), (note == 15 and bank[target].id or 16) do
      rightangleslice.actions[4]['23'][1](bank[target][i])
      rightangleslice.actions[4]['23'][2](bank[target][i],target)
    end
  elseif note == 17 or note == 18 then
    for i = (note == 17 and bank[target].id or 1), (note == 17 and bank[target].id or 16) do
      rightangleslice.actions[4]['34'][1](bank[target][i])
      rightangleslice.actions[4]['34'][2](bank[target][i],target)
    end
  elseif note == 21 then
    sixteen_slices(target)
  elseif note == 23 then
    buff_flush()
  end

  if params:get("midi_echo_enabled") == 2 then
    midi_redraw(target)
  end

end

function start_synced_loop(target)
  if target.count > 0 then
    --pattern_length_to_bars(target)
    target.clock = clock.run(synced_loop, target)
  end
end

function synced_loop(target, state)
  --clock.sleep((60/bpm)*target.rec_clock_time)

  clock.sync(1)
  if state == "restart" then
    target:start()
  end
  --^ would this be problematic?

  --clock.sync(4)
  while true do
    --print("syncing to..."..target.clock_time, clock.get_beats())
    clock.sync(target.clock_time)
    local overdub_flag = target.overdub
    target:stop()
    if overdub_flag == 1 then
      target.overdub = 1
    end
    target:start()
  end
end

function alt_synced_loop(target,state)
  if state == "restart" then
    clock.sync(params:get("launch_quantization") == 1 and 1 or 4)
    print("restarting")
  end
  target:start()
  target.synced_loop_runner = 1
  print("alt_synced")
  while true do
    clock.sync(1/4)
    if target.synced_loop_runner == target.rec_clock_time * 4 then
      print(clock.get_beats(), target.synced_loop_runner)
      local overdub_flag = target.overdub
      target:stop()
      if overdub_flag == 1 then
        target.overdub = 1
      end
      target:start()
      target.synced_loop_runner = 1
    else
      target.synced_loop_runner =  target.synced_loop_runner + 1
    end
  end
end

function stop_pattern(target)
  if target.clock ~= nil then
    clock.cancel(target.clock)
  end
  target.clock = nil
  target:stop()
end

function start_pattern(target)
  print("new start")
  if target.playmode == 2 then
    target.clock = clock.run(alt_synced_loop, target, "restart")
  else
    target:start()
  end
end

function synced_record_start(target,i)
  --midi_pat[i].sync_hold = true
  target.sync_hold = true
  clock.sync(4)
  --midi_pat[i]:rec_start()
  target:rec_start()
  --midi_pat[i].sync_hold = false
  target.sync_hold = false
  if target == midi_pat[i] then
    midi_pattern_watch(i, "pause")
  elseif target == grid_pat[i] then
    grid_pattern_watch(i, "pause")
  end
  clock.run(synced_pattern_record,target)
end

function synced_pattern_record(target)
  clock.sleep((60/bpm)*target.rec_clock_time)
  if target.rec_clock ~= nil then
    target:rec_stop()
    -- if target is a grid pat, should do all the grid pat thing:
    --[[
      midi_clock_linearize(i)
      if grid_pat[i].auto_snap == 1 then
        print("auto-snap")
        snap_to_bars(i,how_many_bars(i))
      end
      grid_pat[i]:start()
      grid_pat[i].loop = 1
    --]]
    pattern_length_to_bars(target, "destructive")
    if target.time[1] ~= nil and target.time[1] < (60/bpm)/4 and target.event[1] == "pause" then
      print("we could lose the first event..."..target.count, target.end_point)
      local butts = 0
      for i = 1,target.count do
        butts = butts + target.time[i]
      end
      print(butts)
      target.time[2] = target.time[2] + target.time[1]
      target.time_beats[2] = target.time_beats[2] + target.time_beats[1]
      table.remove(target.event,1)
      table.remove(target.time,1)
      table.remove(target.time_beats,1)
      target.count = #target.event
      target.end_point = target.count
      print(target.count, target.end_point)
      for i = 1,target.count do
        target:calculate_quantum(i)
      end
    end
    if target.count > 0 then -- just in case the recording was canceled...
      --target:start()
      print("started first run..."..clock.get_beats())
      --target.clock = clock.run(synced_loop, target)
      target.clock = clock.run(alt_synced_loop, target)
    end
  else
    print("clock got canceled already, not going to restart it")
  end
end

function quantize_pattern_times(target, resolution)
  local goal = clock.get_beat_sec()/4
  local adjusted = nil
  for i = 1,target.count do
    target.quantum[i]= util.round(target.time[i] / goal)
    print("quantizes to "..target.quantum[i].." sixteenth notes")
    --[[
    if target.quantum[i] == 0 then
      table.remove(target.event,i)
      table.remove(target.time,i)
      table.remove(target.quantum,i)
    end
    --]]
  end
end

--[[
function try_this(target)
  clock.sync(4)
  target.quant_clock = clock.run(quantized_advance,target)
  target.runner = 1
end

function quantized_advance(target)
  while true do
    if target.count > 0 then
      local step = target.step
      if target.runner == 1 then
        midi_pattern_execute(target.event[step])
      end
      clock.sync(1/4)
      target.runner = target.runner + 1
      if target.runner > target.quantum[step]*4 then
        target.step = target.step + 1
        target.runner = 1
      end
      if target.step > target.end_point then
        target.step = target.start_point
        target.runner = 1
      end
    end
  end
end
--]]

function pattern_length_to_bars(target, style)
  if target.rec == 0 and target.count > 0 then 
    local total_time = 0
    for i = target.start_point,target.end_point do
      total_time = total_time + target.time[i]
    end
    local clean_bars_from_time = util.round(total_time/((60/bpm)*4),0.25)
    local add_time = (((60/bpm)*4) * clean_bars_from_time) - total_time
    print(add_time, clean_bars_from_time)
    if style == "destructive" then
      target.time[#target.event] = target.time[#target.event] + add_time
    end
    target.clock_time = 4 * clean_bars_from_time
  end
end

function shuffle_midi_pat(target)
  pattern = midi_pat[target]
  for i = #pattern.event,2,-1 do
    local j = math.random(i)
    if pattern.event[j] ~= "pause" then
      local original, shuffled = pattern.event[i], pattern.event[j]
      original.note, shuffled.note = shuffled.note, original.note
      original.target, shuffled.target = shuffled.target, original.target
    end
  end
end

function random_midi_pat(target)
  local pattern = midi_pat[target]
  local auto_pat = params:get("random_patterning")
  if pattern.playmode == 2 then
    --clock.sync(1/4)
    --huh????
  end
  local count = auto_pat == 1 and math.random(4,24) or 16
  if pattern.count > 0 or pattern.rec == 1 then
    pattern:rec_stop()
    stop_pattern(pattern)
    pattern:clear()
  end
  for i = 1,count do
    pattern.event[i] = {}
    local constructed = pattern.event[i]
    constructed.note = auto_pat == 1 and math.random(1,16) or snakes[auto_pat-1][i]
    constructed.target = target
    local assigning_pad = bank[target][constructed.note]
    local new_rates = 
    { [1] = math.pow(2,math.random(-3,-1))*((math.random(1,2)*2)-3)
    , [2] = math.pow(2,math.random(-1,1))*((math.random(1,2)*2)-3)
    , [3] = math.pow(2,math.random(1,2))*((math.random(1,2)*2)-3)
    , [4] = math.pow(2,math.random(-2,2))*((math.random(1,2)*2)-3)
    , [5] = assigning_pad.rate
    }
    assigning_pad.rate = new_rates[pattern.random_pitch_range]
    local new_levels = 
    { [0.125] = 1.75
    , [0.25]  = 1.5
    , [0.5]   = 1.25
    , [1.0]   = 1.0
    , [2.0]   = 0.75
    , [4.0]   = 0.5
    }
    assigning_pad.level = new_levels[math.abs(assigning_pad.rate)]
    pattern.time[i] = auto_pat == 1 and ((60/bpm) / math.pow(2,math.random(-2,2))) or (60/bpm) / 4
    pattern.time_beats[i] = pattern.time[i] / clock.get_beat_sec()
    pattern:calculate_quantum(i)
  end
  pattern.count = count
  pattern.start_point = 1
  pattern.end_point = count
  pattern_length_to_bars(pattern, "destructive")
  start_pattern(pattern)
end

---

function pad_clock()
  while true do
    clock.sync(1)
    for i = 1,3 do
      cheat_clock_synced(i)
    end
  end
end

function random_rec_clock()
  while true do
    local lbr = {1,2,4}
    local rler = rec_loop_enc_resolution
    local rec_distance = rec.end_point - rec.start_point
    local bar_count = params:get("rec_loop_enc_resolution") > 2 and (((rec_distance)/(1/rler)) / (rler))*(2*lbr[params:get("live_buff_rate")]) or 1/4
    clock.sync(params:get("rec_loop") == 1 and 4 or bar_count)
    local random_rec_prob = params:get("random_rec_clock_prob")
    if random_rec_prob > 0 then
      local random_rec_comp = math.random(0,100)
      if random_rec_comp < random_rec_prob then
        if params:get("rec_loop") == 1 then
          buff_freeze()
        elseif params:get("rec_loop") == 2 then
          if not rec_state_watcher.is_running then
            softcut.position(1,rec.start_point+0.1)
            softcut.rec_level(1,1)
            rec.state = 1
            rec_state_watcher:start()
            if rec.clear == 1 then rec.clear = 0 end
          end
        end
      end
    end
  end
end

function one_shot_clock()
  if rec.state == 1 and rec_state_watcher.is_running then
    rec_state_watcher:stop()
  end
  if params:get("one_shot_clock_div") < 3 then
    local divs = {1,4}
    local rate = divs[params:get("one_shot_clock_div")]
    clock.sync(rate)
  end
  softcut.position(1,rec.start_point+0.1)
  softcut.rec_level(1,1)
  rec.state = 1
  rec_state_watcher:start()
  if rec.clear == 1 then rec.clear = 0 end
end

function compare_rec_resolution(x)
  local current_mult = (rec.end_point - rec.start_point) / (1/rec_loop_enc_resolution)
  local resolutions =
    { [1] = 10
    , [2] = 100
    , [3] = 1/((60/bpm)/4)
    , [4] = 1/((60/bpm)/2)
    , [5] = 1/((60/bpm))
    , [6] = (1/((60/bpm)))/2
    , [7] = (1/((60/bpm)))/4
    }
  rec_loop_enc_resolution = resolutions[x]
  if x > 2 then
    local lbr = {1,2,4}
    rec.end_point = rec.start_point + (((1/rec_loop_enc_resolution)*current_mult)/lbr[params:get("live_buff_rate")])
    softcut.loop_start(1,rec.start_point)
    softcut.loop_end(1,rec.end_point)
    redraw()
  end
end

function globally_clocked()
  while true do
    clock.sync(1/4)
    if menu == 7 then
      redraw()
    end
    grid_redraw()
    update_tempo()
    step_sequence()
    for i = 1,3 do
      if grid_pat[i].led == nil then grid_pat[i].led = 0 end
      if grid_pat[i].rec == 1 then
        local blink = math.fmod(clock.get_beats(),1)
        if blink <= 0.25 then
          blink = 1
        elseif blink <= 0.5 then
          blink = 2
        elseif blink <= 0.75 then
          blink = 3
        else
          blink = 4
        end
        if blink == 1 then
          grid_pat[i].led = 1
        else
          grid_pat[i].led = 0
        end
      end
    end
    for i = 1,3 do
      if grid_pat[i].tightened_start == 1 then
        internal_clocking_tightened(i)
      end
    end
  end
end

osc_in = function(path, args, from)
  if osc_communication ~= true then
    params:set("osc_IP",from[1])
    params:set("osc_port",from[2])
    osc_communication = true
  end
  for i = 1,3 do
    if path == "/pad_sel_"..i then
      if args[1] ~= 0 then
        bank[i].id = util.round(args[1])
        cheat(i,bank[i].id)
        redraw()
        osc_redraw(i)
      end
    elseif path == "/randomize_this_bank_"..i then
      random_grid_pat(i,3)
      for j = 2,16 do
        bank[i][j].start_point = (math.random(10,30)/10)+(8*(bank[i][j].clip-1))
        bank[i][j].end_point = bank[i][j].start_point + (math.random(10,60)/10)
        bank[i][j].pan = math.random(-100,100)/100
      end
      grid_pat[i]:rec_stop()
      grid_pat[i]:stop()
      grid_pat[i].tightened_start = 0

    elseif path == "/rate_"..i then
      for j = 7,12 do
        osc.send(dest, "/rate_"..i.."_"..j, {0})
      end
      if params:get("rate "..i) > 6 then
        params:set("rate "..i, util.round(args[1]))
        osc.send(dest, "/rate_"..i.."_"..params:get("rate "..i), {1})
      else
        params:set("rate "..i, math.abs(util.round(args[1])-13))
        osc.send(dest, "/rate_"..i.."_"..math.abs(params:get("rate "..i)-13), {1})
      end
      osc.send(dest, "/rate_"..i, {params:get("rate "..i)})
    elseif path == "/rate_rev_"..i then
      params:set("rate "..i, math.abs(params:get("rate "..i)-13))
    elseif path == "/pad_loop_single_"..i then
      if args[1] == 1 then
        bank[i][bank[i].id].loop = true
        softcut.loop(i+1,1)
      elseif args[1] == 0 then
        bank[i][bank[i].id].loop = false
        softcut.loop(i+1,0)
      end
    elseif path == "/pad_loop_all_"..i then
      if args[1] == 1 then
        for j = 1,16 do
          bank[i][j].loop = true
        end
      elseif args[1] == 0 then
        for j = 1,16 do
          bank[i][j].loop = false
        end
      end
      softcut.loop(i+1,bank[i][bank[i].id].loop == true and 1 or 0)
      local loop_to_osc = nil
      if bank[i][bank[i].id].loop == false then
        loop_to_osc = 0
      else
        loop_to_osc = 1
      end
      osc.send(dest, "/pad_loop_single_"..i, {loop_to_osc})
    elseif path == "/pad_start_"..i then
      params:set("start point "..i, util.round(args[1]))
      osc.send(dest, "/pad_start_display_"..i, {tonumber(string.format("%.2f",bank[i][bank[i].id].start_point - (8*(bank[i][bank[i].id].clip-1))))})
    elseif path == "/pad_end_"..i then
      params:set("end point "..i, util.round(args[1]))
      osc.send(dest, "/pad_end_display_"..i, {tonumber(string.format("%.2f",bank[i][bank[i].id].end_point - (8*(bank[i][bank[i].id].clip-1))))})
    elseif path == "/pad_window_"..i then
      local current_difference = (bank[i][bank[i].id].end_point - bank[i][bank[i].id].start_point)
      if bank[i][bank[i].id].start_point + current_difference <= (9+(8*(bank[i][bank[i].id].clip-1))) then
        bank[i][bank[i].id].start_point = util.clamp(bank[i][bank[i].id].start_point + args[1]/25,(1+(8*(bank[i][bank[i].id].clip-1))),(9+(8*(bank[i][bank[i].id].clip-1))))
        bank[i][bank[i].id].end_point = bank[i][bank[i].id].start_point + current_difference
      else
        bank[i][bank[i].id].end_point = (9+(8*(bank[i][bank[i].id].clip-1)))
        bank[i][bank[i].id].start_point = bank[i][bank[i].id].end_point - current_difference
      end
      softcut.loop_start(i+1,bank[i][bank[i].id].start_point)
      softcut.loop_end(i+1,bank[i][bank[i].id].end_point)
      osc.send(dest, "/pad_start_"..i, {(bank[i][bank[i].id].start_point*100)-((8*(bank[i][bank[i].id].clip-1))*100)})
      osc.send(dest, "/pad_start_display_"..i, {tonumber(string.format("%.2f",(bank[i][bank[i].id].start_point) - (8*(bank[i][bank[i].id].clip-1))))})
      osc.send(dest, "/pad_end_"..i, {(bank[i][bank[i].id].end_point*100)-((8*(bank[i][bank[i].id].clip-1))*100)})
      osc.send(dest, "/pad_end_display_"..i, {tonumber(string.format("%.2f",bank[i][bank[i].id].end_point - (8*(bank[i][bank[i].id].clip-1))))})
    elseif path == "/rand_pat_"..i then
      random_grid_pat(i,3)
    elseif path == "/stop_pat_"..i then
      if grid_pat[i].play == 1 then
        grid_pat[i]:stop()
      elseif grid_pat[i].tightened_start == 1 then
        grid_pat[i].tightened_start = 0
        grid_pat[i].step = grid_pat[i].start_point
        quantized_grid_pat[i].current_step = grid_pat[i].start_point
        quantized_grid_pat[i].sub_step = 1
      end
    elseif path == "/start_pat_"..i then
      if grid_pat[i].quantize == 0 then
        if grid_pat[i].play == 0 then
          --grid_pat[i]:start()
          start_pattern(grid_pat[i])
          osc.send(dest, "/start_pat_"..i, {1})
        else
          grid_pat[i]:stop()
          osc.send(dest, "/start_pat_"..i, {0})
        end
      else
        better_grid_pat_q_clock(i)
      end
    elseif path == "/pad_loop_slice_"..i then
      local bpm_to_sixteenth = (60/bpm)/4
      bank[i][bank[i].id].end_point = bank[i][bank[i].id].start_point + bpm_to_sixteenth
      softcut.loop_end(i+1,bank[i][bank[i].id].end_point)
      osc_redraw(i)
    elseif path == "/pad_loop_double_"..i then
      local which_pad = bank[i].id
      local double = (bank[i][which_pad].end_point - bank[i][which_pad].start_point)*2
      local maximum_val = 9+(8*(bank[i][which_pad].clip-1))
      local minimum_val = 1+(8*(bank[i][which_pad].clip-1))
      if bank[i][which_pad].start_point - double >= minimum_val then
        bank[i][which_pad].start_point = bank[i][which_pad].end_point - double
      elseif bank[i][which_pad].start_point - double < minimum_val then
        if bank[i][which_pad].end_point + double < maximum_val then
          bank[i][which_pad].end_point = bank[i][which_pad].end_point + double
        end
      end
      softcut.loop_start(i+1,bank[i][which_pad].start_point)
      softcut.loop_end(i+1,bank[i][which_pad].end_point)
      osc_redraw(i)
    elseif path == "/pad_loop_halve_"..i then
      local which_pad = bank[i].id
      local halve = ((bank[i][which_pad].end_point - bank[i][which_pad].start_point)/2)/2
      bank[i][which_pad].start_point = bank[i][which_pad].start_point + halve
      bank[i][which_pad].end_point = bank[i][which_pad].end_point - halve
      softcut.loop_start(i+1,bank[i][bank[i].id].start_point)
      softcut.loop_end(i+1,bank[i][bank[i].id].end_point)
      osc_redraw(i)
    elseif path == "/pad_loop_rand_"..i then
      bank[i][bank[i].id].start_point = (math.random(10,75)/10)+(8*(bank[i][bank[i].id].clip-1))
      bank[i][bank[i].id].end_point = bank[i][bank[i].id].start_point + (math.random(1,15)/10)
      softcut.loop_start(i+1,bank[i][bank[i].id].start_point)
      softcut.loop_end(i+1,bank[i][bank[i].id].end_point)
      osc_redraw(i)
    elseif path == "/rec_clip_"..i then

      toggle_buffer(i)
      
      --[[
      softcut.level_slew_time(1,0.5)
      softcut.fade_time(1,0.01)
      local old_clip = rec.clip
        
      for go = 1,2 do
        local old_min = (1+(8*(rec.clip-1)))
        local old_max = (9+(8*(rec.clip-1)))
        local old_range = old_min - old_max
        rec.clip = i
        local new_min = (1+(8*(rec.clip-1)))
        local new_max = (9+(8*(rec.clip-1)))
        local new_range = new_max - new_min
        local current_difference = (rec.end_point - rec.start_point)
        rec.start_point = (((rec.start_point - old_min) * new_range) / old_range) + new_min
        rec.end_point = rec.start_point + current_difference
      end
      --]]
      
      for j = 1,3 do
        if j ~= i then
          osc.send(dest, "/buffer_LED_"..j, {0})
        end
      end
      
      osc.send(dest, "/buffer_LED_"..i, {1})
        
      --[[
      if rec.loop == 0 and grid.alt == 0 then
        clock.run(one_shot_clock)
      end
      
        
      softcut.loop_start(1,rec.start_point)
      softcut.loop_end(1,rec.end_point-0.01)
      if rec.loop == 1 then
        if old_clip ~= rec.clip then rec.state = 0 end
        buff_freeze()
        if rec.clear == 1 then
          rec.clear = 0
        end
      end
      --]]
      
      local rec_state_to_osc = nil
      if rec.state == 0 then
        rec_state_to_osc = "not recording"
      else
        rec_state_to_osc = "recording"
      end
      osc.send(dest, "/buffer_state", {rec_state_to_osc})

    end
  end
end

osc.event = osc_in

function osc_redraw(i)
  local loop_to_osc = nil
  if bank[i][bank[i].id].loop == false then
    loop_to_osc = 0
  else
    loop_to_osc = 1
  end
  osc.send(dest, "/pad_loop_single_"..i, {loop_to_osc})
  osc.send(dest, "/rate_"..i, {params:get("rate "..i)})
  for j = 7,12 do
    osc.send(dest, "/rate_"..i.."_"..j, {0})
  end
  if params:get("rate "..i) > 6 then
    osc.send(dest, "/rate_"..i.."_"..params:get("rate "..i), {1})
    osc.send(dest, "/rate_rev_"..i,{0})
  else
    osc.send(dest, "/rate_"..i.."_"..math.abs(params:get("rate "..i)-13), {1})
    osc.send(dest, "/rate_rev_"..i,{1})
  end
  osc.send(dest, "/pad_start_"..i, {(bank[i][bank[i].id].start_point*100)-((8*(bank[i][bank[i].id].clip-1))*100)})
  osc.send(dest, "/pad_start_display_"..i, {tonumber(string.format("%.2f",(bank[i][bank[i].id].start_point) - (8*(bank[i][bank[i].id].clip-1))))})
  osc.send(dest, "/pad_end_"..i, {(bank[i][bank[i].id].end_point*100)-((8*(bank[i][bank[i].id].clip-1))*100)})
  osc.send(dest, "/pad_end_display_"..i, {tonumber(string.format("%.2f",bank[i][bank[i].id].end_point - (8*(bank[i][bank[i].id].clip-1))))})
  for j = 1,16 do
    osc.send(dest, "/pad_sel_"..i.."_"..j, {0})
  end
  osc.send(dest, "/pad_sel_"..i.."_"..bank[i].id, {1})
  local rec_state_to_osc = nil
  if rec.state == 0 then
    rec_state_to_osc = "not recording"
  else
    rec_state_to_osc = "recording"
  end
  osc.send(dest, "/buffer_state", {rec_state_to_osc})
  for j = 1,3 do
    if rec.clip ~= j then
      osc.send(dest, "/buffer_LED_"..j, {0})
    else
      osc.send(dest, "/buffer_LED_"..rec.clip, {1})
    end
  end
end

poll_position_new = {}

phase = function(n, x)
  poll_position_new[n] = x
  if menu == 2 then
    redraw()
  end
end

local tap = 0
local deltatap = 1

function update_tempo()
  local pre_bpm = bpm
  params:set("bpm", util.round(clock.get_tempo()))
  bpm = params:get("bpm") -- FIXME this is where the global bpm is defined
  local t = params:get("bpm")
  local d = params:get("quant_div")
  local d_pat = params:get("quant_div_pats")
  local interval = (60/t) / d
  local interval_pats = (60/t) / d_pat
  if pre_bpm ~= bpm then
    compare_rec_resolution(params:get("rec_loop_enc_resolution"))
    if math.abs(pre_bpm - bpm) >= 1 then
      --print("a change in time!")
    end
  end
  for i = 1,3 do
    --quantizer[i].time = interval
    --grid_pat_quantizer[i].time = interval_pats
  end
end

function rec_count()
  rec_time = rec_time + 0.01
end

function step_sequence()
  for i = 1,3 do
    if step_seq[i].active == 1 then
      step_seq[i].meta_step = step_seq[i].meta_step + 1
      if step_seq[i].meta_step > step_seq[i].meta_duration then step_seq[i].meta_step = 1 end
      if step_seq[i].meta_step == 1 then
        step_seq[i].meta_meta_step = step_seq[i].meta_meta_step + 1
        if step_seq[i].meta_meta_step > step_seq[i][step_seq[i].current_step].meta_meta_duration then step_seq[i].meta_meta_step = 1 end
        if step_seq[i].meta_meta_step == 1 then
          step_seq[i].current_step = step_seq[i].current_step + 1
          if step_seq[i].current_step > step_seq[i].end_point then step_seq[i].current_step = step_seq[i].start_point end
          local current = step_seq[i].current_step
          if grid_pat[i].rec == 0 and step_seq[i][current].assigned_to ~= 0 then
            pattern_saver[i].load_slot = step_seq[i][current].assigned_to
            test_load(step_seq[i][current].assigned_to+((i-1)*8),i)
            grid_pat[i].loop = step_seq[i][current].loop_pattern
          end
        end
      end
    end
  end
end

function sixteen_slices(x)
  local s_p = rec.start_point
  local e_p = rec.end_point
  local distance = e_p-s_p
  local b = bank[x]
  local pad = b.focus_hold and b.focus_pad or b.id
  local function map_em(i)
    b[i].start_point = s_p+((distance/16) * (i-1))
    b[i].end_point = s_p+((distance/16) * (i))
    b[i].clip = rec.clip
  end
  if not b.focus_hold then
    for i = 1,16 do
      map_em(i)
    end
  else
    map_em(pad)
  end
  if b[b.id].loop == true then
    cheat(x,b.id)
  end
end

function rec_to_pad(b)
  local s_p = rec.start_point
  local e_p = rec.end_point
  local distance = e_p-s_p
  bank[b][bank[b].id].start_point = s_p+((distance/16) * (bank[b].id-1))
  bank[b][bank[b].id].end_point = s_p+((distance/16) * (bank[b].id))
  bank[b][bank[b].id].clip = rec.clip
  if bank[b][bank[b].id].loop == true then
    cheat(b,bank[b].id)
  end
end

function pad_to_rec(b)
  local pad = bank[b][bank[b].id]
  local s_p = pad.start_point-(8*(pad.clip-1))
  local e_p = pad.end_point-(8*(pad.clip-1))
  rec.start_point = s_p+(8*(rec.clip-1))
  rec.end_point = e_p+(8*(rec.clip-1))
  softcut.loop_start(1,rec.start_point)
  softcut.loop_end(1,rec.end_point-0.01)
  softcut.position(1,rec.start_point)
end

function reset_all_banks( banks )
  cross_filter = {} -- TODO put into the banks
  for i = 1,3 do
    banks[i] = {}
    local b = banks[i] -- alias
    b.id = 1 -- currently playing pad_id
    b.ext_clock = 1
    b.focus_hold = false
    b.focus_pad = 1
    b.random_mode = 3
    b.crow_execute = 1
    b.snap_to_bars = 1
    b.quantize_press = 0
    b.quantize_press_div = 1
    b.alt_lock = false
    for k = 1,16 do
-- TODO suggest nesting tables for delay,filter,tilt etc
      b[k] = {}
      local pad = b[k] --alias
      pad.bank_id           = i -- capture which bank we're in
      pad.pad_id            = k -- capture which pad of 16
      pad.clip              = 1 -- TODO make this a table with length for start/end calculation
      pad.mode              = 1
        -- TODO these are both identical to zilchmos.start_end_default()
      pad.start_point       = 1+((8/16) * (pad.pad_id-1))
      pad.end_point         = 1+((8/16) *  pad.pad_id)
      pad.sample_end        = 8
      pad.rate              = 1.0
      pad.left_delay_time   = 0.5 -- [delay] controls these
      pad.right_delay_time  = 0.5 -- [delay] controls these
      pad.pause             = false
      pad.play_mode         = "latch"
      pad.level             = 1.0
      pad.left_delay_level  = 1
      pad.right_delay_level = 1
      pad.loop              = false
      pad.fifth             = false
      pad.pan               = 0.0
      -- FIXME these are both just 0.5. why compute them? could instead call that fn?
      pad.left_delay_pan    = util.linlin(-1,1,0,1,pad.pan) * pad.left_delay_level
      pad.right_delay_pan   = util.linlin(-1,1,1,0,pad.pan) * pad.right_delay_level
      pad.fc                = 12000
      pad.q                 = 2.0
      pad.lp                = 1.0
      pad.hp                = 0.0
      pad.bp                = 0.0
      pad.fd                = 0.0
      pad.br                = 0.0
      pad.tilt              = 0
      pad.tilt_ease_type    = 1
      pad.tilt_ease_time    = 50
      pad.cf_fc             = 12000
      pad.cf_lp             = 0
      pad.cf_hp             = 0
      pad.cf_dry            = 1
      pad.cf_exp_dry        = 1
      pad.filter_type       = 4
      pad.enveloped         = false
      pad.envelope_time     = 3.0
      pad.clock_resolution  = 4
      pad.offset            = 1.0
      pad.crow_pad_execute  = 1
    end
    cross_filter[i]         = {}
    cross_filter[i].fc      = 12000
    cross_filter[i].lp      = 0
    cross_filter[i].hp      = 0
    cross_filter[i].dry     = 1
    cross_filter[i].exp_dry = 1
    cheat(i,bank[i].id)
  end
end

function find_the_key(t,val)
  for k,v in pairs(t) do
    if v == val then return k end
  end
  return nil
end

function cheat(b,i)
  env_counter[b]:stop()
  local pad = bank[b][i]
  if pad.enveloped then
    env_counter[b].butt = pad.level
    softcut.level(b+1,pad.level)
    softcut.level_cut_cut(b+1,5,util.linlin(-1,1,0,1,pad.pan)*(pad.left_delay_level*pad.level))
    softcut.level_cut_cut(b+1,6,util.linlin(-1,1,1,0,pad.pan)*(pad.right_delay_level*pad.level))
    env_counter[b].time = (pad.envelope_time/(pad.level/0.05))
    env_counter[b]:start()
  else
    softcut.level_slew_time(b+1,0.1)
    softcut.level(b+1,pad.level)
    softcut.level_cut_cut(b+1,5,util.linlin(-1,1,0,1,pad.pan)*(pad.left_delay_level*pad.level))
    softcut.level_cut_cut(b+1,6,util.linlin(-1,1,1,0,pad.pan)*(pad.right_delay_level*pad.level))
  end
  if pad.end_point - pad.start_point < 0.11 then
    pad.end_point = pad.start_point + 0.1
  end
  if pad.end_point == 9 or pad.end_point == 17 or pad.end_point == 25 then
    pad.end_point = pad.end_point-0.01
  end
  softcut.loop_start(b+1,pad.start_point)
  softcut.loop_end(b+1,pad.end_point)
  softcut.buffer(b+1,pad.mode)
  if pad.pause == false then
    softcut.rate(b+1,pad.rate*pad.offset)
  else
    softcut.rate(b+1,0)
  end
  if pad.loop == false then
    softcut.loop(b+1,0)
  else
    softcut.loop(b+1,1)
  end
  softcut.fade_time(b+1,0.01)
  if pad.rate > 0 then
      softcut.position(b+1,pad.start_point+0.05)
  elseif pad.rate < 0 then
      softcut.position(b+1,pad.end_point-0.05)
  end
  if slew_counter[b] ~= nil then
    slew_counter[b].next_tilt = pad.tilt
    slew_counter[b].next_q = pad.q
    if pad.tilt_ease_type == 1 then
      if slew_counter[b].slewedVal ~= nil and math.floor(slew_counter[b].slewedVal*10000) ~= math.floor(slew_counter[b].next_tilt*10000) then
        if math.floor(slew_counter[b].prev_tilt*10000) ~= math.floor(slew_counter[b].slewedVal*10000) then
          slew_counter[b].interrupted = 1
          slew_filter(util.round(b),slew_counter[b].slewedVal,slew_counter[b].next_tilt,slew_counter[b].prev_q,slew_counter[b].next_q,pad.tilt_ease_time)
        else
          slew_counter[b].interrupted = 0
          slew_filter(util.round(b),slew_counter[b].prev_tilt,slew_counter[b].next_tilt,slew_counter[b].prev_q,slew_counter[b].next_q,pad.tilt_ease_time)
        end
      end
    elseif pad.tilt_ease_type == 2 then
      slew_filter(util.round(b),slew_counter[b].prev_tilt,slew_counter[b].next_tilt,slew_counter[b].prev_q,slew_counter[b].next_q,pad.tilt_ease_time)
    end
  end
  softcut.pan(b+1,pad.pan)
  update_delays()
  if slew_counter[b] ~= nil then
    slew_counter[b].prev_tilt = pad.tilt
    slew_counter[b].prev_q = pad.q
  end
  previous_pad = bank[b].id
  if bank[b].crow_execute == 1 then
    if pad.crow_pad_execute == 1 then
      crow.output[b]()
    end
  end
  --dangerous??
  local rate_array = {-4.0,-2.0,-1.0,-0.5,-0.25,-0.125,0.125,0.25,0.5,1.0,2.0,4.0}
  local s = {}
  for k,v in pairs(rate_array) do
    s[v]=k
  end
  if pad.fifth == false then
    if s[pad.rate] ~= nil then
      params:set("rate "..tonumber(string.format("%.0f",b)),s[pad.rate])
    else
      pad.fifth = true
    end
  end
  params:set("level "..tonumber(string.format("%.0f",b)),pad.level)
  params:set("current pad "..tonumber(string.format("%.0f",b)),i,"true")
  params:set("start point "..tonumber(string.format("%.0f",b)),pad.start_point*100,"true")
  params:set("end point "..tonumber(string.format("%.0f",b)),pad.end_point*100,"true")
  if osc_communication == true then
    osc_redraw(b)
  end
end

function envelope(i)
  softcut.level_slew_time(i+1,0.01)
  env_counter[i].butt = env_counter[i].butt - 0.05
  if env_counter[i].butt > 0 then
    softcut.level(i+1,env_counter[i].butt)
    softcut.level_cut_cut(i+1,5,env_counter[i].butt*bank[i][bank[i].id].left_delay_level)
    softcut.level_cut_cut(i+1,6,env_counter[i].butt*bank[i][bank[i].id].right_delay_level)
  else
    env_counter[i]:stop()
    softcut.level(i+1,0)
    env_counter[i].butt = bank[i][bank[i].id].level
    softcut.level_cut_cut(i+1,5,0)
    softcut.level_cut_cut(i+1,6,0)
    softcut.level_slew_time(i+1,1.0)
  end
end

function slew_filter(i,prevVal,nextVal,prevQ,nextQ,count)
  slew_counter[i]:stop()
  slew_counter[i].current = 0
  slew_counter[i].count = count
  slew_counter[i].duration = (slew_counter[i].count/100)-0.01
  slew_counter[i].beginVal = prevVal
  slew_counter[i].endVal = nextVal
  slew_counter[i].change = slew_counter[i].endVal - slew_counter[i].beginVal
  slew_counter[i].beginQ = prevQ
  slew_counter[i].endQ = nextQ
  slew_counter[i].changeQ = slew_counter[i].endQ - slew_counter[i].beginQ
  slew_counter[i]:start()
end

function easing_slew(i)
  slew_counter[i].slewedVal = slew_counter[i].ease(slew_counter[i].current,slew_counter[i].beginVal,slew_counter[i].change,slew_counter[i].duration)
  slew_counter[i].slewedQ = slew_counter[i].ease(slew_counter[i].current,slew_counter[i].beginQ,slew_counter[i].changeQ,slew_counter[i].duration)
  slew_counter[i].current = slew_counter[i].current + 0.01
  if grid.alt == 1 then
    try_tilt_process(i,bank[i].id,slew_counter[i].slewedVal,slew_counter[i].slewedQ)
  else
    for j = 1,16 do
      try_tilt_process(i,j,slew_counter[i].slewedVal,slew_counter[i].slewedQ)
    end
  end
  if menu == 5 then
    redraw()
  end
end

function try_tilt_process(b,i,t,rq)
  if util.round(t*100) < 0 then
    local trill = math.abs(t)
    bank[b][i].cf_lp = math.abs(t)
    bank[b][i].cf_dry = 1+t
    if util.round(t*100) >= -24 then
      bank[b][i].cf_exp_dry = (util.linexp(0,1,1,101,bank[b][i].cf_dry)-1)/100
    elseif util.round(t*100) <= -24 and util.round(t*100) >= -50 then
      bank[b][i].cf_exp_dry = (util.linexp(0.4,1,1,101,bank[b][i].cf_dry)-1)/100
    elseif util.round(t*100) < -50 then
      bank[b][i].cf_exp_dry = 0
    end
    bank[b][i].cf_fc = util.linexp(0,1,16000,10,bank[b][i].cf_lp)
    params:set("filter "..b.." cutoff",bank[b][i].cf_fc)
    params:set("filter "..b.." lp", math.abs(bank[b][i].cf_exp_dry-1))
    params:set("filter "..b.." dry", bank[b][i].cf_exp_dry)
    if params:get("filter "..b.." hp") ~= 0 then
      params:set("filter "..b.." hp", 0)
    end
    if bank[b][i].cf_hp ~= 0 then
      bank[b][i].cf_hp = 0
    end
  elseif util.round(t*100) > 0 then
    bank[b][i].cf_hp = math.abs(t)
    bank[b][i].cf_fc = util.linexp(0,1,10,12000,bank[b][i].cf_hp)
    bank[b][i].cf_dry = 1-t
    bank[b][i].cf_exp_dry = (util.linexp(0,1,1,101,bank[b][i].cf_dry)-1)/100
    params:set("filter "..b.." cutoff",bank[b][i].cf_fc)
    params:set("filter "..b.." hp", math.abs(bank[b][i].cf_exp_dry-1))
    params:set("filter "..b.." dry", bank[b][i].cf_exp_dry)
    if params:get("filter "..b.." lp") ~= 0 then
      params:set("filter "..b.." lp", 0)
    end
    if bank[b][i].cf_lp ~= 0 then
      bank[b][i].cf_lp = 0
    end
  elseif util.round(t*100) == 0 then
    bank[b][i].cf_fc = 12000
    bank[b][i].cf_lp = 0
    bank[b][i].cf_hp = 0
    bank[b][i].cf_dry = 1
    bank[b][i].cf_exp_dry = 1
    params:set("filter "..b.." cutoff",12000)
    params:set("filter "..b.." lp", 0)
    params:set("filter "..b.." hp", 0)
    params:set("filter "..b.." dry", 1)
  end
  softcut.post_filter_rq(b+1,rq)
end

function buff_freeze()
  softcut.recpre_slew_time(1,0.5)
  softcut.level_slew_time(1,0.5)
  softcut.fade_time(1,0.01)
  rec.state = (rec.state + 1)%2
  softcut.rec_level(1,rec.state)
  if rec.state == 1 then
    softcut.pre_level(1,params:get("live_rec_feedback"))
  else
    softcut.pre_level(1,1)
  end
end

function buff_flush()
  softcut.buffer_clear_region_channel(1,rec.start_point, rec.end_point-rec.start_point)
  rec.state = 0
  rec.clear = 1
  softcut.rec_level(1,0)
end

function toggle_buffer(i)
  softcut.level_slew_time(1,0.5)
  softcut.fade_time(1,0.01)
  
  local old_clip = rec.clip
  
  for go = 1,2 do
    local old_min = (1+(8*(rec.clip-1)))
    local old_max = (9+(8*(rec.clip-1)))
    local old_range = old_min - old_max
    rec.clip = i
    local new_min = (1+(8*(rec.clip-1)))
    local new_max = (9+(8*(rec.clip-1)))
    local new_range = new_max - new_min
    local current_difference = (rec.end_point - rec.start_point)
    rec.start_point = (((rec.start_point - old_min) * new_range) / old_range) + new_min
    rec.end_point = rec.start_point + current_difference
  end
  
  if rec.loop == 0 and grid.alt == 0 then
    clock.run(one_shot_clock)
  elseif rec.loop == 0 and grid.alt == 1 then
    buff_flush()
  end
  
  softcut.loop_start(1,rec.start_point)
  softcut.loop_end(1,rec.end_point-0.01)
  if rec.loop == 1 then
    if old_clip ~= rec.clip then rec.state = 0 end
    buff_freeze()
    if rec.clear == 1 then
      rec.clear = 0
    end
  end
end

function update_delays()
  for i = 1,2 do
    local delay_rate_to_time = (60/bpm) * delay[i].rate
    local delay_time = delay_rate_to_time + (41 + (30*(i-1)))
    delay[i].end_point = delay_time
    softcut.loop_end(i+4,delay[i].end_point)
  end
end

function load_sample(file,sample)
  local old_min = clip[sample].min
  local old_max = clip[sample].max
  if file ~= "-" then
    local ch, len = audio.file_info(file)
    if len/48000 < 32 then
      clip[sample].sample_length = len/48000
    else
      clip[sample].sample_length = 32
    end

    --need this to calculate at 32 second intervals...1,33,65
    --buffer_read_mono (file, start_src, start_dst, dur, ch_src, ch_dst)	
    --softcut.buffer_read_mono(file, 0, 1+(32*(sample-1)),clip[sample].sample_length + 0.05, 1, 2)
    softcut.buffer_clear_region_channel(2,1+(32*(sample-1)),32)
    softcut.buffer_read_mono(file, 0, 1+(32*(sample-1)),clip[sample].sample_length + 0.05, 1, 2)
    --print("start point: "..1+(32*(sample-1)))
    --print("duration: "..clip[sample].sample_length + 0.05)
    clip_table()
    for p = 1,16 do
      for b = 1,3 do
        if bank[b][p].mode == 2 and bank[b][p].clip == sample then
          scale_loop_points(bank[b][p], old_min, old_max, clip[sample].min, clip[sample].max)
        end
      end
    end
  end
end

function save_sample(i)
  local dirname = _path.dust.."audio/cc_saved_samples/"
  if os.rename(dirname, dirname) == nil then
    os.execute("mkdir " .. dirname)
  end
  local name = "cc_"..os.date("%y%m%d_%X-buff")..i..".wav"
  local save_pos = i - 1
  softcut.buffer_write_mono(_path.dust.."/audio/cc_saved_samples/"..name,1+(8*save_pos),8,1)
end

function collect_samples(i) -- this works!!!
  local dirname = _path.dust.."audio/cc_collection-samples/"
  if os.rename(dirname, dirname) == nil then
    os.execute("mkdir " .. dirname)
  end
  local dirname = _path.dust.."audio/cc_collection-samples/"..params:get("collection").."/"
  if os.rename(dirname, dirname) == nil then
    os.execute("mkdir " .. dirname)
  end
  local name = "cc_"..params:get("collection").."-"..i..".wav"
  local save_pos = i - 1
  softcut.buffer_write_mono(_path.dust.."audio/cc_collection-samples/"..params:get("collection").."/"..name,1+(8*save_pos),8,1)
end

function reload_collected_samples(file,sample)
  if rec.state == 1 then
    buff_freeze()
  end
  if file ~= "-" then
    softcut.buffer_read_mono(file, 0, 1+(8 * (sample-1)), 8, 1, 1)
  end
end

function key(n,z)
  if n == 3 and z == 1 then
    if menu == 1 then
      for i = 1,10 do
        if page.main_sel == i then
          menu = i+1
        end
      end
    elseif menu == 2 then
      local loop_nav = (page.loops_sel + 1)%4
      page.loops_sel = loop_nav
    elseif menu == 3 then
      local level_nav = (page.levels_sel + 1)%3
      page.levels_sel = level_nav
    elseif menu == 5 then
      local filter_nav = (page.filtering_sel + 1)%3
      page.filtering_sel = filter_nav
    elseif menu == 7 then
      local time_nav = page.time_sel
      local id = time_nav
      if time_nav >= 1 and time_nav < 4 then
        if g.device == nil and grid_pat[time_nav].count == 0 then
          if page.time_page_sel[time_nav] == 1 then
            if midi_pat[time_nav].playmode < 3 then
              if midi_pat[time_nav].rec == 0 then
                if midi_pat[time_nav].count == 0 then
                  if midi_pat[time_nav].playmode == 1 then
                    midi_pat[time_nav]:rec_start()
                  else
                    midi_pat[time_nav].rec_clock = clock.run(synced_record_start,midi_pat[time_nav],time_nav)
                  end
                else
                  midi_pat[time_nav].overdub = midi_pat[time_nav].overdub == 0 and 1 or 0
                end
              elseif midi_pat[time_nav].rec == 1 then
                midi_pat[time_nav]:rec_stop()
                if midi_pat[time_nav].playmode == 1 then
                  --midi_pat[time_nav]:start()
                  start_pattern(midi_pat[time_nav])
                elseif midi_pat[time_nav].playmode == 2 then
                  --midi_pat[time_nav]:start()
                  print("line 2196")
                  --start_synced_loop(midi_pat[time_nav])
                  midi_pat[time_nav]:rec_stop()
                  clock.cancel(midi_pat[time_nav].rec_clock)
                  if midi_pat[time_nav].clock ~= nil then
                    print("clearing clock: "..midi_pat[time_nav].clock)
                    clock.cancel(midi_pat[time_nav].clock)
                  end
                  midi_pat[id]:clear()
                end
              end
            end
          end
        end
        if page.time_page_sel[time_nav] == 2 then
          if g.device ~= nil then
            print("random grid pat!", id)
            random_grid_pat(id,2)
          else
            shuffle_midi_pat(id)
            ("random midi pat!")
          end
        elseif page.time_page_sel[time_nav] == 5 then
          if not key1_hold then
            if g.device ~= nil then
              if grid_pat[id].playmode == 3 or grid_pat[id].playmode == 4 then
                clock.run(random_grid_pat, id, 3)
              else
                random_grid_pat(id,3)
              end
            else
              random_midi_pat(id)
            end
          end
        end
        if key1_hold then
          if grid_pat[id].count > 0 then
            grid_pat[id]:rec_stop()
            grid_pat[id]:stop()
            grid_pat[id].tightened_start = 0
            grid_pat[id]:clear()
            pattern_saver[id].load_slot = 0
          end
          if midi_pat[id].count > 0 then
            midi_pat[id]:rec_stop()
            if midi_pat[id].clock ~= nil then
              print("clearing clock: "..midi_pat[id].clock)
              clock.cancel(midi_pat[id].clock)
            end
            midi_pat[id]:clear()
          end
        end
      end
    elseif menu == 8 then

      if key1_hold then
        rytm.reset_pattern()
      else
        rytm.track[rytm.track_edit].pos = 1
      end

      --[==[
      if key1_hold then
        if page.track_page < 4 then
          if tracker[page.track_page][page.track_sel[page.track_page]].pad ~= nil then
            page.track_page_section[page.track_page] = 4
          end
        end
      else
        if page.track_page < 4 then
          if page.track_page_section[page.track_page] == 1 then
            page.track_page_section[page.track_page] = 2
          elseif page.track_page_section[page.track_page] == 2 then
            page.track_page_section[page.track_page] = 3
          elseif page.track_page_section[page.track_page] == 3 then
            if tracker[page.track_page][page.track_sel[page.track_page]].pad ~= nil then
              tracker[page.track_page].step = page.track_sel[page.track_page]
              trackers.cheat(page.track_page,page.track_sel[page.track_page])
            else
              local source = tracker[page.track_page][page.track_sel[page.track_page]-1]
              local destination = tracker[page.track_page][page.track_sel[page.track_page]]
              if source ~= nil then
                trackers.copy_prev(source,destination)
                trackers.append()
              end
            end
          elseif page.track_page_section[page.track_page] == 4 then
            tracker[page.track_page].step = page.track_sel[page.track_page]
            trackers.cheat(page.track_page,page.track_sel[page.track_page])
          end
        else
          if page.track_page_section[page.track_page] == 1 then
            page.track_page_section[page.track_page] = 2
          elseif page.track_page_section[page.track_page] == 2 then
            page.track_page_section[page.track_page] = 3
          elseif page.track_page_section[page.track_page] == 3 then
            trackers.snake(1,tracker[1].snake)
          end
        end
      end
      --]==]

    elseif menu == 9 then
      arp[page.arp_page_sel].hold = not arp[page.arp_page_sel].hold
      if not arp[page.arp_page_sel].hold then
        arps.clear(page.arp_page_sel)
      end
    elseif menu == 10 then
      if page.rnd_page_section == 1 then
        if key1_hold then
          for i = 1,5 do
            rnd.transport(page.rnd_page,i,"off")
            rnd.restore_default(page.rnd_page,i)
          end
        else
          page.rnd_page_section = 2
        end
      elseif page.rnd_page_section == 2 then
        if key1_hold then
          local rnd_bank = page.rnd_page
          local rnd_slot = page.rnd_page_sel[rnd_bank]
          local state = tostring(rnd[rnd_bank][rnd_slot].playing)
          rnd.transport(rnd_bank,rnd_slot,state == "false" and "on" or "off")
          if state == "true" then
            rnd.restore_default(rnd_bank,rnd_slot)
          end
        else
          page.rnd_page_section = 3
        end
      end
    end

  elseif n == 2 and z == 1 then
    if menu == 11 then
      if help_menu ~= "welcome" then
        help_menu = "welcome"
      else
        menu = 1
      end
    elseif menu == 8 then
      menu = 1
      --[[
      if page.track_page_section[page.track_page] == 3 then
        page.track_page_section[page.track_page] = 2
      elseif page.track_page_section[page.track_page] == 4 then
        page.track_page_section[page.track_page] = 3
      elseif page.track_page_section[page.track_page] == 2 then
        page.track_page_section[page.track_page] = 1
      else
        menu = 1
      end
      --]]
    elseif menu == 10 then
      if page.rnd_page_section == 2 then
        page.rnd_page_section = 1
      elseif page.rnd_page_section == 3 then
        page.rnd_page_section = 2
      else
        menu = 1
      end
    else
      menu = 1
    end
    if key1_hold == true then key1_hold = false end
  end

  if n == 1 and z == 1 then
    if menu == 2 or menu == 5 or menu == 11 then
      if key1_hold == false then
        key1_hold = true
      else
        key1_hold = false
      end
    elseif menu == 7 then
      key1_hold = true
    elseif menu == 8 then
      key1_hold = true
      --[[
      if page.track_page_section[page.track_page] == 1 and page.track_page < 4 then
        trackers.transport(page.track_page)
      elseif page.track_page_section[page.track_page] == 3 and page.track_page < 4 then
        tracker[page.track_page].recording = not tracker[page.track_page].recording
        key1_hold = true
      elseif page.track_page_section[page.track_page] == 4 then
        key1_hold = true
      end
      -]]
    elseif menu == 9 then
      key1_hold = true
      page.arp_param_group[page.arp_page_sel] = (page.arp_param_group[page.arp_page_sel] % 2) + 1
      if not arp[page.arp_page_sel].hold then
        arps.clear(page.arp_page_sel)
      end
    else
      key1_hold = true
    end
    
  elseif n == 1 and z == 0 then
    if menu ~= 2 and menu ~= 5 and menu ~= 11 then
      key1_hold = false
    end
    if menu == 7 then
      if key1_hold_and_modify == false then
        local time_nav = page.time_sel
        local id = time_nav
        if midi_pat[id].play == 1 then
          if midi_pat[id].clock ~= nil then
            clock.cancel(midi_pat[id].clock)
            print("pausing clock")
            midi_pat[id].step = 1
          end
          midi_pat[id]:stop()
        else
          if midi_pat[id].count > 0 then
            if midi_pat[id].playmode == 1 then
              --midi_pat[id]:start()
              start_pattern(midi_pat[id])
            elseif midi_pat[id].playmode == 2 then
              print("line 2387")
              --midi_pat[id].clock = clock.run(synced_loop, midi_pat[id], "restart")
              midi_pat[id].clock = clock.run(alt_synced_loop, midi_pat[id], "restart")
            end
          end
        end
        if grid_pat[id].count > 0 then
          if grid_pat[id].quantize == 0 then
            if grid_pat[id].play == 1 then
              --grid_pat[id]:stop()
              stop_pattern(grid_pat[id])
            else
              --grid_pat[id]:start()
              start_pattern(grid_pat[id])
            end
          else
            grid_pat[id].tightened_start = (grid_pat[id].tightened_start + 1)%2
            grid_pat[id].step = grid_pat[id].start_point
            quantized_grid_pat[id].current_step = grid_pat[id].start_point
            quantized_grid_pat[id].sub_step = 1
          end
        end
      else
        key1_hold_and_modify = false
      end
    end
  end
  redraw()
end

function enc(n,d)
  encoder_actions.init(n,d)
end

function redraw()
  screen.clear()
  screen.level(15)
  screen.font_size(8)
  main_menu.init()
  screen.update()
end

--GRID
g = grid.connect()

g.key = function(x,y,z)
  grid_actions.init(x,y,z)
end

function jump_live(i,s,y,z)

  local pad = bank[i][s]

  local old_duration = pad.mode == 1 and 8 or clip[pad.clip].sample_length
  local old_clip = pad.clip
  local old_min = (1+(old_duration*(old_clip-1)))
  local old_max = ((old_duration+1)+(old_duration*(old_clip-1)))
  local old_range = old_min - old_max
  pad.clip = math.abs(y-5)
  local new_duration = pad.mode == 1 and 8 or clip[pad.clip].sample_length
  local new_clip = pad.clip
  --local new_min = (1+(new_duration*(pad.clip-1)))
  if pad.mode == 1 then
    local new_min = (1+(new_duration*(pad.clip-1)))
    local new_max = ((new_duration+1)+(new_duration*(pad.clip-1)))
    local new_range = new_max - new_min
    local current_difference = (pad.end_point - pad.start_point) -- is this where it gets weird?
    pad.start_point = (((pad.start_point - old_min) * new_range) / old_range) + new_min
    pad.end_point = pad.start_point + current_difference
  end


--[[
  for go = 1,2 do
    local old_min = (1+(duration*(bank[i][s].clip-1)))
    local old_max = ((duration+1)+(duration*(bank[i][s].clip-1)))
    local old_range = old_min - old_max
    bank[i][s].clip = math.abs(y-5)
    local new_min = (1+(duration*(bank[i][s].clip-1)))
    local new_max = ((duration+1)+(duration*(bank[i][s].clip-1)))
    local new_range = new_max - new_min
    local current_difference = (bank[i][s].end_point - bank[i][s].start_point)
    bank[i][s].start_point = (((bank[i][s].start_point - old_min) * new_range) / old_range) + new_min
    bank[i][s].end_point = bank[i][s].start_point + current_difference
    if menu == 11 then
      which_bank = i
      help_menu = "buffer jump"
    end
  end
  --]]

  if menu == 11 then
    which_bank = i
    help_menu = "buffer jump"
  end
end

function clip_table()
  clip[1].min = 1
  clip[1].max = clip[1].min + clip[1].sample_length
  --clip[2].min = clip[1].max
  clip[2].min = 33
  clip[2].max = clip[2].min + clip[2].sample_length
  --clip[3].min = clip[2].max
  clip[3].min = 65
  clip[3].max = clip[3].min + clip[3].sample_length
end

-- length mods

function scale_loop_points(pad,old_min,old_max,new_min,new_max)
  --local pad = bank[b][p]
  local duration = pad.end_point - pad.start_point
  pad.start_point = util.linlin(old_min,old_max,new_min,new_max,pad.start_point)
  --pad.end_point = util.linlin(old_min,old_max,new_min,new_max,pad.end_point)
  if pad.start_point + duration > new_max then
    pad.end_point = new_max
  else
    pad.end_point = pad.start_point + duration
  end
end

function change_mode(target,old_mode)
  local live_min = live[target.clip].min
  local live_max = live[target.clip].max
  local clip_min = clip[target.clip].min
  local clip_max = clip[target.clip].max
  local duration = target.end_point - target.start_point
  if old_mode == 1 then
    target.start_point = util.linlin(live_min,live_max,clip_min,clip_max,target.start_point)
    --target.end_point = util.linlin(live_min,live_max,clip_min,clip_max,target.end_point)
  elseif old_mode == 2 then
    target.start_point = util.linlin(clip_min,clip_max,live_min,live_max,target.start_point)
    --target.end_point = util.linlin(clip_min,clip_max,live_min,live_max,target.end_point)
  end
  if target.start_point + duration > (old_mode == 1 and clip[target.clip].max or live[target.clip].max) then
    target.end_point = (old_mode == 1 and clip[target.clip].max or live[target.clip].max)
  else
    target.end_point = target.start_point + duration
  end
end

function jump_clip(i,s,y,z)
  local pad = bank[i][s]
  local current_difference = (pad.end_point - pad.start_point)
  if pad.mode == 2 then
    local old_clip = pad.clip
    pad.clip = math.abs(y-5)
    --local current_difference = (pad.end_point - pad.start_point)
    pad.start_point = util.linlin(clip[old_clip].min,clip[old_clip].max,clip[pad.clip].min,clip[pad.clip].max,pad.start_point)
    if pad.start_point + current_difference > clip[pad.clip].max then
      pad.end_point = clip[pad.clip].max
    else
      pad.end_point = pad.start_point + current_difference
    end
  else
    local old_clip = pad.clip
    pad.clip = math.abs(y-5)
    --local current_difference = (pad.end_point - pad.start_point)
    pad.start_point = util.linlin(live[old_clip].min,live[old_clip].max,live[pad.clip].min,live[pad.clip].max,pad.start_point)
    if pad.start_point + current_difference > live[pad.clip].max then
      pad.end_point = live[pad.clip].max
    else
      pad.end_point = pad.start_point + current_difference
    end
  end
end

--/ length mods

function grid_entry(e)
  if e.state > 0 then
    lit[e.id] = {}
    lit[e.id].x = e.x
    lit[e.id].y = e.y
  else
    if lit[e.id] ~= nil then
      lit[e.id] = nil
    end
  end
  grid_redraw()
end

function grid_redraw()
  if g.device ~= nil then
    g:all(0)
    
    if grid_page == 0 then
      
      for j = 0,2 do
        for k = 1,4 do
          k = k+(5*j)
          for i = 8,5,-1 do
            g:led(k,i,3)
          end
        end
      end
      
      for j = 0,2 do
        for k = (5-j),(15-j),5 do
          for i = (4-j),1,-1 do
            g:led(k,i,3)
          end
        end
      end
      
      for i = 1,3 do
        local target = grid_pat[i]
        if target.rec == 1 then
          g:led(2+(5*(i-1)),1,(9*target.led))
        elseif (target.quantize == 0 and target.play == 1) or (target.quantize == 1 and target.tightened_start == 1) then
          if target.overdub == 0 then
            g:led(2+(5*(i-1)),1,9)
          else
            g:led(2+(5*(i-1)),1,15)
          end
        elseif target.count > 0 then
          g:led(2+(5*(i-1)),1,5)
        else
          g:led(2+(5*(i-1)),1,3)
        end
      end
      
      for i = 1,3 do
        if arc_pat[i].rec == 1 then
          g:led(16,5-i,15)
        elseif arc_pat[i].play == 1 then
          g:led(16,5-i,9)
        elseif arc_pat[i].count > 0 then
          g:led(16,5-i,5)
        else
          g:led(16,5-i,0)
        end
      end
      
      if a.device ~= nil then
        for i = 1,3 do
          for j = 5,15,5 do
            g:led(j,8,arc_param[j/5] == 1 and 5 or 0)
            g:led(j,7,arc_param[j/5] == 2 and 5 or 0)
            g:led(j,6,arc_param[j/5] == 3 and 5 or 0)
            if arc_param[j/5] == 4 then
              for k = 8,6,-1 do
                g:led(j,k,5)
              end
            elseif arc_param[j/5] == 5 then
              g:led(j,8,5)
              g:led(j,7,5)
            elseif arc_param[j/5] == 6 then
              g:led(j,7,5)
              g:led(j,6,5)
            end
          end
        end
      end
      
      for i = 1,3 do
        if bank[i].focus_hold == false then
          g:led(selected[i].x, selected[i].y, 15)
          if i == nil then print("2339") end
          if bank[i].id == nil then print("2340", i) end
          if bank[i][bank[i].id].pause == nil then print("2341") end
          if bank[i][bank[i].id].pause == true then
            g:led(3+(5*(i-1)),1,15)
            g:led(3+(5*(i-1)),2,15)
          else
            g:led(3+(5*(i-1)),1,3)
            g:led(3+(5*(i-1)),2,3)
          end
        else
          local focus_x = (math.ceil(bank[i].focus_pad/4)+(5*(i-1)))
          local focus_y = 8-((bank[i].focus_pad-1)%4)
          g:led(selected[i].x, selected[i].y, 5)
          g:led(focus_x, focus_y, 15)
          if bank[i][bank[i].focus_pad].pause == true then
            g:led(3+(5*(i-1)),1,15)
            g:led(3+(5*(i-1)),2,15)
          else
            g:led(3+(5*(i-1)),1,3)
            g:led(3+(5*(i-1)),2,3)
          end
        end
      end
      
      for i = 1,3 do
        if bank[i].focus_hold == true then
          g:led(5*i,5,(10*bank[i][bank[i].focus_pad].crow_pad_execute)+5)
        else
          local alt = bank[i].alt_lock and 1 or 0
          g:led(5*i,5,15*alt)
        end
      end
      
      for i,e in pairs(lit) do
        g:led(e.x, e.y,15)
      end
      
      g:led(16,8,(grid.alt*12)+3)
      
      for i = 1,3 do
        if bank[i].focus_hold == false then
          g:led(1 + (5*(i-1)), math.abs(bank[i][bank[i].id].clip-5),8)
          g:led(2 + (5*(i-1)), math.abs(bank[i][bank[i].id].mode-5),6)
          g:led(1+(5*(i-1)),1,0)
          if bank[i][bank[i].id].loop == false then
            g:led(3+(5*(i-1)),4,2)
          elseif bank[i][bank[i].id].loop == true then
            g:led(3+(5*(i-1)),4,4)
          end
          if arp[i].hold == false then
            g:led(3+(5*(i-1)),3,0)
          else
            g:led(3+(5*(i-1)),3,6)
          end
        else
          g:led(1 + (5*(i-1)), math.abs(bank[i][bank[i].focus_pad].clip-5),8)
          g:led(2 + (5*(i-1)), math.abs(bank[i][bank[i].focus_pad].mode-5),6)
          g:led(1+(5*(i-1)),1,10)
          if bank[i][bank[i].focus_pad].loop == false then
            g:led(3+(5*(i-1)),4,2)
          elseif bank[i][bank[i].focus_pad].loop == true then
            g:led(3+(5*(i-1)),4,4)
          end
        end
      end
      
      if rec.clear == 0 then
        g:led(16,8-rec.clip,(5*rec.state)+5)
      elseif rec.clear == 1 then
        g:led(16,8-rec.clip,3)
      end
    
    else
      
      -- if we're on page 2...
      
      for i = 1,3 do
        for j = step_seq[i].start_point,step_seq[i].end_point do
          if j < 9 then
            g:led((i*5)-2,9-j,2)
            if grid.loop_mod == 1 then
              g:led((i*5)-2,9-step_seq[i].start_point,4)
              g:led((i*5)-2,9-step_seq[i].end_point,4)
            end
          elseif j >=9 then
            g:led((i*5)-1,17-j,2)
            if grid.loop_mod == 1 then
              g:led((i*5)-1,17-step_seq[i].start_point,4)
              g:led((i*5)-1,17-step_seq[i].end_point,4)
            end
          end
        end
      end
      
      for i = 1,11,5 do
        for j = 1,8 do
          local current = math.floor(i/5)+1
          if step_seq[current].held == 0 then
            g:led(i,j,(5*pattern_saver[current].saved[9-j])+2)
            g:led(i,j,j == 9 - pattern_saver[current].load_slot and 15 or ((5*pattern_saver[current].saved[9-j])+2))
          else
            g:led(i,j,(5*pattern_saver[current].saved[9-j])+2)
            g:led(i,j,j == 9 - step_seq[current][step_seq[current].held].assigned_to and 15 or ((5*pattern_saver[current].saved[9-j])+2))
          end
        end
      end
      
      for i = 1,3 do
        for j = 1,16 do
          if step_seq[i][j].assigned_to ~= 0 then
            if j < 9 then
              g:led((i*5)-2,9-j,4)
            elseif j >= 9 then
              g:led((i*5)-1,17-j,4)
            end
          end
        end
        if step_seq[i].current_step < 9 then
          g:led((i*5)-2,9-step_seq[i].current_step,15)
        elseif step_seq[i].current_step >=9 then
          g:led((i*5)-1,9-(step_seq[i].current_step-8),15)
        end
        if step_seq[i].held < 9 then
          g:led((i*5)-2,9-step_seq[i].held,9)
        elseif step_seq[i].held >= 9 then
          g:led((i*5)-1,9-(step_seq[i].held-8),9)
        end
      end
      
      for i = 1,3 do
        g:led((i*5)-3, 9-step_seq[i].meta_duration,4)
        g:led((i*5)-3, 9-step_seq[i].meta_step,6)
      end
      
      for i = 1,3 do
        if step_seq[i].held == 0 then
          g:led((i*5), 9-step_seq[i][step_seq[i].current_step].meta_meta_duration,4)
          g:led((i*5), 9-step_seq[i].meta_meta_step,6)
        else
          g:led((i*5), 9-step_seq[i].meta_meta_step,2)
          g:led((i*5), 9-step_seq[i][step_seq[i].held].meta_meta_duration,4)
        end
        if step_seq[i].held == 0 then
          g:led(16,8-i,(step_seq[i].active*6)+2)
        else
          g:led(16,8-i,step_seq[i][step_seq[i].held].loop_pattern*4)
        end
      end
      
      g:led(16,8,(grid.alt_pp*12)+3)
      g:led(16,2,(grid.loop_mod*9)+3)
      
      if grid.loop_mod == 1 then
        
      end
      
    end
    g:led(16,1,15*grid_page)
    
    g:refresh()
  end
end
--/GRID

function grid_pattern_execute(entry)
  if entry ~= nil then
    if entry ~= "pause" then
      local i = entry.i
      if entry.action == "pads" then
        if params:get("zilchmo_patterning") == 2 then
          bank[i][entry.id].rate = entry.rate
        end
        selected[i].id = entry.id
        selected[i].x = entry.x
        selected[i].y = entry.y
        bank[i].id = selected[i].id
        if params:get("zilchmo_patterning") == 2 then
          bank[i][bank[i].id].mode = entry.mode
          bank[i][bank[i].id].clip = entry.clip
        end
        if arc_param[i] ~= 4 and #arc_pat[1].event == 0 then
          if params:get("zilchmo_patterning") == 2 then
            bank[i][bank[i].id].start_point = entry.start_point
            bank[i][bank[i].id].end_point = entry.end_point
          end
        end
        cheat(i,bank[i].id)
      elseif string.match(entry.action, "zilchmo") then
        if params:get("zilchmo_patterning") == 2 then
          bank[i][entry.id].rate = entry.rate
          if fingers[entry.row][entry.bank] == nil then
            fingers[entry.row][entry.bank] = {}
          end
          fingers[entry.row][entry.bank].con = entry.con
          zilchmo(entry.row,entry.bank)
          if arc_param[i] ~= 4 and #arc_pat[1].event == 0 then
            bank[i][bank[i].id].start_point = entry.start_point
            bank[i][bank[i].id].end_point = entry.end_point
            softcut.loop_start(i+1,bank[i][bank[i].id].start_point)
            softcut.loop_end(i+1,bank[i][bank[i].id].end_point)
          end
          local length = math.floor(math.log10(entry.con)+1)
          for i = 1,length do
            if grid_page == 0 then
              g:led((entry.row+1)*entry.bank,5-(math.floor(entry.con/(10^(i-1))) % 10),15)
              g:refresh()
            end
          end
        end
      end
      grid_redraw()
      redraw()
    end
  end
end

function arc_pattern_execute(entry)
  local i = entry.i
  local id = arc_control[i]
  local param = entry.param
  if param ~= 4 then
    local which_pad = entry.pad

    if arc_pat[i].step ~= 0 then
      if arc_pat[i].step > 1 then
        if params:get("arc_patterning") == 2 then
          if arc_pat[i].event[arc_pat[i].step].pad ~= arc_pat[i].event[arc_pat[i].step-1].pad then
            bank[id].id = arc_pat[i].event[arc_pat[i].step].pad
            selected[id].x = (math.ceil(bank[id].id/4)+(5*(id-1)))
            selected[id].y = 8-((bank[id].id-1)%4)
            cheat(id,arc_pat[i].event[arc_pat[i].step].pad)
            slew_filter(id,entry.prev_tilt,entry.tilt,bank[id][bank[id].id].q,bank[id][bank[id].id].q,15)
          end
        end
      elseif arc_pat[i].step == 1 then
        if params:get("arc_patterning") == 2 then
          bank[id].id = arc_pat[i].event[arc_pat[i].step].pad
          selected[id].x = (math.ceil(bank[id].id/4)+(5*(id-1)))
          selected[id].y = 8-((bank[id].id-1)%4)
          cheat(id,arc_pat[i].event[arc_pat[i].step].pad)
          slew_filter(id,arc_pat[i].event[arc_pat[i].count].tilt,entry.tilt,bank[id][bank[id].id].q,bank[id][bank[id].id].q,15)
        end
      end 
    elseif arc_pat[i].step == 0 then
      arc_pat[i].step = 1
      if params:get("arc_patterning") == 2 then
        bank[id].id = arc_pat[i].event[arc_pat[i].step].pad
        selected[id].x = (math.ceil(bank[id].id/4)+(5*(id-1)))
        selected[id].y = 8-((bank[id].id-1)%4)
        cheat(id,arc_pat[i].event[arc_pat[i].step].pad)
        slew_filter(id,arc_pat[i].event[arc_pat[i].count].tilt,entry.tilt,bank[id][bank[id].id].q,bank[id][bank[id].id].q,15)
      end
    end
      
    bank[id][which_pad].start_point = (entry.start_point + (8*(bank[id][which_pad].clip-1)) + arc_offset)
    bank[id][which_pad].end_point = (entry.end_point + (8*(bank[id][which_pad].clip-1)) + arc_offset)
    if bank[id].id == which_pad then
      softcut.loop_start(id+1, (entry.start_point + (8*(bank[id][which_pad].clip-1))) + arc_offset)
      softcut.loop_end(id+1, (entry.end_point + (8*(bank[id][which_pad].clip-1))) + arc_offset)
    end
  else
    slew_filter(id,entry.prev_tilt,entry.tilt,bank[id][bank[id].id].q,bank[id][bank[id].id].q,15)
  end
  redraw()
end

function arc_delay_pattern_execute(entry)
  local i = entry.i
  local side = entry.delay_focus
  arc_p[4].delay_focus = side
  if side == "L" then
    arc_p[4].left_delay_value = entry.left_delay_value
    params:set("delay L: rate",entry.left_delay_value)
  else
    arc_p[4].right_delay_value = entry.right_delay_value
    params:set("delay R: rate",entry.right_delay_value)
  end
  redraw()
end

function zilchmo(k,i)
  rightangleslice.init(k,i)
  lit = {}
  grid_redraw()
  redraw()
end

function pad_copy(destination, source)
  for k,v in pairs(source) do
    if k ~= bank_id and k ~= pad_id then
      destination[k] = v
    end
  end
end

a = arc.connect()
arc_d = {}
for i = 1,3 do
  arc_d[i] = {}
end

a.delta = function(n,d)
  arc_d[n] = d
  arc_actions.init(n,arc_d[n])
end

arc_redraw = function()
  a:all(0)
  local which_pad = nil
  for i = 1,3 do
    if bank[arc_control[i]].focus_hold == false then
      which_pad = bank[arc_control[i]].id
    else
      which_pad = bank[arc_control[i]].focus_pad
    end
    local duration = bank[i][which_pad].mode == 1 and 8 or clip[bank[i][which_pad].clip].sample_length
    if arc_param[i] == 1 then
      local start_to_led = (bank[arc_control[i]][which_pad].start_point-1)-(duration*(bank[arc_control[i]][which_pad].clip-1))
      local end_to_led = (bank[arc_control[i]][which_pad].end_point-1)-(duration*(bank[arc_control[i]][which_pad].clip-1))
      if start_to_led <= end_to_led then
        a:segment(i, util.linlin(0, duration, tau*(1/4), tau*1.23, start_to_led), util.linlin(0, duration, (tau*(1/4))+0.1, tau*1.249999, end_to_led), 15)
      else
        a:segment(i, util.linlin(0, duration, (tau*(1/4))+0.1, tau*1.23, end_to_led), util.linlin(0, duration, tau*(1/4), tau*1.249999, start_to_led), 15)
      end
    end
    if arc_param[i] == 2 then
      local start_to_led = (bank[arc_control[i]][which_pad].start_point-1)-(duration*(bank[arc_control[i]][which_pad].clip-1))
      local end_to_led = (bank[arc_control[i]][which_pad].end_point-1)-(duration*(bank[arc_control[i]][which_pad].clip-1))
      local playhead_to_led = util.linlin(1,(duration+1),1,64,(poll_position_new[i+1] - (duration*(bank[i][which_pad].clip-1))))
      a:led(i,(math.floor(playhead_to_led))+16,5)
      a:led(i,(math.floor(util.linlin(0,duration,1,64,start_to_led)))+16,15)
      a:led(i,(math.floor(util.linlin(0,duration,1,64,end_to_led)))+17,8)
    end
    if arc_param[i] == 3 then
      local start_to_led = (bank[arc_control[i]][which_pad].start_point-1)-(duration*(bank[arc_control[i]][which_pad].clip-1))
      local end_to_led = (bank[arc_control[i]][which_pad].end_point-1)-(duration*(bank[arc_control[i]][which_pad].clip-1))
      local playhead_to_led = util.linlin(1,(duration+1),1,64,(poll_position_new[i+1] - (duration*(bank[i][which_pad].clip-1))))
      a:led(i,(math.floor(playhead_to_led))+16,5)
      a:led(i,(math.floor(util.linlin(0,duration,1,64,end_to_led)))+17,15)
      a:led(i,(math.floor(util.linlin(0,duration,1,64,start_to_led)))+16,8)
    end
    if arc_param[i] == 4 then
      local tilt_to_led = slew_counter[i].slewedVal
      if bank[i].focus_hold == true then
        which_pad = bank[i].focus_pad
        tilt_to_led = bank[i][bank[i].focus_pad].tilt
      else
        which_pad = bank[i].id
      end
      if tilt_to_led == nil then
        tilt_to_led = bank[i][which_pad].tilt
        a:led(i,47,5)
        a:led(i,48,10)
        a:led(i,49,15)
        a:led(i,50,10)
        a:led(i,51,5)
      elseif tilt_to_led >= -0.04 and tilt_to_led <=0.20 then
        a:led(i,47,5)
        a:led(i,48,10)
        a:led(i,49,15)
        a:led(i,50,10)
        a:led(i,51,5)
      elseif tilt_to_led < -0.04 then
        a:segment(i, tau*(1/4), util.linlin(-1, 1, (tau*(1/4))+0.1, tau*1.249999, tilt_to_led), 15)
      elseif tilt_to_led > 0.20 then
        a:segment(i, util.linlin(-1, 1, (tau*(1/4)), (tau*1.24)+0.4, tilt_to_led-0.1), tau*(1/4)+0.1, 15)
      end
    end
    if arc_param[i] == 5 then
      local level_to_led = bank[i][bank[i].id].level
        for j = 1,17 do
          a:led(i,(math.floor(util.linlin(0,2,5,70,(level_to_led)-(1/8*j))))+16,15)
        end
    end
    if arc_param[i] == 6 then
      local pan_to_led = bank[i][bank[i].id].pan
      a:led(i,(math.floor(util.linlin(-1,1,10,55,pan_to_led)))+22,4)
      a:led(i,(math.floor(util.linlin(-1,1,10,55,pan_to_led)))+17,15)
      a:led(i,(math.floor(util.linlin(-1,1,10,55,pan_to_led)))+12,4)
    end
  end
  
  for i = 1,13 do
    local arc_left_delay_level = (params:get("delay L: rate") == i and 15 or 5)
    local arc_right_delay_level = (params:get("delay R: rate") == i and 15 or 5)
    local arc_try = params:get("delay L: rate")
    if grid.alt == 0 then
      a:led(4,(41+((i-1)*4)-16),arc_left_delay_level)
    else
      a:led(4,(41+((i-1)*4)-16),arc_right_delay_level)
    end
  end
  
  a:refresh()
end

--file loading

function midi_state_save()
  local file = io.open(_path.data.. "cheat_codes/midi_state.data", "w+")
  io.output(file)
  io.write("midi_control_enabled: "..params:get("midi_control_enabled").."\n")
  io.write("midi_control_device: "..params:get("midi_control_device").."\n")
  io.write("midi_echo_enabled: "..params:get("midi_echo_enabled").."\n")
  for i = 1,3 do
    io.write("bank_"..i.."_midi_channel: "..params:get("bank_"..i.."_midi_channel").."\n")
    io.write("bank_"..i.."_pad_midi_base: "..params:get("bank_"..i.."_pad_midi_base").."\n")
  end
  io.close(file)
end

function count_lines_in(file)
  lines = {}
  for line in io.lines(file) do 
    lines[#lines + 1] = line
  end
  return #lines
end

function midi_state_restore()
  local file = io.open(_path.data .. "cheat_codes/midi_state.data", "r")
  if file then
    io.input(file)
    for i = 1,count_lines_in(_path.data.. "cheat_codes/midi_state.data") do
      local s = io.read()
      local param,val = s:match("(.+): (.+)")
      params:set(param,tonumber(val))
      --string.match(io.read(), ": (.*)")
    end
    io.close(file)
  end
end

function savestate()
  local file = io.open(_path.data .. "cheat_codes/collections"..tonumber(string.format("%.0f",params:get("collection")))..".data", "w+")
  io.output(file)
  io.write("PERMANENCE".."\n")
  for i = 1,3 do
    for k = 1,16 do 
      io.write(bank[i].id .. "\n")
      io.write(selected[i].x .. "\n")
      io.write(selected[i].y .. "\n")
      io.write(bank[i][k].clip .. "\n")
      io.write(bank[i][k].mode .. "\n")
      io.write(bank[i][k].start_point .. "\n")
      io.write(bank[i][k].end_point .. "\n")
      io.write(bank[i][k].rate .. "\n")
      io.write(tostring(bank[i][k].pause) .. "\n")
      io.write(tostring(bank[i][k].play_mode) .. "\n")
      io.write(bank[i][k].level .. "\n")
      io.write(tostring(bank[i][k].loop) .. "\n")
      io.write(tostring(bank[i][k].fifth) .. "\n")
      io.write(bank[i][k].pan .. "\n")
      io.write(bank[i][k].fc .. "\n")
      io.write(bank[i][k].q .. "\n")
      io.write(bank[i][k].lp .. "\n")
      io.write(bank[i][k].hp .. "\n")
      io.write(bank[i][k].bp .. "\n")
      io.write(bank[i][k].fd .. "\n")
      io.write(bank[i][k].br .. "\n")
      io.write(bank[i][k].filter_type .. "\n")
      io.write(arc_control[i] .. "\n")
      io.write(arc_param[i] .. "\n")
    end
    io.write(params:get("rate slew time ".. i) .. "\n")
    io.write(tostring(params:get("clip "..i.." sample") .. "\n"))
    local sides = {"delay L: ", "delay R: "}
    for k = 1,2 do
      io.write(params:get(sides[k].."rate") .. "\n")
      io.write(params:get(sides[k].."global level") .. "\n")
      io.write(params:get(sides[k].."feedback") .. "\n")
      io.write(params:get(sides[k].."(a) send") .. "\n")
      io.write(params:get(sides[k].."(b) send") .. "\n")
      io.write(params:get(sides[k].."(c) send") .. "\n")
      io.write(params:get(sides[k].."filter cut") .. "\n")
      io.write(params:get(sides[k].."filter q") .. "\n")
      io.write(params:get(sides[k].."filter lp") .. "\n")
      io.write(params:get(sides[k].."filter hp") .. "\n")
      io.write(params:get(sides[k].."filter bp") .. "\n")
      io.write(params:get(sides[k].."filter dry") .. "\n")
    end
  end
  io.write(params:get("offset").."\n")
    -- v1.1 items
  io.write("v1.1".."\n")
  for i = 1,3 do
    for k = 1,16 do
      io.write(tostring(bank[i][k].enveloped) .. "\n")
      io.write(bank[i][k].envelope_time .. "\n")
    end
  end
  io.write(params:get("zilchmo_patterning") .. "\n")
  io.write(params:get("rec_loop") .. "\n")
  io.write(params:get("live_rec_feedback") .. "\n")
  io.write(params:get("quantize_pads") .. "\n")
  io.write(params:get("quantize_pats") .. "\n")
  io.write(params:get("quant_div") .. "\n")
  io.write(params:get("quant_div_pats") .. "\n")
  io.write(params:get("bpm") .. "\n")
  io.write(rec.clip .. "\n")
  io.write(rec.start_point .. "\n")
  io.write(rec.end_point .. "\n")
  io.write("v1.1.1.1.1.1.1.1".."\n")
  for i = 1,3 do
    io.write(step_seq[i].active .. "\n")
    io.write(step_seq[i].meta_duration .. "\n")
    for k = 1,16 do
      io.write(step_seq[i][k].meta_meta_duration .. "\n")
      io.write(step_seq[i][k].assigned_to .. "\n")
      io.write(bank[i][k].tilt .. "\n")
      io.write(bank[i][k].tilt_ease_time .. "\n")
      io.write(bank[i][k].tilt_ease_type .. "\n")
    end
  end
  io.write("the last params".."\n")
  --io.write(params:get("clock_out") .. "\n")
  io.write("0".."\n")
  --io.write(params:get("crow_clock_out") .. "\n")
  io.write("0".."\n")
  --io.write(params:get("midi_device") .. "\n")
  io.write("0".."\n")
  io.write(params:get("loop_enc_resolution") .."\n")
  --io.write(params:get("clock") .. "\n")
  io.write("0".."\n")
  io.write(params:get("lock_pat") .. "\n")
  for i = 1,3 do
    io.write(bank[i].crow_execute .. "\n")
    io.write(bank[i].snap_to_bars .. "\n")
  end
  for i = 1,3 do
    for j = 1,16 do
      io.write(bank[i][j].offset .. "\n")
    end
  end
  io.write("crow execute count".."\n")
  for i = 1,3 do
    io.write(crow.count_execute[i] .. "\n")
  end
  io.write("step seq loop points".."\n")
  for i = 1,3 do
    io.write(step_seq[i].start_point .. "\n")
    io.write(step_seq[i].end_point .. "\n")
  end
  io.write("Live buffer max".."\n")
  io.write(params:get"live_buff_rate" .. "\n")
  io.write("loop Pattern per step".."\n")
  for i = 1,3 do
    for k = 1,16 do
      io.write(step_seq[i][k].loop_pattern.."\n")
    end
  end
  io.write("collect live?".."\n")
  io.write(params:get("collect_live").."\n")
  if params:get("collect_live") == 2 then
    io.write("sample refs".."\n")
    for i = 1,3 do
      io.write("/home/we/dust/audio/cc_collection-samples/"..params:get("collection").."/".."cc_"..params:get("collection").."-"..i..".wav".."\n")
      collect_samples(i)
    end
  end
  io.write("last Pattern playmode".."\n")
  for i = 1,3 do
    io.write(grid_pat[i].playmode.."\n")
  end
  io.write("1.2.1: arc patterning".."\n")
  io.write(params:get("arc_patterning").."\n")
  io.write("1.2.2: crow_pad_execute".."\n")
  for i = 1,3 do
    for k = 1,16 do
      io.write(bank[i][k].crow_pad_execute.."\n")
    end
  end
  io.write("1.3: Pattern random pitch range".."\n")
  for i = 1,3 do
    io.write(grid_pat[i].random_pitch_range.."\n")
  end
  io.write("1.3.1".."\n")
  io.write("one_shot_clock_div: "..params:get("one_shot_clock_div").."\n")
  io.write("rec_loop_enc_resolution: "..params:get("rec_loop_enc_resolution").."\n")
  io.write("more 1.3.1".."\n")
  io.write("random_rec_clock_prob: "..params:get("random_rec_clock_prob").."\n")
  io.close(file)
  if selected_coll ~= params:get("collection") then
    meta_copy_coll(selected_coll,params:get("collection"))
  end
  meta_shadow(params:get("collection"))
  --maybe not this? want to clean up
  selected_coll = params:get("collection")
  for i = 1,3 do
    if arc_pat[i].count > 0 then
      save_arc_pattern(i)
    end
    save_midi_pattern(i)
  end
end

function loadstate()
  selected_coll = params:get("collection")
  local file = io.open(_path.data .. "cheat_codes/collections"..selected_coll..".data", "r")
  if file then
    io.input(file)
    if io.read() == "PERMANENCE" then
      for i = 1,3 do
        for k = 1,16 do
          bank[i].id = tonumber(io.read())
          selected[i].x = tonumber(io.read())
          selected[i].y = tonumber(io.read())
          bank[i][k].clip = tonumber(io.read())
          bank[i][k].mode = tonumber(io.read())
          bank[i][k].start_point = tonumber(io.read())
          bank[i][k].end_point = tonumber(io.read())
          bank[i][k].rate = tonumber(io.read())
          local pause_to_boolean = io.read()
          if pause_to_boolean == "true" then
            bank[i][k].pause = true
          else
            bank[i][k].pause = false
          end
          bank[i][k].play_mode = io.read()
          bank[i][k].level = tonumber(io.read())
          local loop_to_boolean = io.read()
          if loop_to_boolean == "true" then
            bank[i][k].loop = true
          else
            bank[i][k].loop = false
          end
          local fifth_to_boolean = io.read()
          if fifth_to_boolean == "true" then
            bank[i][k].fifth = true
          else
            bank[i][k].fifth = false
          end
          bank[i][k].pan = tonumber(io.read())
          bank[i][k].fc = tonumber(io.read())
          bank[i][k].q = tonumber(io.read())
          bank[i][k].lp = tonumber(io.read())
          bank[i][k].hp = tonumber(io.read())
          bank[i][k].bp = tonumber(io.read())
          bank[i][k].fd = tonumber(io.read())
          bank[i][k].br = tonumber(io.read())
          tonumber(io.read())
          bank[i][k].filter_type = 4
          arc_control[i] = tonumber(io.read())
          arc_param[i] = tonumber(io.read())
        end
      params:set("rate slew time ".. i,tonumber(io.read()))
      local string_to_sample = io.read()
      params:set("clip "..i.." sample", string_to_sample)
      local sides = {"delay L: ", "delay R: "}
      for k = 1,2 do
        params:set(sides[k].."rate",tonumber(io.read()))
        params:set(sides[k].."global level",tonumber(io.read()))
        params:set(sides[k].."feedback",tonumber(io.read()))
        params:set(sides[k].."(a) send",tonumber(io.read()))
        params:set(sides[k].."(b) send",tonumber(io.read()))
        params:set(sides[k].."(c) send",tonumber(io.read()))
        params:set(sides[k].."filter cut",tonumber(io.read()))
        params:set(sides[k].."filter q",tonumber(io.read()))
        params:set(sides[k].."filter lp",tonumber(io.read()))
        params:set(sides[k].."filter hp",tonumber(io.read()))
        params:set(sides[k].."filter bp",tonumber(io.read()))
        params:set(sides[k].."filter dry",tonumber(io.read()))
      end
    end
    params:set("offset",tonumber(io.read()))
    else
      print("invalid data file")
    end
    if io.read() == "v1.1" then
      for i = 1,3 do
        for k = 1,16 do
          local enveloped_to_boolean = io.read()
          if enveloped_to_boolean == "true" then
            bank[i][k].enveloped = true
          else
            bank[i][k].enveloped = false
          end
          bank[i][k].envelope_time = tonumber(io.read())
        end
      end
      params:set("zilchmo_patterning",tonumber(io.read()))
      params:set("rec_loop",tonumber(io.read()))
      params:set("live_rec_feedback",tonumber(io.read()))
      tonumber(io.read()) -- kill off quantize_pads
      params:set("quantize_pads",1)
      tonumber(io.read()) -- kill off quantize_pats
      params:set("quantize_pats",1)
      tonumber(io.read()) -- kill off quant_div
      params:set("quant_div",4)
      params:set("quant_div_pats",tonumber(io.read()))
      local bpm_to_clock = tonumber(io.read())
      params:set("bpm",bpm_to_clock)
      params:set("clock_tempo",bpm_to_clock)
      rec.clip = tonumber(io.read())
      rec.start_point = tonumber(io.read())
      rec.end_point = tonumber(io.read())
      softcut.loop_start(1,rec.start_point)
      softcut.loop_end(1,rec.end_point-0.01)
      softcut.position(1,rec.start_point)
    end
    if io.read() == "v1.1.1.1.1.1.1.1" then
      for i = 1,3 do
        step_seq[i].active = tonumber(io.read())
        step_seq[i].meta_duration = tonumber(io.read())
        for k = 1,16 do
          step_seq[i][k].meta_meta_duration = tonumber(io.read())
          step_seq[i][k].assigned_to = tonumber(io.read())
          bank[i][k].tilt = tonumber(io.read())
          bank[i][k].tilt_ease_time = tonumber(io.read())
          bank[i][k].tilt_ease_type = tonumber(io.read())
        end
      end
    end
    if io.read() == "the last params" then
      --params:set("clock_out",tonumber(io.read()))
      local disregard = tonumber(io.read())
      --params:set("crow_clock_out",tonumber(io.read()))
      local disregard = tonumber(io.read())
      --params:set("midi_device",tonumber(io.read()))
      local disregard = tonumber(io.read())
      params:set("loop_enc_resolution",tonumber(io.read()))
      --params:set("clock",tonumber(io.read()))
      local disregard_the_clock_source = tonumber(io.read())
      local disregard = tonumber(io.read())
      params:set("lock_pat",1)
      for i = 1,3 do
        bank[i].crow_execute = tonumber(io.read())
        bank[i].snap_to_bars = tonumber(io.read())
      end
      for i = 1,3 do
        for j = 1,16 do
          bank[i][j].offset = tonumber(io.read())
        end
      end
    end
    if io.read() == "crow execute count" then
      for i = 1,3 do
        crow.count_execute[i] = tonumber(io.read())
      end
    end
    if io.read() == "step seq loop points" then
      for i = 1,3 do
        step_seq[i].start_point = tonumber(io.read())
        step_seq[i].current_step = step_seq[i].start_point
        step_seq[i].end_point = tonumber(io.read())
      end
    end
    if io.read() == "Live buffer max" then
      params:set("live_buff_rate",tonumber(io.read()))
    end
    if io.read() == "loop Pattern per step" then
      for i = 1,3 do
        for k = 1,16 do
          step_seq[i][k].loop_pattern = tonumber(io.read())
        end
      end
    end
    if io.read() == "collect live?" then
      local restore_live = tonumber(io.read())
      params:set("collect_live",restore_live)
      if restore_live == 2 then
        if io.read() == "sample refs" then
          for i = 1,3 do
            local string_to_sample = io.read()
            reload_collected_samples(string_to_sample,i)
          end
        end
      end
    end
    if io.read() == "last Pattern playmode" then
      for i = 1,3 do
        grid_pat[i].playmode = tonumber(io.read())
        --set_pattern_mode(grid_pat[i],i)
      end
    end
    if io.read() == "1.2.1: arc patterning" then
      params:set("arc_patterning", tonumber(io.read()))
    end
    if io.read() == "1.2.2: crow_pad_execute" then
      for i = 1,3 do
        for k = 1,16 do
          bank[i][k].crow_pad_execute = tonumber(io.read())
        end
      end
    end
    if io.read() == "1.3: Pattern random pitch range" then
      for i  = 1,3 do
        grid_pat[i].random_pitch_range = tonumber(io.read())
      end
    end
    if io.read() == "1.3.1" then
      params:set("one_shot_clock_div", tonumber(string.match(io.read(), ': (.*)')))
      params:set("rec_loop_enc_resolution", tonumber(string.match(io.read(), ': (.*)')))
    end
    if io.read() == "more 1.3.1" then
      params:set("random_rec_clock_prob", tonumber(string.match(io.read(), ': (.*)')))
    end
    io.close(file)
    for i = 1,3 do
      if bank[i][bank[i].id].loop == true then
        cheat(i,bank[i].id)
      else
        softcut.loop(i+1, 0)
        softcut.position(i+1,bank[i][bank[i].id].start_point)
      end
    end
  end
  already_saved()
  for i = 1,3 do
    if step_seq[i].active == 1 and step_seq[i][step_seq[i].current_step].assigned_to ~= 0 then
      test_load(step_seq[i][step_seq[i].current_step].assigned_to+((i-1)*8),i)
    end
  end
  --maybe?
  if selected_coll ~= params:get("collection") then
    meta_shadow(selected_coll)
  elseif selected_coll == params:get("collection") then
    cleanup()
  end
  one_point_two()
  for i = 1,3 do
    local dirname = _path.data .. "cheat_codes/arc-patterns/collection-"..params:get("collection").."/encoder-"..i..".data"
    if os.rename(dirname, dirname) ~= nil then
      load_arc_pattern(i)
    end
  end
  for i = 1,3 do
    local dirname = _path.data .. "cheat_codes/arc-patterns/collection-"..params:get("collection").."/encoder-"..i..".data"
    if os.rename(dirname, dirname) ~= nil then
      load_arc_pattern(i)
    end
  end
  for i = 1,3 do
    local dirname = _path.data .. "cheat_codes/midi-patterns/collection-"..params:get("collection").."/"..i..".data"
    if os.rename(dirname, dirname) ~= nil then
      load_midi_pattern(i)
    end
  end
end

function test_save(i)
  if grid.alt_pp == 0 then
    if grid_pat[i].count > 0 and grid_pat[i].rec == 0 then
      copy_entire_pattern(i)
      save_pattern(i,pattern_saver[i].save_slot+8*(i-1))
      pattern_saver[i].saved[pattern_saver[i].save_slot] = 1
      pattern_saver[i].load_slot = pattern_saver[i].save_slot
      g:led(math.floor((i-1)*5)+1,9-pattern_saver[i].save_slot,15)
      g:refresh()
    else
      print("no pattern data to save")
      g:led(math.floor((i-1)*5)+1,9-pattern_saver[i].save_slot,0)
      g:refresh()
    end
  else
    if pattern_saver[i].saved[pattern_saver[i].save_slot] == 1 then
      delete_pattern(pattern_saver[i].save_slot+8*(i-1))
      pattern_saver[i].saved[pattern_saver[i].save_slot] = 0
      pattern_saver[i].load_slot = 0
    else
      print("no pattern data to delete")
    end
  end
end

function test_load(slot,destination)
  if pattern_saver[destination].saved[slot-((destination-1)*8)] == 1 then
    if grid_pat[destination].play == 1 then
      stop_pattern(grid_pat[destination])
    elseif grid_pat[destination].tightened_start == 1 then
      grid_pat[destination].tightened_start = 0
      grid_pat[destination].step = grid_pat[destination].start_point
      quantized_grid_pat[destination].current_step = grid_pat[destination].start_point
      quantized_grid_pat[destination].sub_step = 1
    end
    load_pattern(slot,destination)
    start_pattern(grid_pat[destination])
  end
end

function save_pattern(source,slot)
  local file = io.open(_path.data .. "cheat_codes/pattern"..selected_coll.."_"..slot..".data", "w+")
  io.output(file)
  io.write("stored pad pattern: collection "..selected_coll.." + slot "..slot.."\n")
  io.write(original_pattern[source].count .. "\n")
  for i = 1,original_pattern[source].count do
    io.write(original_pattern[source].time[i] .. "\n")

    -- new stuff
    if original_pattern[source].event[i] ~= "pause" then
      io.write(original_pattern[source].event[i].id .. "\n")
      io.write(original_pattern[source].event[i].rate .. "\n")
      io.write(tostring(original_pattern[source].event[i].loop) .. "\n")
      if original_pattern[source].event[i].mode ~= nil then
        io.write(original_pattern[source].event[i].mode .. "\n")
      else
        io.write("nil" .. "\n")
      end
      io.write(tostring(original_pattern[source].event[i].pause) .. "\n")
      io.write(original_pattern[source].event[i].start_point .. "\n")
      if original_pattern[source].event[i].clip ~= nil then
        io.write(original_pattern[source].event[i].clip .. "\n")
      else
        io.write("nil" .. "\n")
      end
      io.write(original_pattern[source].event[i].end_point .. "\n")
      if original_pattern[source].event[i].rate_adjusted ~= nil then
        io.write(tostring(original_pattern[source].event[i].rate_adjusted) .. "\n")
      else
        io.write("nil" .. "\n")
      end
      io.write(original_pattern[source].event[i].y .. "\n")
      io.write(original_pattern[source].event[i].x .. "\n")
      io.write(tostring(original_pattern[source].event[i].action) .. "\n")
      io.write(original_pattern[source].event[i].i .. "\n")
      if original_pattern[source].event[i].previous_rate ~= nil then
        io.write(original_pattern[source].event[i].previous_rate .. "\n")
      else
        io.write("nil" .. "\n")
      end
      if original_pattern[source].event[i].row ~=nil then
        io.write(original_pattern[source].event[i].row .. "\n")
      else
        io.write("nil" .. "\n")
      end
      if original_pattern[source].event[i].con ~= nil then
        io.write(original_pattern[source].event[i].con .. "\n")
      else
        io.write("nil" .. "\n")
      end
      if original_pattern[source].event[i].bank ~= nil and #original_pattern[source].event > 0 then
        io.write(original_pattern[source].event[i].bank .. "\n")
      else
        io.write("nil" .. "\n")
      end
    else
      io.write("pause" .. "\n")
    end
  end
  --/new stuff!

  io.write(original_pattern[source].metro.props.time .. "\n")
  io.write(original_pattern[source].prev_time .. "\n")
  io.write("which playmode?" .. "\n")
  io.write(original_pattern[source].playmode .. "\n")
  io.write("start point" .. "\n")
  io.write(original_pattern[source].start_point .. "\n")
  io.write("end point" .. "\n")
  io.write(original_pattern[source].end_point .. "\n")

  --new stuff, quantum and time_beats!
  io.write("cheat codes 2.0" .. "\n")
  for i = 1,original_pattern[source].count do
    io.write(original_pattern[source].quantum[i] .. "\n")
    io.write(original_pattern[source].time_beats[i] .. "\n")
  end
  --/new stuff, quantum and time_beats!

  io.close(file)
  save_external_timing(source,slot)
  print("saved pattern "..source.." to slot "..slot)
end

function already_saved()
  for i = 1,24 do
    local file = io.open(_path.data .. "cheat_codes/pattern"..selected_coll.."_"..i..".data", "r")
    if file then
      io.input(file)
      if io.read() == "stored pad pattern: collection "..selected_coll.." + slot "..i then
        local current = math.floor((i-1)/8)+1
        pattern_saver[current].saved[i-(8*(current-1))] = 1
      else
        local current = math.floor((i-1)/8)+1
        pattern_saver[current].saved[i-(8*(current-1))] = 0
        os.remove(_path.data .. "cheat_codes/pattern" ..selected_coll.."_"..i..".data")
      end
      io.close(file)
    else
      local current = math.floor((i-1)/8)+1
      pattern_saver[current].saved[i-(8*(current-1))] = 0
    end
  end
end

function one_point_two()
  for i = 1,24 do
    local file = io.open(_path.data .. "cheat_codes/pattern"..selected_coll.."_"..i..".data", "r")
    if file then
      io.input(file)
      if io.read() == "stored pad pattern: collection "..selected_coll.." + slot "..i then
        local current = math.floor((i-1)/8)+1
                ---
        --create pre-1.2 external files
        local ext_file = io.open(_path.data .. "cheat_codes/external-timing/pattern"..selected_coll.."_"..i.."_external-timing.data", "r")
        if ext_file then
          io.close(ext_file)
        else
          load_pattern(i,current)
        end
      else
      end
      io.close(file)
    end
  end
  for i = 1,3 do
    grid_pat[i]:rec_stop()
    grid_pat[i]:stop()
    grid_pat[i].tightened_start = 0
    grid_pat[i]:clear()
    pattern_saver[i].load_slot = 0
  end
end

function clear_zero()
  for i = 1,24 do
    local file = io.open(_path.data .. "cheat_codes/pattern0_"..i..".data", "r")
    if file then
      io.input(file)
      if io.read() == "stored pad pattern: collection 0 + slot "..i then
        os.remove(_path.data .. "cheat_codes/pattern0_"..i..".data")
        print("cleared default pattern")
      end
      io.close(file)
    end
  end
  for i = 1,24 do
    local external_timing_file = io.open(_path.data .. "cheat_codes/external-timing/pattern0_"..i.."_external-timing.data", "r")
    if external_timing_file then
      io.input(external_timing_file)
      if io.read() == "external clock timing for stored pad pattern: collection 0 + slot "..i then
        os.remove(_path.data .. "cheat_codes/external-timing/pattern0_"..i.."_external-timing.data")
        print("cleared default external timing")
      end
      io.close(external_timing_file)
    end
  end
end

function delete_pattern(slot)
  local file = io.open(_path.data .. "cheat_codes/pattern"..selected_coll.."_"..slot..".data", "w+")
  io.output(file)
  io.write()
  io.close(file)
  print("deleted pattern from slot "..slot)
  local external_timing_file = io.open(_path.data .. "cheat_codes/external-timing/pattern"..selected_coll.."_"..slot.."_external-timing.data", "w+")
  io.output(external_timing_file)
  io.write()
  io.close(external_timing_file)
  print("deleted external timing from slot "..slot)
end

function copy_pattern_across_coll(read_coll,write_coll,slot)
  local infile = io.open(_path.data .. "cheat_codes/pattern"..read_coll.."_"..slot..".data", "r")
  local outfile = io.open(_path.data .. "cheat_codes/pattern"..write_coll.."_"..slot..".data", "w+")
  io.output(outfile)
  for line in infile:lines() do
    if line == "stored pad pattern: collection "..read_coll.." + slot "..slot then
      io.write("stored pad pattern: collection "..write_coll.." + slot "..slot.."\n")
    else
      io.write(line.."\n")
    end
  end
  io.close(infile)
  io.close(outfile)

  --/externalshadow
  local external_timing_infile = io.open(_path.data .. "cheat_codes/external-timing/pattern"..read_coll.."_"..slot.."_external-timing.data", "r")
  local external_timing_outfile = io.open(_path.data .. "cheat_codes/external-timing/pattern"..write_coll.."_"..slot.."_external-timing.data", "w+")
  io.output(external_timing_outfile)
  for line in external_timing_infile:lines() do
    if line == "external clock timing for stored pad pattern: collection "..read_coll.." + slot "..slot then
      io.write("external clock timing for stored pad pattern: collection "..write_coll.." + slot "..slot.."\n")
    else
      io.write(line.."\n")
    end
  end
  io.close(external_timing_infile)
  io.close(external_timing_outfile)
  --externalshadow/
  
end

function shadow_pattern(read_coll,write_coll,slot)
  local infile = io.open(_path.data .. "cheat_codes/pattern"..read_coll.."_"..slot..".data", "r")
  local outfile = io.open(_path.data .. "cheat_codes/shadow-pattern"..write_coll.."_"..slot..".data", "w+")
  io.output(outfile)
  for line in infile:lines() do
    if line == "stored pad pattern: collection "..read_coll.." + slot "..slot then
      io.write("stored pad pattern: collection "..write_coll.." + slot "..slot.."\n")
    else
      io.write(line.."\n")
    end
  end
  io.close(infile)
  io.close(outfile)
  
  --/externalshadow
  local external_timing_infile = io.open(_path.data .. "cheat_codes/external-timing/pattern"..read_coll.."_"..slot.."_external-timing.data", "r")
  local external_timing_outfile = io.open(_path.data .. "cheat_codes/external-timing/shadow-pattern"..write_coll.."_"..slot.."_external-timing.data", "w+")
  io.output(external_timing_outfile)
  for line in external_timing_infile:lines() do
    if line == "external clock timing for stored pad pattern: collection "..read_coll.." + slot "..slot then
      io.write("external clock timing for stored pad pattern: collection "..write_coll.." + slot "..slot.."\n")
    else
      io.write(line.."\n")
    end
  end
  io.close(external_timing_infile)
  io.close(external_timing_outfile)
  --externalshadow/

end

function meta_shadow(coll)
  for i = 1,3 do
    for j = 1,8 do
      if pattern_saver[i].saved[j] == 1 then
        shadow_pattern(coll,coll,j+(8*(i-1)))
      elseif pattern_saver[i].saved[j] == 0 then
        local file = io.open(_path.data .. "cheat_codes/shadow-pattern"..coll.."_"..j+(8*(i-1))..".data", "w+")
        -- need an already saved shadow thing here to clear out
        if file then
          io.output(file)
          io.write()
          io.close(file)
        end
        
        --/externalshadow
        local external_timing_file = io.open(_path.data .. "cheat_codes/external-timing/shadow-pattern"..coll.."_"..j+(8*(i-1)).."_external-timing.data", "w+")
        if external_timing_file then
          io.output(external_timing_file)
          io.write()
          io.close(external_timing_file)
        end
        --externalshadow/
      end
    end
  end
end

function clear_empty_shadows(coll)
  for i = 1,24 do
    local file = io.open(_path.data .. "cheat_codes/shadow-pattern"..coll.."_"..i..".data", "r")
    if file then
      io.input(file)
      if io.read() == "stored pad pattern: collection "..coll.." + slot "..i then
        local current = math.floor((i-1)/8)+1
        pattern_saver[current].saved[i-(8*(current-1))] = 1
      else
        local current = math.floor((i-1)/8)+1
        pattern_saver[current].saved[i-(8*(current-1))] = 0
        os.remove(_path.data .. "cheat_codes/shadow-pattern" ..coll.."_"..i..".data")
      end
      io.close(file)
    else
      local current = math.floor((i-1)/8)+1
      pattern_saver[current].saved[i-(8*(current-1))] = 0
    end
  end
  
  --/externalshadow
  for i = 1,24 do
    local file = io.open(_path.data .. "cheat_codes/external-timing/shadow-pattern"..coll.."_"..i.."_external-timing.data", "r")
    if file then
      io.input(file)
      if io.read() == "external clock timing for stored pad pattern: collection "..coll.." + slot "..i then
        local current = math.floor((i-1)/8)+1
        pattern_saver[current].saved[i-(8*(current-1))] = 1
      else
        local current = math.floor((i-1)/8)+1
        pattern_saver[current].saved[i-(8*(current-1))] = 0
        os.remove(_path.data .. "cheat_codes/external-timing/shadow-pattern" ..coll.."_"..i.."_external-timing.data")
      end
      io.close(file)
    end
  end
  --externalshadow/
  
end

function shadow_to_play(coll,slot)
  local infile = io.open(_path.data .. "cheat_codes/shadow-pattern"..coll.."_"..slot..".data", "r")
  local outfile = io.open(_path.data .. "cheat_codes/pattern"..coll.."_"..slot..".data", "w+")
  io.output(outfile)
  if infile then
    for line in infile:lines() do
      if line == "stored pad pattern: collection "..coll.." + slot "..slot then
        io.write("stored pad pattern: collection "..coll.." + slot "..slot.."\n")
      else
        io.write(line.."\n")
      end
    end
    io.close(infile)
    io.close(outfile)
  end
  
  --/externalshadow
  local external_timing_infile = io.open(_path.data .. "cheat_codes/external-timing/shadow-pattern"..coll.."_"..slot.."_external-timing.data", "r")
  local external_timing_outfile = io.open(_path.data .. "cheat_codes/external-timing/pattern"..coll.."_"..slot.."_external-timing.data", "w+")
  io.output(external_timing_outfile)
  if external_timing_infile then
    for line in external_timing_infile:lines() do
      if line == "external clock timing for stored pad pattern: collection "..coll.." + slot "..slot then
        io.write("external clock timing for stored pad pattern: collection "..coll.." + slot "..slot.."\n")
      else
        io.write(line.."\n")
      end
    end
    io.close(external_timing_infile)
    io.close(external_timing_outfile)
  end
  --externalshadow/
  
end

function meta_copy_coll(read_coll,write_coll)
  for i = 1,3 do
    for j = 1,8 do
      if pattern_saver[i].saved[j] == 1 then
        copy_pattern_across_coll(read_coll,write_coll,j+(8*(i-1)))
      elseif pattern_saver[i].saved[j] == 0 then
        local file = io.open(_path.data .. "cheat_codes/pattern"..write_coll.."_"..j+(8*(i-1))..".data", "w+")
        if file then
          io.output(file)
          io.write()
          io.close(file)
        end
        
        --/externalshadow
        local external_timing_file = io.open(_path.data .. "cheat_codes/external-timing/pattern"..write_coll.."_"..j+(8*(i-1)).."_external-timing.data", "w+")
        if external_timing_file then
          io.output(external_timing_file)
          io.write()
          io.close(external_timing_file)
        end
        --externalshadow/
        
      end
    end
  end
end

function load_pattern(slot,destination)
  local file = io.open(_path.data .. "cheat_codes/pattern"..selected_coll.."_"..slot..".data", "r")
  if file then
    io.input(file)
    if io.read() == "stored pad pattern: collection "..selected_coll.." + slot "..slot then
      grid_pat[destination].event = {}
      grid_pat[destination].count = tonumber(io.read())
      for i = 1,grid_pat[destination].count do
        grid_pat[destination].time[i] = tonumber(io.read())

        -- new stuff
        local pause_or_id = io.read()
        print(pause_or_id)
        grid_pat[destination].event[i] = {}
        if pause_or_id ~= "pause" then
          grid_pat[destination].event[i].id = {}
          grid_pat[destination].event[i].rate = {}
          grid_pat[destination].event[i].loop = {}
          grid_pat[destination].event[i].mode = {}
          grid_pat[destination].event[i].pause = {}
          grid_pat[destination].event[i].start_point = {}
          grid_pat[destination].event[i].clip = {}
          grid_pat[destination].event[i].end_point = {}
          grid_pat[destination].event[i].rate_adjusted = {}
          grid_pat[destination].event[i].y = {}
          grid_pat[destination].event[i].x = {}
          grid_pat[destination].event[i].action = {}
          grid_pat[destination].event[i].i = {}
          grid_pat[destination].event[i].previous_rate = {}
          grid_pat[destination].event[i].row = {}
          grid_pat[destination].event[i].con = {}
          grid_pat[destination].event[i].bank = nil
          --grid_pat[destination].event[i].id = tonumber(io.read())
          -- new stuff
          grid_pat[destination].event[i].id = tonumber(pause_or_id)
          grid_pat[destination].event[i].rate = tonumber(io.read())
          local loop_to_boolean = io.read()
          if loop_to_boolean == "true" then
            grid_pat[destination].event[i].loop = true
          else
            grid_pat[destination].event[i].loop = false
          end
          grid_pat[destination].event[i].mode = tonumber(io.read())
          local pause_to_boolean = io.read()
          if pause_to_boolean == "true" then
            grid_pat[destination].event[i].pause = true
          else
            grid_pat[destination].event[i].pause = false
          end
          grid_pat[destination].event[i].start_point = tonumber(io.read())
          grid_pat[destination].event[i].clip = tonumber(io.read())
          grid_pat[destination].event[i].end_point = tonumber(io.read())
          local rate_adjusted_to_boolean = io.read()
          if rate_adjusted_to_boolean == "true" then
            grid_pat[destination].event[i].rate_adjusted = true
          else
            grid_pat[destination].event[i].rate_adjusted = false
          end
          grid_pat[destination].event[i].y = tonumber(io.read())
          local loaded_x = tonumber(io.read())
          grid_pat[destination].event[i].action = io.read()
          grid_pat[destination].event[i].i = destination
          local source = tonumber(io.read())
          if destination < source then
            grid_pat[destination].event[i].x = loaded_x - (5*(source-destination))
          elseif destination > source then
            grid_pat[destination].event[i].x = loaded_x + (5*(destination-source))
          elseif destination == source then
            grid_pat[destination].event[i].x = loaded_x
          end
          grid_pat[destination].event[i].previous_rate = tonumber(io.read())
          grid_pat[destination].event[i].row = tonumber(io.read())
          grid_pat[destination].event[i].con = io.read()
          local loaded_bank = tonumber(io.read())
          if loaded_bank ~= nil then
            if destination < source then
              grid_pat[destination].event[i].bank = loaded_bank - (5*(source-destination))
            elseif destination > source then
              grid_pat[destination].event[i].bank = loaded_bank + (5*(source-destination))
            elseif destination == source then
              grid_pat[destination].event[i].bank = loaded_bank
            end
          end
        else
          grid_pat[destination].event[i] = "pause"
        end

      end
      grid_pat[destination].metro.props.time = tonumber(io.read())
      grid_pat[destination].prev_time = tonumber(io.read())
      if io.read() == "which playmode?" then
        grid_pat[destination].playmode = tonumber(io.read())
      else
        grid_pat[destination].playmode = 1
      end
      --set_pattern_mode(grid_pat[destination],destination)
      if io.read() == "start point" then
        grid_pat[destination].start_point = tonumber(io.read())
      else
        grid_pat[destination].start_point = 1
      end
      if io.read() == "end point" then
        grid_pat[destination].end_point = tonumber(io.read())
      else
        grid_pat[destination].end_point = grid_pat[destination].count
      end

      --new stuff, quantum and time_beats!
      if io.read() == "cheat codes 2.0" then
        for i = 1,grid_pat[destination].count do
          grid_pat[destination].quantum[i] = tonumber(io.read())
          grid_pat[destination].time_beats[i] = tonumber(io.read())
        end
      end
      --/new stuff, quantum and time_beats!
    end

    io.close(file)
    load_external_timing(destination,slot)
  else
    print("nofile")
  end
end

function cleanup()
  clear_zero()
  for i = 1,3 do
    for j = 1,8 do
      shadow_to_play(selected_coll,j+(8*(i-1)))
    end
  end
  
  --need all this to just happen at cleanup after save
  for i = 1,24 do
    local file = io.open(_path.data .. "cheat_codes/pattern"..selected_coll.."_"..i..".data", "r")
    if file then
      io.input(file)
      if io.read() == "stored pad pattern: collection "..selected_coll.." + slot "..i then
        local current = math.floor((i-1)/8)+1
        pattern_saver[current].saved[i-(8*(current-1))] = 1
      else
        local current = math.floor((i-1)/8)+1
        pattern_saver[current].saved[i-(8*(current-1))] = 0
        os.remove(_path.data .. "cheat_codes/pattern" ..selected_coll.."_"..i..".data")
      end
      io.close(file)
    else
      local current = math.floor((i-1)/8)+1
      pattern_saver[current].saved[i-(8*(current-1))] = 0
    end
  end
  
  --/externalshadow
  for i = 1,24 do
    local file = io.open(_path.data .. "cheat_codes/external-timing/pattern"..selected_coll.."_"..i.."_external-timing.data", "r")
    if file then
      io.input(file)
      if io.read() == "external clock timing for stored pad pattern: collection "..selected_coll.." + slot "..i then
        local current = math.floor((i-1)/8)+1
        pattern_saver[current].saved[i-(8*(current-1))] = 1
      else
        local current = math.floor((i-1)/8)+1
        pattern_saver[current].saved[i-(8*(current-1))] = 0
        os.remove(_path.data .. "cheat_codes/external-timing/pattern" ..selected_coll.."_"..i.."_external-timing.data")
      end
      io.close(file)
    else
      --print("can't clean these external files?")
    end
  end
  --externalshadow/
  
  clear_empty_shadows(selected_coll)
end

-- arc pattern stuff!

function save_arc_pattern(which)
  local dirname = _path.data.."cheat_codes/arc-patterns/"
  if os.rename(dirname, dirname) == nil then
    os.execute("mkdir " .. dirname)
  end
  
  local dirname = _path.data.."cheat_codes/arc-patterns/collection-"..selected_coll.."/"
  if os.rename(dirname, dirname) == nil then
    os.execute("mkdir " .. dirname)
  end
  
  local file = io.open(_path.data .. "cheat_codes/arc-patterns/collection-"..selected_coll.."/encoder-"..which..".data", "w+")
  io.output(file)
  io.write("stored arc pattern: collection "..selected_coll.." + encoder "..which.."\n")
  io.write(arc_pat[which].count .. "\n")
  for i = 1,arc_pat[which].count do
    io.write(arc_pat[which].time[i] .. "\n")
    io.write(arc_pat[which].event[i].i .. "\n")
    io.write(arc_pat[which].event[i].param .. "\n")
    io.write(arc_pat[which].event[i].pad .. "\n")
    io.write(arc_pat[which].event[i].start_point .. "\n")
    io.write(arc_pat[which].event[i].end_point .. "\n")
    io.write(arc_pat[which].event[i].prev_tilt .. "\n")
    io.write(arc_pat[which].event[i].tilt .. "\n")
  end
  io.write(arc_pat[which].metro.props.time .. "\n")
  io.write(arc_pat[which].prev_time .. "\n")
  io.write("start point: " .. arc_pat[which].start_point .. "\n")
  io.write("end point: " .. arc_pat[which].end_point .. "\n")
  io.close(file)
  print("saved arc pattern for encoder "..which)
end

function load_arc_pattern(which)
  local file = io.open(_path.data .. "cheat_codes/arc-patterns/collection-"..selected_coll.."/encoder-"..which..".data", "r")
  if file then
    io.input(file)
    if io.read() == "stored arc pattern: collection "..selected_coll.." + encoder "..which then
      arc_pat[which].event = {}
      arc_pat[which].count = tonumber(io.read())
      for i = 1,arc_pat[which].count do
        arc_pat[which].time[i] = tonumber(io.read())
        arc_pat[which].event[i] = {}
        arc_pat[which].event[i].i = {}
        arc_pat[which].event[i].param = {}
        arc_pat[which].event[i].pad = {}
        arc_pat[which].event[i].start_point = {}
        arc_pat[which].event[i].end_point = {}
        arc_pat[which].event[i].prev_tilt = {}
        arc_pat[which].event[i].tilt = {}
        --
        arc_pat[which].event[i].i = tonumber(io.read())
        arc_pat[which].event[i].param = tonumber(io.read())
        arc_pat[which].event[i].pad = tonumber(io.read())
        arc_pat[which].event[i].start_point = tonumber(io.read())
        arc_pat[which].event[i].end_point = tonumber(io.read())
        arc_pat[which].event[i].prev_tilt = tonumber(io.read())
        arc_pat[which].event[i].tilt = tonumber(io.read())
      end
      arc_pat[which].metro.props.time = tonumber(io.read())
      arc_pat[which].prev_time = tonumber(io.read())
      local new_arc_array = io.read()
      if new_arc_array ~= nil then
        arc_pat[which].start_point = tonumber(string.match(new_arc_array, ': (.*)'))
      else
        arc_pat[which].start_point = 1
      end
      local new_arc_array = io.read()
      if new_arc_array ~= nil then
        arc_pat[which].end_point = tonumber(string.match(new_arc_array, ': (.*)'))
      else
        arc_pat[which].end_point = arc_pat[which].count
      end
    end
    io.close(file)
  else
    print("nofile")
  end
end

function save_midi_pattern(which)
  local dirname = _path.data.."cheat_codes/midi-patterns/"
  if os.rename(dirname, dirname) == nil then
    os.execute("mkdir " .. dirname)
  end
  
  local dirname = _path.data.."cheat_codes/midi-patterns/collection-"..selected_coll.."/"
  if os.rename(dirname, dirname) == nil then
    os.execute("mkdir " .. dirname)
  end
  
  local file = io.open(_path.data .. "cheat_codes/midi-patterns/collection-"..selected_coll.."/"..which..".data", "w+")
  io.output(file)
  if midi_pat[which].count > 0 then
    io.write("stored midi pattern: collection "..selected_coll..", pattern "..which.."\n")
    io.write("total: "..midi_pat[which].count .. "\n")
    for i = 1,midi_pat[which].count do
      io.write("unquant time: "..midi_pat[which].time[i] .. "\n")
      --io.write("quant duration: "..midi_pat[which].time_beats[i] .. "\n")
      io.write("quant duration: 0.8".."\n")
      io.write("target: "..midi_pat[which].event[i].target .. "\n")
      io.write("note: "..midi_pat[which].event[i].note .. "\n")
    end
    io.write("metro props time: "..midi_pat[which].metro.props.time .. "\n")
    io.write("metro prev time: "..midi_pat[which].prev_time .. "\n")
    io.write("pattern start point: " .. midi_pat[which].start_point .. "\n")
    io.write("pattern end point: " .. midi_pat[which].end_point .. "\n")
  else
    io.write("no data present")
  end
  io.close(file)
  print("saved midi pattern "..which)
end

function load_midi_pattern(which)
  local file = io.open(_path.data .. "cheat_codes/midi-patterns/collection-"..selected_coll.."/"..which..".data", "r")
  if file then
    io.input(file)
    if io.read() == "stored midi pattern: collection "..selected_coll..", pattern "..which then
      midi_pat[which].event = {}
      midi_pat[which].count = tonumber(string.match(io.read(), ': (.*)'))
      for i = 1,midi_pat[which].count do
        midi_pat[which].time[i] = tonumber(string.match(io.read(), ': (.*)'))
        midi_pat[which].time_beats[i] = tonumber(string.match(io.read(), ': (.*)'))
        midi_pat[which].event[i] = {}
        midi_pat[which].event[i].target = tonumber(string.match(io.read(), ': (.*)'))
        midi_pat[which].event[i].note = tonumber(string.match(io.read(), ': (.*)'))
        --
      end
      midi_pat[which].metro.props.time = tonumber(string.match(io.read(), ': (.*)'))
      midi_pat[which].prev_time = tonumber(string.match(io.read(), ': (.*)'))
      midi_pat[which].start_point = tonumber(string.match(io.read(), ': (.*)'))
      midi_pat[which].end_point = tonumber(string.match(io.read(), ': (.*)'))
    end
    io.close(file)
  else
    print("nofile")
  end
end