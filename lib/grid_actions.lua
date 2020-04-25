grid_actions = {}

function grid_actions.init(x,y,z)
  
  if osc_communication == true then osc_communication = false end
  
  if grid_page == 0 then
    
    for i = 1,3 do
      if grid.alt == 1 then
        if x == 1+(5*(i-1)) and y == 1 and z == 1 then
          bank[i].focus_hold = not bank[i].focus_hold
        end
      end
    end
    
    for i = 1,3 do
      if z == 1 and x > 0 + (5*(i-1)) and x <= 4 + (5*(i-1)) and y >=5 then
        if bank[i].focus_hold == false then
          if grid.alt == 0 then
            selected[i].x = x
            selected[i].y = y
            selected[i].id = (math.abs(y-9)+((x-1)*4))-(20*(i-1))
            bank[i].id = selected[i].id
            which_bank = i
            if menu == 8 then
              help_menu = "banks"
            end
            pad_clipboard = nil
            if bank[i].quantize_press == 0 then
              cheat(i, bank[i].id)
              grid_p[i] = {}
              grid_p[i].action = "pads"
              grid_p[i].i = i
              grid_p[i].id = selected[i].id
              grid_p[i].x = selected[i].x
              grid_p[i].y = selected[i].y
              grid_p[i].rate = bank[i][bank[i].id].rate
              grid_p[i].start_point = bank[i][bank[i].id].start_point
              grid_p[i].end_point = bank[i][bank[i].id].end_point
              grid_p[i].rate_adjusted = false
              grid_p[i].loop = bank[i][bank[i].id].loop
              grid_p[i].pause = bank[i][bank[i].id].pause
              grid_p[i].mode = bank[i][bank[i].id].mode
              grid_p[i].clip = bank[i][bank[i].id].clip
              grid_pat[i]:watch(grid_p[i])
            else
              table.insert(quantize_events[i],selected[i].id)
            end
          end
        else
          if grid.alt == 0 then
            bank[i].focus_pad = (math.abs(y-9)+((x-1)*4))-(20*(i-1))
          elseif grid.alt == 1 then
            if not pad_clipboard then
              pad_clipboard = {}
              bank[i].focus_pad = (math.abs(y-9)+((x-1)*4))-(20*(i-1))
              pad_copy(pad_clipboard, bank[i][bank[i].focus_pad])
            else
              bank[i].focus_pad = (math.abs(y-9)+((x-1)*4))-(20*(i-1))
              pad_copy(bank[i][bank[i].focus_pad], pad_clipboard)
              pad_clipboard = nil
            end
          end
        end
        redraw()
      elseif z == 0 and x > 0 + (5*(i-1)) and x <= 4 + (5*(i-1)) and y >=5 then
        if bank[i][bank[i].id].play_mode == "momentary" then
          softcut.rate(i+1,0)
        end
      end
    end
    
    for k = 4,2,-1 do
      for i = 1,3 do
        if z == 1 and x == (k+1)+(5*(i-1)) and y <=k then
          local t1 = util.time()
          fingers[k].dt = t1-fingers[k].t
          fingers[k].t = t1
          if fingers[k].dt > 0.1 then
            fingers[k][i] = {}
          end
          table.insert(fingers[k][i],math.abs(y-(k+1)))
          table.sort(fingers[k][i])
          fingers[k][i].con = table.concat(fingers[k][i])
          for j = 1,#fingers[k][i] do
            local e = {}
            e.state = 1
            e.id = (k+1)+(5*(i-1))+math.abs(fingers[k][i][j]-(k+1))
            e.x = (k+1)+(5*(i-1))
            e.y = math.abs(fingers[k][i][j]-(k+1))
            grid_entry(e)
          end
        elseif z == 0 and x == (k+1)+(5*(i-1)) and y<=k then
          if k == 4 then
            counter_four.key_up:stop()
            counter_four.key_up:start()
          elseif k == 3 then
            counter_three.key_up:stop()
            counter_three.key_up:start()
          elseif k == 2 then
            counter_two.key_up:stop()
            counter_two.key_up:start()
          elseif k == 1 then
            zilchmo(1,i)
          end
          selected_zilchmo_row = k
          selected_zilchmo_bank = i
        end
      end
    end
    
    for k = 1,1 do
      for i = 1,3 do
        if z == 0 and x == (k+1)+(5*(i-1)) and y<=k then
          if grid_pat[i].quantize == 0 then -- still relevant
            if grid.alt == 1 then -- still relevant
              grid_pat[i]:rec_stop()
              grid_pat[i]:stop()
              --grid_pat[i].external_start = 0
              grid_pat[i].tightened_start = 0
              grid_pat[i]:clear()
              pattern_saver[i].load_slot = 0
            elseif grid_pat[i].rec == 1 then -- still relevant
              grid_pat[i]:rec_stop()
              midi_clock_linearize(i)
              if grid_pat[i].auto_snap == 1 then
                print("auto-snap")
                snap_to_bars(i,how_many_bars(i))
              end
              grid_pat[i]:start()
              grid_pat[i].loop = 1
            elseif grid_pat[i].count == 0 then
              grid_pat[i]:rec_start()
            elseif grid_pat[i].play == 1 then
              grid_pat[i]:stop()
            else
              grid_pat[i]:start()
            end
          else
            if grid.alt == 1 then
              grid_pat[i]:rec_stop()
              grid_pat[i]:stop()
              grid_pat[i].tightened_start = 0
              grid_pat[i]:clear()
              pattern_saver[i].load_slot = 0
            else
              --table.insert(grid_pat_quantize_events[i],i)
              better_grid_pat_q_clock(i)
            end
          end
          if menu == 8 then
            help_menu = "grid patterns"
            which_bank = i
          end
        end
      end
    end
    
    for i = 4,2,-1 do
      if x == 16 and y == i and z == 0 then
        local current = math.abs(y-5)
        if grid.alt == 1 then
          arc_pat[current]:rec_stop()
          arc_pat[current]:stop()
          arc_pat[current]:clear()
        elseif arc_pat[current].rec == 1 then
          arc_pat[current]:rec_stop()
          arc_pat[current]:start()
        elseif arc_pat[current].count == 0 then
          arc_pat[current]:rec_start()
        elseif arc_pat[current].play == 1 then
          arc_pat[current]:stop()
        else
          arc_pat[current]:start()
        end
        if menu == 8 then
          help_menu = "arc patterns"
          which_bank = current
        end
      end
    end
    
    for i = 1,3 do
      if x == (3)+(5*(i-1)) and y == 4 and z == 1 then
        which_bank = i
        local which_pad = nil
        if bank[i].focus_hold == false then
          which_pad = bank[i].id
        else
          which_pad = bank[i].focus_pad
        end
        if bank[i][which_pad].loop == true then
          if grid.alt == 0 then
            bank[i][which_pad].loop = false
          else
            for j = 1,16 do
              bank[i][j].loop = false
            end
          end
          if bank[i].focus_hold == false then
            softcut.loop(i+1,0)
          end
        else
          if grid.alt == 0 then
            bank[i][which_pad].loop = true
          else
            for j = 1,16 do
              bank[i][j].loop = true
            end
          end
          if bank[i].focus_hold == false then
            softcut.loop(i+1,1)
          end
        end
        if menu == 8 then
          help_menu = "loop"
        end
      end
      redraw()
    end
    
    if x == 16 and y == 8 then
      if grid.alt_pp == 1 then
        grid.alt_pp = 0
      end
      grid.alt = z
      if menu == 8 then
        if grid.alt == 1 then
          help_menu = "alt"
        elseif grid.alt == 0 then
          help_menu = "welcome"
        end
      end
      redraw()
      grid_redraw()
    end
    
    if y == 4 or y == 3 or y == 2 then
      if x == 1 or x == 6 or x == 11 then
        local which_pad = nil
        local current = math.sqrt(math.abs(x-2))
        if grid.alt == 0 then
          if bank[current].focus_hold == false then
            clip_jump(current, bank[current].id, y, z)
          else
            clip_jump(current, bank[current].focus_pad, y, z)
          end
        else
          for j = 1,16 do
            clip_jump(current, j, y, z)
          end
        end
        if z == 0 then
          redraw()
          if bank[current].focus_hold == false then
            cheat(current,bank[current].id)
          end
        end
      end
    end
    
    for i = 4,3,-1 do
      for j = 2,12,5 do
        if x == j and y == i and z == 1 then
          local which_pad = nil
          if grid.alt == 0 then
            local current = math.sqrt(math.abs(x-3))
            if bank[current].focus_hold == false then
              bank[current][bank[current].id].mode = math.abs(i-5)
            else
              bank[current][bank[current].focus_pad].mode = math.abs(i-5)
            end
          else
            for k = 1,16 do
              local current = math.sqrt(math.abs(x-3))
              bank[current][k].mode = math.abs(i-5)
            end
          end
          local current = math.sqrt(math.abs(x-3))
          if bank[current].focus_hold == false then
            which_pad = bank[current].id
          else
            which_pad = bank[current].focus_pad
          end
          if bank[current][which_pad].mode == 1 then
            bank[current][which_pad].sample_end = 8
          else
            bank[current][which_pad].sample_end = clip[bank[current][which_pad].clip].sample_length
          end
          if bank[current].focus_hold == false then
            local current = math.sqrt(math.abs(x-3))
            cheat(current,bank[current].id)
          end
          if menu == 8 then
            which_bank = current
            help_menu = "mode"
          end
        end
      end
    end
    
    for i = 7,5,-1 do
      if x == 16 and z == 1 and y == i then
        softcut.level_slew_time(1,0.5)
        softcut.fade_time(1,0.01)
        
        local old_clip = rec.clip
        
        for go = 1,2 do
        local old_min = (1+(8*(rec.clip-1)))
        local old_max = (9+(8*(rec.clip-1)))
        local old_range = old_min - old_max
        rec.clip = 8-y
        local new_min = (1+(8*(rec.clip-1)))
        local new_max = (9+(8*(rec.clip-1)))
        local new_range = new_max - new_min
        local current_difference = (rec.end_point - rec.start_point)
        rec.start_point = (((rec.start_point - old_min) * new_range) / old_range) + new_min
        rec.end_point = rec.start_point + current_difference
        end
        
        if rec.loop == 0 and grid.alt == 0 then
          softcut.position(1,rec.start_point)
          if rec.state == 0 then
            rec.state = 1
            softcut.rec_level(1,1)
            rec_state_watcher:start()
            end
          if rec.clear == 1 then rec.clear = 0 end
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
        if grid.alt == 1 then
          buff_flush()
        end
        
        if menu == 8 then
          help_menu = "buffer switch"
        end
      end
    end
    
    for i = 8,6,-1 do
      --if z == 1 then
        if x == 5 or x == 10 or x == 15 then
          if y == i then
            if z == 1 then
              arc_switcher[x/5] = arc_switcher[x/5] + 1
              if grid.alt == 0 and arc_switcher[x/5] == 1 then
                arc_param[x/5] = 9-y
                if menu == 8 then
                  which_bank = x/5
                  help_menu = "arc params"
                end
                redraw()
              elseif grid.alt == 0 and arc_switcher[x/5] == 3 then
                 arc_param[x/5] = 4
              end
            elseif z == 0 then
              arc_switcher[x/5] = arc_switcher[x/5] - 1
            end
          end
        end
      --end
    end
    
    if y == 5 and z == 1 then
      for i = 1,3 do
        if bank[i].focus_hold == true then
          if x == i*5 then
            bank[i][bank[i].focus_pad].crow_pad_execute = (bank[i][bank[i].focus_pad].crow_pad_execute + 1)%2
            if grid.alt == 1 then
              for j = 1,16 do
                bank[i][j].crow_pad_execute = bank[i][bank[i].focus_pad].crow_pad_execute
              end
            end
          end
        end
      end
    end
    
    --- new page focus
    for k = 4,1,-1 do
      for i = 1,3 do
        if z == 1 and x == k+(5*(i-1)) and y == k then
          
          ---
          if grid.alt == 0 then
            menu = 6-y
            if key1_hold == true then key1_hold = false end
            if menu == 2 then
              page.loops_sel = math.floor((x/4)-1)
            elseif menu == 5 then
              page.filtering_sel = math.floor((x/4))
            end
            redraw()
          else
            if y == 2 then
              random_grid_pat(math.ceil(x/4),3)
            end
            if y == 4 then
              local current = math.floor(x/5)+1
              bank[current][bank[current].id].rate = 1
              softcut.rate(current+1,1*bank[current][bank[current].id].offset)
              if bank[current][bank[current].id].fifth == true then
                bank[current][bank[current].id].fifth = false
              end
            end
          end
          ---
        end
      end
    end
    
  else
    
    if grid.loop_mod == 0 then
    
      for i = 1,11,5 do
        for j = 1,8 do
          if x == i and y == j then
            local current = math.floor(x/5)+1
            if z == 1 then
              saved_already = pattern_saver[current].saved[9-y]
              if step_seq[current].held == 0 then
                pattern_saver[current].source = math.floor(x/5)+1
                pattern_saver[current].save_slot = 9-y
                pattern_saver[current]:start()
              else
                --if there's a pattern saved there...
                if pattern_saver[current].saved[9-y] == 1 then
                  if grid.alt_pp == 0 then
                    step_seq[current][step_seq[current].held].assigned_to = 9-y
                  end
                end
              end
            elseif z == 0 then
              if step_seq[current].held == 0 then
                pattern_saver[math.floor(x/5)+1]:stop()
                if grid.alt_pp == 0 and saved_already == 1 then
                  if pattern_saver[current].saved[9-y] == 1 then
                    pattern_saver[current].load_slot = 9-y
                    test_load((9-y)+(8*(current-1)),current)
                  end
                end
              end
            end
          end
        end
      end
      
      for i = 2,12,5 do
        for j = 1,8 do
          if z == 1 and x == i and y == j then
            local current = math.floor(x/5)+1
            step_seq[current].meta_duration = 9-y
          end
        end
      end
      
      for i = 3,13,5 do
        for j = 1,8 do
          if z == 1 and x == i and y == j then
            local current = math.floor(x/5)+1
            step_seq[current].held = 9-y
            if grid.alt_pp == 1 then
              step_seq[current][step_seq[current].held].assigned_to = 0
            end
          elseif z == 0 and x == i and y == j then
            local current = math.floor(x/5)+1
            step_seq[current].held = 0
          elseif z == 1 and x == i+1 and y == j then
            local current = math.floor(x/5)+1
            step_seq[current].held = (9-y)+8
            if grid.alt_pp == 1 then
              step_seq[current][step_seq[current].held].assigned_to = 0
            end
          elseif z == 0 and x == i+1 and y == j then
            local current = math.floor(x/5)+1
            step_seq[current].held = 0
          end
        end
      end
      
      for i = 5,15,5 do
        for j = 1,8 do
          if z == 1 and x == i and y == j then
            local current = x/5
            if step_seq[current].held == 0 then
              step_seq[current][step_seq[current].current_step].meta_meta_duration = 9-y
            else
              step_seq[current][step_seq[current].held].meta_meta_duration = 9-y
            end
            if grid.alt_pp == 1 then
              for k = 1,16 do
                step_seq[current][k].meta_meta_duration = 9-y
              end
            end
          end
        end
      end
      
      for i = 7,5,-1 do
        if x == 16 and y == i and z == 1 then
          if step_seq[8-i].held == 0 then
            if grid.alt_pp == 1 then
              step_seq[8-i].current_step = step_seq[8-i].start_point
              step_seq[8-i].meta_step = 1
              step_seq[8-i].meta_meta_step = 1
              if step_seq[8-i].active == 1 and step_seq[8-i][step_seq[8-i].current_step].assigned_to ~= 0 then
                test_load(step_seq[8-i][step_seq[8-i].current_step].assigned_to+(((8-i)-1)*8),8-i)
              end
            else
              step_seq[8-i].active = (step_seq[8-i].active + 1)%2
            end
          else
            step_seq[8-i][step_seq[8-i].held].loop_pattern = (step_seq[8-i][step_seq[8-i].held].loop_pattern + 1)%2
          end
        end
      end
      
      
      if x == 16 and y == 8 then
        grid.alt_pp = z
        redraw()
        grid_redraw()
      end
    
    elseif grid.loop_mod == 1 then
      for i = 3,13,5 do
        if x == i or x == i+1 then
          local current = math.floor(x/5)+1
          if z == 1 then
            step_seq[current].loop_held = step_seq[current].loop_held + 1
            if step_seq[current].loop_held == 1 then
              if x == i then
                step_seq[current].start_point = 9-y
              elseif x == i+1 then
                step_seq[current].start_point = 17-y
              end
              if step_seq[current].start_point > step_seq[current].current_step then
                step_seq[current].current_step = step_seq[current].start_point
              end
            elseif step_seq[current].loop_held == 2 then
              if x == i then
                step_seq[current].end_point = 9-y
              elseif x == i+1 then
                step_seq[current].end_point = 17-y
              end
            end
          elseif z == 0 then
            step_seq[current].loop_held = step_seq[current].loop_held - 1
          end
        end
      end
    end
    
    if x == 16 and y == 2 then
      grid.loop_mod = z
      redraw()
      grid_redraw()
    end
    
    if menu == 8 then
      if x == 1 or x == 6 or x == 11 then
        help_menu = "meta: slots"
      elseif x == 2 or x == 7 or x == 12 then
        help_menu = "meta: clock"
      elseif x == 3 or x == 4 or x == 8 or x == 9 or x == 13 or x == 14 then
        if grid.loop_mod == 0 then
          help_menu = "meta: step"
        end
      elseif x == 5 or x == 10 or x == 15 then
        help_menu = "meta: duration"
      elseif x == 16 then
        if y == 8 then
          if z == 1 then
            help_menu = "meta: alt"
          elseif z == 0 then
            help_menu = "welcome"
          end
        elseif y == 7 or y == 6 or y == 5 then
          help_menu = "meta: toggle"
        elseif y == 2 then
          if z == 1 then
            help_menu = "meta: loop mod"
          elseif z == 0 then
            help_menu = "welcome"
          end
        end
      end
      redraw()
    end
  
  end
  
  if x == 16 and y == 1 and z == 1 then
    if grid.alt == 0 then
      grid_page = (grid_page + 1)%2
      if menu == 8 then
        if grid_page == 1 then
          help_menu = "meta page"
        elseif grid_page == 0 then
          help_menu = "welcome"
        end
        redraw()
      end
    elseif grid.alt == 1 then
      --clk_midi:stop()
      --clk:reset()
    end
  end
    
end

return grid_actions