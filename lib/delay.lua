local delays = {}

function delays.init(target)
  local clocked_add = {4,3,2,3,4}
  local clocked_num = {7,5,3,4,5}
  
  clocked_delays =
  { 16, 63/4,   47/4,   31/2,   46/3,   61/4
  , 15, 59/4,   44/3,   29/2,   43/3,   57/4
  , 14, 55/4,   41/3,   27/2,   40/3,   53/4
  , 13, 51/4,   38/3,   25/2,   37/3,   49/4
  , 12, 47/4,   35/3,   23/2,   34/3,   45/4
  , 11, 43/4,   32/3,   21/2,   31/3,   41/4 
  , 10, 39/4,   29/3,   19/2,   28/3,   37/4
  , 9,  35/4,   26/3,   17/2,   25/3,   33/4
  , 8,  31/4,   23/3,   15/2,   22/3,   29/4
  , 7,  27/4,   20/3,   13/2,   19/3,   25/4 
  , 6,  23/4,   17/3,   11/2,   16/3,   21/4
  , 5,  19/4,   14/3,   9/2,    13/3,   17/4
  , 4,  15/4,   11/3,   7/2,    10/3,   13/4
  , 3,  11/4,   8/3 ,   5/2,    7/3 ,   9/4
  , 2,  7/4,    5/3 ,   3/2,    4/3 ,   5/4
  , 1,  4/5,    3/4 ,   2/3,    3/5,    4/7 , 1/2, 1/4
  }
  -- clocked_fracs = {(1+1), (1+3/4), (1+2/3), (1+1/2), (1+1/3), (1+1/4), (1/1),(4/5),(3/4),(2/3),(3/5),(4/7),(1/2)}
  -- flipped = 2,7,5,3,4,5,1
  -- flopped = 1,4,3,2,3,4,1
  -- flopped[1]/flipped[1], 
  clocked_num = {1260,1176,1155,1120,1092,1080,1050,840,735,700,630,560,525,420,336,315,280,252,240,210}
  clocked_denom = 420
  clocked_mults = 5
  clocked_rates = {}
  
  delay = {}
  for i = 1,2 do
    delay[i] = {}
    delay[i].id = 7
    delay[i].arc_rate_tracker = 7
    delay[i].arc_rate = 7
    delay[i].rate = 1
    delay[i].start_point = 41 + (30*(i-1))
    delay[i].end_point = delay[i].start_point + clock.get_beat_sec()
    delay[i].clocked_length = clocked_delays[7]
    delay[i].free_end_point = delay[i].start_point + 1
    delay[i].modifier = 1
    delay[i].mode = "clocked"
    delay[i].feedback_mute = false
    delay[i].level_mute = false
    delay[i].send_mute = false
    delay[i].held = 0
    delay[i].saver_active = false
    delay[i].selected_bundle = 0
    delay[i].wobble_hold = false
  end

  delay_bundle = { {},{} }
  for i = 1,2 do
    for j = 1,16 do
      delay_bundle[i][j] = {}
      delay_bundle[i][j].saved = false
      -- delay_bundle[i][j].load_slot = 0
      -- delay_bundle[i][j].save_slot = nil
    end
  end

  delay_grid = {}
  delay_grid.bank = 1

end

function delays.build_bundle(target,slot)
  -- delay[target].saver_active = true -- declare this external to the function
  clock.sleep(1)
  if delay[target].saver_active then
    local b = delay_bundle[target][slot]
    local delay_name = target == 1 and "delay L: " or "delay R: "
    b.mode = params:get(delay_name.."mode")
    b.clocked_length = params:get(delay_name.."div/mult")
    b.free_end_point = params:get(delay_name.."free length")
    b.fade_time = params:get(delay_name.."fade time")
    b.modifier = delay[target].modifier
    b.rate = params:get(delay_name.."rate")
    b.feedback = params:get(delay_name.."feedback")
    b.filter_cut = params:get(delay_name.."filter cut")
    b.filter_q = params:get(delay_name.."filter q")
    b.filter_lp = params:get(delay_name.."filter lp")
    b.filter_hp = params:get(delay_name.."filter hp")
    b.filter_bp = params:get(delay_name.."filter bp")
    b.filter_dry = params:get(delay_name.."filter dry")
    b.global_level = params:get(delay_name.."global level")
    b.saved = true
    delay[target].selected_bundle = slot
  end
  delay[target].saver_active = false
end

function delays.restore_bundle(target,slot)
  local b = delay_bundle[target][slot]
  local delay_name = target == 1 and "delay L: " or "delay R: "
  if b.mode ~= nil then
    params:set(delay_name.."mode", b.mode)
    params:set(delay_name.."div/mult", b.clocked_length)
    params:set(delay_name.."free length", b.free_end_point)
    params:set(delay_name.."fade time", b.fade_time)
    params:set(delay_name.."rate", b.rate)
    delay[target].modifier = b.modifier
    params:set(delay_name.."feedback", b.feedback)
    params:set(delay_name.."filter cut", b.filter_cut)
    params:set(delay_name.."filter q", b.filter_q)
    params:set(delay_name.."filter lp", b.filter_lp)
    params:set(delay_name.."filter hp", b.filter_hp)
    params:set(delay_name.."filter bp", b.filter_bp)
    params:set(delay_name.."filter dry", b.filter_dry)
    params:set(delay_name.."global level", b.global_level)
  else
    print(delay_name.."no data saved in slot "..slot)
  end
end

function delays.clear_bundle(target,slot)
  delay_bundle[target][slot] = {}
  delay_bundle[target][slot].saved = false
  delay[target].selected_bundle = 0
end

function delays.savestate(source,collection)
  local del_name = source == 1 and "L" or "R"
  local dirname = _path.data.."cheat_codes/delays/"
  if os.rename(dirname, dirname) == nil then
    os.execute("mkdir " .. dirname)
  end
  
  local dirname = _path.data.."cheat_codes/delays/collection-"..collection.."/"
  if os.rename(dirname, dirname) == nil then
    os.execute("mkdir " .. dirname)
  end

  tab.save(delay_bundle[source],_path.data .. "cheat_codes/delays/collection-"..collection.."/"..del_name..".data")
end

function delays.loadstate(collection)
  local del_name = {"L","R"}
  for i = 1,2 do
    if tab.load(_path.data .. "cheat_codes/delays/collection-"..collection.."/"..del_name[i]..".data") ~= nil then
      delay_bundle[i] = tab.load(_path.data .. "cheat_codes/delays/collection-"..collection.."/"..del_name[i]..".data")
    end
  end
end

function delays.quick_action(target,param)
  if param == "level mute" then
    delay[target].level_mute = not delay[target].level_mute
    if delay[target].level_mute then
      softcut.level_slew_time(target+4,0.25)
      if params:get(target == 1 and "delay L: global level" or "delay R: global level") == 0 then
        softcut.level(target+4,1)
      else
        softcut.level(target+4,0)
      end
    else
      softcut.level(target+4,params:get(target == 1 and "delay L: global level" or "delay R: global level"))
    end
  elseif param == "feedback mute" then
    delay[target].feedback_mute = not delay[target].feedback_mute
    if delay[target].feedback_mute then
      if params:get(target == 1 and "delay L: feedback" or "delay R: feedback") == 0 then
        softcut.pre_level(target+4,1)
      else
        softcut.pre_level(target+4,0)
      end
    else
      softcut.pre_level(target+4,params:get(target == 1 and "delay L: feedback" or "delay R: feedback")/100)
    end
  elseif param == "send mute" then
    delay[target].send_mute = not delay[target].send_mute
    if delay[target].send_mute then
      if (target == 1 and bank[delay_grid.bank][bank[delay_grid.bank].id].left_delay_level or bank[delay_grid.bank][bank[delay_grid.bank].id].right_delay_level) == 0 then
        softcut.level_cut_cut(delay_grid.bank+1,target+4,1)
      else
        softcut.level_cut_cut(delay_grid.bank+1,target+4,0)
      end
    else
      softcut.level_cut_cut(delay_grid.bank+1,target+4,target == 1 and bank[delay_grid.bank][bank[delay_grid.bank].id].left_delay_level or bank[delay_grid.bank][bank[delay_grid.bank].id].right_delay_level)
    end
  end
end

function delays.set_value(target,index,param)
  if param == "level" then
    local delay_name = {"delay L: global level", "delay R: global level"}
    local levels = {1,0.75,0.5,0.25,0}
    params:set(delay_name[target],levels[index])
  elseif param == "feedback" then
    local delay_name = {"delay L: feedback", "delay R: feedback"}
    local feedback_levels = {100,75,50,25,0}
    params:set(delay_name[target],feedback_levels[index])
  elseif param == "send" or param == "send all" then
    local send_levels = {1,0.75,0.5,0.25,0}
    local b = bank[delay_grid.bank][bank[delay_grid.bank].id]
    if target ==  1 then
      if param == "send" then
        b.left_delay_level = send_levels[index]
      elseif param == "send all" then
        for i = 1,16 do
          bank[delay_grid.bank][i].left_delay_level = send_levels[index]
        end
      end
      softcut.level_cut_cut(delay_grid.bank+1,5,util.linlin(-1,1,0,1,b.pan)*(b.left_delay_level*b.level))
    else
      if param == "send" then
        b.right_delay_level = send_levels[index]
      elseif param == "send all" then
        for i = 1,16 do
          bank[delay_grid.bank][i].right_delay_level = send_levels[index]
        end
      end
      softcut.level_cut_cut(delay_grid.bank+1,6,util.linlin(-1,1,1,0,b.pan)*(b.right_delay_level*b.level))
    end
  end
end

function delays.change_duration(target,source,param)
  if param == "sync" then
    local mode = {"delay L: mode","delay R: mode"}
    local div_mult = {"delay L: div/mult","delay R: div/mult"}
    local free_length = {"delay L: free length","delay R: free length"}
    params:set(mode[target], params:get(mode[source]))
    params:set(div_mult[target], params:get(div_mult[source]))
    params:set(free_length[target], params:get(free_length[source]))
  elseif param == "double" or param == "halve" then
    if delay[target].mode == "free" then
      local free_length = {"delay L: free length", "delay R: free length"}
      local pre_change = params:get(free_length[target])
      if string.len(string.match(pre_change*(param == "double" and 2 or 0.5),'.([^.]+)$')) <=4 then
        if param == "double" then
          if pre_change*2 <= 30 then
            params:set(free_length[target], pre_change*2)
          end
        else
          params:set(free_length[target],pre_change*0.5)
        end
      end
    else
      delay[target].modifier = util.clamp(delay[target].modifier * (param == "double" and 2 or 0.5),0.125,16)
      local delay_rate_to_time = clock.get_beat_sec() * delay[target].clocked_length * delay[target].modifier
      local delay_time = delay_rate_to_time + (41 + (30*(target-1)))
      delay[target].end_point = delay_time
      softcut.loop_end(target+4,delay[target].end_point)
    end
  elseif param == "clock sync" then
    local free_length = {"delay L: free length", "delay R: free length"}
    local bar_to_del = clock.get_beat_sec() * 4
    params:set(free_length[target], bar_to_del)
  end
end

function delays.sync_clock_to_length(source)
  if delay[source].mode == "free" and delay[source].free_end_point-delay[source].start_point > 0.1 then
    local duration = delay[source].free_end_point-delay[source].start_point
    local quarter = duration/4
    local derived_bpm = 60/quarter
    while derived_bpm < 70 do
      derived_bpm = derived_bpm * 2
      if derived_bpm > 160 then break end
    end
    while derived_bpm > 160 do
      derived_bpm = derived_bpm/2
      if derived_bpm <= 70 then break end
    end
    params:set("bpm",derived_bpm)
  end
end

function delays.change_rate(target,param)
  local rate = {"delay L: rate", "delay R: rate"}
  if param == "double" or param == "halve" then
    local pre_change = params:get(rate[target])
    if param == "double" and pre_change*2 <= 24 then
      params:set(rate[target], pre_change*2)
    elseif param == "halve" then
      params:set(rate[target], pre_change*0.5)
    end
  elseif param == "wobble" then
    local bump = {params:get("delay L: rate bump"), params:get("delay R: rate bump")}
    local wobble = bump[target] == 1 and 0.5 or math.random(-75,75)/1000
    softcut.rate(target+4,params:get(rate[target])+wobble)
    delay[target].wobble_hold = true
  elseif param == "restore" then
    softcut.rate(target+4,params:get(rate[target]))
    delay[target].wobble_hold = false
  end
end


function delays.save_delay(source)
  local dirname = _path.dust.."audio/cc_saved_delays/"
  if os.rename(dirname, dirname) == nil then
    os.execute("mkdir " .. dirname)
  end

  local dirname = _path.dust.."audio/cc_saved_delays/"..os.date("%y%m%d").."/"
  if os.rename(dirname, dirname) == nil then
    os.execute("mkdir " .. dirname)
  end

  local id = os.date("%X")
  local name = id.."-"..(source == 1 and "L-" or "R-")..params:get("bpm")..".wav"
  local duration = delay[source].mode == "clocked" and delay[source].end_point-delay[source].start_point or delay[source].free_end_point-delay[source].start_point
  softcut.buffer_write_mono(_path.dust.."audio/cc_saved_delays/"..os.date("%y%m%d").."/"..name,delay[source].start_point,duration,1)
end

return delays