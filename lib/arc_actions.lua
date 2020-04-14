arc_actions = {}

function arc_actions.init(n,d)
  --if n == 4 then n = 1 end
  if n < 4 then
    if bank[arc_control[n]].focus_hold == 0 then
      which_pad = bank[arc_control[n]].id
    elseif bank[arc_control[n]].focus_hold == 1 then
      which_pad = bank[arc_control[n]].focus_pad
    end
    if arc_param[n] == 1 then
      if grid.alt == 0 then
        local current_difference = (bank[arc_control[n]][which_pad].end_point - bank[arc_control[n]][which_pad].start_point)
        if bank[arc_control[n]][which_pad].start_point + current_difference <= (9+(8*(bank[arc_control[n]][which_pad].clip-1))) then
          bank[arc_control[n]][which_pad].start_point = util.clamp(bank[arc_control[n]][which_pad].start_point + d/80,(1+(8*(bank[arc_control[n]][which_pad].clip-1))),(9+(8*(bank[arc_control[n]][which_pad].clip-1))))
          bank[arc_control[n]][which_pad].end_point = bank[arc_control[n]][which_pad].start_point + current_difference
        else
          bank[arc_control[n]][which_pad].end_point = (9+(8*(bank[arc_control[n]][which_pad].clip-1)))
          bank[arc_control[n]][which_pad].start_point = bank[arc_control[n]][which_pad].end_point - current_difference
        end
      else
        for j = 1,16 do
          local current_difference = (bank[arc_control[n]][j].end_point - bank[arc_control[n]][j].start_point)
          if bank[arc_control[n]][j].start_point + current_difference <= (9+(8*(bank[arc_control[n]][j].clip-1))) then
            bank[arc_control[n]][j].start_point = util.clamp(bank[arc_control[n]][j].start_point + d/80,(1+(8*(bank[arc_control[n]][j].clip-1))),(9+(8*(bank[arc_control[n]][j].clip-1))))
            bank[arc_control[n]][j].end_point = bank[arc_control[n]][j].start_point + current_difference
          else
            bank[arc_control[n]][j].end_point = (9+(8*(bank[arc_control[n]][j].clip-1)))
            bank[arc_control[n]][j].start_point = bank[arc_control[n]][j].end_point - current_difference
          end
        end
      end
      if bank[arc_control[n]].focus_hold == 0 or bank[arc_control[n]].focus_pad == bank[arc_control[n]].id then
      --if bank[arc_control[n]].focus_hold == 0 then
        softcut.loop_start(arc_control[n]+1,bank[arc_control[n]][bank[arc_control[n]].id].start_point)
        softcut.loop_end(arc_control[n]+1,bank[arc_control[n]][bank[arc_control[n]].id].end_point)
      end
    elseif arc_param[n] == 2 then
      if grid.alt == 0 then
        if bank[arc_control[n]][which_pad].start_point < (bank[arc_control[n]][which_pad].end_point - d/80) then
          bank[arc_control[n]][which_pad].start_point = util.clamp(bank[arc_control[n]][which_pad].start_point + d/80,(1+(8*(bank[arc_control[n]][which_pad].clip-1))),(9+(8*(bank[arc_control[n]][which_pad].clip-1))))
        end
      else
        for j = 1,16 do
          bank[arc_control[n]][j].start_point = util.clamp(bank[arc_control[n]][j].start_point + d/80,(1+(8*(bank[arc_control[n]][j].clip-1))),(9+(8*(bank[arc_control[n]][j].clip-1))))
        end
      end
      --if bank[arc_control[n]].focus_hold == 0 then
      if bank[arc_control[n]].focus_hold == 0 or bank[arc_control[n]].focus_pad == bank[arc_control[n]].id then
        softcut.loop_start(arc_control[n]+1,bank[arc_control[n]][bank[arc_control[n]].id].start_point)
      end
    elseif arc_param[n] == 3 then
      if grid.alt == 0 then
        bank[arc_control[n]][which_pad].end_point = util.clamp(bank[arc_control[n]][which_pad].end_point + d/80,(1+(8*(bank[arc_control[n]][which_pad].clip-1))),(9+(8*(bank[arc_control[n]][which_pad].clip-1))))
      else
        for j = 1,16 do
          bank[arc_control[n]][j].end_point = util.clamp(bank[arc_control[n]][j].end_point + d/80,(1+(8*(bank[arc_control[n]][j].clip-1))),(9+(8*(bank[arc_control[n]][j].clip-1))))
        end
      end
      --if bank[arc_control[n]].focus_hold == 0 then
      if bank[arc_control[n]].focus_hold == 0 or bank[arc_control[n]].focus_pad == bank[arc_control[n]].id then
        softcut.loop_end(arc_control[n]+1,bank[arc_control[n]][bank[arc_control[n]].id].end_point)
      end
    elseif arc_param[n] == 4 then
      local a_c = arc_control[n]
      if key1_hold or grid.alt == 1 then
        if slew_counter[a_c] ~= nil then
          slew_counter[a_c].prev_tilt = bank[a_c][which_pad].tilt
        end
        bank[a_c][which_pad].tilt = util.explin(1,3,-1,1,bank[a_c][which_pad].tilt+2)
        bank[a_c][which_pad].tilt = util.clamp(bank[a_c][which_pad].tilt+(d/1000),-1,1)
        bank[a_c][which_pad].tilt = util.linexp(-1,1,1,3,bank[a_c][which_pad].tilt)-2
        if d < 0 then
          if util.round(bank[a_c][which_pad].tilt*100) < 0 and util.round(bank[a_c][which_pad].tilt*100) > -9 then
            bank[a_c][which_pad].tilt = -0.10
          elseif util.round(bank[a_c][which_pad].tilt*100) > 0 and util.round(bank[a_c][which_pad].tilt*100) < 3 then
            bank[a_c][which_pad].tilt = 0.0
          end
        end
        --if bank[arc_control[n]].focus_hold == 0 then
        if bank[arc_control[n]].focus_hold == 0 or bank[arc_control[n]].focus_pad == bank[arc_control[n]].id then
          slew_filter(a_c,slew_counter[a_c].prev_tilt,bank[a_c][bank[a_c].id].tilt,bank[a_c][bank[a_c].id].q,bank[a_c][bank[a_c].id].q,15)
        end
      else
        if slew_counter[a_c] ~= nil then
          slew_counter[a_c].prev_tilt = bank[a_c][bank[a_c].id].tilt
        end
        for j = 1,16 do
          bank[a_c][j].tilt = util.explin(1,3,-1,1,bank[a_c][j].tilt+2)
          bank[a_c][j].tilt = util.clamp(bank[a_c][j].tilt+(d/1000),-1,1)
          bank[a_c][j].tilt = util.linexp(-1,1,1,3,bank[a_c][j].tilt)-2
          if d < 0 then
            if util.round(bank[a_c][j].tilt*100) < -1 and util.round(bank[a_c][j].tilt*100) > -9 then
              bank[a_c][j].tilt = -0.10
            elseif util.round(bank[a_c][j].tilt*100) > 0 and util.round(bank[a_c][j].tilt*100) < 3 then
              bank[a_c][j].tilt = 0.0
            end
          end
        end
        slew_filter(a_c,slew_counter[a_c].prev_tilt,bank[a_c][bank[a_c].id].tilt,bank[a_c][bank[a_c].id].q,bank[a_c][bank[a_c].id].q,15)
      end
    end
  end
  
  if n == 4 then
    if grid.alt == 0 then
      delay[1].arc_rate_tracker = util.clamp(delay[1].arc_rate_tracker + d/10,1,13)
      delay[1].arc_rate = math.floor(delay[1].arc_rate_tracker)
      params:set("delay L: rate",math.floor(delay[1].arc_rate_tracker))
    else
      delay[2].arc_rate_tracker = util.clamp(delay[2].arc_rate_tracker + d/10,1,13)
      delay[2].arc_rate = math.floor(delay[2].arc_rate_tracker)
      params:set("delay R: rate",math.floor(delay[2].arc_rate_tracker))
    end
  end

  if n == 1 or n == 2 or n == 3 then
    arc_p[n] = {}
    arc_p[n].i = n
    arc_p[n].param = arc_param[n]
    local id = arc_control[n]
    if bank[id].focus_hold == 0 then
      arc_p[n].pad = bank[id].id
    elseif bank[id].focus_hold == 1 then
      arc_p[n].pad = bank[id].focus_pad
    end
    arc_p[n].start_point = bank[id][arc_p[n].pad].start_point - (8*(bank[id][arc_p[n].pad].clip-1))
    arc_p[n].end_point = bank[id][arc_p[n].pad].end_point - (8*(bank[id][arc_p[n].pad].clip-1))
    arc_p[n].prev_tilt = slew_counter[id].prev_tilt
    arc_p[n].tilt = bank[id][bank[id].id].tilt
    arc_pat[n]:watch(arc_p[n])
  end
  
  if n == 4 then
    arc_p[n] = {}
    arc_p[n].i = n
    if grid.alt == 0 then
      arc_p[n].delay_focus = "L"
      arc_p[n].left_delay_value = params:get("delay L: rate")
    else
      arc_p[n].delay_focus = "R"
      arc_p[n].right_delay_value = params:get("delay R: rate")
    end
  end
  redraw()
end

return arc_actions