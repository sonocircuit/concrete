-- concre'te v0.1.4 @sonocircuit
-- llllllll.co/t/concrete
--
-- virtual tape
-- explorations
--
--
--
-- for docs go to:
-- >> github.com
--    /sonocircuit/concrete
--
-- or smb into:
-- >> code/concrete/docs
--
--
--
--       -- ----- -- -
--          -- ----- -- -
--             -- ----- -- -
--
--

-----------------------------------------------------------------------------------------------------------------------------
-- TODO 1: revisit LFOs --> matrix mod? adapt lfo lib?
-- TODO 2: fix crow implementation and reactivate
-----------------------------------------------------------------------------------------------------------------------------

local a = arc.connect()
local g = grid.connect()
local m = midi.connect()

local textentry = require 'textentry'
local mu = require 'musicutil'

--local _lfos = include 'lib/concrete_lfo'

-------- variables --------
local pset_load = false
local default_pset = 1

local shift = false
local pageNum = 1
local focus_page1 = 1
local focus_page2 = 0
local focus_page3 = 0
local param_page3 = 0
local focus_page4 = 0
local active_splice = 1
local prev_splice = 1
local play = false
local rec = false
local is_recording = false
local ext_signal = 1 
local sos_signal = 0
local armed = false
local glb_level = 1
local glb_pan = 1
local glb_cutoff = 1
local glb_filter_q = 1
local gbl_rate_slew = 0
local voice_rate = 1
local prev_morph_val = 0
local pos_counter = 0
local gene_length = 10
local morph_freeze = false
local morph_clocked = false
local mclk_div = 1
local gclk_div = 1
local reel_has_audio = false
local reel_is_full = false
local init_recording = true
local waveviz_reel = false
local waveviz_splice = false
local save_buffer = false
local filename_reel = ""
local MAX_REEL = 320
local GENE_NUM = 4
local ghost_voice = 5
local rec_voice = 6
local rec_at_threshold = false
local midi_channel = 1
local midi_root = 60
local key_root = -21
local crow_is = false
local dirtygrid = false

-- variables for arc
local arc_is = false
local arc_off = 0
local arc_enc1_count = 0
local arc_vs_sens = 100

-- variables for grid
local g_pos_reset = false
local g_rec_mode = false
local g_rec_dest = false
local g_rec_speed = false
local g_interval = 4

-- variables for warble
local tau = math.pi * 2
local warble_amount = 0
local warble_depth = 0
local warble_freq = 6
local warble_counter = 1
local warble_slope = 0
local warble_active = false

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
options.scale = {"oct", "oct+p4", "oct+p5", "oct+p4+p5"}
options.crow_input = {"none", "play [trig]", "play [gate]", "restart [trig]", "rec [trig]", "rec [gate]", "add splice [trig]", "next splice [trig]", "prev splice [trig]", "random splice [trig]", "select splice [cv]", "varispeed v/8 [cv]", "slide [cv]", "size [cv]", "morph [cv]"}
options.crow_output = {"none", "gene ramp [cv]", "loop reset [trig]"}
options.clock_tempo = {"2", "1", "1/2", "1/4", "3/16", "1/6", "1/8", "3/32", "1/12", "1/16","1/32"}
options.clock_value = {2, 1, 1/2, 1/4, 3/16, 1/6, 1/8, 3/32, 1/12, 1/16, 1/32}
options.params_gbl = {"global_level", "global_pan", "global_cutoff_rel", "global_filter_q_rel"}
options.params = {"level", "pan", "cutoff", "filter_q"}
options.params_view = {"level", "pan", "cutoff", "filter q"}
options.rate_slew = {0, 0.05, 0.1, 0.2, 0.5}

local scale = {
  {-oct2, -oct1, -oct0, -oct05, -oct025, oct025, oct05, oct0, oct1, oct2}, -- octaves
  {-oct2, -p4_1, -oct1, -p4,  -oct0, -p4_05, -oct05, -p4_025, -oct025, oct025, p4_025, oct05, p4_05, oct0, p4, oct1, p4_1, oct2}, -- octaves and fifths
  {-oct2, -p5_1, -oct1, -p5,  -oct0, -p5_05, -oct05, -p5_025, -oct025, oct025, p5_025, oct05, p5_05, oct0, p5, oct1, p5_1, oct2}, -- octaves and fifths
  {-oct2, -p5_1, -p4_1, -oct1, -p5, -p4, -oct0, -p4_05, -p5_05, -oct05, -p4_025, -p5_025, -oct025, oct025, p5_025, p4_025, oct05, p5_05, p4_05, oct0, p4, p5, oct1, p4_1, p5_1, oct2} -- octaves + fiths + fourths
}

local splice = {}
splice[1] = {}
splice[1].s = 1
splice[1].e = MAX_REEL + 1
splice[1].l = MAX_REEL

local voice = {}
for i = 1, 6 do
  voice[i] = {}
  voice[i].active = true
  voice[i].s = 1
  voice[i].level = 1
  voice[i].prev_level = 1
  voice[i].pan = 0
  voice[i].fc = 18000
  voice[i].fq = 2
  voice[i].rate_mod = 1
  voice[i].trsp_value = 1
  voice[i].pos_abs = 1
  voice[i].pos_rel = 0
end

-------- reels --------
function load_reel(path)
  if path ~= "cancel" and path ~= "" then
    local ch, len = audio.file_info(path)
    if ch > 0 and len > 0 then
      filename_reel = path
      softcut.buffer_clear()
      softcut.buffer_read_mono(path, 0, 1, -1, 1, 1, 0, 1)
      local l = math.min(len / 48000, MAX_REEL)
      init_reel(l)
      print("file loaded: "..path.." is "..l.."s")
    else
      print("not a sound file")
    end
    params:set("load_reel", "", true)
  end
end

function load_splice(path)
  local filename_append = path
  local ch, len = audio.file_info(filename_append)
  if ch > 0 and len > 0 then
    if reel_has_audio then
      local start_pos = splice[#splice].e
      softcut.buffer_read_mono(filename_append, 0, start_pos, -1, 1, 1, 0, 1)
      local l = math.min(len / 48000, (MAX_REEL - start_pos + 1))
      append_splice(start_pos + l)
      print("splice added: "..filename_append.." is "..l.."s")
    else
      softcut.buffer_read_mono(filename_append, 0, 1, -1, 1, 1, 0, 1)
      local l = math.min(len / 48000, MAX_REEL)
      init_reel(l)
      print("splice added: "..filename_append.." is "..l.."s")
    end
    params:set("append_file", "")
  else
    print("not a sound file")
  end
end

function save_splice(txt)
  if txt then
    local start = splice[active_splice].s
    local length = splice[active_splice].e - splice[active_splice].s
    util.make_dir(_path.audio .. "concrete/splices")
    softcut.buffer_write_mono(_path.audio.."concrete/splices/"..txt..".wav", start, length, 1)
    print("splice saved: " .._path.audio .. "concrete/splices/" .. txt .. ".wav")
  else
    print("save cancel")
  end
end

function save_reel(txt)
  if txt then
    local length = splice[#splice].e - 1
    util.make_dir(_path.audio .. "concrete/reels")
    softcut.buffer_write_mono(_path.audio.."concrete/reels/"..txt..".wav", 1, length, 1)
    print("reel saved: " .._path.audio .. "concrete/reels/" .. txt .. ".wav")
  else
    print("save cancel")
  end
end

function clear_reel()
  softcut.buffer_clear()
  reel_is_full = false
  init_recording = true
  reel_has_audio = false
  active_splice = 1
  splice = {}
  splice[1] = {}
  splice[1].s = 1
  splice[1].e = 1 + MAX_REEL
  splice[1].l = MAX_REEL
  waveviz_reel = true
  waveviz_splice = true
  softcut.render_buffer(1, 1, MAX_REEL, 128)
  set_loops()
  set_start_pos()
  params:set("load_reel", "", true)
  print("cleared reel")
end

function init_reel(dur)
  active_splice = 1
  splice = {}
  splice[1] = {}
  splice[1].s = 1
  splice[1].e = 1 + dur
  splice[1].l = dur
  reel_has_audio = true
  init_recording = false
  waveviz_reel = true
  waveviz_splice = true
  softcut.render_buffer(1, 1, dur, 128)
  set_loops()
  set_start_pos()
  print("init reel > length: "..dur)
end

function add_splice(pos)
  table.insert(splice, active_splice + 1, {})
  splice[active_splice + 1].s = pos or voice[1].pos_abs
  splice[active_splice + 1].e = splice[active_splice].e
  splice[active_splice].e = pos or voice[1].pos_abs
  splice[active_splice + 1].l = splice[active_splice + 1].e - splice[active_splice + 1].s
  splice[active_splice].l = splice[active_splice].e - splice[active_splice].s
  set_loops()
  set_start_pos()
  waveviz_splice = true
  softcut.render_buffer(1, splice[active_splice].s, splice[active_splice].l, 128)
  dirtygrid = true
  -- print_markers()
end

function remove_splice()
  if active_splice < #splice then
    splice[active_splice + 1].s = splice[active_splice].s
    splice[active_splice + 1].l = splice[active_splice + 1].e - splice[active_splice].s
    table.remove(splice, active_splice)
    set_loops()
    set_start_pos()
    waveviz_splice = true
    softcut.render_buffer(1, splice[active_splice].s, splice[active_splice].l, 128)
    dirtygrid = true
  end
  --print_markers()
end

function append_splice(pos)
  table.insert(splice, #splice + 1, {})
  splice[#splice].s = splice[#splice - 1].e
  splice[#splice].e = pos or voice[rec_voice].pos_abs
  splice[#splice].l = splice[#splice].e - splice[#splice].s
  waveviz_reel = true
  softcut.render_buffer(1, 1, splice[#splice].e - 1, 128)
  dirtygrid = true
  --print_markers()
end

function nudge_splice_start(d)
  local amt = d / 50
  if active_splice > 1 then
    splice[active_splice].s = util.clamp(splice[active_splice].s + amt, splice[active_splice - 1].s + 0.01, splice[active_splice].e - 0.01)
    splice[active_splice - 1].e = splice[active_splice].s
    splice[active_splice - 1].l = splice[active_splice - 1].e - splice[active_splice - 1].s
    splice[active_splice].l = splice[active_splice].e - splice[active_splice].s
  end
  set_loops()
  waveviz_splice = true
  softcut.render_buffer(1, splice[active_splice].s, splice[active_splice].l, 128)
  --print_markers()
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
  waveviz_splice = true
  softcut.render_buffer(1, splice[active_splice].s, splice[active_splice].l, 128)
  --print_markers()
end

function delete_splice(splice_num)
  local active_splice = splice_num or active_splice
  if #splice > 1 then
    if active_splice == #splice then
      local last_splice = active_splice
      set_active_splice(-1)
      softcut.buffer_clear_region_channel(1, splice[last_splice].s - 0.01, -1, 0.01)
      table.remove(splice, #splice)
    else
      softcut.buffer_clear_region_channel(1, splice[active_splice].s, splice[active_splice].l, 0.01, 0)
      local tail = splice[#splice].e - splice[active_splice].e
      softcut.buffer_copy_mono(1, 1, splice[active_splice].e, splice[active_splice].s, tail, 0.01, 0, 0)
      local pos_shift = splice[active_splice].l
      for i = active_splice + 1, #splice do
        splice[i].s = splice[i].s - pos_shift
        splice[i].e = splice[i].e - pos_shift
        splice[i].l = splice[i].e - splice[i].s
      end
      table.remove(splice, active_splice)
      softcut.buffer_clear_region_channel(1, splice[#splice].e, -1, 0.01)
      set_loops()
    end
    if splice[#splice].e < MAX_REEL then
      reel_is_full = false
    end
    -- display waveforms
    waveviz_reel = true
    softcut.render_buffer(1, 1, splice[#splice].e - 1, 128)
    clock.run(
      function()
        clock.sleep(0.2)
        prev_splice = 0
        set_active_splice(0)
      end
    )
    dirtygrid = true
    --print_markers()
  end
end

function flip_splice(splice_num)
  local active_splice = splice_num or active_splice
  softcut.buffer_copy_mono(1, 2, splice[active_splice].s, splice[active_splice].s, splice[active_splice].l, 0.01, 0, 1)
  clock.run(
    function()
      clock.sleep(0.1)
      softcut.buffer_copy_mono(2, 1, splice[active_splice].s, splice[active_splice].s, splice[active_splice].l, 0.01, 0, 0)
      set_loops()
      waveviz_reel = true
      softcut.render_buffer(1, 1, splice[#splice].e - 1, 128)
      clock.run(
        function()
          clock.sleep(0.1)
          waveviz_splice = true
          softcut.render_buffer(1, splice[active_splice].s, splice[active_splice].l, 128)
        end
      )
    end
  )
  --print_markers()
  --print("flipped splice "..active_splice)
end

function gain_reduction()
  softcut.buffer_clear_region(splice[active_splice].s, splice[active_splice].l, 0.01, 0.794)
  waveviz_reel = true
  softcut.render_buffer(1, 1, splice[#splice].e - 1, 128)
end

function set_active_splice(inc)
  active_splice = util.clamp(active_splice + inc, 1, #splice)
  clock.run(
    function()
      clock.sleep(0.1)
      if active_splice ~= prev_splice then
        if params:get("morph_mode") == 2 then
          voice[1].s = util.clamp(splice[active_splice].s + splice[active_splice].l * params:get("slide"), splice[active_splice].s, splice[active_splice].e)
        end
        set_loops()
        set_start_pos()
        prev_splice = active_splice
        waveviz_splice = true
        softcut.render_buffer(1, splice[active_splice].s, splice[active_splice].l, 128)
      end
    end
  )
  dirtygrid = true
end

function set_random_splice()
  local inc = math.random(1, #splice) - active_splice
  set_active_splice(inc)
end

function select_splice(val)
  local segment = 1 / #splice
  for i = 1, #splice do
    if val <= segment * i then
      local inc = i - active_splice
      set_active_splice(inc)
      break
    end
  end
end

-- debug stuff
function print_markers()
  for i = 1, #splice do
    print("splice "..i)
    tab.print(splice[i])
  end
end


-------- voices / playheads --------
function set_play()
  if play then
    if rec then
      rec = false
      set_rec()
      set_levels()
    else
      play = false
      pos_counter = 0
      set_levels()
    end
  else
    play = true
    set_start_pos()
    set_rec()
    set_levels()
  end
  page_redraw(1)
end

function toggle_recording()
  if params:get("rec_dest") == 3 then
    if not reel_is_full then
      rec = not rec
    else
      rec = false
    end
  else
    rec = not rec
  end
  set_rec()
  page_redraw(1)
end

function set_rec()
  if rec and play then
    softcut.rec_level(rec_voice, params:get("rec_level"))
    softcut.pre_level(rec_voice, params:get("dub_level"))
    if not is_recording then
      -- set position
      if params:get("rec_dest") ~= 3 then
        softcut.position(rec_voice, voice[1].pos_abs)
        softcut.loop_start(rec_voice, splice[active_splice].s)
        softcut.loop_end(rec_voice, splice[active_splice].e)
      else
        softcut.position(rec_voice, splice[#splice].e)
        softcut.loop_start(rec_voice, splice[#splice].e)
        softcut.loop_end(rec_voice, MAX_REEL + 1)
      end
      -- set rate
      local rate = params:get("rec_rate") < 3 and math.abs(voice_rate) or math.abs(voice_rate * 2)
      softcut.rate(rec_voice, rate)
      is_recording = true
    end
  elseif rec and not play then
    amp_in[1]:start()
    amp_in[2]:start()
    rec_at_threshold = true
  else
    softcut.rec_level(rec_voice, 0)
    softcut.pre_level(rec_voice, 1)
    if is_recording then
      if init_recording then
        init_reel(voice[rec_voice].pos_abs - 1)
        init_recording = false
        is_recording = false
      elseif params:get("rec_dest") == 3 then
        append_splice()
        is_recording = false
      else
        is_recording = false
        waveviz_reel = true
        softcut.render_buffer(1, 1, splice[#splice].e - 1, 128)
      end
    end
    if rec_at_threshold then
      amp_in[1]:stop()
      amp_in[2]:stop()
      rec_at_threshold = false
    end
  end
  set_levels()
end

function set_levels()
  -- voice levels
  for i = 1, GENE_NUM do
    local level = voice[i].level * glb_level
    if play and voice[i].active then
      softcut.level(i, level)
    else
      softcut.level(i, 0)
    end
  end
  -- rec levels
  if params:get("rec_mode") == 1 then
    ext_signal = sos_signal
    for i = 1, GENE_NUM do
      softcut.level_cut_cut(i, rec_voice, 0)
    end
    set_input_routing()
  else
    -- set input level
    ext_signal = 1 - sos_signal
    -- and set levels
    if get_active_voices() == 1 then
      level_reduction = 0.9
    elseif get_active_voices() == 2 then
      level_reduction = 0.75
    elseif get_active_voices() == 3 then
      level_reduction = 0.6
    elseif get_active_voices() == 4 then
      level_reduction = 0.5
    end
    for i = 1, GENE_NUM do
      if voice[i].active then
        softcut.level_cut_cut(i, rec_voice, voice[i].level * sos_signal * level_reduction)
      else
        softcut.level_cut_cut(i, rec_voice, 0)
      end
    end
    set_input_routing()
  end
end

function set_input_routing()
  if params:get("rec_input") == 1 then -- L&R
    softcut.level_input_cut(1, rec_voice, ext_signal * 0.7)
    softcut.level_input_cut(2, rec_voice, ext_signal * 0.7)
  elseif params:get("rec_input")  == 2 then -- L IN
    softcut.level_input_cut(1, rec_voice, ext_signal * 1)
    softcut.level_input_cut(2, rec_voice, 0)
  elseif params:get("rec_input")  == 3 then -- R IN
    softcut.level_input_cut(1, rec_voice, 0)
    softcut.level_input_cut(2, rec_voice, ext_signal * 1)
  elseif params:get("rec_input")  == 4 then -- OFF
    softcut.level_input_cut(1, rec_voice, 0)
    softcut.level_input_cut(2, rec_voice, 0)
    if params:get("rec_mode") == 1 then
      params:set("rec_mode", 2) -- force to s.o.s mode
    end
  end
end

function select_filter(i, option)
  softcut.post_filter_lp(i, option == 1 and 1 or 0) 
  softcut.post_filter_hp(i, option == 2 and 1 or 0) 
  softcut.post_filter_bp(i, option == 3 and 1 or 0) 
  softcut.post_filter_br(i, option == 4 and 1 or 0)
  softcut.post_filter_dry(i, option == 5 and 1 or 0)
end

function set_panning()
  for i = 1, GENE_NUM do
    local pan = voice[i].pan * glb_pan
    softcut.pan(i, pan)
  end
end


local delta_viz_fc = "<  >"
function set_cutoff(d)
  local min = math.min(voice[1].fc, voice[2].fc, voice[3].fc, voice[4].fc)
  local max = math.max(voice[1].fc, voice[2].fc, voice[3].fc, voice[4].fc)
  for i = 1, GENE_NUM do
    if d < 0 and params:get("cutoff"..i) > 20 then
      params:delta("cutoff"..i, d)
      params:set("global_cutoff_rel", 0)
      delta_viz_fc = "<<"
    elseif d > 0 and params:get("cutoff"..i) < 18000 then
      params:delta("cutoff"..i, d)
      params:set("global_cutoff_rel", 0)
      delta_viz_fc = ">>"
    end
  end
  if d < 0 and min == 20 then
    delta_viz_fc = "|<"
  elseif d > 0 and max == 18000 then
    delta_viz_fc = ">|"
  end
end

local delta_viz_fq = "<  >"
function set_filter_q(d)
  local min = math.min(voice[1].fq, voice[2].fq, voice[3].fq, voice[4].fq)
  local max = math.max(voice[1].fq, voice[2].fq, voice[3].fq, voice[4].fq)
  for i = 1, GENE_NUM do
    if d < 0 and params:get("filter_q"..i) > 0.1 then
      params:delta("filter_q"..i, d)
      params:set("global_filter_q_rel", 0)
      delta_viz_fq = "<<"
    elseif d > 0 and params:get("filter_q"..i) < 4 then
      params:delta("filter_q"..i, d)
      params:set("global_filter_q_rel", 0)
      delta_viz_fq = ">>"
    end
  end
  if d < 0 and min == 0.1 then
    delta_viz_fq = "|<"
  elseif d > 0 and max == 4 then
    delta_viz_fq = ">|"
  end
end

function set_rate()
  for i = 1, GENE_NUM do
    local rate = voice_rate * voice[i].rate_mod * voice[i].trsp_value
    softcut.rate(i, rate)
  end
  if params:get("rec_rate") == 1 then
    local rate = math.abs(voice_rate)
    softcut.rate(rec_voice, rate)
  end
end

function set_rate_slew(mode)
  for i = 1, GENE_NUM do
    softcut.rate_slew_time(i, gbl_rate_slew)
  end
  if mode < 3 then
    warble_amount = 0
    warble_depth = 0
  elseif mode == 3 then
    warble_amount = 12
    warble_depth = 8
  elseif mode == 4 then
    warble_amount = 24
    warble_depth = 22
  else
    warble_amount = 36
    warble_depth = 40
  end
end

local rate_rst = false
local pan_rst = false
function reset_morph_params()
  if not morph_freeze then
    local morph = params:get("morph") * 100
    if morph > 79 then rate_rst = true end
    if morph > 74 then pan_rst = true end
    -- reset rate mod
    if morph < 80 and rate_rst then
      for i = 1, GENE_NUM do
        voice[i].rate_mod = 1
      end
      set_rate()
      rate_rst = false
    end
    -- reset levels and pan
    if morph < 75 and pan_rst then
      for i = 1, GENE_NUM do
        voice[i].level = params:get("level"..i)
        voice[i].pan = params:get("pan"..i)
      end
      set_levels()
      set_panning()
      pan_rst = false
    end
  end
end

function set_start_pos()
  for i = 1, GENE_NUM do
    softcut.position(i, voice[i].s)
  end
  pos_counter = 0
  if params:get("rec_dest") == 1 then
    softcut.position(rec_voice, voice[1].s)
  end

  --[[
  for i = 1, 4 do
    if params:get("crow_out_"..i) == 2 then
      crow.output[i].action = "{ to(0, 0), to(8, "..gene_length.."), to(0, 0, 'lin') }"
      crow.output[i]()
    elseif params:get("crow_out_"..i) == 3 then
      crow.output[i].action = "pulse(0.02, 8)"
      crow.output[i]()
    end
  end
  ]]

  set_levels()
  page_redraw(1)
end

function set_loops()
  -- calculate start, end and length
  if params:get("morph_mode") == 1 then -- --TODO: testing required: you might run into trouble if pset loads into clocked mode as voice[1].s == 1
    voice[1].s = util.clamp(splice[active_splice].s + splice[active_splice].l * params:get("slide"), splice[active_splice].s, splice[active_splice].e)
  end
  gene_length = util.clamp(splice[active_splice].l * params:get("gene_size"), 0.01, splice[active_splice].l)
  -- and set loop window to active splice
  for i = 1, GENE_NUM do
    softcut.loop_start(i, splice[active_splice].s)
    softcut.loop_end(i, splice[active_splice].e)
  end
  -- morph genes according to the morph param
  local mval = params:get("morph") * 100
  local sval = params:get("morph") * 1.25
  if mval < 5 then
    -- set all to same start pos
    voice[1].active = true
    for i = 2, GENE_NUM do
      voice[i].s = voice[1].s
      voice[i].active = false
    end
  elseif mval >= 5 and mval <= 30 then
    -- shift gene 2 only
    local shift_amount = (gene_length / 2) * sval
    voice[2].s = voice[1].s + shift_amount
    if voice[2].s > splice[active_splice].e then
      voice[2].s = voice[2].s - splice[active_splice].l
    end
    voice[2].active = true
    -- keep others aligned
    for i = 3, GENE_NUM do
      voice[i].s = voice[1].s
      voice[i].active = false
    end
  elseif mval > 30 and mval <= 60 then
    -- shift gene 2 + 3 
    local shift_amount = (gene_length / 3) * sval
    voice[2].s = voice[1].s + shift_amount
    if voice[2].s > splice[active_splice].e then
      voice[2].s = voice[2].s - splice[active_splice].l
    end
    voice[2].active = true
    voice[3].s = voice[2].s + shift_amount
    if voice[3].s > splice[active_splice].e then
      voice[3].s = voice[2].s - splice[active_splice].l
    end
    voice[3].active = true
    -- keep gene 4 aligned
    voice[4].s = voice[1].s
    voice[4].active = false
  elseif mval > 60 and mval <= 90 then
    -- shift gene 2 + 3 + 4
    local shift_amount = (gene_length / 4) * sval
    voice[2].s = voice[1].s + shift_amount
    if voice[2].s > splice[active_splice].e then
      voice[2].s = voice[2].s - splice[active_splice].l
    end
    voice[2].active = true
    voice[3].s = voice[2].s + shift_amount
    if voice[3].s > splice[active_splice].e then
      voice[3].s = voice[3].s - splice[active_splice].l
    end
    voice[3].active = true
    voice[4].s = voice[3].s + shift_amount
    if voice[4].s > splice[active_splice].e then
      voice[4].s = voice[4].s - splice[active_splice].l
    end
    voice[4].active = true
  elseif mval > 90 then -- if > 90 then max rand and changing start pos will not change the start pos of the other genes.
    -- keep things how they are
  end
end

function morph_values()
  while true do
    clock.sync(1/4) --16th notes
    local mval = params:get("morph") * 100
    if math.random(100) <= params:get("morph_prob") and not morph_freeze and play then
      if mval > 74 and params:get("randomize_pan") == 2 then
        voice[1].pan = (math.random() * 20 - 10) / 10
        voice[2].pan = -voice[1].pan
        voice[3].pan = (math.random() * 20 - 10) / 10
        voice[4].pan = -voice[3].pan
        for i = 1, GENE_NUM do
          softcut.pan(i, voice[i].pan)
        end
        page_redraw(3)
      end
      if mval >= 75 and params:get("randomize_level") == 2 then 
        for i = 1, GENE_NUM do
          voice[i].level = math.random(25, 100) / 100
          set_levels()
        end
        page_redraw(3)
      end
      if mval >= 80 and mval < 85 and params:get("randomize_rate") == 2 then 
        for i = 2, GENE_NUM do
          local dice = math.random(-1, 1)
          if dice ~= 0 then
            voice[i].rate_mod = dice
            set_rate()
          end
        end
      elseif mval >= 85 and mval < 90 and params:get("randomize_rate") == 2 then
        for i = 2, GENE_NUM do
          local dice = math.random(-2, 2)
          if dice ~= 0 then
            voice[i].rate_mod = dice
            set_rate()
          end
        end
      elseif mval >= 90 and mval < 95 and params:get("randomize_rate") == 2 then
        for i = 2, GENE_NUM do
          local rnd = math.random(#scale[params:get("scale")])
          voice[i].rate_mod = scale[params:get("scale")][rnd]
          set_rate()
        end
      elseif mval >= 95 and params:get("randomize_rate") == 2 then
        for i = 2, GENE_NUM do
          local rnd = math.random(#scale[params:get("scale")])
          local dice = math.random(-2, 2)
          if dice ~= 0 then
            voice[i].rate_mod = scale[params:get("scale")][rnd] * dice
          else
            voice[i].rate_mod = scale[params:get("scale")][rnd]
          end
          set_rate()
        end
      end
    end
  end
end

function step_genes()
  while true do
    clock.sync(mclk_div)
    if params:get("gene_size") < 1 and params:get("morph_mode") == 2 then
      for i = 1, GENE_NUM do
        if voice_rate > 0 then
          voice[i].s = voice[i].s + gene_length
          if voice[i].s > splice[active_splice].e then
            voice[i].s = voice[i].s - splice[active_splice].l
          end
        elseif voice_rate < 0 then
          voice[i].s = voice[i].s - gene_length
          if voice[i].s < splice[active_splice].s then
            voice[i].s = voice[i].s + splice[active_splice].l
          end
        end
      end
      set_start_pos()
    end
  end
end

-------- ghost voice --------
function ghost_activity()
  while true do
    clock.sync(gclk_div)
    if params:get("ghost_active") == 2 and play then
      summon_ghost()
    elseif params:get("ghost_active") == 3 and not play then
      summon_ghost()
    elseif params:get("ghost_active") == 4 then
      summon_ghost()
    end
  end
end

function summon_ghost()
  -- ghost here
  if math.random(100) <= params:get("ghost_prob") then
    voice[ghost_voice].active = true
    -- set loop
    local start_pos = 1
    if params:get("ghost_distribution") == 1 then
      start_pos = 1 + math.random() * splice[#splice].e
    else
      start_pos = splice[active_splice].s + math.random() * splice[active_splice].l
    end
    local end_pos = start_pos + clock.get_beat_sec() * gclk_div
    softcut.loop_start(ghost_voice, start_pos)
    softcut.loop_end(ghost_voice, end_pos)
    -- set rate
    local rates = {0.25, 0.5, 1, -1, -0.5, -0.25}
    local rate = rates[math.random(1, 6)]
    softcut.rate(ghost_voice, rate)
    -- set pan
    local pan = voice[ghost_voice].pan * (math.random() * 20 - 10) / 10
    softcut.pan(ghost_voice, pan)
    -- let level
    local ghost_level = voice[ghost_voice].level * glb_level
    softcut.level(ghost_voice, ghost_level)
  end
  -- ghost vanish
  if math.random(100) <= params:get("ghost_duration") then
    voice[ghost_voice].active = false
    local ghost_level = 0
    softcut.level(ghost_voice, ghost_level)
  end
  -- set rec levels
  if rec then
    if params:get("rec_mode") == 1 or params:get("ghost_active") == 1 or params:get("ghost_active") == 3 then
      softcut.level_cut_cut(ghost_voice, rec_voice, 0)
    else
      local level = voice[ghost_voice].active and voice[ghost_voice].level * sos_signal or 0
      softcut.level_cut_cut(ghost_voice, rec_voice, level)
    end
  end
end


-------- tape warble --------
function make_warble()
  local slope = 1 * math.sin(((tau / 100) * (warble_counter)) - (tau / (warble_freq)))
  warble_slope = util.linlin(-1, 1, -1, 0, math.max(-1, math.min(1, slope))) * warble_depth * 0.001
  warble_counter = warble_counter + warble_freq
  -- activate warble
  if play and math.random(100) <= warble_amount then
    if not warble_active then
      warble_active = true
    end
  end
  -- make warble
  if warble_active then
    for i = 1, GENE_NUM do
      local warble_rate = voice_rate * (1 + warble_slope)
      softcut.rate(i, warble_rate)
    end
  end
  -- stop warble
  if warble_active and warble_slope > -0.001 then
    set_rate()
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
    wave_reel_gain = table_getmax(waveform_reel_samples) / 0.9
  end
  if waveviz_splice then
    waveform_splice_samples = {}
    waveform_splice_samples = s
    waveviz_splice = false
    wave_splice_gain = table_getmax(waveform_splice_samples) / 0.8
    --reel_has_audio = wave_reel_gain > 0 and true or false
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
  return util.clamp(max, 0.4, 1)
end


-------- midi --------
function build_midi_device_list()
  midi_devices = {}
  for i = 1, #midi.vports do
    local long_name = midi.vports[i].name
    local short_name = string.len(long_name) > 15 and util.acronym(long_name) or long_name
    table.insert(midi_devices, i..": "..short_name)
  end
end

function midi_connect()
  build_midi_device_list()
end

function midi_disconnect()
  clock.run(
    function()
      clock.sleep(0.2)
      build_midi_device_list()
    end
  )
end

function midi_events(data)
  local msg = midi.to_msg(data)
  if msg.type == "note_on" and msg.ch == midi_channel then
    local semitone = math.pow(2, (msg.note - midi_root) / 12)
    for i = 1, 4 do
      voice[i].trsp_value = semitone
      if params:get("adsr_active") == 2 then
        env_gate_on(i)
      end
    end
    set_rate()
  elseif msg.type == "note_off" and msg.ch == midi_channel then
    if params:get("adsr_active") == 2 then
      for i = 1, 4 do
        env_gate_off(i)
      end
    end
  end
end

function set_midi_event_callback()
  midi.cleanup()
  m.event = midi_events
end

-- envelopes
local env = {}
env.attack = 0
env.decay = 0
env.sustain = 1
env.release = 0
for i = 1, 4 do
  env[i] = {}
  env[i].gate = false
  env[i].trig = false
  env[i].a_is_running = false
  env[i].d_is_running = false
  env[i].r_is_running = false
  env[i].max_value = 1
  env[i].init_value = 0
  env[i].prev_value = 0
  env[i].count = 0
  env[i].direction = 0
  env[i].id = "env "..i
end

function env_gate_on(i)
  env_get_value(i)
  env[i].gate = true
  env[i].a_is_running = true
  env[i].count = 0
  env[i].direction = 1
  --print("gate on")
end

function env_gate_off(i)
  env_get_value(i)
  env[i].gate = false
  env[i].a_is_running = false
  env[i].d_is_running = false
  env[i].r_is_running = true
  env[i].count = 0
  env[i].direction = 1
  --print("gate off")
end

function env_increment(i, d)
  params:delta("level"..i, d * 100)
  --if view == vENV then dirtygrid = true end
end

function env_set_value(i, val)
  params:set("level"..i, val)
end

function env_get_value(i)
  env[i].prev_value = params:get("level"..i)
end

function env_stop(i)

end

--- make envelope
function env_run()
  while true do
    clock.sleep(1/10)
    for i = 1, 4 do
      env[i].count = env[i].count + env[i].direction
      if env[i].gate then
        if env[i].a_is_running then
          if env.attack == 0 then
            env_set_value(i, env[i].max_value)
            env_get_value(i)
            env[i].count = 0
            env[i].a_is_running = false
            env[i].d_is_running = true
          else
            local d = (env[i].max_value - env[i].prev_value) / env.attack
            env_increment(i, d)
            if env[i].count >= env.attack then
              env_get_value(i)
              env[i].count = 0
              env[i].a_is_running = false
              env[i].d_is_running = true
            end
          end
        end
        if env[i].d_is_running then
          local s = env[i].max_value * env.sustain
          if env.decay == 0 then
            env[i].direction = 0
            env[i].count = 0
            env[i].d_is_running = false
            env_set_value(i, s)
            env_get_value(i)
          else
            local d = -(env[i].prev_value - s) / env.decay
            env_increment(i, d)
            if env[i].count >= env.decay then
              env[i].direction = 0
              env[i].count = 0
              env[i].d_is_running = false
              env_set_value(i, s)
              env_get_value(i)
            end
          end
        end
      else
        if env[i].r_is_running then
          if env.release == 0 then
            env[i].direction = 0
            env[i].count = 0
            env[i].r_is_running = false
            env_set_value(i, env[i].init_value)
            env_stop(i)
          else
            local d = -(env[i].prev_value - env[i].init_value) / env.release
            env_increment(i, d)
            if env[i].count >= env.release then
              env[i].direction = 0
              env[i].count = 0
              env[i].r_is_running = false
              env[i].trig = false
              env_set_value(i, env[i].init_value)
              env_stop(i)
            end
          end
        end
      end
    end
  end
end

function init_envelope()
  for i = 1, 4 do
    if params:get("adsr_active") == 2 then
      env[i].max_value = params:get("level"..i)
      voice[i].prev_level = voice[i].level
      params:set("level"..i, env[i].init_value)
    else
      env[i].gate = false
      env[i].a_is_running = false
      env[i].d_is_running = false
      env[i].r_is_running = false
      env[i].count = 0
      env[i].direction = 1
      params:set("level"..i, voice[i].prev_level)
    end
  end
  page_redraw(3)
end

function clamp_env_levels(i)
  if env[i].init_value >= env[i].max_value then
    params:set(i.."adsr_init", env[i].max_value)
  end
  if env.sustain >= env[i].max_value then
    params:set(i.."adsr_sustain", env[i].max_value)
  end
  if env[i].init_value >= env.sustain then
    params:set(i.."adsr_sustain", env[i].init_value)
  end
end


--[[
-------- crow --------
function crow_in_change_1(v)
  print("channel 1")
  print(v)
end

function crow_in_change_2(v)
  print("channel 2")
  print(v)
end

function crow_in_stream(v)

end

function set_crow_input(ch, mode)
  if mode == 1 then
    crow.input[ch].mode("none")
  elseif mode > 1 and mode < 10 then
    crow.input[ch].mode("change", 2.0, 0.2, "both")
    crow.input[ch].change = ch == 1 and crow_in_change_1 or crow_in_change_2
  elseif mode > 9 then
    crow.input[ch].stream = crow_in_stream
    crow.input[ch].mode("stream", 0.01)
  end
end
]]

-------- helpers --------
function round_form(param, quant, form)
  return(util.round(param, quant)..form)
end

function get_active_voices()
  local active_voices = 1
  for i = 2, GENE_NUM do
    if voice[i].active then
      active_voices = active_voices + 1
    end
  end
  return active_voices
end


-------- init --------
function init()

  build_midi_device_list()

  --[[
  -- crow params
  params:add_group("crow_params",  "CROW", 6)

  for i = 1, 2 do
    params:add_option("crow_in_"..i, "input "..i, options.crow_input, 1)
    params:set_action("crow_in_"..i, function(mode) set_crow_input(i, mode) end)
  end

  for i = 1, 4 do
    params:add_option("crow_out_"..i, "output "..i, options.crow_output, 1)
  end
  ]]


  -- arc params
  params:add_group("arc_params", "ARC", 2)

  params:add_option("arc_orientation", "arc orientation", {"horizontal", "vertical"}, 1)
  params:set_action("arc_orientation", function(val) arc_off = (val - 1) * 16 end)

  params:add_option("arc_vs_sens", "varispeeed sensitivity", {"lo", "hi"}, 1)
  params:set_action("arc_vs_sens", function(x) arc_vs_sens = x == 1 and 100 or 500 end)

  -- reel params
  params:add_separator("reel", "reel")

  params:add_group("load_save_reel", "load & save", 4)

  params:add_file("load_reel", "> load reel", "")
  params:set_action("load_reel", function(path) load_reel(path) end)

  params:add_trigger("save_reel", "< save reel")
  params:set_action("save_reel", function() textentry.enter(save_reel) end)

  params:add_option("save_buffer_pset", "? save reel with pset", {"no", "yes"}, 2)
  params:set_action("save_buffer_pset", function(x) save_buffer = x == 2 and true or false end)

  params:add_trigger("clear_reel", "!! clear and reset reel !!")
  params:set_action("clear_reel", function() clear_reel() end)

  params:add_group("rec_params", "recording", 9)

  params:add_binary("toggle_rec", "> toggle rec", "trigger", 0)
  params:set_action("toggle_rec", function() toggle_recording() end)

  params:add_option("rec_mode", "mode", {"input only", "s.o.s"}, 1) 
  params:set_action("rec_mode", function() set_levels() end)

  params:add_option("rec_input", "input", {"summed", "left", "right", "off"}, 1)
  params:set_action("rec_input", function() set_levels() end)

  params:add_option("rec_dest", "destination", {"follow loop", "active splice", "new splice"}, 1)

  params:add_option("rec_rate", "rate", {"follow rate", "constant", "highspeed"}, 1)

  params:add_control("rec_threshold", "threshold", controlspec.new(-40, 6, 'lin', 0, -12, "dB"))

  params:add_control("sos_level", "s.o.s level", controlspec.new(0, 1, "lin", 0, 0.8), function(param) return (round_form(util.linlin(0, 1, 0, 100, param:get()), 1, "%")) end)
  params:set_action("sos_level", function(val) sos_signal = val set_levels() page_redraw(1) end)

  params:add_control("rec_level", "rec level", controlspec.new(0, 1, "lin", 0, 1), function(param) return (round_form(util.linlin(0, 1, 0, 100, param:get()), 1, "%")) end)
  params:set_action("rec_level", function() set_rec() end)

  params:add_control("dub_level", "overdub level", controlspec.new(0, 1, "lin", 0, 0.8), function(param) return (round_form(util.linlin(0, 1, 0, 100, param:get()), 1, "%")) end)
  params:set_action("dub_level", function() set_rec() page_redraw(1) end)

  params:add_group("splice_params", "splices", 16)

  params:add_separator("splice_audio_params", "audio")

  params:add_file("append_file", ">> append splice to reel", "")
  params:set_action("append_file", function(path) load_splice(path) end)

  params:add_trigger("save_splice", "<< save active splice")
  params:set_action("save_splice", function() textentry.enter(save_splice) end)

  params:add_binary("flip_splice_param", "> reverse active splice", "trigger", 0)
  params:set_action("flip_splice_param", function() flip_splice() end)

  params:add_trigger("reduce_gain", "> reduce gain [-1bB]")
  params:set_action("reduce_gain", function() gain_reduction() end)
  params:hide("reduce_gain")

  params:add_separator("splice_markers_params", "markers")

  params:add_binary("add_splice_param", "> add splice marker", "trigger", 0)
  params:set_action("add_splice_param", function() add_splice() end)

  params:add_binary("remove_splice_param", "> remove splice marker", "trigger", 0)
  params:set_action("remove_splice_param", function() remove_splice() end)
  params:hide("remove_splice_param")

  params:add_trigger("clear_markers", "> !! clear all markers !!")
  params:set_action("clear_markers", function() init_reel(splice[#splice].e - 1) end)

  params:add_separator("splice_organize_params", "organize")

  params:add_control("splice_select", "select splice", controlspec.new(0, 1, "lin", 0, 0, ""), function() return active_splice end)
  params:set_action("splice_select", function(val) select_splice(val) end)

  params:add_binary("next_splice_param", "> next splice", "trigger", 0)
  params:set_action("next_splice_param", function() set_active_splice(1) end)

  params:add_binary("prev_splice_param", "> previous splice", "trigger", 0)
  params:set_action("prev_splice_param", function() set_active_splice(-1) end)

  params:add_binary("rand_splice_param", "> random splice", "trigger", 0)
  params:set_action("rand_splice_param", function() set_random_splice() end)

  params:add_separator("splice_danger_zone", "danger zone")

  params:add_trigger("clear_splice", "> !! delete active splice !!")
  params:set_action("clear_splice", function() delete_splice() end)

  -- voice params
  params:add_separator("voices", "voix")
  
  params:add_group("global_voice_params", "all", 7)

  params:add_control("global_level", "level", controlspec.new(0, 1, "lin", 0, 1), function(param) return (round_form(util.linlin(0, 1, 0, 100, param:get()), 1, "%")) end)
  params:set_action("global_level", function(x) glb_level = x set_levels() page_redraw(3) end)

  params:add_control("global_pan", "pan", controlspec.new(-1, 1, "lin", 0, 1, ""), function(param) return (round_form(util.linlin(-1, 1, -100, 100, param:get()), 1, "%")) end)
  params:set_action("global_pan", function(x) glb_pan = x set_panning() page_redraw(3) end)

  params:add_control("global_cutoff_abs", "cutoff", controlspec.new(20, 18000, 'exp', 1, 18000, "Hz"))
  params:set_action("global_cutoff_abs", function(x) for i = 1, GENE_NUM do params:set("cutoff"..i, x) end page_redraw(3) end)

  params:add_control("global_filter_q_abs", "filter q", controlspec.new(0.1, 4.0, 'exp', 0.01, 2.0, ""))
  params:set_action("global_filter_q_abs", function(x) for i = 1, GENE_NUM do params:set("filter_q"..i, x) end page_redraw(3) end)

  params:add_number("global_cutoff_rel", "cutoff", -1, 1, 0, function() return delta_viz_fc end)
  params:set_action("global_cutoff_rel", function(d) if d ~= 0 then set_cutoff(d) end page_redraw(3) end)
  params:hide("global_cutoff_rel")

  params:add_number("global_filter_q_rel", "filter q", -1, 1, 0, function() return delta_viz_fq end)
  params:set_action("global_filter_q_rel", function(d) if d ~= 0 then set_filter_q(d) end page_redraw(3) end)
  params:hide("global_filter_q_rel")

  params:add_option("global_filter_type", "filter type", {"low pass", "high pass", "band pass", "band reject", "off"}, 1)
  params:set_action("global_filter_type", function(x) for i = 1, GENE_NUM do params:set("filter_type"..i, x) end end)

  params:add_group("individual_voice_params", "individual", 24)

  local gene_id = {"[one]", "[two]", "[three]", "[four]", "[ghost]"}
  for i = 1, GENE_NUM do
    params:add_separator("voice_"..i.."_params","playhead "..gene_id[i])

    params:add_control("level"..i, "level", controlspec.new(0, 1, "lin", 0, 1), function(param) return (round_form(util.linlin(0, 1, 0, 100, param:get()), 1, "%")) end)
    params:set_action("level"..i, function(x) voice[i].level = x set_levels() page_redraw(3) end)

    params:add_control("pan"..i, "pan", controlspec.new(-1, 1, "lin", 0, 0, ""))
    params:set_action("pan"..i, function(x) voice[i].pan = x set_panning() page_redraw(3) end)

    params:add_control("cutoff"..i, "filter cutoff", controlspec.new(20, 18000, 'exp', 1, 18000, "Hz"))
    params:set_action("cutoff"..i, function(x) voice[i].fc = x softcut.post_filter_fc(i, x) page_redraw(3) end)

    params:add_control("filter_q"..i, "filter q", controlspec.new(0.1, 4.0, 'exp', 0.01, 2.0, ""))
    params:set_action("filter_q"..i, function(x) voice[i].fq = x softcut.post_filter_rq(i, x) page_redraw(3) end)

    params:add_option("filter_type"..i, "filter type", {"low pass", "high pass", "band pass", "band reject", "off"}, 1)
    params:set_action("filter_type"..i, function(x) select_filter(i, x) end)
  end

  params:add_group("ghost_voice_params", "ghost", 12)

  params:add_separator("ghost_behaviour", "behaviour")

  params:add_option("ghost_active", "apperance", {"never", "with playback", "with silence", "always"}, 1)

  params:add_number("ghost_prob", "probability", 0, 100, 16, function(param) return round_form(param:get(), 1, "%") end)

  params:add_number("ghost_duration", "votility", 0, 100, 24, function(param) return round_form(param:get(), 1, "%") end)

  params:add_option("ghost_distribution", "dispersal", {"free", "contained"})

  params:add_option("ghost_clk", "rate", options.clock_tempo, 9)
  params:set_action("ghost_clk", function(idx) gclk_div = options.clock_value[idx] * 4 end)

  params:add_separator("ghost_playhead", "playhead")

  params:add_control("level"..ghost_voice, "level", controlspec.new(0, 1, "lin", 0, 0.5), function(param) return (round_form(util.linlin(0, 1, 0, 100, param:get()), 1, "%")) end)
  params:set_action("level"..ghost_voice, function(x) voice[ghost_voice].level = x end)

  params:add_control("pan"..ghost_voice, "pan", controlspec.new(-1, 1, "lin", 0, 0, ""))
  params:set_action("pan"..ghost_voice, function(x) voice[ghost_voice].pan = x softcut.pan(ghost_voice, x) end)

  params:add_control("cutoff"..ghost_voice, "filter cutoff", controlspec.new(20, 18000, 'exp', 1, 4600, "Hz"))
  params:set_action("cutoff"..ghost_voice, function(x) softcut.post_filter_fc(ghost_voice, x) end)

  params:add_control("filter_q"..ghost_voice, "filter q", controlspec.new(0.1, 4.0, 'exp', 0.01, 2.0, ""))
  params:set_action("filter_q"..ghost_voice, function(x) softcut.post_filter_rq(ghost_voice, x) end)

  params:add_option("filter_type"..ghost_voice, "filter type", {"low pass", "high pass", "band pass", "band reject", "off"}, 1)
  params:set_action("filter_type"..ghost_voice, function(x) select_filter(ghost_voice, x)  end)

  -- exploration params
  params:add_separator("essai", "essai")

  params:add_binary("toggle_play", "> toggle play", "trigger", 0)
  params:set_action("toggle_play", function() set_play() end)

  params:add_binary("reset_pos", "> reset position", "trigger", 0)
  params:set_action("reset_pos", function() set_start_pos() end)

  params:add_option("tape_transport", "tape transport", {"new", "used", "old", "vintage", "broken"}, 1)
  params:set_action("tape_transport", function(mode) gbl_rate_slew = options.rate_slew[mode] set_rate_slew(mode) end)

  params:add_control("varispeed", "varispeed", controlspec.new(-4, 4, "lin", 0, 1), function(param) return (round_form(util.linlin(-4, 4, -400, 400, param:get()), 1, "%")) end)
  params:set_action("varispeed", function(val) voice_rate = val set_rate() page_redraw(2) end)

  params:add_option("scale", "scale", options.scale, 1)

  params:add_control("slide", "slide", controlspec.new(0, 1, "lin", 0, 0), function(param) return (round_form(util.linlin(0, 1, 0, 100, param:get()), 1, "%")) end)
  params:set_action("slide", function() set_loops() page_redraw(2) end)

  params:add_control("gene_size", "size", controlspec.new(0, 1, "lin", 0, 1), function(param) return (round_form(util.linlin(0, 1, 0, 100, param:get()), 1, "%")) end)
  params:set_action("gene_size", function() set_loops() page_redraw(2) end)

  params:add_control("morph", "morph", controlspec.new(0, 1, "lin", 0, 0), function(param) return (round_form(util.linlin(0, 1, 0, 100, param:get()), 1, "%")) end)
  params:set_action("morph", function() set_loops() reset_morph_params() page_redraw(2) end)

  params:add_option("morph_mode", "morph mode", {"free", "clocked"}, 1)

  params:add_option("morph_clk", "moprh clock", options.clock_tempo, 7)
  params:set_action("morph_clk", function(idx) mclk_div = options.clock_value[idx] * 4 end)

  params:add_group("rand_settings", "randomization settings", 5)

  params:add_number("morph_prob", "probability", 1, 100, 20, function(param) return param:get().."%" end)

  params:add_option("randomize_level", "level @morph > 75", {"off", "on"}, 1)

  params:add_option("randomize_pan", "pan @morph > 75", {"off", "on"}, 2)

  params:add_option("randomize_rate", "rate @morph > 80", {"off", "on"}, 2)

  params:add_binary("morph_freez", "> freeze values", "toggle", 0)
  params:set_action("morph_freez", function(x) morph_freeze = x == 1 and true or false page_redraw(2) end)

  -- keyboard params
  params:add_separator("keyboard_params",  "keyboard midi/grid")

  params:add_option("midi_device", "midi device", midi_devices, 1)
  params:set_action("midi_device", function(val) m = midi.connect(val) set_midi_event_callback() end)

  params:add_number("midi_channel", "midi channel", 1, 16, 1)
  params:set_action("midi_channel", function(val) midi_channel = val end)

  params:add_number("root_note", "root note", 1, 127, 60, function(param) return mu.note_num_to_name(param:get(), true) end)
  params:set_action("root_note", function(val) midi_root = val key_root = val - 81 dirtygrid = true end)

  params:add_number("grid_interval", "interval [y]", 2, 6, 4, function(param) return param:get().."st" end)
  params:set_action("grid_interval", function(val) g_interval = val dirtygrid = true end)

  params:add_option("adsr_active", "envelope", {"off", "on"}, 1)
  params:set_action("adsr_active", function() init_envelope() end)

  params:add_group("env_settings", "envelope settings", 4)

  params:add_control("adsr_attack", "attack", controlspec.new(0, 10, 'lin', 0.1, 0.2, "s"))
  params:set_action("adsr_attack", function(val) env.attack = val * 10 end)

  params:add_control("adsr_decay", "decay", controlspec.new(0, 10, 'lin', 0.1, 0.5, "s"))
  params:set_action("adsr_decay", function(val) env.decay = val * 10 end)

  params:add_control("adsr_sustain", "sustain", controlspec.new(0, 1, 'lin', 0, 1, ""), function(param) return (round_form(param:get() * 100, 1, "%")) end)
  params:set_action("adsr_sustain", function(val) env.sustain = val end)

  params:add_control("adsr_release", "release", controlspec.new(0, 10, 'lin', 0.1, 1, "s"))
  params:set_action("adsr_release", function(val) env.release = val * 10 end)   

  --[[
 -- lfo params
 params:add_separator("modulation", "modulation")

 local gene_id = {"[one]", "[two]", "[three]", "[four]", "[ghost]"}
 params:add_group("level_lfos", "level lfos", 15 * (GENE_NUM + 1))
 local level_lfo = {}
 for i = 1, GENE_NUM + 1 do
   level_lfo[i] = _lfos:add{min = 0, max = 1}
   level_lfo[i]:add_params("level_lfo"..i, "playhead "..gene_id[i].." level")
   level_lfo[i]:set("action", function(scaled, raw) params:set("level"..i, scaled) end)
 end

 params:add_group("pan_lfos", "pan lfos", 15 * (GENE_NUM + 1))
 local pan_lfo = {}
 for i = 1, GENE_NUM + 1 do
   pan_lfo[i] = _lfos:add{min = -1, max = 1}
   pan_lfo[i]:add_params("pan_lfo"..i, "playhead "..gene_id[i].." pan")
   pan_lfo[i]:set("action", function(scaled, raw) params:set("pan"..i, scaled) end)
 end

 params:add_group("cutoff_lfos", "cutoff lfos", 15 * (GENE_NUM + 1))
 local cutoff_lfo = {}
 for i = 1, GENE_NUM + 1 do
   cutoff_lfo[i] = _lfos:add{min = 20, max = 18000}
   cutoff_lfo[i]:add_params("cutoff_lfo"..i, "playhead "..gene_id[i].." cutoff")
   cutoff_lfo[i]:set("action", function(scaled, raw) params:set("cutoff"..i, scaled) end)
 end

 local varispeed_lfo = _lfos:add{min = -4, max = 4}
 varispeed_lfo:add_params("varispeed_lfo", "varispeed", "varispeed lfo")
 varispeed_lfo:set("action", function(scaled, raw) params:set("varispeed", scaled) end)

 local slide_lfo = _lfos:add{min = 0, max = 1}
 slide_lfo:add_params("slide_lfo", "slide", "slide lfo")
 slide_lfo:set("action", function(scaled, raw) params:set("slide", scaled) end)

 local gene_size_lfo = _lfos:add{min = 0, max = 1}
 gene_size_lfo:add_params("gene_size_lfo", "size", "size lfo")
 gene_size_lfo:set("action", function(scaled, raw) params:set("gene_size", scaled) end)

 local morph_lfo = _lfos:add{min = 0, max = 1}
 morph_lfo:add_params("morph_lfo", "morph", "morph lfo")
 morph_lfo:set("action", function(scaled, raw) params:set("morph", scaled) end)
 ]]
 
  -- init softcut settings
  for i = 1, GENE_NUM do -- genes 1 - 4
    softcut.enable(i, 1)
    softcut.buffer(i, 1)

    softcut.level_input_cut(1, i, 0)
    softcut.level_input_cut(2, i, 0)

    softcut.play(i, 1)
    softcut.rec(i, 0)
    
    softcut.level(i, 1)
    softcut.pan(i, 0)

    softcut.pre_level(i, 1)
    softcut.rec_level(i, 0)
    
    softcut.post_filter_dry(i, 0)
    softcut.post_filter_lp(i, 1)
    softcut.post_filter_fc(i, 18000)
    softcut.post_filter_rq(i, 4)

    softcut.fade_time(i, 0.05)
    softcut.level_slew_time(i, 0.2)
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
    softcut.rec_offset(i, -0.06)

    softcut.level(i, 0)
    softcut.pan(i, 0)
    
    softcut.pre_level(i, 1)
    softcut.rec_level(i, 0)

    softcut.fade_time(i, 0.1)
    softcut.level_slew_time(i, 0.1)
    softcut.rate_slew_time(i, 0)
    softcut.rate(i, 1)

    softcut.post_filter_dry(i, 1)
    softcut.post_filter_lp(i, 0)
    softcut.post_filter_fc(i, 20000)
    softcut.post_filter_rq(i, 4)

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
    os.execute("mkdir -p ".._path.audio.."concrete/reels")
    -- store data in one big table
    local reel_data = {}
    reel_data.active = active_splice
    reel_data.splice = {table.unpack(splice)}
    reel_data.voice = {table.unpack(voice)}
    if save_buffer then
      local length = splice[#splice].e - 1
      softcut.buffer_write_mono(_path.audio.."concrete/reels/"..name..".wav", 1, length, 1)
      reel_data.path = _path.audio.."concrete/reels/"..name..".wav"
    else
      reel_data.path = filename_reel
    end
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
      local reel_data = tab.load(norns.state.data.."pset_data/"..number.."/"..pset_id.."_reel.data")
      softcut.buffer_clear()
      softcut.buffer_read_mono(reel_data.path, 0, 1, -1, 1, 1, 0, 1)
      active_splice = reel_data.active
      splice = {table.unpack(reel_data.splice)}
      voice = {table.unpack(reel_data.voice)}
      set_loops()
      set_start_pos()
      reel_has_audio = true
      init_recording = false
      waveviz_reel = true
      softcut.render_buffer(1, 1, splice[#splice].e - 1, 128)
      clock.run(
        function()
          clock.sleep(0.1)
          waveviz_splice = true
          softcut.render_buffer(1, splice[active_splice].s, splice[active_splice].l, 128)
        end
      )
      params:set("adsr_active", 1)
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
  midi.add = midi_connect
  midi.remove = midi_disconnect
  midi.event = 
  --norns.crow.add = crow_connect
  --norns.crow.remove = crow_disconnect

  softcut.event_render(wave_render)
  softcut.event_phase(poll_positions)
  softcut.poll_start_phase()

  -- detect if arc is connected
  for v in pairs(arc.devices) do
    if arc.devices[v].name ~= nil then
      arc_is = true
    end
  end

  -- detect if crow is connected
  if norns.crow.connected() then
    crow_is = true
  end

  -- metros
  screenredrawtimer = metro.init(function() screen_redraw() end, 1/15, -1)
  screenredrawtimer:start()

  hardwareredrawtimer = metro.init(function() hardware_redraw() end, 1/30, -1)
  hardwareredrawtimer:start()
  dirtygrid = true

  warbletimer = metro.init(function() make_warble() end, 1/10, -1)
  warbletimer:start()

  -- clocks
  geneclock = clock.run(step_genes)
  morphclock = clock.run(morph_values)
  ghostclock = clock.run(ghost_activity)
  envcounter = clock.run(env_run)

  -- bang params
  if pset_load then
    params:read(default_pset)
  else
    params:bang()
  end

  -- threshold rec poll
  amp_in = {}
  local amp_src = {"amp_in_l", "amp_in_r"}
  for ch = 1, 2 do
    amp_in[ch] = poll.set(amp_src[ch])
    amp_in[ch].time = 0.01
    amp_in[ch].callback = function(val)
      if val > util.dbamp(params:get("rec_threshold")) / 10 then
        if not play then
          play = true
          set_start_pos()
        else
          rec = true
        end
        set_rec()
        set_levels()
        amp_in[ch]:stop()
        rec_at_threshold = false
      end
    end
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
function poll_positions(i, pos)
  -- get positions
  if play then
    voice[i].pos_rel = ((pos - splice[active_splice].s) / splice[active_splice].l)
    voice[i].pos_abs = pos
  end
  -- gene counter
  if i == 1 and play then 
    pos_counter = pos_counter + 1
    if pos_counter >= util.round(gene_length, 0.01) * 100 then
      set_start_pos()
    end
    page_redraw(1)
  end
  -- ensure that recording stops when the rec head reaches the end of the reel.
  if i == rec_voice and is_recording and (params:get("rec_dest") == 3 or init_recording) then
    if voice[rec_voice].pos_abs >= MAX_REEL and not reel_is_full then
      rec = false
      set_rec()
      reel_is_full = true
      print("no more space left, sorry :(")
    end
  end
end


-------- norns UI --------
function key(n, z)
  if n == 1 then
    shift = z == 1 and true or false
  end
  if pageNum == 1 then
    if n == 2 and z == 1 and not shift then
      focus_page1 = 1 - focus_page1
    end
    if focus_page1 == 0 then
      if n == 3 and z == 1 then
        if shift then
          remove_splice()
        else
          if play then
            add_splice()
          end
        end
      end
    else
      if n == 2 and z == 1 then
        if shift then
          amp_in[1]:start()
          amp_in[2]:start()
          rec_at_threshold = true
        end
      elseif n == 3 and z == 1 then
        if shift then
          toggle_recording()
        else
          set_play()
        end
      end
    end
  elseif pageNum == 2 then
    if n == 2 and z == 1 and not shift then
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
    if n == 2 and z == 1 then
      focus_page3 = 1 - focus_page3
    elseif n == 3 and z == 1 then
      param_page3 = (param_page3 + 1) % 4
    end
  elseif pageNum == 4 then
    if n == 2 and z == 1 then
      focus_page4 = 1 - focus_page4
    end
  end
  dirtyscreen = true
end

function enc(n, d)
  if n == 1 then
    if shift then
      params:delta("global_level", d)
    else
      pageNum = util.clamp(pageNum + d, 1, 3)
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
          set_active_splice(inc)
        end
      end
    else
      if n == 2 then
        if shift then
          params:delta("rec_dest", d)
        else
          params:delta("sos_level", d)
        end
      elseif n == 3 then
        if shift then
          params:delta("rec_mode", d)
        else
          params:delta("dub_level", d)
        end
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
          local rate = scale[idx][rate_idx]
          params:set("varispeed", rate)
        else
          params:delta("varispeed", d / 20)
        end
      elseif n == 3 then
        params:delta("slide", d)
      end
    end
  elseif pageNum == 3 then
    local i = focus_page3 == 0 and 1 or 3
    local parameter = options.params[param_page3 + 1]
    local glb_param = options.params_gbl[param_page3 + 1]
    if n == 2 then
      if shift then
        params:delta(glb_param, d)
      else
        params:delta(parameter..i, d)
      end
    elseif n == 3 then
      if not shift then
        params:delta(parameter..i + 1, d)
      end
    end
  elseif pageNum == 4 then
    if focus_page4 == 0 then
      if n == 2 then
        params:delta("adsr_attack", d)
      elseif n == 3 then
        params:delta("adsr_decay", d)
      end
    else
      if n == 2 then
        params:delta("adsr_sustain", d)
      elseif n == 3 then
        params:delta("adsr_release", d)
      end
    end
  end
  dirtyscreen = true
end

function redraw()
  screen.clear()
  -- shift indicator
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
      local splice_start = util.linlin(1, splice[#splice].e, 4, 124, splice[active_splice].s)
      local splice_end = util.linlin(1, splice[#splice].e, 4, 124, splice[active_splice].e)
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

    if is_recording then
      screen.level(15)
      screen.rect(24, 7, 78, 10)
      screen.fill()
      screen.level(0)
      screen.move(64, 14)
      screen.text_center("recording...")
    end

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

    -- rec_voice write head
    if is_recording then
      screen.level(0)
      screen.move(util.linlin(0, 1, 25, 105, voice[rec_voice].pos_rel), 30)
      screen.line_rel(0, 30)
      screen.stroke()
    end

    -- gene 4 playhead
    if voice[4].level > 0 then
      screen.level(init_recording and 0 or 2)
      screen.move(util.linlin(0, 1, 25, 105, voice[4].pos_rel), 30)
      screen.line_rel(0, 30)
      screen.stroke()
    end

    -- gene 3 playhead
    if voice[3].level > 0 then
      screen.level(init_recording and 0 or 4)
      screen.move(util.linlin(0, 1, 25, 105, voice[3].pos_rel), 30)
      screen.line_rel(0, 30)
      screen.stroke()
    end

    -- gene 2 playhead
    if voice[2].level > 0 then
      screen.level(init_recording and 0 or 6)
      screen.move(util.linlin(0, 1, 25, 105, voice[2].pos_rel), 30)
      screen.line_rel(0, 30)
      screen.stroke()
    end

    -- gene 1 playhead
    if voice[1].level > 0 then
      screen.level(init_recording and 0 or 15)
      screen.move(util.linlin(0, 1, 25, 105, voice[1].pos_rel), 30)
      screen.line_rel(0, 30)
      screen.stroke()
    end

    -- rec key
    --screen.level(focus_page1 == 1 and 15 or 4)
    screen.level(rec_at_threshold and 6 or (focus_page1 == 1 and 15 or 4))
    if rec or rec_at_threshold then
      screen.rect(3, 30, 17, 13)
      screen.fill()
    end
    screen.level(15)
    screen.rect(4, 30, 17, 13)
    screen.stroke()
    screen.level(focus_page1 == 1 and 15 or 4)
    if rec then screen.level(0) end
    screen.move(10, 38)
    if g_rec_speed then
      if params:get("rec_rate") == 1 then
        screen.text("F")
      elseif params:get("rec_rate") == 2 then
        screen.text("C")
      else
        screen.text("H")
      end
    else
      screen.text("R")
    end

    if (shift or g_rec_dest) and focus_page1 == 1 then
      if params:get("rec_dest") == 1 then
        screen.move(10, 40)
        screen.text("_")
      elseif params:get("rec_dest") == 2 then
        screen.move(8, 38)
        screen.text("|")
        screen.move(15, 38)
        screen.text("|")
      else
        screen.move(15, 38)
        screen.text(">")        
      end
    end
    
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

    -- s.o.s /rec level
    screen.level(15)
    screen.rect(108, 30, 6, 31)
    screen.stroke()
    screen.level(focus_page1 == 1 and 15 or 4)
    screen.rect(108, 60, 5, -util.linlin(0, 1, 0, 30, params:get("sos_level")))
    screen.fill()

    if params:get("rec_mode") == 2 then
      screen.level(0)
      for i = 1, 31, 2 do
        screen.move(108, i + 28)
        screen.line_rel(5, 0)
        screen.stroke()
      end
    end
    
    screen.level(15)
    screen.move(108, 61 - util.linlin(0, 1, 0, 31, params:get("sos_level")))
    screen.line_rel(5, 0)
    screen.stroke()
    
    -- overdub level
    screen.level(15)
    screen.rect(118, 30, 6, 31)
    screen.stroke()
    screen.level(focus_page1 == 1 and 15 or 4)
    screen.rect(118, 60, 5, -util.linlin(0, 1, 0, 30, params:get("dub_level")))
    screen.fill()
    
    screen.level(15)
    screen.move(118, 61 - util.linlin(0, 1, 0, 31, params:get("dub_level")))
    screen.line_rel(5, 0)
    screen.stroke()

  elseif pageNum == 2 then

    -- morph level
    screen.level(15)
    screen.line_width(1)
    screen.rect(4, 4, 16, 50)
    screen.stroke()
    screen.level(focus_page2 == 0 and 15 or 4)
    screen.rect(4, 53, 15, - util.linlin(0, 1, 0, 49, params:get("morph")))
    screen.fill()
    screen.move(0, 62)
    screen.font_face(1)
    screen.font_size(8)
    screen.text("morph")
    if morph_freeze then
      screen.level(0)
      for i = 1, 24 do
        screen.move(4, 54 - i * 2) 
        screen.line_rel(15, 0)
        screen.stroke()
      end
    end
    screen.level(15)
    screen.move(4, 54 - util.linlin(0, 1, 0, 50, params:get("morph")))
    screen.line_rel(15, 0)
    screen.stroke()

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
    
    screen.level(15)
    screen.move(108, 4 + util.linlin(0, 1, 0, 50, params:get("gene_size")))
    screen.line_rel(15, 0)
    screen.stroke()

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
    local param_name = options.params_view[param_page3 + 1]
    local parameter = options.params[param_page3 + 1]
    screen.level(15)
    screen.move(64, 34)
    screen.text_center(param_name)
    -- draw boxes
    screen.line_width(1)
    for i = 1, 2 do
      for j = 1, 2 do
        screen.rect(8 + (i - 1) * 63, 8 + (j - 1) * 32, 50, 16)
        screen.stroke()
      end
    end

    -- draw levels voice 1 + 2
    for i = 1, 2 do
      local off_x = (i - 1) * 63
      if parameter == "level" then
        screen.level(focus_page3 == 0 and 15 or 4)
        screen.rect(8 + off_x, 8, util.linlin(0, 1, 0, 49, voice[i].level), 15)
        screen.fill()
        if glb_level < 1 then
          screen.level(2)
          screen.move(util.linlin(0, 1, 9 + off_x, 57 + off_x, voice[i].level * glb_level), 8)
          screen.line_rel(0, 15)
          screen.stroke()
        end
      elseif parameter == "pan" then
        screen.level(focus_page3 == 0 and 15 or 4)
        screen.move(33 + off_x, 8)
        screen.line_rel(0, 15)
        screen.stroke()
        if voice[i].pan > 0 then
          screen.rect(32 + off_x, 8, util.linlin(0, 1, 0, 25, voice[i].pan), 15)
          screen.fill()
        elseif voice[i].pan < 0 then
          screen.rect(32 + off_x, 8, -util.linlin(-1, 0, 24, 0, voice[i].pan), 15)
          screen.fill()
        end
        if glb_pan < 1 and voice[i].pan ~= 0 then
          screen.level(2)
          screen.move(util.linlin(-1, 1, 9 + off_x, 57 + off_x, voice[i].pan * glb_pan), 8)
          screen.line_rel(0, 15)
          screen.stroke()
        end
      elseif parameter == "cutoff" then
        screen.level(focus_page3 == 0 and 15 or 4)
        screen.rect(8 + off_x, 8, util.explin(20, 18000, 0, 49, voice[i].fc), 15)
        screen.fill()
      elseif parameter == "filter_q" then
        screen.level(focus_page3 == 0 and 15 or 4)
        screen.rect(58 + off_x, 8, - util.linlin(0.01, 4, 0, 49, voice[i].fq), 15)
        screen.fill()
      end
    end

    -- draw levels voice 3 + 4
    for i = 3, 4 do
      local off_x = (i - 3) * 63
      if parameter == "level" then
        screen.level(focus_page3 == 1 and 15 or 4)
        screen.rect(8 + off_x, 40, util.linlin(0, 1, 0, 49, voice[i].level), 15)
        screen.fill()
        if glb_level < 1 then
          screen.level(2)
          screen.move(util.linlin(0, 1, 9 + off_x, 57 + off_x, voice[i].level * glb_level), 40)
          screen.line_rel(0, 15)
          screen.stroke()
        end
      elseif parameter == "pan" then
        screen.level(focus_page3 == 1 and 15 or 4)
        screen.move(33 + off_x, 40)
        screen.line_rel(0, 15)
        screen.stroke()
        if voice[i].pan > 0 then
          screen.rect(32 + off_x, 40, util.linlin(0, 1, 0, 25, voice[i].pan), 15)
          screen.fill()
        elseif voice[i].pan < 0 then
          screen.rect(32 + off_x, 40, -util.linlin(-1, 0, 24, 0, voice[i].pan), 15)
          screen.fill()
        end
        if glb_pan < 1 and voice[i].pan ~= 0 then
          screen.level(2)
          screen.move(util.linlin(-1, 1, 9 + off_x, 57 + off_x, voice[i].pan * glb_pan), 40)
          screen.line_rel(0, 15)
          screen.stroke()
        end
      elseif parameter == "cutoff" then
        screen.level(focus_page3 == 1 and 15 or 4)
        screen.rect(8 + off_x, 40, util.explin(20, 18000, 0, 49, voice[i].fc), 15)
        screen.fill()
      elseif parameter == "filter_q" then
        screen.level(focus_page3 == 1 and 15 or 4)
        screen.rect(58 + off_x, 40, - util.linlin(0.01, 4, 0, 49, voice[i].fq), 15)
        screen.fill()
      end
    end
  elseif pageNum == 4 then
    -- a/d
    screen.level(focus_page4 == 0 and 15 or 4)
    screen.font_size(16)
    screen.move(25, 30)
    screen.text_center("A")
    screen.move(50, 30)
    screen.text_center("D")
    screen.font_size(8)
    screen.move(25, 46)
    screen.text_center(params:string("adsr_attack"))
    screen.move(50, 46)
    screen.text_center(params:string("adsr_decay"))
    -- s/r
    screen.level(focus_page4 == 1 and 15 or 4)
    screen.font_size(16)
    screen.move(75, 30)
    screen.text_center("S")
    screen.move(100, 30)
    screen.text_center("R")
    screen.font_size(8)
    screen.move(75, 46)
    screen.text_center(params:string("adsr_sustain"))
    screen.move(100, 46)
    screen.text_center(params:string("adsr_release"))
  end
  screen.update()
end

-------- arc UI --------
function a.delta(n, d)
  if pageNum < 3 then
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
          local rate = scale[idx][rate_idx]
          params:set("varispeed", rate)
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
  elseif pageNum == 3 then
    if shift then
      local glb_param = options.params_gbl[param_page3 + 1]
      params:delta(glb_param, d / 20)
    else
      local parameter = options.params[param_page3 + 1]
      params:delta(parameter..n, d / 20)
    end
  elseif pageNum == 4 then
    if n == 1 then
      params:delta("adsr_attack", d / 20)
    elseif n == 2 then
      params:delta("adsr_decay", d / 20)
    elseif n == 3 then
      params:delta("adsr_sustain", d / 20)
    elseif n == 4 then
      params:delta("adsr_release", d / 20)
    end
    page_redraw(4)
  end
end

function arcredraw()
  a:all(0)
  if pageNum < 3 then
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
    local m_view_raw = math.ceil(params:get("morph") * 58 + 1)
    local m_view = util.clamp(m_view_raw, 1, 45) - 29
    local intensity = 3
    if m_view >= -10 and m_view <= 6 then
      intensity = 6
    elseif m_view > 6 and m_view <= 15 then
      intensity = 8
    elseif m_view > 15 then
      intensity = 11
    end
    for i = 1, m_view + 29 do
      a:led(4, i - 29 - arc_off, intensity)
    end
    a:led(4, 18 - arc_off, m_view_raw < 44 and 0 or m_view_raw - 44)
    a:led(4, 21 - arc_off, m_view_raw < 47 and 0 or m_view_raw - 44)
    a:led(4, 24 - arc_off, m_view_raw < 51 and 0 or m_view_raw - 44)
    a:led(4, 27 - arc_off, m_view_raw < 54 and 0 or m_view_raw - 44)
    a:led(4, -28 - arc_off, 6)
    a:led(4, 30 - arc_off, 6)
    a:led(4, m_view - arc_off, 15)
  elseif pageNum == 3 then
    local parameter = options.params[param_page3 + 1]
    for i = 1, 4 do
      if parameter == "level" then
        local arc_vol = math.floor(params:get("level"..i) * 58) - 28
        for j = 1, arc_vol + 28 do
          a:led(i, j - 28 - arc_off, 3)
        end
        a:led(i, -28 - arc_off, 6)
        a:led(i, 30 - arc_off, 6)
        a:led(i, arc_vol - arc_off, 15)
      elseif parameter == "pan" then
        local arc_pan = math.floor(params:get("pan"..i) * 24)
        if arc_pan > 0 then
          for j = 2, arc_pan do
            a:led(i, j - arc_off, 4)
          end
        elseif arc_pan < 0 then
          for j = arc_pan + 2, 0 do
            a:led(i, j - arc_off, 4)
          end
        end        
        a:led (i, 1 - arc_off, 10)
        a:led (i, 25 - arc_off, 6)
        a:led (i, -23 - arc_off, 6)
        a:led (i, arc_pan + 1 - arc_off, 15)
      elseif parameter == "cutoff" then
        local arc_cut = math.floor(util.explin(20, 18000, 0, 1, params:get("cutoff"..i)) * 48) + 41
        a:led (i, 25 - arc_off, 6)
        a:led (i, -23 - arc_off, 6)
        for j = -22, 24 do
          if j < arc_cut - 64 then
            a:led(i, j - arc_off, 3)
          end
        end
        a:led(i, arc_cut - arc_off, 15)        
      else
        arc_q = math.floor(util.explin(0.1, 4, 0, 1, params:get("filter_q"..i)) * 32) + 17
        for j = 17, 49 do
          if j > arc_q then
            a:led(i, j - arc_off, 3)
          end
        end
        a:led(i, 17 - arc_off, 6)
        a:led(i, 49 - arc_off, 6)
        a:led(i, 42 - arc_off, 6)
        a:led(i, 36 - arc_off, 6)
        a:led(i, arc_q - arc_off, 15)        
      end
    end
  elseif pageNum == 4 then
      -- draw adsr attack
    local attack = math.floor(util.linlin(0.1, 10, 0, 1, params:get("adsr_attack")) * 48) + 41
    a:led (1, 25 - arc_off, 5)
    a:led (1, -23 - arc_off, 5)
    for i = -22, 24 do
      if i < attack - 64 then
        a:led(1, i - arc_off, 3)
      end
    end
    a:led(1, attack - arc_off, 15)
    -- draw adsr decay
    local decay = math.floor(util.linlin(0.1, 10, 0, 1, params:get("adsr_decay")) * 48) + 41
    a:led (2, 25 - arc_off, 5)
    a:led (2, -23 - arc_off, 5)
    for i = -22, 24 do
      if i < decay - 64 then
        a:led(2, i - arc_off, 3)
      end
    end
    a:led(2, decay - arc_off, 15)
    -- draw adsr sustain
    local sustain = math.floor(params:get("adsr_sustain") * 48) + 41
    a:led (3, 25 - arc_off, 5)
    a:led (3, -23 - arc_off, 5)
    for i = -22, 24 do
      if i < sustain - 64 then
        a:led(3, i - arc_off, 3)
      end
    end
    a:led(3, sustain - arc_off, 15)
    -- draw adsr release
    local release = math.floor(util.linlin(0.1, 10, 0, 1, params:get("adsr_release")) * 48) + 41
    a:led (4, 25 - arc_off, 5)
    a:led (4, -23 - arc_off, 5)
    for i = -22, 24 do
      if i < release - 64 then
        a:led(4, i - arc_off, 3)
      end
    end
    a:led(4, release - arc_off, 15)
  end
  a:refresh()
end


-------- grid UI --------
local held_key = 0

function g.key(x, y, z)
  if y == 8 then
    if x == 3 then
      --g_pos_reset = z == 1 and true or false
    elseif x == 4 then
      g_rec_dest = z == 1 and true or false
      dirtyscreen = true
    elseif x == 5 then
      g_rec_speed = z == 1 and true or false
      dirtyscreen = true
    elseif x == 6 and not (g_rec_speed or g_rec_dest) then
      g_rec_mode = z == 1 and true or false
    end
  end
  -- left quardrant
  if x < 9 then
    if z == 1 then
      if y < 5 then
        local i = x + (y - 1) * 8
        if i <= #splice then
          local inc = i - active_splice
          set_active_splice(inc)
        else
          if play then add_splice() end
        end
        dirtyscreen = true
      elseif y == 5 then
        if x == 2 then
          params:set("varispeed", 0)
        elseif x > 2 and x < 8 then
          local rate = scale[1][x + 3]
          params:set("varispeed", rate)
        end
      elseif y == 6 then
        if x == 7 then
          params:set("varispeed", 0)
        elseif x > 1 and x < 7 then
          local rate = scale[1][x - 1]
          params:set("varispeed", rate)
        end
      elseif y == 7 then
        -- rec params
      elseif y == 8 then
        if x < 3 then
          set_play()
        elseif x == 3 then
          set_start_pos()
        elseif x == 6 and not g_rec_mode then
          if g_rec_dest then
            params:set("rec_dest", 1)
          elseif g_rec_speed then
            params:set("rec_rate", 1)
          end
        elseif x == 7 then
          if g_rec_dest then
            params:set("rec_dest", 2)
          elseif g_rec_mode then
            params:set("rec_mode", 1)
          elseif g_rec_speed then
            params:set("rec_rate", 2)
          else
            if rec_at_threshold then
              amp_in[1]:stop()
              amp_in[2]:stop()
              rec_at_threshold = false
            else
              amp_in[1]:start()
              amp_in[2]:start()
              rec_at_threshold = true
            end
          end
        elseif x == 8 then
          if g_rec_dest then
            params:set("rec_dest", 3)
          elseif g_rec_mode then
            params:set("rec_mode", 2)
          elseif g_rec_speed then
            params:set("rec_rate", 3)
          else
            toggle_recording()
          end
        end
        dirtyscreen = true
      end
    elseif z == 0 then
      if y == 8 then
        if x == 2 then
          set_play()
        end
      end
    end
  -- right quadrant
  else
    if y < 7 then
      local note = (key_root + x) + g_interval * (6 - y)
      held_key = held_key + (z * 2 - 1)
      --local v = util.wrap(held_key, 1, 4)
      if z == 1 then
        local semitone = math.pow(2, note / 12)
        for i = 1, 4 do
          voice[i].trsp_value = semitone
          if params:get("adsr_active") == 2 then
            env_gate_on(i)
          end
        end
        set_rate()
        --print("note on "..note)
      else
        if held_key < 1 then
          for i = 1, 4 do
            if params:get("adsr_active") == 2 then
              env_gate_off(i)
            end
            --voice[i].trsp_value = voice[1].trsp_value
          end
        end
        --print("note off "..note)
      end
    elseif y == 8 then
      if x == 11 and z == 1 then
        pageNum = 1
        dirtyscreen = true
      elseif x == 12 and z == 1 then
        pageNum = 2
        dirtyscreen = true
      elseif x == 13 and z == 1 then
        pageNum = 3
        dirtyscreen = true
      elseif x == 14 and z == 1 then
        pageNum = 4
        dirtyscreen = true
      elseif x == 16 and z == 1 then
        params:set("adsr_active", params:get("adsr_active") == 1 and 2 or 1)
      end
    end
  end
  dirtygrid = true
end

function gridredraw()
  g:all(0)
  -- splices
  for i = 1, 8 do
    for j = 1, 4 do
      g:led(i, j, 1)
    end
  end
  for i = 1, #splice do
    if i < 9 then
      g:led(i, 1, i == active_splice and 12 or 6)
    elseif i < 17 then
      g:led(i - 8, 2, i == active_splice and 12 or 5)
    elseif i < 25 then
      g:led(i - 16, 3, i == active_splice and 12 or 4)
    elseif i < 33 then
      g:led(i - 24, 4, i == active_splice and 12 or 3)
    end
  end
  -- speed
  for i = 1, 6 do
    g:led(i + 1, 5, i * 2)
    g:led(i + 1, 6, 14 - i * 2)
  end
  -- playback & recording
  g:led(1, 8, play and 12 or 6)
  g:led(2, 8, play and 8 or 4)
  g:led(3, 8, g_pos_reset and 15 or 2)
  g:led(4, 8 , g_rec_dest and 10 or 0)
  g:led(5, 8 , g_rec_speed and 10 or 0)
  g:led(6, 8 , g_rec_mode and 10 or 0)
  if g_rec_dest then
    for i = 1, 3 do
      g:led(i + 5, 8, params:get("rec_dest") == i and 8 or 4)
    end
  elseif g_rec_speed then
    for i = 1, 3 do
      g:led(i + 5, 8, params:get("rec_rate") == i and 8 or 4)
    end
  elseif g_rec_mode then
    for i = 1, 2 do
      g:led(i + 6, 8, params:get("rec_mode") == i and 8 or 4)
    end
  else
    g:led(7, 8 , rec_at_threshold and 8 or 4)
    g:led(8, 8 , recording and 15 or 6)
  end
  -- left quadrant
  for x = 9, 16 do
    for y = 1, 6 do
      local note = (-21 + x) + g_interval * (6 - y)
      local hs = note % 12
      if hs == 0 then
        g:led(x, y, 12)
      elseif hs == 4 then
        g:led(x, y, 5)
      elseif hs == 5 then
        g:led(x, y, 8)
      elseif hs == 2 or hs == 7 or hs == 9 or hs == 11 then
        g:led(x, y, 4)
      else
        g:led(x, y, 2)  
      end
    end
  end
  for i = 1, 4 do
    g:led(10 + i, 8, pageNum == i and 12 or 4)
  end
  g:led(16, 8, params:get("adsr_active") == 2 and 12 or 6)
  g:refresh()
end


-------- utilities --------
function hardware_redraw()
  if arc_is then arcredraw() end
  if dirtygrid then
    gridredraw()
    dirtygrid = false
  end
end

function screen_redraw()
  if dirtyscreen then
    redraw()
    dirtyscreen = false
  end
  if is_recording then
    if init_recording then
      reel_has_audio = true
      waveviz_splice = true
      softcut.render_buffer(1, 1, voice[rec_voice].pos_abs, 128)
    elseif params:get("rec_dest") ~= 3 then
      waveviz_splice = true
      softcut.render_buffer(1, splice[active_splice].s, splice[active_splice].l, 128)
    end
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
  if crow_is then
    --params:show("crow_params")
  else
    --params:hide("crow_params")
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

function crow_connect()
  crow_is = true
  build_menu()
end

function crow_disconnect()
  crow_is = false
  build_menu()
end

function r()
  norns.script.load(norns.state.script)
end

function cleanup()
  arc.add = function() end
  arc.remove = function() end
  midi.add = function() end
  midi.remove = function() end
  norns.crow.add = function() end
  norns.crow.remove = function() end
end
