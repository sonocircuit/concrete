-- concre'te
-- 
--
-- virtual tape
-- explorations
--
-- v0.0.1 @sonocircuit
-- w/ contributions @xylr??
--
--
--
--
--       -- ----- -- -
--          -- ----- -- -
--             -- ----- -- -
--
--
-- 

-- TODO:
-- adapt morph -> in og MG genes move closer togeter with higher settings... currently it's the other way around.
-- add capstan age {"new", "used", "old", "vintage"} which affects softcut.rate_slew_time(voice, time)
-- add start/stop mode {"immidiate", "gradual"}, if gradual then when play/stop is pressed rate_slew_time is set to 4s and the rate ramps up/down to the las set speed.
-- add warble to all four voices
-- implement "ghost voice" (softcut voice 5 has nothing to do)... just leaving it here for ideas.
-- implement recoding
-- look into splice selection modes {"immidiate", "end of gene"} when set to end of gene it waits until the currently playing gene ends before swiching splice.
-- look into a method for implementing the deletion of whole splices --> softcut.copy_buffer is what is needed here.. and a lot of padding.
-- add more scales, got the math done. yey!
-- implement the crow input and output params/destinations
-- implement morph clocked mode where gene-windows are stepped through according to the system clock and clock div setttings.
-- look into the whole file saving/pset buffer saving buissness... how to use flags, which and where.
-- add third UX/UI page with level, pan and filter params, also for arc.

local a = arc.connect()

local fileselect = require 'fileselect'
local textentry = require 'textentry'
local _lfos = require 'lfo'

-------- variables --------
local pset_load = false
local default_pset = 1

local shift = false
local pageNum = 1
local focus_page1 = 1
local focus_page2 = 0
local active_splice = 1
local play = false
local rec = false
local is_recording = false
local armed = false
local mute = true
local voice_rate = 1
local prev_morph_val = 0
local pos_counter = 0
local gene_length = 10
local morph_freeze = false
local morph_clocked = false
local reel_has_audio = false
local waveviz_reel = false
local waveviz_splice = false
local save_buffer = false
local MAX_REEL = 320 -- seconds
local GENE_NUM = 4
local ghost_voice = 5
local rec_voice = 6

-- variables for arc
local arc_is = false
local arc_off = 0
local arc_enc1_count = 0
local arc_vs_sens = 100

-- variables for scales
local oct025 = math.pow(2, -24/12) -- speed == 0.25
local p5_025 = math.pow(2, -19/12)
local p4_025 = math.pow(2, -17/12)
local M3_025 = math.pow(2, -16/12)
local m3_025 = math.pow(2, -15/12)
local oct05 = math.pow(2, -12/12) -- speed == 0.5
local p5_05 = math.pow(2, -7/12)
local p4_05 = math.pow(2, -5/12)
local M3_05 = math.pow(2, -4/12)
local m3_05 = math.pow(2, -3/12)
local oct0 = math.pow(2, 0/12) -- speed == 1
local m3 = math.pow(2, 3/12)
local M3 = math.pow(2, 4/12)
local p4 = math.pow(2, 5/12)
local p5 = math.pow(2, 7/12)
local oct1 = math.pow(2, 12/12) -- speed == 2
local m3_1 = math.pow(2, 15/12)
local M3_1 = math.pow(2, 16/12)
local p4_1 = math.pow(2, 17/12)
local p5_1 = math.pow(2, 19/12)
local oct2 = math.pow(2, 24/12) -- speed == 4

-------- tables --------
local options = {}
options.scale = {"oct", "oct+p5"}
options.crow_input = {"none", "play [trig]", "play [gate]", "rec [trig]", "rec [gate]", "add splice", "next splice", "select splice", "varispeed", "slide", "morph", "size"}
options.crow_output = {"none", "env follower", "gene ramp", "EOGT"}

scale = {
  {-oct2, -oct1, -oct0, -oct05, -oct025, oct025, oct05, oct0, oct1, oct2}, -- octaves
  {-oct2, -p5_1, -oct1, -p5,  -oct0, -p5_05, -oct05, -p5_025, -oct025, oct025, p5_025, oct05, p5_05, oct0, p5, oct1, p5_1, oct2} -- octaves and fifths
}

reel = {}
reel.s = 1
reel.e = MAX_REEL + 1
reel.l = MAX_REEL

splice = {}
splice[1] = {}
splice[1].s = 1
splice[1].e = MAX_REEL + 1
splice[1].l = MAX_REEL

voice = {}
for i = 1, 6 do -- all 6 softcut voices
  voice[i] = {}
  voice[i].s = 1
  voice[i].level = 1
  voice[i].pan = 0
  voice[i].rate_mod = 1
  voice[i].pos_get = 1
  voice[i].pos_abs = 1
  voice[i].pos_rel = 0
end


-------- reels --------
function load_reel(path)
  if path ~= "cancel" and path ~= "" then
    local ch, len = audio.file_info(path)
    if ch > 0 and len > 0 then
      softcut.buffer_clear()
      --buffer_read_mono(file, start_src, start_dst, dur, ch_src, ch_dst, preserve, mix) -- reference
      softcut.buffer_read_mono(path, 0, 1, -1, 1, 1, 0, 1)
      local l = math.min(len / 48000, MAX_REEL)
      init_reel(l)
      reel_has_audio = true
      waveviz_reel = true
      waveviz_splice = true
      softcut.render_buffer(1, 1, l, 128)
      print("file loaded: "..path.." is "..l.."s")
    else
      print("not a sound file")
    end
  end
end

function save_reel(txt)
  if txt then
    local length = splice[#splice].e - 1
    util.make_dir(_path.audio .. "concrete")
    --buffer_write_mono(file, start, dur, buffer) -- reference
    softcut.buffer_write_mono(_path.audio.."concrete/"..txt..".wav", 1, length, 1)
    print("file saved: " .._path.audio .. "concrete/" .. txt .. ".wav")
  else
    print("save cancel")
  end
end

function clear_reel()
  softcut.buffer_clear()
  waveviz_reel = true
  waveviz_splice = true
  reel_has_audio = false
  init_reel(MAX_REEL)
  softcut.render_buffer(1, 1, MAX_REEL, 128)
  params:set("load_reel", "") -- reset fileselect
end

function init_reel(dur)
  reel.s = 1
  reel.e = 1 + dur
  reel.l = dur
  active_splice = 1
  splice = {}
  splice[1] = {}
  splice[1].s = 1
  splice[1].e = 1 + dur
  splice[1].l = dur
  set_loops()
  set_start_pos()
end

function add_splice(pos) -- add dummy splice via maiden by adding arg in s. if no arg then it takes pos_abs.x§x x
  table.insert(splice, active_splice + 1, {}) -- make a new entry and shift
  splice[active_splice + 1].s = pos or voice[1].pos_abs -- start of new splice
  splice[active_splice + 1].e = splice[active_splice].e -- new end is prev end
  splice[active_splice].e = pos or voice[1].pos_abs -- end of prev slice
  splice[active_splice + 1].l = splice[active_splice + 1].e - splice[active_splice + 1].s -- new length
  splice[active_splice].l = splice[active_splice].e - splice[active_splice].s
  set_loops()
  set_start_pos()
  waveviz_splice = true
  softcut.render_buffer(1, splice[active_splice].s, splice[active_splice].l, 128)
  -- debug stuff
  --for i = 1, #splice do
    --print("splice "..i)
    --tab.print(splice[i])
  --end
end

function remove_splice()
  if active_splice < #splice then
    splice[active_splice + 1].s = splice[active_splice].s -- restore to prev start
    splice[active_splice + 1].l = splice[active_splice + 1].e - splice[active_splice].s -- new length
    table.remove(splice, active_splice) -- remove current entry and shift
    set_loops()
    set_start_pos()
    waveviz_splice = true
    softcut.render_buffer(1, splice[active_splice].s, splice[active_splice].l, 128)
  end
  -- debug stuff
  --for i = 1, #splice do
    --print("splice "..i)
    --tab.print(splice[i])
  --end
end

function nudge_splice_start(d)
  local amt = d / 50
  if active_splice > 1 then
    splice[active_splice].s = util.clamp(splice[active_splice].s + amt, splice[active_splice - 1].s + 0.01, splice[active_splice].e - 0.01)
    splice[active_splice - 1].e = splice[active_splice].s
    splice[active_splice - 1].l = splice[active_splice - 1].e - splice[active_splice - 1].s -- new length
    splice[active_splice].l = splice[active_splice].e - splice[active_splice].s
  end
  set_loops()
  --set_start_pos()
  waveviz_splice = true
  softcut.render_buffer(1, splice[active_splice].s, splice[active_splice].l, 128)
  -- debug stuff
  --for i = 1, #splice do
    --print("splice "..i)
    --tab.print(splice[i])
  --end
end

function nudge_splice_end(d)
  local amt = d / 50
  if active_splice < #splice then
    splice[active_splice].e = util.clamp(splice[active_splice].e + amt, splice[active_splice].s + 0.01, splice[active_splice + 1].e - 0.01)
    splice[active_splice + 1].s = splice[active_splice].e
    splice[active_splice + 1].l = splice[active_splice + 1].e - splice[active_splice + 1].s
    splice[active_splice].l = splice[active_splice].e - splice[active_splice].s
  end
  set_loops()
  --set_start_pos()
  waveviz_splice = true
  softcut.render_buffer(1, splice[active_splice].s, splice[active_splice].l, 128)
  -- debug stuff
  --for i = 1, #splice do
    --print("splice "..i)
    --tab.print(splice[i])
  --end
end


-------- voices / playheads --------
function set_play()
  if play then
    set_start_pos()
    set_levels()
    set_rec()
  else
    pos_counter = 0
    set_levels()
    if rec then
      rec = false
      set_rec()
    end
  end
end

function set_rec()
  if rec and play then
    softcut.rec_level(rec_voice, params:get("rec_level"))
    softcut.pre_level(rec_voice, params:get("dub_level"))
    if params:get("rec_dest") == 1 then
      softcut.position(rec_voice, voice[1].pos_abs) -- same as voice 1 
    else
      softcut.position(rec_voice, splice[#splice].e) -- end of last splice
    end
    reel_has_audio = true
    --print("start recording")
  else
    softcut.rec_level(rec_voice, 0)
    softcut.pre_level(rec_voice, 1)
    waveviz_reel = true
    softcut.render_buffer(1, 1, splice[#splice].e - 1, 128)
    --print("stop recording")
  end
end

function set_levels()
  for i = 1, GENE_NUM do
    if play then
      local level = params:get("morph") == 0 and voice[i].level * 0.75 or voice[i].level
      softcut.level(i, level)
    else
      softcut.level(i, 0)
    end
    -- something to figure out... how to do the routings/levels when sos and so on
    if params:get("rec_mode") == 1 then
      -- input only
    else
      -- sound on sound
    end
  end
end

function set_rate()
  for i = 1, GENE_NUM do
    local rate = voice_rate * voice[i].rate_mod
    softcut.rate(i, rate)
  end
  softcut.rate(rec_voice, voice_rate)
end

function reset_morph_params()
  if not morph_freeze then
    local morph = params:get("morph") * 100
    -- reset rate mod
    if morph < 80 then
      for i = 1, GENE_NUM do
        voice[i].rate_mod = 1
      end
      set_rate()
    end
    -- reset pan
    if morph < 75 then
      for i = 1, GENE_NUM do
        voice[i].pan = params:get("pan"..i)
      end
    end
  end
end

function set_start_pos()
  for i = 1, GENE_NUM do
    softcut.position(i, voice[i].s)
  end
  if params:get("rec_dest") == 1 then
    softcut.position(rec_voice, voice[1].s)
  end
  pos_counter = 0
end

function set_loops()  
  -- calculate start, end and length
  voice[1].s = util.clamp(splice[active_splice].s + splice[active_splice].l * params:get("slide"), splice[active_splice].s, splice[active_splice].e)
  gene_length = util.clamp(splice[active_splice].l * params:get("gene_size"), 0.01, splice[active_splice].l)
  -- and set loop window to active splice
  for i = 1, GENE_NUM do
    softcut.loop_start(i, splice[active_splice].s)
    softcut.loop_end(i, splice[active_splice].e)
  end
  -- morph genes according to the morph param
  local mval = params:get("morph") * 100
  -- new stuff
  if mval < 1 then
    -- set all to same start pos
    for i = 2, GENE_NUM do
      voice[i].s = voice[1].s
    end
  elseif mval > 0 and mval <= 30 then
    -- shift gene 2 only
    local shift_amount = (gene_length / 2) * params:get("morph") * 1.25
    voice[2].s = voice[1].s + shift_amount
    if voice[2].s > splice[active_splice].e then
      voice[2].s = voice[2].s - splice[active_splice].l
    end
    -- keep others aligned
    for i = 3, GENE_NUM do
      voice[i].s = voice[1].s
    end
  elseif mval > 30 and mval <= 60 then
    -- shift gene 2 + 3 
    local shift_amount = (gene_length / 3) * params:get("morph") * 1.25
    voice[2].s = voice[1].s + shift_amount
    if voice[2].s > splice[active_splice].e then
      voice[2].s = voice[2].s - splice[active_splice].l
    end
    voice[3].s = voice[2].s + shift_amount
    if voice[3].s > splice[active_splice].e then
      voice[3].s = voice[2].s - splice[active_splice].l
    end
    -- keep gene 4 aligned
    voice[4].s = voice[1].s
  elseif mval > 60 and mval <= 90 then
    -- shift gene 2 + 3 + 4
    local shift_amount = (gene_length / 3) * params:get("morph") * 1.25
    voice[2].s = voice[1].s + shift_amount
    if voice[2].s > splice[active_splice].e then
      voice[2].s = voice[2].s - splice[active_splice].l
    end
    voice[3].s = voice[2].s + shift_amount
    if voice[3].s > splice[active_splice].e then
      voice[3].s = voice[3].s - splice[active_splice].l
    end
    voice[4].s = voice[3].s + shift_amount
    if voice[4].s > splice[active_splice].e then
      voice[4].s = voice[4].s - splice[active_splice].l
    end
  elseif mval > 90 then -- if > 90 then max rand and changing start pos will not change the start pos of the other genes.
    -- keep things how they are
  end
  -- debug stuff
  --print("---")
  --print("gene 1 start "..voice[1].s)
  --print("gene 2 start "..voice[2].s)
  --print("gene 3 start "..voice[3].s)
end

function set_softcut_input(option) -- select softcut input
  if option == 1 then -- L&R
    softcut.level_input_cut(1, rec_voice, 0.7)
    softcut.level_input_cut(2, rec_voice, 0.7)
  elseif option == 2 then -- L IN
    softcut.level_input_cut(1, rec_voice, 1)
    softcut.level_input_cut(2, rec_voice, 0)
 elseif option == 3 then -- R IN
    softcut.level_input_cut(1, rec_voice, 0)
    softcut.level_input_cut(2, rec_voice, 1)
 elseif option == 4 then -- OFF
    softcut.level_input_cut(1, rec_voice, 0)
    softcut.level_input_cut(2, rec_voice, 0)
  end
end

function filter_select(i, option) -- select filter type
  softcut.post_filter_lp(i, option == 1 and 1 or 0) 
  softcut.post_filter_hp(i, option == 2 and 1 or 0) 
  softcut.post_filter_bp(i, option == 3 and 1 or 0) 
  softcut.post_filter_br(i, option == 4 and 1 or 0)
  softcut.post_filter_dry(i, option == 5 and 1 or 0)
  --if pageNum == 3 then dirtyscreen = true end
end

function morph_values()
  while true do
    clock.sync(1/4) --16th notes
    --TODO: parameterize rand dest and tweek values and move to dedicated clock
    local mval = params:get("morph") * 100
    if math.random(100) <= params:get("morph_prob") and not morph_freeze and play then
      if mval > 74 and params:get("randomize_pan") == 2 then
        for i = 1, 2 do
          voice[i].pan = (math.random() * 20 - 10) / 10  -- randomize first two voices...
          voice[i + 2].pan = -voice[i].pan -- ...and then flip the other two accordingly
          softcut.pan(i, voice[i].pan)
          softcut.pan(i, voice[i + 2].pan)
        end
      end
      if mval > 74 and params:get("randomize_level") == 2 then 
        for i = 1, GENE_NUM do
          voice[i].level = math.random(25, 100) / 100
          set_levels()
        end
      end
      if mval > 80 and mval < 90 and params:get("randomize_rate") == 2 then 
        for i = 2, GENE_NUM do
          local dice = math.random(-1, 1)
          if dice ~= 0 then
            voice[i].rate_mod = dice
            set_rate()
          end
        end
      elseif mval >= 90 and mval < 95 and params:get("randomize_rate") == 2 then
        for i = 2, GENE_NUM do
          local dice = math.random(-2, 2)
          if dice ~= 0 then
            voice[i].rate_mod = dice
            set_rate()
          end
        end
      elseif mval >= 95 and params:get("randomize_rate") == 2 then
        for i = 2, GENE_NUM do
          local rnd = math.random(#scale[params:get("scale")])
          voice[i].rate_mod = scale[params:get("scale")][rnd]
          set_rate()
        end
      end
    end
  end
end

function step_genes()
  while true do
    clock.sync(1/2) -- parameterize clock division
    if params:get("gene_size") < 1 and params:get("morph_mode") == 2 then
      voice[1].s = voice[1].s + gene_length
      set_start_pos()
    end
  end
end


-------- waveforms --------
local waveform_reel_samples = {}
local waveform_splice_samples = {}
local wave_reel_gain = 1
local wave_splice_gain = 1

function wave_render(ch, start, i, s)
  if waveviz_reel then
    waveform_reel_samples = {}
    waveform_reel_samples = s
    waveviz_reel = false
    wave_reel_gain = table_getmax(waveform_reel_samples) / 1
  end
  if waveviz_splice then
    waveform_splice_samples = {}
    waveform_splice_samples = s
    waveviz_splice = false
    wave_splice_gain = table_getmax(waveform_splice_samples) / 1
    reel_has_audio = wave_reel_gain > 0 and true or false
  end
  dirtyscreen = true
end

function table_getmax(t)
  local max = 0
  for _,v in pairs(t) do
    if math.abs(v) > max then
      max = math.abs(v)
    end
  end
  return max
end


-------- helpers --------
function round_form(param, quant, form)
  return(util.round(param, quant)..form)
end


-------- init --------
function init()
  -- crow params
  params:add_group("crow_params",  "CROW", 6)

  params:add_option("crow_in_1", "input 1", options.crow_input, 1)

  params:add_option("crow_in_2", "input 2", options.crow_input, 1)
  
  params:add_option("crow_out_1", "output 1", options.crow_output, 1)

  params:add_option("crow_out_2", "output 2", options.crow_output, 1)

  params:add_option("crow_out_3", "output 3", options.crow_output, 1)

  params:add_option("crow_out_4", "output 4", options.crow_output, 1)
  
  -- arc params
  params:add_group("arc_params", "ARC", 2)

  params:add_option("arc_orientation", "arc orientation", {"horizontal", "vertical"}, 1)
  params:set_action("arc_orientation", function(val) arc_off = (val - 1) * 16 end)

  params:add_option("arc_vs_sens", "varispeeed sensitivity", {"lo", "hi"}, 1)
  params:set_action("arc_vs_sens", function(x) arc_vs_sens = x == 1 and 100 or 500 end)

  -- reel params
  params:add_separator("reel", "reel")

  params:add_group("save_load", "save & load", 4)

  params:add_file("load_reel", "> load reel", "")
  params:set_action("load_reel", function(path) load_reel(path) end)

  params:add_trigger("save_reel", "< save reel")
  params:set_action("save_reel", function() textentry.enter(save_reel) end)

  params:add_trigger("clear_reel", "!! clear reel")
  params:set_action("clear_reel", function() clear_reel() end)

  params:add_option("save_buffer", "? save reel with pset", {"no", "yes"}, 1)
  params:set_action("save_buffer", function(x) save_buffer = x == 2 and true or false end)

  params:add_group("rec_params", "recording", 5)

  params:add_option("rec_mode", "rec mode", {"input only", "s.o.s"}, 1)

  params:add_option("rec_input", "rec input", {"summed", "left", "right", "off"}, 1)
  params:set_action("rec_input", function(x) set_softcut_input(x) end)

  params:add_option("rec_dest", "rec destination", {"active splice", "new splice"}, 1)

  params:add_control("rec_level", "rec level", controlspec.new(0, 1, "lin", 0, 1), function(param) return (round_form(util.linlin(0, 1, 0, 100, param:get()), 1, "%")) end)

  params:add_control("dub_level", "overdub level", controlspec.new(0, 1, "lin", 0, 0.8), function(param) return (round_form(util.linlin(0, 1, 0, 100, param:get()), 1, "%")) end)

  params:add_group("splice_params", "splices", 2)

  params:add_option("splice_mode", "next splice", {"immidiate", "@ end of gene"}, 1)

  params:add_trigger("clear_splices", "  !! clear all splice markers !!")
  params:set_action("clear_splices", function() init_reel(splice[#splice].e) end)

  -- voice params
  params:add_separator("voices", "voix")
  
  params:add_group("global_voice_params", "all", 5)

  params:add_control("global_level", "level", controlspec.new(0, 1, "lin", 0, 0.5), function(param) return (round_form(util.linlin(0, 1, 0, 100, param:get()), 1, "%")) end)
  params:set_action("global_level", function(x) for i = 1, GENE_NUM do params:set("level"..i, x) end end)

  params:add_control("global_pan", "pan", controlspec.new(-1, 1, "lin", 0, 0, ""))
  params:set_action("global_pan", function(x) for i = 1, GENE_NUM do params:set("pan"..i, x) end end)

  params:add_control("global_cutoff", "filter cutoff", controlspec.new(20, 18000, 'exp', 1, 18000, "Hz"))
  params:set_action("global_cutoff", function(x) for i = 1, GENE_NUM do params:set("cutoff"..i, x) end end)

  params:add_control("global_filter_q", "filter q", controlspec.new(0.1, 4.0, 'exp', 0.01, 2.0, ""))
  params:set_action("global_filter_q", function(x) for i = 1, GENE_NUM do params:set("filter_q"..i, x) end end)

  params:add_option("global_filter_type", "filter type", {"low pass", "high pass", "band pass", "band reject", "off"}, 1)
  params:set_action("global_filter_type", function(x) for i = 1, GENE_NUM do params:set("filter_type"..i, x) end end)

  params:add_group("individual_voice_params", "individual", 24)

  local gene_id = {"[one]", "[two]", "[three]", "[four]"}
  for i = 1, GENE_NUM do
    params:add_separator("voice_"..i.."_params","voice "..gene_id[i])

    params:add_control("level"..i, "level", controlspec.new(0, 1, "lin", 0, 0.5), function(param) return (round_form(util.linlin(0, 1, 0, 100, param:get()), 1, "%")) end)
    params:set_action("level"..i, function(x) voice[i].level = x set_levels() end)

    params:add_control("pan"..i, "pan", controlspec.new(-1, 1, "lin", 0, 0, ""))
    params:set_action("pan"..i, function(x) voice[i].pan = x softcut.pan(i, x) end)

    params:add_control("cutoff"..i, "filter cutoff", controlspec.new(20, 18000, 'exp', 1, 18000, "Hz"))
    params:set_action("cutoff"..i, function(x) softcut.post_filter_fc(i, x) end)

    params:add_control("filter_q"..i, "filter q", controlspec.new(0.1, 4.0, 'exp', 0.01, 2.0, ""))
    params:set_action("filter_q"..i, function(x) softcut.post_filter_rq(i, x) end)

    params:add_option("filter_type"..i, "filter type", {"low pass", "high pass", "band pass", "band reject", "off"}, 1)
    params:set_action("filter_type"..i, function(x) filter_select(i, x) end)
  end

  -- exploration params
  params:add_separator("essai", "essai")

  params:add_control("varispeed", "varispeed", controlspec.new(-4, 4, "lin", 0, 1), function(param) return (round_form(util.linlin(-4, 4, -400, 400, param:get()), 1, "%")) end)
  params:set_action("varispeed", function(val) voice_rate = val set_rate() end)

  params:add_option("scale", "scale", options.scale, 1)
  params:set_action("scale", function() end)

  params:add_control("slide", "slide", controlspec.new(0, 1, "lin", 0, 0), function(param) return (round_form(util.linlin(0, 1, 0, 100, param:get()), 1, "%")) end)
  params:set_action("slide", function() set_loops() end)

  params:add_control("gene_size", "size", controlspec.new(0, 1, "lin", 0, 1), function(param) return (round_form(util.linlin(0, 1, 0, 100, param:get()), 1, "%")) end)
  params:set_action("gene_size", function() set_loops() end)

  params:add_control("morph", "morph", controlspec.new(0, 1, "lin", 0, 0), function(param) return (round_form(util.linlin(0, 1, 0, 100, param:get()), 1, "%")) end)
  params:set_action("morph", function() set_loops() reset_morph_params() end)

  params:add_group("morph_settings", "morph settings", 6)

  params:add_option("morph_mode", "morph mode", {"free", "clocked"}, 1)

  params:add_number("morph_prob", "randomization prob", 1, 100, 20, function(param) return param:get().."%" end)

  params:add_option("randomize_level", "randomize level", {"off", "on"}, 1)

  params:add_option("randomize_pan", "randomize pan", {"off", "on"}, 2)

  params:add_option("randomize_rate", "randomize rate", {"off", "on"}, 2)

  params:add_binary("morph_freez", "freeze values", "toggle", 0)
  params:set_action("morph_freez", function(x) morph_freeze = x == 1 and true or false end)

  -- lfo params
  params:add_separator("modulation", "modulation")

  params:add_group("level_lfos", "level lfos", 15 * GENE_NUM)
  local level_lfo = {}
  for i = 1, GENE_NUM do
    level_lfo[i] = _lfos:add{min = 0, max = 1}
    level_lfo[i]:add_params("level_lfo"..i, "voice "..gene_id[i].." level")
    level_lfo[i]:set("action", function(scaled, raw) params:set("level"..i, scaled) page_redraw(3) end)
  end

  params:add_group("pan_lfos", "pan lfos", 15 * GENE_NUM)
  local pan_lfo = {}
  for i = 1, GENE_NUM do
    pan_lfo[i] = _lfos:add{min = -1, max = 1}
    pan_lfo[i]:add_params("pan_lfo"..i, "voice "..gene_id[i].." pan")
    pan_lfo[i]:set("baseline", "center")
    pan_lfo[i]:set("action", function(scaled, raw) params:set("pan"..i, scaled) page_redraw(3) end)
  end

  params:add_group("cutoff_lfos", "cutoff lfos", 15 * GENE_NUM)
  local cutoff_lfo = {}
  for i = 1, GENE_NUM do
    cutoff_lfo[i] = _lfos:add{min = 20, max = 18000}
    cutoff_lfo[i]:add_params("cutoff_lfo"..i, "voice "..gene_id[i].." cutoff")
    cutoff_lfo[i]:set("baseline", "center")
    cutoff_lfo[i]:set("action", function(scaled, raw) params:set("cutoff"..i, scaled) page_redraw(3) end)
  end

  local varispeed_lfo = _lfos:add{min = -4, max = 4}
  varispeed_lfo:add_params("varispeed_lfo", "varispeed", "varispeed lfo")
  varispeed_lfo:set("baseline", "center")
  varispeed_lfo:set("action", function(scaled, raw) params:set("varispeed", scaled) page_redraw(2) end)

  local slide_lfo = _lfos:add{min = 0, max = 1}
  slide_lfo:add_params("slide_lfo", "slide", "slide lfo")
  slide_lfo:set("action", function(scaled, raw) params:set("slide", scaled) page_redraw(2) end)

  local gene_size_lfo = _lfos:add{min = 0, max = 1}
  gene_size_lfo:add_params("gene_size_lfo", "size", "size lfo")
  gene_size_lfo:set("action", function(scaled, raw) params:set("gene_size", scaled) page_redraw(2) end)

  local morph_lfo = _lfos:add{min = 0, max = 1}
  morph_lfo:add_params("morph_lfo", "morph", "morph lfo")
  morph_lfo:set("action", function(scaled, raw) params:set("morph", scaled) page_redraw(2) end)

  -- init softcut settings
  for i = 1, GENE_NUM do -- genes 1 - 4

    softcut.enable(i, 1)
    softcut.buffer(i, 1)

    softcut.play(i, 1)
    softcut.rec(i, 0) -- not required as we have a separate rec head

    softcut.level(i, 1)
    softcut.pan(i, 0)

    softcut.pre_level(i, 1)
    softcut.rec_level(i, 0)

    softcut.post_filter_dry(i, 0)
    softcut.post_filter_lp(i, 1)
    softcut.post_filter_fc(i, 18000)
    softcut.post_filter_rq(i, 4)

    softcut.fade_time(i, 0.05)
    softcut.level_slew_time(i, 0.1)
    softcut.pan_slew_time(i, 0.2)
    softcut.rate_slew_time(i, 0)
    softcut.rate(i, 1)

    softcut.loop_start(i, 1)
    softcut.loop_end(i, 2)
    softcut.loop(i, 1)
    softcut.position(i, 1)

    softcut.phase_quant(i, 0.01)
    softcut.phase_offset(i, 0)
  end

  for i = 5, 6 do -- ghost and rec voice
    softcut.enable(i, 1)
    softcut.buffer(i, 1)

    softcut.play(i, 1)
    softcut.rec(i, 1)
    softcut.rec_offset(i, 0)

    softcut.level(i, 0)
    softcut.pan(i, 0)

    softcut.pre_level(i, 1)
    softcut.rec_level(i, 0)

    softcut.fade_time(i, 0.01)
    softcut.level_slew_time(i, 0.01)
    softcut.rate_slew_time(i, 0)
    softcut.rate(i, 1)

    softcut.loop_start(i, 1)
    softcut.loop_end(i, MAX_REEL + 1)
    softcut.loop(i, 1)
    softcut.position(i, 1)

    softcut.phase_quant(i, 0.01)
    softcut.phase_offset(i, 0)
  end

  -- pset callbacks
  params.action_write = function(filename, name, number)
    -- make directories
    os.execute("mkdir -p "..norns.state.data.."pset_data/"..number.."/")
    os.execute("mkdir -p ".._path.audio.."concrete/")
    -- save buffer content
    if save_buffer then
      local length = splice[#splice].e - 1
      softcut.buffer_write_mono(_path.audio.."concrete/"..name..".wav", 1, length, 1)
    end
    -- store data in one big table
    local reel_data = {}
    reel_data.reel_start = reel.s
    reel_data.reel_end = reel.e
    reel_data.reel_length = reel.l
    reel_data.active = active_splice
    reel_data.splice = {table.unpack(splice)}
    reel_data.gene = {table.unpack(gene)}
    -- and save the chunk
    tab.save(reel_data, norns.state.data.."pset_data/"..number.."/"..name.."_reel.data")
    print("finished writing pset:'"..name.."'")
  end

  params.action_read = function(filename, silent, number) -- find out why silent returns nil
    local loaded_file = io.open(filename, "r")
    if loaded_file then
      io.input(loaded_file)
      local pset_id = string.sub(io.read(), 4, -1)
      io.close(loaded_file)
      -- load sesh data
      reel_data = tab.load(norns.state.data.."pset_data/"..number.."/"..pset_id.."_reel.data")
      -- paste data
      reel.s = reel_data.reel_start
      reel.e = reel_data.reel_end
      reel.l = reel_data.reel_length
      active_splice = reel_data.active
      splice = {table.unpack(reel_data.splice)}
      gene = {table.unpack(reel_data.gene)}
      set_loops()
      set_start_pos()
      dirtyscreen = true
      dirtygrid = true
      print("finished reading pset:'"..pset_id.."'")
    end
  end

  params.action_delete = function(filename, name, number)
    norns.system_cmd("rm -r "..norns.state.data.."pset_data/"..number.."/")
    print("finished deleting pset:'"..name.."'")
  end

  -- callbacks
  arc.add = drawarc_connect
  arc.remove = drawarc_disconnect

  softcut.event_render(wave_render)
  softcut.event_position(get_position)
  softcut.event_phase(poll_positions)
  softcut.poll_start_phase()

  -- detect if arc is connected
  for v in pairs(arc.devices) do
    if arc.devices[v].name ~= nil then
      arc_is = true
    end
  end

  -- metros
  screenredrawtimer = metro.init(function() screen_redraw() end, 1/15, -1)
  screenredrawtimer:start()

  hardwareredrawtimer = metro.init(function() hardware_redraw() end, 1/30, -1)
  if arc_is then
    hardwareredrawtimer:start()
  end

  -- clocks
  geneclock = clock.run(step_genes)
  morphclock = clock.run(morph_values)

  -- bang params
  if pset_load then
    params:read(default_pset)
  else
    params:bang()
  end

  -- set defaults
  set_rate()
  set_loops()
  set_start_pos()
  build_menu()

  norns.enc.sens(1, 5)

  print("concrète loaded and ready to splice!")
end

-------- softcut callbacks --------
function get_position(i, pos)
  voice[i].pos_get = pos
end

function poll_positions(i, pos)
  -- get positions
  if play and i <= GENE_NUM then
    voice[i].pos_rel = ((pos - splice[active_splice].s) / splice[active_splice].l)
    voice[i].pos_abs = pos
  end
  -- gene counter
  if i == 1 and play then 
    pos_counter = pos_counter + 1
    if pos_counter > util.round(gene_length, 0.01) * 100 then
      set_start_pos()
      pos_counter = 0
    end
  end
  -- ensure that recording stops when the rec head reaches the end of the reel.
  if i == rec_voice and params:get("rec_dest") == 2 then
    if voice[rec_voice].pos_abs > MAX_REEL + 1 then
      rec = false
      set_rec()
      print("no more space left, sorry :(")
    end
  end

  if pageNum == 1 then dirtyscreen = true end
end


-------- norns UI --------
function key(n, z)
  if n == 1 then
    shift = z == 1 and true or false
  end
  if pageNum == 1 then
    if n == 2 and z == 1 then
      focus_page1 = 1 - focus_page1
    end
    if focus_page1 == 0 then
      if n == 3 then
        if z == 1 then
          if shift then
            remove_splice()
          else
            if play then
              add_splice()
            end
          end
        end
      end
    else
      if n == 3 and z == 1 then
        if shift then
          rec = not rec
          set_rec()
        else
          play = not play
          set_play()
        end
      end
    end
  elseif pageNum == 2 then
    if n == 2 and z == 1 then
      focus_page2 = 1 - focus_page2
    end
    if focus_page2 == 0 then
      if n == 3 then
        if shift then
          if z == 1 then
            params:delta("morph_freez", 1)
            reset_morph_params()
          end
        else
          if z == 1 then
            prev_morph_val = params:get("morph")
            params:set("morph", 1)
          elseif z == 0 then
            params:set("morph", prev_morph_val)
          end
        end
      end
    else
      if n == 3 and z == 1 then
        params:set("varispeed", -voice_rate)       
      end
    end
  elseif pageNum == 3 then
    --
  end
  dirtyscreen = true
end

function enc(n, d)
  if n == 1 then
    if shift then
      params:delta("level", d)
    else
      pageNum = util.clamp(pageNum + d, 1, 2)
    end
  end
  if pageNum == 1 then
    if focus_page1 == 0 then
      if n == 2 then
        if shift then
          nudge_splice_start(d)
        else
          local add = d / 20
          for i = 1, GENE_NUM do
            local curr_pos = voice[i].pos_abs
            local new_pos = curr_pos + add
            softcut.position(i, new_pos)
          end
        end        
      elseif n == 3 then
        if shift then
          nudge_splice_end(d)
        else
          local inc = d > 0 and 1 or - 1
          active_splice = util.clamp(active_splice + inc, 1, #splice)
          set_loops()
          if #splice > 1 then
            --set_start_pos()
        end
        waveviz_splice = true
        softcut.render_buffer(1, splice[active_splice].s, splice[active_splice].l, 128)
        end
      end
    else
      if n == 2 then
        params:delta("rec_level", d)
      elseif n == 3 then
        params:delta("dub_level", d)
      end
    end
  elseif pageNum == 2 then
    if focus_page2 == 0 then
      if n == 2 then
        params:delta("morph", d)
      elseif n == 3 then
        params:delta("gene_size", d)
      end
    else
      if n == 2 then
        if shift then
          local idx = params:get("scale")
          local inc = d > 0 and 1 or -1
          local rate_idx = 1
          -- snap to closest scale value
          for i = 1, #scale[idx] do
            if scale[idx][i] < voice_rate then
              rate_idx = inc == 1 and i or i + 1
            elseif scale[idx][i] == voice_rate then
              rate_idx = i
            end
          end
          -- set rate
          rate_idx = util.clamp(rate_idx + inc, 1, #scale[idx])
          voice_rate = scale[idx][rate_idx]
          params:set("varispeed", voice_rate)
        else
          params:delta("varispeed", d / 20)
        end
      elseif n == 3 then
        params:delta("slide", d)
      end
    end
  elseif pageNum == 3 then
    --
  end
  dirtyscreen = true
end

function redraw()
  screen.clear()

  screen.level(shift and 15 or 0)
  screen.rect(126, 1, 2, 2)
  screen.fill()


  if pageNum == 1 then
    screen.level(focus_page1 == 0 and 15 or 4)

    -- reel window
    screen.line_width(1)
    screen.move(4, 4)
    screen.line_rel(120, 0)
    screen.move(4, 21)
    screen.line_rel(120, 0)
    screen.stroke()

    -- waveform
    if not reel_has_audio then
      screen.level(15)
      screen.move(64, 14)
      screen.text_center("load or record")
    else
      screen.level(6)
      local x_pos = 0
      for i, s in ipairs(waveform_reel_samples) do
        local height = util.round(math.abs(s) * (8 / wave_reel_gain))
        screen.move(util.linlin(0, 128 , 5, 124, x_pos), 12 - height)
        screen.line_rel(0, 2 * height)
        screen.stroke()
        x_pos = x_pos + 1
      end
      screen.stroke()
    end

    -- splice markers and indicator in reel window
    screen.level(15)
    if #splice > 1 then
      for i = 2, #splice do
        screen.move(util.linlin(1 , splice[#splice].e, 4, 124, splice[i].s), 4)
        screen.line_rel(0, 16)
        screen.stroke()
      end
      local splice_start = util.linlin(1 , reel.e, 4, 124, splice[active_splice].s)
      local splice_end = util.linlin(1 , reel.e, 4, 124, splice[active_splice].e)
      screen.level(focus_page1 == 0 and 15 or 4)
      screen.line_width(3)
      screen.move(splice_start, 25)
      screen.line_rel(splice_end - splice_start + 1, 0)
      screen.stroke()
    end

    -- active splice window
    screen.line_width(1)
    screen.move(24, 30)
    screen.line_rel(80, 0)
    screen.move(24, 61)
    screen.line_rel(80, 0)
    screen.stroke()

    -- waveform
    if reel_has_audio then
      screen.level(6)
      local x_pos = 0
      for i, s in ipairs(waveform_splice_samples) do
        local height = util.round(math.abs(s) * (15 / wave_splice_gain))
        screen.move(util.linlin(0, 128 , 25, 104, x_pos), 45 - height)
        screen.line_rel(0, 2 * height)
        screen.stroke()
        x_pos = x_pos + 1
      end
      screen.stroke()
    end

    -- gene 4 playhead
    if voice[4].level > 0 then
      screen.level(2)
      screen.move(util.linlin(0, 1, 25, 105, voice[4].pos_rel), 30)
      screen.line_rel(0, 30)
      screen.stroke()
    end

    -- gene 3 playhead
    if voice[3].level > 0 then
      screen.level(4)
      screen.move(util.linlin(0, 1, 25, 105, voice[3].pos_rel), 30)
      screen.line_rel(0, 30)
      screen.stroke()
    end

    -- gene 2 playhead
    if voice[2].level > 0 then
      screen.level(6)
      screen.move(util.linlin(0, 1, 25, 105, voice[2].pos_rel), 30)
      screen.line_rel(0, 30)
      screen.stroke()
    end

    -- gene 1 playhead
    if voice[1].level > 0 then
      screen.level(15)
      screen.move(util.linlin(0, 1, 25, 105, voice[1].pos_rel), 30)
      screen.line_rel(0, 30)
      screen.stroke()
    end

    -- rec key
    screen.level(focus_page1 == 1 and 15 or 4)
    if rec then
      screen.rect(3, 30, 17, 13)
      screen.fill()
    end
    screen.level(15)
    screen.rect(4, 30, 17, 13)
    screen.stroke()
    screen.level(focus_page1 == 1 and 15 or 4)
    if rec then screen.level(0) end
    screen.move(10, 38)
    screen.text("R")

    -- play key
    screen.level(focus_page1 == 1 and 15 or 4)
    if play then
      screen.rect(3, 48, 17, 13)
      screen.fill()
    end
    screen.level(15)
    screen.rect(4, 48, 17, 13)
    screen.stroke()
    screen.level(focus_page1 == 1 and 15 or 4)
    if play then screen.level(0) end
    screen.move(10, 56)
    screen.text("P")

    -- ovedub level
    screen.level(15)
    screen.rect(108, 30, 6, 31)
    screen.stroke()
    screen.level(focus_page1 == 1 and 15 or 4)
    screen.rect(108, 60, 5, -util.linlin(0, 1, 0, 30, params:get("rec_level")))
    screen.fill()

    -- s.o.s level
    screen.level(15)
    screen.rect(118, 30, 6, 31)
    screen.stroke()
    screen.level(focus_page1 == 1 and 15 or 4)
    screen.rect(118, 60, 5, -util.linlin(0, 1, 0, 30, params:get("dub_level")))
    screen.fill()

  elseif pageNum == 2 then

    -- morph level
    screen.level(15)
    screen.line_width(1)
    screen.rect(4, 4, 16, 50)
    screen.stroke()
    screen.level(focus_page2 == 0 and 15 or 4)
    screen.rect(4, 53, 15, - util.linlin(0, 1, 0, 48, params:get("morph")))
    screen.fill()
    if morph_freeze then
      screen.level(0)
      for i = 1, 4 do
        for j = 1, 10 do
          screen.rect(1 + i * 4, 1 + j * 5, 1, 1)
          screen.fill()
        end
      end
    end
    screen.level(15)
    screen.move(0, 62)
    screen.font_face(1)
    screen.font_size(8)
    screen.text("morph")

    -- gene size
    screen.level(15)
    screen.rect(108, 4, 16, 50)
    screen.stroke()
    screen.level(focus_page2 == 0 and 15 or 4)
    screen.rect(108, 4, 15, util.linlin(0, 1, 0, 49, params:get("gene_size")))
    screen.fill()
    screen.move(107, 62)
    screen.font_face(1)
    screen.font_size(8)
    screen.text("size")

    -- varispeed
    screen.level(focus_page2 == 1 and 15 or 4)
    screen.move(64, 10)
    screen.font_size(8)
    screen.text_center("va r i  s p e ed")

    screen.line_width(2)
    screen.level(voice_rate < 0 and 15 or 4)
    screen.move(28, 18)
    screen.line_rel(35, 0)
    screen.stroke()

    screen.level(voice_rate > 0 and 15 or 4)
    screen.move(63, 18)
    screen.line_rel(35, 0)
    screen.stroke()

    screen.level(focus_page2 == 1 and 15 or 4)
    screen.move(util.linlin(-3, 3, 28, 98, voice_rate), 13)
    screen.line_rel(0, 10)
    screen.stroke()

    -- slide
    screen.level(focus_page2 == 1 and 10 or 4)
    screen.move(28, 46)
    screen.line_rel(71, 0)
    screen.move(util.linlin(0, 1, 28, 98, params:get("slide")), 41)
    screen.line_rel(0, 10)
    screen.stroke()

    screen.move(64, 38)
    screen.font_size(8)
    screen.text_center("s l  i   d    e")
    
  elseif pageNum == 3 then
    
    screen.level(15)
    screen.move(64, 36)
    screen.text_center("level   pan   cutoff  etc..")

  end
  screen.update()
end

-------- arc UI --------
function a.delta(n, d)
  -- enc 1: varispeed
  if n == 1 then
    if shift then
      local idx = params:get("scale")
      local inc = d > 0 and 1 or -1
      local rate_idx = 1
      arc_enc1_count = (arc_enc1_count + 1) % 25
      if arc_enc1_count == 0 then
        -- snap to closest scale value
        for i = 1, #scale[idx] do
          if scale[idx][i] < voice_rate then
            rate_idx = inc == 1 and i or i + 1
          elseif scale[idx][i] == voice_rate then
            rate_idx = i
          end
        end
        -- set rate      
        rate_idx = util.clamp(rate_idx + inc, 1, #scale[idx])
        voice_rate = scale[idx][rate_idx]
        params:set("varispeed", voice_rate)
      end
    else
      params:delta("varispeed", d / arc_vs_sens)
    end
  -- enc 2: slide
  elseif n == 2 then
    if shift then
      local add = d / 500
      for i = 1, GENE_NUM do
        local curr_pos = voice[i].pos_abs
        local new_pos = curr_pos + add
        softcut.position(i, new_pos)
      end
    else
      params:delta("slide", d / 20)
    end
  -- enc 3: size
  elseif n == 3 then
    params:delta("gene_size", d / 20)
  -- enc 4: morph
  elseif n == 4 then
    params:delta("morph", d / 20)
  end
  if pageNum == 2 then dirtyscreen = true end
end

function arcredraw()
  a:all(0)
  -- draw varispeed
  local rate_pos = math.floor(params:get("varispeed") * 5.25 + 1)
  local shft = voice_rate > 0 and 1 or -21
  if voice_rate ~= 0 then
    for i = 1, 21 do
      a:led(1, i + shft - arc_off, 2)
    end
  end
  for i = 2, #scale[params:get("scale")] - 1 do
    local rate_step = math.floor((scale[params:get("scale")][i]) * 5.25 + 1)
    if rate_step > 0 then
      a:led(1, rate_step + 1 - arc_off, 6)
    else
      a:led(1, rate_step - arc_off, 6)
    end
  end
  if voice_rate > 0 then
    a:led(1, rate_pos + 1 - arc_off, 15)
  elseif voice_rate <= 0 then
    a:led(1, rate_pos - arc_off, 15)
  end
  a:led(1, 22 - arc_off, 6)
  a:led(1, -20 - arc_off, 6)
  
  -- draw slide
  local gene_4_pos = math.floor(voice[4].pos_rel * 58 + 1) - 29
  a:led(2, gene_4_pos - arc_off, 2)
  local gene_3_pos = math.floor(voice[3].pos_rel * 58 + 1) - 29
  a:led(2, gene_3_pos - arc_off, 4)
  local gene_2_pos = math.floor(voice[2].pos_rel * 58 + 1) - 29
  a:led(2, gene_2_pos - arc_off, 6)
  local gene_1_pos = math.floor(voice[1].pos_rel * 58 + 1) - 29
  a:led(2, gene_1_pos - arc_off, 8)
  a:led(2, -28 - arc_off, 6)
  a:led(2, 30 - arc_off, 6)
  local slideview = math.floor(params:get("slide") * 58 + 1) - 29
  a:led(2, slideview - arc_off, 15)
  
  -- gene size
  local startpoint = math.floor(params:get("gene_size") * -28)
  local endpoint = math.ceil(params:get("gene_size") * 28)
  for i = startpoint, endpoint do
    a:led(3, i + 1 - arc_off, 10)
  end
  a:led(3, -28 - arc_off, 6)
  a:led(3, 30 - arc_off, 6)
  
  -- morph
  local morphview = util.clamp(math.floor(params:get("morph") * 58 + 1), 1, 44) - 29
  local intensity = 2
  if morphview > - 12 then
    intensity = 4
  elseif morphview > 5 then
    intensity = 6
  elseif morphview > 14 then
    intensity = 8
  end
  for i = 1, morphview + 29 do
    a:led(4, i - 29 - arc_off, intensity)
  end
  a:led(4, 15 - arc_off, 5)
  a:led(4, 18 - arc_off, 5)
  a:led(4, 21 - arc_off, 5)
  a:led(4, 24 - arc_off, 5)
  a:led(4, 27 - arc_off, 5)
  a:led(4, -28 - arc_off, 6)
  a:led(4, 30 - arc_off, 6)
  
  a:led(4, morphview - arc_off, 15)

  a:refresh()
end


-------- utilities --------
function hardware_redraw()
  if arc_is then arcredraw() end
end

function screen_redraw()
  if dirtyscreen then
    redraw()
    dirtyscreen = false
  end
  if is_recording then
    waveviz_splice = true
    softcut.render_buffer(1, splice[active_splice].s, splice[active_splice].l, 128)
  end
end

function page_redraw(num)
  if pageNum == num then
    dirtyscreen = true
  end
end

function build_menu()
  if arc_is then
    params:show("arc_params")
  else
    params:hide("arc_params")
  end
  _menu.rebuild_params()
  dirtyscreen = true
end

function drawarc_connect()
  hardware_redraw()
  arc_is = true
  hardwareredrawtimer:start()
  build_menu()
end

function drawarc_disconnect()
  arc_is = false
  hardwareredrawtimer:stop()
  build_menu()
end

function r()
  norns.script.load(norns.state.script)
end

function cleanup()
  arc.add = function() end
  arc.remove = function() end
end
