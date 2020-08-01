local zilchmos = {}
local z = zilchmos

--[[
    which_bank is a global & being set from inside of here
    bpm
    grid_alt should be boolean
]]--

zilchmos.sc = {}

---------------------------------------
--- main function

-- this is the new zilchmos.init
function zilchmos.init(k,i)
  -- for .help functionality
  which_bank = i -- FIXME should be in the help. namespace
  if menu == 11 then
    help_menu = "zilchmo_"..k
  end


  local b = bank[i] -- just alias for shorter lines
  local p = b.focus_hold and b.focus_pad or b.id -- was 'which_pad'

  -- TODO fingers should be passed in as an argument, not globally accessed
  local finger    = fingers[k][i].con
  local p_action  = z.actions[k][finger][1]
  local sc_action = z.actions[k][finger][2]

  -- here's where we call the action
  --if grid.alt == 0 then
  if not b.alt_lock and grid.alt == 0 then
    p_action( b[p] )
    --trackers.inherit(which_bank,p)
  elseif b.alt_lock or grid.alt == 1 then
    z.map( p_action, b ) -- or map it over the whole bank
  end
  if not b.focus_hold then
    sc_action( b[p], i ) -- and then update softcut if we're in perform mode
  end
end

-- this function tanks a single bank, and applies function fn to each pad
function zilchmos.map( fn, bank ) -- this is a local bank, represents bank[i]
  for i=1,16 do -- will execute for each of the 16 elements in bank
    fn( bank[i] ) -- pass each pad to the supplied function
    --trackers.inherit(which_bank,i)
  end
end


-- pad helpers

function z.level_down( pad ) z.level_inc( pad, -0.125 ) end
function z.level_up( pad )   z.level_inc( pad, 0.125 ) end
function z.pan_left( pad )   z.pan( pad, -1 ) end
function z.pan_center( pad ) z.pan( pad, 0 ) end
function z.pan_right( pad )  z.pan( pad, 1 ) end
function z.pan_nudge_left( pad )  z.pan_nudge( pad, -0.1 ) end
function z.pan_nudge_right( pad ) z.pan_nudge( pad, 0.1 ) end
function z.rate_double( pad )  z.rate_mul( pad, 2 ) end
function z.rate_halve( pad )   z.rate_mul( pad, 0.5 ) end
function z.rate_reverse( pad ) z.rate_mul( pad, -1 ) end
function z.loop_sync_left( pad )  z.loop_sync( pad, -1 ) end
function z.loop_sync_right( pad ) z.loop_sync( pad, 1 ) end

-- core pad modifiers

function zilchmos.level_inc( pad, delta )
  pad.level = util.clamp( pad.level + delta, 0, 2 )
end

function zilchmos.pan_reverse( pad )
  pad.pan = -pad.pan
end

function zilchmos.play_toggle( pad )
  pad.pause = not pad.pause
end

function zilchmos.pan( pad, position )
  pad.pan = position
end

function zilchmos.pan_nudge( pad, delta )
  pad.pan = util.clamp( pad.pan + delta, -1, 1 )
end

function zilchmos.pan_random( pad )
  pad.pan = math.random(-100,100)/100
end

function zilchmos.start_zero( pad )
  local duration = pad.mode == 1 and 8 or clip[pad.clip].sample_length
  pad.start_point = (duration*(pad.clip-1)) + 1
end

function zilchmos.start_end_default( pad )
  --pad.start_point = 1+((8/16) * (pad.pad_id-1)) + (8*(pad.clip-1))
  --pad.end_point   = 1+((8/16) *  pad.pad_id)    + (8*(pad.clip-1))

  --what if this was just sixteen_slices?
  local duration;
  if pad.mode == 1 and pad.clip == rec.clip then
    --slice within bounds
    duration = rec.end_point-rec.start_point
    pad.start_point = rec.start_point+((duration/16) * (pad.pad_id-1))
    pad.end_point = rec.start_point+((duration/16) * (pad.pad_id))
  else
    duration = pad.mode == 1 and 8 or math.modf(clip[pad.clip].sample_length)
    pad.start_point = ((duration/16) * (pad.pad_id-1))+(duration*(pad.clip-1))+1
    pad.end_point = ((duration/16) * (pad.pad_id))+(duration*(pad.clip-1))+1
  end
end

function zilchmos.end_sixteenths( pad )
  local duration = pad.mode == 1 and 8 or clip[pad.clip].sample_length
  local s_p = pad.mode == 1 and live[pad.clip].min or clip[pad.clip].min
  pad.end_point   = pad.start_point + (clock.get_beat_sec()/4)
end

function zilchmos.end_at_eight( pad )
  local duration = pad.mode == 1 and 8 or clip[pad.clip].sample_length
  pad.end_point = (duration*pad.clip)+1
end

function zilchmos.start_random( pad )
  local duration, max_end, min_start;
  if pad.mode == 1 and pad.clip == rec.clip then
    duration = rec.end_point-rec.start_point
    max_end = math.floor(pad.end_point * 100)-10
    if max_end < math.floor(rec.start_point * 100) then
      min_start = math.floor(((duration*(pad.clip-1))+1) * 100)
    else
      min_start = math.floor(rec.start_point * 100) -- this sucks...
    end
  else
    --duration = math.modf(clip[pad.clip].sample_length)
    duration = pad.mode == 1 and 8 or math.modf(clip[pad.clip].sample_length)
    max_end = math.floor(pad.end_point * 100)
    min_start = math.floor(((duration*(pad.clip-1))+1) * 100)
  end
  pad.start_point = math.random(min_start,max_end)/100


  --[[
  local duration = pad.mode == 1 and 8 or math.modf(clip[pad.clip].sample_length)
  local max_end = math.floor(pad.end_point * 100)
  local min_start = math.floor(((duration*(pad.clip-1))+1) * 100)
  pad.start_point = math.random(min_start,max_end)/100
  --]]

end

function zilchmos.end_random( pad )
  local duration, max_end, min_start;
  if pad.mode == 1 and pad.clip == rec.clip then
    duration = rec.end_point-rec.start_point
    max_end = math.floor(rec.end_point*100)
    if pad.start_point > rec.start_point then
      min_start = math.floor(pad.start_point * 100)+10
    else
      min_start = math.floor(rec.start_point * 100)
    end
  else
    duration = util.round(clip[pad.clip].sample_length)
    max_end = math.floor(((duration*pad.clip)+1) * 100)
    min_start = math.floor(pad.start_point * 100)
  end
  pad.end_point = math.random(min_start,max_end)/100
end


function zilchmos.start_end_random( pad )
  local duration, jump, max_end, min_start, current_difference;
  current_difference = pad.end_point - pad.start_point
  local function case1(x)
    duration = x
    min_start = math.floor((rec.start_point * 100) + (current_difference*100))
    max_end = math.floor(rec.end_point * 100)
    pad.end_point = math.random(min_start,max_end)/100
    pad.start_point = pad.end_point - current_difference
  end
  local function case2(x)
    duration = x
    jump = math.random(100, ((duration+1)*100) ) / 100+(duration*(pad.clip-1))
    if jump+current_difference >= (duration+1)+(duration*(pad.clip-1)) then
      pad.end_point = (duration+1)+(duration*(pad.clip-1))
      pad.start_point = pad.end_point - current_difference
    else
      pad.start_point = jump
      pad.end_point = pad.start_point + current_difference
    end
  end
  if pad.mode == 1 and pad.clip == rec.clip then
    if current_difference < (rec.end_point - rec.start_point)/2 then
      case1(rec.end_point-rec.start_point)
    else
      if pad.start_point >= rec.start_point and pad.end_point < rec.end_point then -- case 1
        if current_difference * 2 < (rec.end_point - rec.start_point) then
          case1(rec.end_point-rec.start_point)
        else
          case2(8)
        end
      else
        case2(8)
      end
    end
  else
    case2(pad.mode == 1 and 8 or math.modf(clip[pad.clip].sample_length))
  --[[
  elseif pad.mode == 1 and pad.clip ~= rec.clip then
    case2(8)
  elseif pad.mode == 2 then
    case2(math.modf(clip[pad.clip].sample_length))
    --]]
  end
end

function zilchmos.loop_double( pad )
  local duration = pad.mode == 1 and 8 or clip[pad.clip].sample_length
  --local double = (pad.end_point - pad.start_point)*2
  local double = pad.end_point - pad.start_point
  local maximum_val = (duration+1)+(duration*(pad.clip-1))
  local minimum_val = 1+(duration*(pad.clip-1))
  if pad.end_point + double < maximum_val then
    pad.end_point = pad.end_point + double
  end
end

function zilchmos.loop_halve( pad )
  local half = (pad.end_point-pad.start_point)/2
  pad.end_point = pad.end_point - half
end

function zilchmos.loop_sync( pad, dir )
  local src_bank_num = (pad.bank_id-1 + dir)%3 + 1
  local src_bank     = bank[src_bank_num] -- FIXME global access of bank
  local src_pad      = src_bank[src_bank.id]
  -- shift start/end by the difference between clips
  pad.start_point = src_pad.start_point + 8*(pad.clip - src_pad.clip)
  pad.end_point   = src_pad.end_point   + 8*(pad.clip - src_pad.clip)
end

function zilchmos.rate_mul( pad, mul )
  pad.rate = pad.rate * mul
  -- NOTE: here we ensure speed doesn't surpass 4, but don't clamp, drop an octave
  if math.abs(pad.rate) > 4     then pad.rate = pad.rate / 2 end
  if math.abs(pad.rate) < 0.125 then pad.rate = pad.rate * 2 end
end

function zilchmos.rate_up_fifth( pad )
  -- should a 'raise-a-fifth' command fail if exceeds 4x, or raise fifth then drop oct
  -- how to handle release from raising
  if math.abs(pad.rate) < 4 then
    if pad.fifth then
      pad.rate = pad.rate < 0 and math.ceil(math.abs(pad.rate)) * -1 or pad.rate > 0 and math.ceil(math.abs(pad.rate))
      pad.fifth = false
      if math.abs(pad.rate) == 3 then
        pad.rate = pad.rate == 3 and 4 or pad.rate == -3 and -4
      end
    else
      pad.rate  = pad.rate*1.5
      pad.fifth = true
    end
  end
end


-- softcut

function zilchmos.sc.level( pad, i )
  if not pad.enveloped then
    softcut.level_slew_time(i+1,1.0)
    softcut.level(i+1,pad.level)
    if pad.left_delay_thru then
      softcut.level_cut_cut(i+1,5,util.linlin(-1,1,0,1,pad.pan)*(pad.left_delay_level))
    else
      softcut.level_cut_cut(i+1,5,util.linlin(-1,1,0,1,pad.pan)*(pad.left_delay_level*pad.level))
    end
    if pad.right_delay_thru then
      softcut.level_cut_cut(i+1,6,util.linlin(-1,1,1,0,pad.pan)*(pad.right_delay_level))
    else
      softcut.level_cut_cut(i+1,6,util.linlin(-1,1,1,0,pad.pan)*(pad.right_delay_level*pad.level))
    end
  end
end

function zilchmos.sc.play_toggle( pad, i )
  if pad.pause then
    softcut.level(i+1, 0.0)
    softcut.rate(i+1, 0.0)
  else
    if pad.enveloped then
      cheat( i, pad.pad_id )
    else
      softcut.level(i+1, pad.level)
    end
    softcut.rate(i+1, pad.rate * pad.offset)
  end
end

function zilchmos.sc.pan( pad, i )
  softcut.pan(i+1,pad.pan)
end

function zilchmos.sc.start( pad, i )
  softcut.loop_start(i+1,pad.start_point)
end

function zilchmos.sc.start_end( pad, i )
  softcut.loop_start(i+1,pad.start_point)
  softcut.loop_end(i+1,pad.end_point)
end

function zilchmos.sc._end( pad, i )
  softcut.loop_end(i+1,pad.end_point)
end

function zilchmos.sc.rate( pad, i )
  if pad.pause == false then
    softcut.rate(i+1, pad.rate*pad.offset)
  end
end

function zilchmos.sc.sync( pad, i )
  zilchmos.sc.start_end( pad, i )
  softcut.position(i+1, pad.start_point )
end

function zilchmos.sc.cheat( pad, i, p )
  if pad.loop and not pad.enveloped then
    cheat( i, pad.pad_id )
  end
end


--------------------------------------
--- actions


-- mapping of key-combos to pad functions & softcut actions
-- TODO the softcut actions should occur automatically using metatable over pad{}
zilchmos.actions =
{ [2] = -- level & play/pause
  { ['1']  = { z.level_down   , z.sc.level }
  , ['2']  = { z.level_up     , z.sc.level }
  , ['12'] = { z.play_toggle  , z.sc.play_toggle }
  }
, [3] = -- panning
  { ['1']   = { z.pan_left        , z.sc.pan }
  , ['2']   = { z.pan_center      , z.sc.pan }
  , ['3']   = { z.pan_right       , z.sc.pan }
  , ['12']  = { z.pan_nudge_left  , z.sc.pan }
  , ['23']  = { z.pan_nudge_right , z.sc.pan }
  , ['13']  = { z.pan_reverse     , z.sc.pan }
  , ['123'] = { z.pan_random      , z.sc.pan }
  }
, [4] = -- start/end points, rate, direction
  { ['1']    = { z.start_zero           , z.sc.start }
  , ['2']    = { z.start_end_default    , z.sc.start_end }
  , ['3']    = { z.end_sixteenths       , z.sc.start_end }
  , ['4']    = { z.end_at_eight         , z.sc._end }
  , ['12']   = { z.start_random         , z.sc.cheat }
  , ['34']   = { z.end_random           , z.sc._end }
  , ['23']   = { z.start_end_random     , z.sc.start_end }
  , ['13']   = { z.loop_double          , z.sc.start_end }
  , ['24']   = { z.loop_halve           , z.sc.start_end }
  , ['123']  = { z.loop_sync_left       , z.sc.sync }
  , ['234']  = { z.loop_sync_right      , z.sc.sync }
  , ['124']  = { z.rate_double          , z.sc.rate }
  , ['134']  = { z.rate_halve           , z.sc.rate }
  , ['14']   = { z.rate_reverse         , z.sc.rate }
  , ['1234'] = { z.rate_up_fifth        , z.sc.rate }
  }
}


return zilchmos
