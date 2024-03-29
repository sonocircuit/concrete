-- concrete v1.1.0 @sonocircuit
-- llllllll.co/t/concrete
--
--    virtual tape exploration
--    ---- | --- --- -- ---- -- 
--      --- -- ------ | --- -
--     ---- -- | ------ --- | -
--
-- for docs go to:
-- >> github.com
--    /sonocircuit/concrete
--
-- or smb into:
-- >> code/concrete/docs
--


-----------------------------------------------------------------------------------------------------------------------------
-- TODO: add ji scales
-----------------------------------------------------------------------------------------------------------------------------

a = arc.connect()
g = grid.connect()
m = midi.connect()

tx = require 'textentry'
mu = require 'musicutil'
--_lfos = require 'lfo'

_arc = include 'lib/concrete_arc'
_key = include 'lib/concrete_key'
_enc = include 'lib/concrete_enc'
_draw = include 'lib/concrete_draw'
_lfos = include 'lib/concrete_lfo'
_grd = include 'lib/concrete_grid'

-------- variables --------
pset_load = false
default_pset = 1

shift = false
pageNum = 1
focus_page1 = 1
focus_page2 = 0
focus_page3 = 0
param_page3 = 1
focus_page4 = 0
view_message = ""
msg_timer = nil

active_splice = 1
prev_splice = 1
splice_page = 1
play = false
rec = false
is_recording = false
ext_signal = 1 
sos_signal = 0
armed = false

save_buffer = false
filename_reel = ""
reel_path = _path.audio .. "concrete/reels/"
splice_path = _path.audio .. "concrete/splices/"
load_reel_ch = 1
load_splice_ch = 1

MAX_REEL = 320
GENE_NUM = 4
ghost_voice = 5
rec_voice = 6
rec_at_threshold = false

reel_has_audio = false
reel_is_full = false
init_recording = true
waveviz_reel = false
waveviz_splice = false

glb_level = 1
glb_pan = 1
glb_cutoff = 1
glb_filter_q = 1
gbl_rate_slew = 0

voice_rate = 1
prev_morph_val = 0
pos_counter = 0
gene_length = 10
morph_freeze = false
morph_clocked = false
mclk_div = 1
gclk_div = 1
rate_rst = false
pan_rst = false

-- variables for midi and keys
midi_channel = 1
midi_root = 60
key_root = -21
crow_is = false

voicetab = {0, 0, 0, 0}
active_notes = {{}, {}, {}, {}}

-- variables for arc
arc_is = false
arc_off = 0
arc_enc1_count = 0
arc_vs_sens = 100

-- variables for grid
g_pos_reset = false
g_rec_mode = false
g_rec_dest = false
g_rec_speed = false
g_slotinit = false
g_slotmod = false
g_interval_chrom = 5
g_interval_scale = 4
g_voice = 0
g_scale_active = false
g_note_val = 0
g_note_rate = 1
g_set_env = false
g_lfo_state = false
g_lfo_rate = false
g_lfo_depth = false
g_lfo_shape = false
dirtygrid = false

-- variable for crow
crow_smoothing = 0.02 
crow_val_change = false
crow_prev_value = {}
crow_in_mode = {}
crow_in_thresh = {}
crow_in_done_action = {}
for i = 1, 2 do
  crow_prev_value[i] = 0
  crow_in_mode[i] = 1
  crow_in_thresh[i] = false
  crow_in_done_action[i] = false
end
crow_out_mode = {}
for i = 1, 4 do
  crow_out_mode[i] = 1
end

-- variables for warble
tau = math.pi * 2
warble_amount = 0
warble_depth = 0
warble_freq = 6
warble_counter = 1
warble_slope = 0
warble_active = false

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
options = {}
options.scale = {"oct", "oct+p4", "oct+p5", "oct+p4+p5"}
options.crow_input = {"none", "play [trig]", "play [gate]", "restart [trig]", "rec [trig]", "rec [gate]", "add splice [trig]", "next splice [trig]", "prev splice [trig]", "random splice [trig]", "select splice [cv]", "varispeed v/8 [cv]", "slide [cv]", "size [cv]", "morph [cv]"}
options.crow_output = {"none", "ramp [cv]", "loop reset [trig]"}
options.clock_tempo = {"2", "1", "1/2", "1/4", "3/16", "1/6", "1/8", "3/32", "1/12", "1/16","1/32"}
options.clock_value = {2, 1, 1/2, 1/4, 3/16, 1/6, 1/8, 3/32, 1/12, 1/16, 1/32}
options.params_gbl = {"global_level", "global_pan", "global_cutoff_rel", "global_filter_q_rel"}
options.params = {"level", "pan", "cutoff", "filter_q"}
options.params_view = {"level", "pan", "cutoff", "filter q"}
options.rate_slew = {0, 0.05, 0.1, 0.2, 0.5}

scale = {
  {-oct2, -oct1, -oct0, -oct05, -oct025, oct025, oct05, oct0, oct1, oct2}, -- octaves
  {-oct2, -p4_1, -oct1, -p4,  -oct0, -p4_05, -oct05, -p4_025, -oct025, oct025, p4_025, oct05, p4_05, oct0, p4, oct1, p4_1, oct2}, -- octaves and fifths
  {-oct2, -p5_1, -oct1, -p5,  -oct0, -p5_05, -oct05, -p5_025, -oct025, oct025, p5_025, oct05, p5_05, oct0, p5, oct1, p5_1, oct2}, -- octaves and fifths
  {-oct2, -p5_1, -p4_1, -oct1, -p5, -p4, -oct0, -p4_05, -p5_05, -oct05, -p4_025, -p5_025, -oct025, oct025, p5_025, p4_025, oct05, p5_05, p4_05, oct0, p4, p5, oct1, p4_1, p5_1, oct2} -- octaves + fiths + fourths
}

splice = {}
splice[1] = {}
splice[1].s = 1
splice[1].e = MAX_REEL + 1
splice[1].l = MAX_REEL

voice = {}
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

g_key = {}
for x = 9, 16 do
  g_key[x] = {}
  for y = 1, 6 do
    g_key[x][y] = {}
    g_key[x][y].state = false
    g_key[x][y].voice = 1
  end
end

state_slot = {}
for i = 1, 8 do
  state_slot[i] = {}
  state_slot[i].has_data = false
  state_slot[i].varispeed = {}
  state_slot[i].slide = {}
  state_slot[i].morph = {}
  state_slot[i].size = {}
end

-------- reels --------
function load_reel(path)
  if path ~= "cancel" and path ~= "" then
    local ch, len = audio.file_info(path)
    if ch > 0 and len > 0 then
      filename_reel = path
      softcut.buffer_clear()
      softcut.buffer_read_mono(path, 0, 1, -1, load_reel_ch, 1, 0, 1)
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
      softcut.buffer_read_mono(filename_append, 0, start_pos, -1, load_splice_ch, 1, 0, 1)
      local l = math.min(len / 48000, (MAX_REEL - start_pos + 1))
      append_splice(start_pos + l)
      print("splice added: "..filename_append.." is "..l.."s")
    else
      softcut.buffer_read_mono(filename_append, 0, 1, -1, load_splice_ch, 1, 0, 1)
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
    softcut.buffer_write_mono(_path.audio.."concrete/splices/"..txt..".wav", start, length, 1)
    print("splice saved: " .._path.audio .. "concrete/splices/" .. txt .. ".wav")
  else
    print("save cancel")
  end
end

function save_reel(txt)
  if txt then
    local length = splice[#splice].e - 1
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
    set_loops()
    waveviz_splice = true
    softcut.render_buffer(1, splice[active_splice].s, splice[active_splice].l, 128)
  end
  --print_markers()
end

function nudge_splice_end(d)
  local amt = d / 50
  if active_splice < #splice then
    splice[active_splice].e = util.clamp(splice[active_splice].e + amt, splice[active_splice].s + 0.01, splice[active_splice + 1].e - 0.01)
    splice[active_splice + 1].s = splice[active_splice].e
    splice[active_splice + 1].l = splice[active_splice + 1].e - splice[active_splice + 1].s
    splice[active_splice].l = splice[active_splice].e - splice[active_splice].s
    set_loops()
    waveviz_splice = true
    softcut.render_buffer(1, splice[active_splice].s, splice[active_splice].l, 128)
  end
  --print_markers()
end

function nudge_splice_window(d)
  local amt = d / 50
  if active_splice > 1 and active_splice < #splice then
    -- set start
    splice[active_splice].s = util.clamp(splice[active_splice].s + amt, splice[active_splice - 1].s + 0.01, splice[active_splice].e - 0.01)
    splice[active_splice - 1].e = splice[active_splice].s
    splice[active_splice - 1].l = splice[active_splice - 1].e - splice[active_splice - 1].s
    -- set end
    splice[active_splice].e = util.clamp(splice[active_splice].e + amt, splice[active_splice].s + 0.01, splice[active_splice + 1].e - 0.01)
    splice[active_splice + 1].s = splice[active_splice].e
    splice[active_splice + 1].l = splice[active_splice + 1].e - splice[active_splice + 1].s
    -- set lentgh
    splice[active_splice].l = splice[active_splice].e - splice[active_splice].s
    -- set loops and viz
    set_loops()
    waveviz_splice = true
    softcut.render_buffer(1, splice[active_splice].s, splice[active_splice].l, 128)
  end
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

function clear_all_splice_markers()
  clock.sleep(2)
  if g_slotmod then
    init_reel(splice[#splice].e - 1)
    dirtygrid = true
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
  --page_redraw(1)
  dirtygrid = true
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
  --page_redraw(1)
  dirtygrid = true
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
  elseif not rec and not play then
    amp_in[1]:stop()
    amp_in[2]:stop()
    rec_at_threshold = false
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

delta_viz_fc = "<  >"
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

delta_viz_fq = "<  >"
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

function set_rate(warble)
  local warble = warble or 1
  for i = 1, GENE_NUM do
    local rate = voice_rate * voice[i].rate_mod * voice[i].trsp_value * warble
    softcut.rate(i, rate)
    --print("voice "..i.." "..voice[i].trsp_value)
  end
  if params:get("rec_rate") == 1 then
    local rate = math.abs(voice_rate)
    softcut.rate(rec_voice, rate)
  end
end

function get_snap(inc)
  local idx = params:get("scale")
  for i = 1, #scale[idx] do
    if voice_rate > scale[idx][i] - 0.00001 and voice_rate < scale[idx][i] + 0.00001 then
      local snap = inc > 0 and i + 1 or i - 1
      return snap
    elseif voice_rate < scale[idx][i] then
      local snap = inc > 0 and i or i - 1
      return snap
    end
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

function init_param_state()
  params:set("varispeed", 1)
  params:set("slide", 0)
  params:set("morph", 0)
  params:set("gene_size", 1)
  set_start_pos()
end

function save_param_state(i)
  state_slot[i].has_data = true
  state_slot[i].varispeed = params:get("varispeed")
  state_slot[i].slide = params:get("slide")
  state_slot[i].morph = params:get("morph")
  state_slot[i].size = params:get("gene_size")
end

function clear_param_state(i)
  state_slot[i].has_data = false
  state_slot[i].varispeed = {}
  state_slot[i].slide = {}
  state_slot[i].morph = {}
  state_slot[i].size = {}
end

function load_param_state(i)
  params:set("varispeed", state_slot[i].varispeed)
  params:set("slide", state_slot[i].slide)
  params:set("morph", state_slot[i].morph)
  params:set("gene_size", state_slot[i].size)
end

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
  pos_counter = 0
  for i = 1, GENE_NUM do
    softcut.position(i, voice[i].s)
  end
  if params:get("rec_dest") == 1 then
    softcut.position(rec_voice, voice[1].s)
  end
  for i = 1, 4 do
    if crow_out_mode[i] == 2 then
      crow.output[i].action = "{ to(0, 0), to(8, "..gene_length.."), to(0, 0, 'lin') }"
      crow.output[i]()
    elseif crow_out_mode[i] == 3 then
      crow.output[i].action = "pulse(0.02, 8)"
      crow.output[i]()
    end
  end
  set_levels()
  --page_redraw(1)
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
  elseif mval > 95 then -- if > 95 then max rand and changing start pos will not change the start pos of the other genes.
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
  -- ghost volatility
  if math.random(100) <= params:get("ghost_duration") then
    voice[ghost_voice].active = false
    local ghost_level = 0
    softcut.level(ghost_voice, ghost_level)
  end
  -- set rec levels
  if rec and params:get("ghost_rec") == 2 then
    if params:get("rec_mode") == 1 or params:get("ghost_active") == 1 or params:get("ghost_active") == 3 then
      softcut.level_cut_cut(ghost_voice, rec_voice, 0)
    else
      local level = voice[ghost_voice].active and voice[ghost_voice].level * sos_signal or 0
      softcut.level_cut_cut(ghost_voice, rec_voice, level)
    end
  else
    softcut.level_cut_cut(ghost_voice, rec_voice, 0)
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
    local warble_rate = voice_rate * (1 + warble_slope)
    set_rate(warble_rate)
  end
  -- stop warble
  if warble_active and warble_slope > -0.001 then
    set_rate(1)
  end
end


-------- waveforms --------
waveform_reel_samples = {}
waveform_splice_samples = {}
wave_reel_gain = 1
wave_splice_gain = 1

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


-------- envelopes --------
env = {}
env.attack = 0
env.decay = 0
env.sustain = 1
env.release = 1
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
end

function env_gate_on(i)
  env_get_value(i)
  env[i].gate = true
  env[i].a_is_running = true
  env[i].count = 0
  env[i].direction = 1
end

function env_gate_off(i)
  env_get_value(i)
  env[i].gate = false
  env[i].a_is_running = false
  env[i].d_is_running = false
  env[i].r_is_running = true
  env[i].count = 0
  env[i].direction = 1
end

function env_increment(i, d)
  params:delta("level"..i, d * 100)
end

function env_set_value(i, val)
  params:set("level"..i, val)
end

function env_get_value(i)
  env[i].prev_value = params:get("level"..i)
end

function env_stop(i)
 --print("env "..i.." off")
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
            --env_stop(i)
          else
            local d = -(env[i].prev_value - env[i].init_value) / env.release
            env_increment(i, d)
            if env[i].count >= env.release then
              env[i].direction = 0
              env[i].count = 0
              env[i].r_is_running = false
              env[i].trig = false
              env_set_value(i, env[i].init_value)
              --env_stop(i)
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
    if params:get("keys_mode") == 1 then
      for i = 1, GENE_NUM do
        voice[i].trsp_value = semitone
        if params:get("adsr_active") == 2 then env_gate_on(i) end
      end
      set_rate()
    else
      -- poly mode
      for i, v in ipairs(voicetab) do
        if v == 0 then
          active_notes[i] = msg.note
          voicetab[i] = 1
          voice[i].trsp_value = semitone
          for vox = 1, GENE_NUM do
            if voicetab[vox] == 0 then
              voice[vox].trsp_value = semitone
            end
          end
          set_rate()
          if params:get("adsr_active") == 2 then env_gate_on(i) end
          return
        end
      end
    end
  elseif msg.type == "note_off" and msg.ch == midi_channel then
    if params:get("keys_mode") == 1 then
      if params:get("adsr_active") == 2 then
        for i = 1, GENE_NUM do
          env_gate_off(i)
        end
      end
    else
      -- poly mode
      if tab.contains(active_notes, msg.note) then
        voicetab[tab.key(active_notes, msg.note)] = 0
        for i, v in ipairs(voicetab) do
          if v == 0 then
            if params:get("adsr_active") == 2 then env_gate_off(i) end
          end
        end
      end
    end
  end
end

function set_midi_event_callback() -- TODO! --> see steve's implem on llllllllll
  midi.cleanup()
  m.event = midi_events
end


-------- scales --------
function build_scale(current_scale)
  scale_notes = {}
  scale_notes = mu.generate_scale_of_length(midi_root - 24, current_scale, 60)
end


-------- crow --------
function crow_in_stream_1(v)
  crow_in_handle(v, 1)
end

function crow_in_stream_2(v)
  crow_in_handle(v, 2)
end

function crow_in_handle(v, i)
  if (v > crow_prev_value[i] + crow_smoothing) or (v < crow_prev_value[i] - crow_smoothing) then
    crow_prev_value[i] = v
    crow_val_change = true
    --print(i.." is at "..crow_prev_value[i])
  else
    crow_val_change = false
  end
  local mode = crow_in_mode[i]

  if mode > 1 and mode < 11 then
    -- set theshold
    if crow_prev_value[i] >= 4 and not crow_in_thresh[i] then
      crow_in_thresh[i] = true
    elseif crow_prev_value[i] < 4 and crow_in_thresh[i] then
      crow_in_thresh[i] = false
    end
    -- make action
    if mode == 3 or mode == 6 then
      if crow_in_thresh[i] and not crow_in_done_action[i] then
        if mode == 3 then
          set_play()
        elseif mode == 6 then
          toggle_recording()
        end
        crow_in_done_action[i] = true
      elseif not crow_in_thresh[i] and crow_in_done_action[i] then
        if mode == 3 then
          set_play()
        elseif mode == 6 then
          toggle_recording()
        end
        crow_in_done_action[i] = false
      end
    else
      if crow_in_thresh[i] and not crow_in_done_action[i] then
        if mode == 2 then
          set_play()
        elseif mode == 4 then
          set_start_pos()
        elseif mode == 5 then
          toggle_recording()
        elseif mode == 7 then
          add_splice()
        elseif mode == 8 then
          set_active_splice(1)
        elseif mode == 9 then
          set_active_splice(-1)
        elseif mode == 10 then
          set_random_splice()
        end
        crow_in_done_action[i] = true
      elseif not crow_in_thresh[i] then
        crow_in_done_action[i] = false
      end
    end
  elseif mode > 10 then
    if crow_val_change then
      if mode == 11 then -- select splice
        local volt = util.clamp(crow_prev_value[i], 0, 5)
        local val = util.round(util.linlin(0, 5, 0, 1, volt), 0.01)
        select_splice(val)
      elseif mode == 12 then -- varispeed
        if crow_prev_value[i] > 0 then
          local volt = util.clamp(crow_prev_value[i], 0, 5)
          local v8 = util.round(volt, 1/12) - 36/12
          local val = math.pow(2, v8)
          params:set("varispeed", val)
        elseif crow_prev_value[i] < 0 then
          local volt = -util.clamp(crow_prev_value[i], -5, 0)
          local v8 = util.round(volt, 1/12) - 36/12
          local val = -math.pow(2, v8)
          params:set("varispeed", val)
        end
      elseif mode == 13 then -- slide
        local volt = util.clamp(crow_prev_value[i], 0, 5)
        local val = util.round(util.linlin(0, 5, 0, 1, volt), 0.01)
        params:set("slide", val)
      elseif mode == 14 then -- size
        local volt = util.clamp(crow_prev_value[i], 0, 5)
        local val = 1 - util.round(util.linlin(0, 5, 0, 1, volt), 0.01)
        params:set("gene_size", val)
      elseif mode == 15 then -- morph
        local volt = util.clamp(crow_prev_value[i], 0, 5)
        local val = util.round(util.linlin(0, 5, 0, 1, volt), 0.01)
        params:set("morph", val)
      end
    end
  end
end

-------- helpers --------
local function round_form(param, quant, form)
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

  -- populate scale_names table
  scale_names = {}
  for i = 1, #mu.SCALES - 1 do
    table.insert(scale_names, string.lower(mu.SCALES[i].name))
  end

  -- populate scale intervals
  scale_intervals = {}
  for i = 1, #mu.SCALES - 1 do
    scale_intervals[i] = {table.unpack(mu.SCALES[i].intervals)}
  end
  
  build_midi_device_list()

  if util.file_exists(reel_path) == false then
    util.make_dir(reel_path)
  end

  if util.file_exists(splice_path) == false then
    util.make_dir(splice_path)
  end

  -- crow params
  params:add_group("crow_params",  "CROW", 6)

  for i = 1, 2 do
    params:add_option("crow_in_"..i, "input "..i, options.crow_input, 1)
    params:set_action("crow_in_"..i, function(mode) crow_in_mode[i] = mode end)
  end

  for i = 1, 4 do
    params:add_option("crow_out_"..i, "output "..i, options.crow_output, 1)
    params:set_action("crow_out_"..i, function(mode) crow_out_mode[i] = mode end)
  end

  -- arc params
  params:add_group("arc_params", "ARC", 2)

  params:add_option("arc_orientation", "arc orientation", {"horizontal", "vertical"}, 1)
  params:set_action("arc_orientation", function(val) arc_off = (val - 1) * 16 end)

  params:add_option("arc_vs_sens", "varispeeed sensitivity", {"lo", "hi"}, 1)
  params:set_action("arc_vs_sens", function(x) arc_vs_sens = x == 1 and 100 or 500 end)

  -- reel params
  params:add_separator("reel", "reel")

  params:add_group("load_save_reel", "load & save", 5)

  params:add_file("load_reel", "> load reel", "")
  params:set_action("load_reel", function(path) load_reel(path) end)

  params:add_trigger("save_reel", "< save reel")
  params:set_action("save_reel", function() tx.enter(save_reel) end)

  params:add_option("load_reel_channel", "? select channel", {"left", "right"}, 1)
  params:set_action("load_reel_channel", function(x) load_reel_ch = x end)

  params:add_option("save_buffer_pset", "? save reel with pset", {"no", "yes"}, 2)
  params:set_action("save_buffer_pset", function(x) save_buffer = x == 2 and true or false end)

  params:add_trigger("clear_reel", "!! clear and reset reel !!")
  params:set_action("clear_reel", function() clear_reel() end)

  params:add_group("rec_params", "recording", 10)

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
  params:set_action("sos_level", function(val) sos_signal = val set_levels() end) -- page_redraw(1)

  params:add_control("rec_level", "rec level", controlspec.new(0, 1, "lin", 0, 1), function(param) return (round_form(util.linlin(0, 1, 0, 100, param:get()), 1, "%")) end)
  params:set_action("rec_level", function() set_rec() end)

  params:add_control("dub_level", "overdub level", controlspec.new(0, 1, "lin", 0, 0.8), function(param) return (round_form(util.linlin(0, 1, 0, 100, param:get()), 1, "%")) end)
  params:set_action("dub_level", function() set_rec() end) -- page_redraw(1)

  params:add_option("ghost_rec", "record ghost", {"no", "yes"}, 2)

  params:add_group("splice_params", "splices", 17)

  params:add_separator("splice_audio_params", "audio")

  params:add_file("append_file", ">> append splice to reel", "")
  params:set_action("append_file", function(path) load_splice(path) end)

  params:add_option("load_splice_channel", "? select channel", {"left", "right"}, 1)
  params:set_action("load_splice_channel", function(x) load_splice_ch = x end)

  params:add_trigger("save_splice", "<< save active splice")
  params:set_action("save_splice", function() tx.enter(save_splice) end)

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

  params:add_number("ghost_duration", "volatility", 0, 100, 24, function(param) return round_form(param:get(), 1, "%") end)

  params:add_option("ghost_distribution", "dispersal", {"free", "confined"})

  params:add_option("ghost_clk", "rate", options.clock_tempo, 9)
  params:set_action("ghost_clk", function(idx) gclk_div = options.clock_value[idx] * 4 end)

  params:add_separator("ghost_playhead", "playhead")

  params:add_control("level"..ghost_voice, "level", controlspec.new(0, 1, "lin", 0, 0.5), function(param) return (round_form(util.linlin(0, 1, 0, 100, param:get()), 1, "%")) end)
  params:set_action("level"..ghost_voice, function(x) voice[ghost_voice].level = x end)

  params:add_control("pan"..ghost_voice, "pan", controlspec.new(-1, 1, "lin", 0, 0, ""))
  params:set_action("pan"..ghost_voice, function(x) voice[ghost_voice].pan = x softcut.pan(ghost_voice, x) end)

  params:add_control("cutoff"..ghost_voice, "filter cutoff", controlspec.new(20, 18000, 'exp', 1, 4600, "Hz"))
  params:set_action("cutoff"..ghost_voice, function(x) softcut.post_filter_fc(ghost_voice, x) end)

  params:add_control("filter_q"..ghost_voice, "filter q", controlspec.new(0.1, 4.0, 'lin', 0.01, 2.0, ""))
  params:set_action("filter_q"..ghost_voice, function(x) softcut.post_filter_rq(ghost_voice, x) end)

  params:add_option("filter_type"..ghost_voice, "filter type", {"low pass", "high pass", "band pass", "band reject", "off"}, 1)
  params:set_action("filter_type"..ghost_voice, function(x) select_filter(ghost_voice, x)  end)

  -- exploration params
  params:add_separator("essai", "essai")

  params:add_binary("toggle_play", "> toggle play", "trigger", 0)
  params:set_action("toggle_play", function() set_play() end)

  params:add_binary("reset_pos", "> reset position", "trigger", 0)
  params:set_action("reset_pos", function() set_start_pos() end)

  params:add_binary("init_essai_params", "> init state", "trigger", 0)
  params:set_action("init_essai_params", function() init_param_state() end)

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

  params:add_option("morph_mode", "morph mode", {"normal", "clocked"}, 1)

  params:add_option("morph_clk", "moprh clock", options.clock_tempo, 7)
  params:set_action("morph_clk", function(idx) mclk_div = options.clock_value[idx] * 4 end)

  params:add_group("rand_settings", "randomization settings", 6)

  params:add_number("morph_prob", "probability", 1, 100, 20, function(param) return param:get().."%" end)

  params:add_option("randomize_level", "level @morph > 75", {"off", "on"}, 1)

  params:add_option("randomize_pan", "pan @morph > 75", {"off", "on"}, 2)

  params:add_option("randomize_direction", "direction @morph > 80", {"off", "on"}, 2)
  params:hide("randomize_direction")

  params:add_option("randomize_rate", "rate @morph > 80", {"off", "on"}, 2)

  params:add_binary("morph_freez", "> freeze values", "toggle", 0)
  params:set_action("morph_freez", function(x) morph_freeze = x == 1 and true or false page_redraw(2) end)

  -- keyboard params
  params:add_separator("keyboard_params",  "keyboard midi/grid")

  params:add_option("keyboard_type", "keyboard type", {"chromatic", "scale"}, 1)
  params:set_action("keyboard_type", function(mode) g_scale_active = mode == 2 and true or false build_menu() dirtygrid = true end)

  params:add_option("keys_scale", "scale type", scale_names, 2)
  params:set_action("keys_scale", function(val) build_scale(val) current_scale = val dirtygrid = true end)

  params:add_number("grid_interval_chrom", "interval [y]", 2, 6, 5, function(param) return param:get().."st" end)
  params:set_action("grid_interval_chrom", function(val) g_interval_chrom = val dirtygrid = true end)

  params:add_number("grid_interval_scale", "interval [y]", 1, 8, 4, function(param) return param:get().."deg" end)
  params:set_action("grid_interval_scale", function(val) g_interval_scale = val - 1 dirtygrid = true end)

  params:add_option("keys_mode", "voice allocation", {"mono", "poly"}, 1)

  params:add_number("root_note", "root note", 1, 127, 60, function(param) return mu.note_num_to_name(param:get(), true) end)
  params:set_action("root_note", function(val) midi_root = val key_root = val - 81 dirtygrid = true end)

  params:add_option("midi_device", "midi device", midi_devices, 1)
  params:set_action("midi_device", function(val) m = midi.connect(val) set_midi_event_callback() end)

  params:add_number("midi_channel", "midi channel", 1, 16, 1)
  params:set_action("midi_channel", function(val) midi_channel = val end)

  params:add_option("adsr_active", "envelope", {"off", "on"}, 1)
  params:set_action("adsr_active", function() init_envelope() dirtygrid = true end)

  params:add_group("env_settings", "envelope settings", 4)

  params:add_control("adsr_attack", "attack", controlspec.new(0, 10, 'lin', 0.1, 0.2, "s"))
  params:set_action("adsr_attack", function(val) env.attack = val * 10 end)

  params:add_control("adsr_decay", "decay", controlspec.new(0, 10, 'lin', 0.1, 0.5, "s"))
  params:set_action("adsr_decay", function(val) env.decay = val * 10 end)

  params:add_control("adsr_sustain", "sustain", controlspec.new(0, 1, 'lin', 0, 1, ""), function(param) return (round_form(param:get() * 100, 1, "%")) end)
  params:set_action("adsr_sustain", function(val) env.sustain = val end)

  params:add_control("adsr_release", "release", controlspec.new(0, 10, 'lin', 0.1, 1, "s"))
  params:set_action("adsr_release", function(val) env.release = val * 10 end)   

 -- lfo params
  params:add_separator("modulation", "modulation")

  local gene_id = {"[one]", "[two]", "[three]", "[four]", "[ghost]"}
  params:add_group("level_lfos", "level lfos", 15 * (GENE_NUM + 1))
  local level_lfo = {}
  for i = 1, GENE_NUM + 1 do
    level_lfo[i] = _lfos:add{min = 0, max = 1, baseline = 'max'}
    level_lfo[i]:add_params("level_lfo"..i, "playhead "..gene_id[i].." level")
    level_lfo[i]:set("action", function(scaled, raw) params:set("level"..i, scaled) end)
    level_lfo[i]:set('state_callback', function(enabled)
      if not enabled and level_lfo[i].prev_value ~= nil then
        params:set("level"..i, level_lfo[i].prev_value)
      elseif enabled then
        level_lfo[i].prev_value = params:get("level"..i)
      end
    end)
  end

  params:add_group("pan_lfos", "pan lfos", 15 * (GENE_NUM + 1))
  local pan_lfo = {}
  for i = 1, GENE_NUM + 1 do
    pan_lfo[i] = _lfos:add{min = -1, max = 1, baseline = 'center'}
    pan_lfo[i]:add_params("pan_lfo"..i, "playhead "..gene_id[i].." pan")
    pan_lfo[i]:set("action", function(scaled, raw) params:set("pan"..i, scaled) end)
    pan_lfo[i]:set('state_callback', function(enabled)
      if not enabled and pan_lfo[i].prev_value ~= nil then
        params:set("pan"..i, pan_lfo[i].prev_value)
      elseif enabled then
        pan_lfo[i].prev_value = params:get("pan"..i)
      end
    end)
  end

  params:add_group("cutoff_lfos", "cutoff lfos", 15 * (GENE_NUM + 1))
  local cutoff_lfo = {}
  for i = 1, GENE_NUM + 1 do
    cutoff_lfo[i] = _lfos:add{min = 20, max = 18000, baseline = 'max'}
    cutoff_lfo[i]:add_params("cutoff_lfo"..i, "playhead "..gene_id[i].." cutoff")
    cutoff_lfo[i]:set("action", function(scaled, raw) params:set("cutoff"..i, scaled) end)
    cutoff_lfo[i]:set('state_callback', function(enabled)
      if not enabled and cutoff_lfo[i].prev_value ~= nil then
        params:set("cutoff"..i, cutoff_lfo[i].prev_value)
      elseif enabled then
        cutoff_lfo[i].prev_value = params:get("cutoff"..i)
      end
    end)
  end

  params:add_group("filter_q_lfos", "filter q lfos", 15 * (GENE_NUM + 1))
  local filter_q_lfo = {}
  for i = 1, GENE_NUM + 1 do
    filter_q_lfo[i] = _lfos:add{min = 0.01, max = 4, baseline = 'max'}
    filter_q_lfo[i]:add_params("filter_q_lfo"..i, "playhead "..gene_id[i].." filter q")
    filter_q_lfo[i]:set("action", function(scaled, raw) params:set("filter_q"..i, scaled) end)
    filter_q_lfo[i]:set('state_callback', function(enabled)
      if not enabled and filter_q_lfo[i].prev_value ~= nil then
        params:set("filter_q"..i, filter_q_lfo[i].prev_value)
      elseif enabled then
        filter_q_lfo[i].prev_value = params:get("filter_q"..i)
      end
    end)
  end

  local varispeed_lfo = _lfos:add{min = -4, max = 4, baseline = 'center'}
  varispeed_lfo:add_params("varispeed_lfo", "varispeed", "varispeed lfo")
  varispeed_lfo:set("action", function(scaled, raw) params:set("varispeed", scaled) end)
  varispeed_lfo:set('state_callback', function(enabled)
    if not enabled and varispeed_lfo.prev_value ~= nil then
      params:set("varispeed", varispeed_lfo.prev_value)
    elseif enabled then
      varispeed_lfo.prev_value = params:get("varispeed")
    end
  end)

  local slide_lfo = _lfos:add{min = 0, max = 1, baseline = 'min'}
  slide_lfo:add_params("slide_lfo", "slide", "slide lfo")
  slide_lfo:set("action", function(scaled, raw) params:set("slide", scaled) end)
  slide_lfo:set('state_callback', function(enabled)
    if not enabled and slide_lfo.prev_value ~= nil then
      params:set("slide", slide_lfo.prev_value)
    elseif enabled then
      slide_lfo.prev_value = params:get("slide")
    end
  end)

  local gene_size_lfo = _lfos:add{min = 0, max = 1, baseline = 'max', mode = 'free'}
  gene_size_lfo:add_params("gene_size_lfo", "size", "size lfo")
  gene_size_lfo:set("action", function(scaled, raw) params:set("gene_size", scaled) end)
  gene_size_lfo:set('state_callback', function(enabled)
    if not enabled and gene_size_lfo.prev_value ~= nil then
      params:set("gene_size", gene_size_lfo.prev_value)
    elseif enabled then
      gene_size_lfo.prev_value = params:get("gene_size")
    end
  end)

  local morph_lfo = _lfos:add{min = 0, max = 1, baseline = 'min', mode = 'free'}
  morph_lfo:add_params("morph_lfo", "morph", "morph lfo")
  morph_lfo:set("action", function(scaled, raw) params:set("morph", scaled) end)
  morph_lfo:set('state_callback', function(enabled)
    if not enabled and morph_lfo.prev_value ~= nil then
      params:set("morph", morph_lfo.prev_value)
    elseif enabled then
      morph_lfo.prev_value = params:get("morph")
    end
  end)
 
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
    --os.execute("mkdir -p ".._path.audio.."concrete/reels")
    -- store data in one big table
    local reel_data = {}
    reel_data.active = active_splice
    reel_data.splice = {table.unpack(splice)}
    reel_data.voice = {table.unpack(voice)}
    reel_data.state = {table.unpack(state_slot)}
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

  params.action_read = function(filename, silent, number)
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
      state_slot = {table.unpack(reel_data.state)}
      set_loops()
      set_start_pos()
      reel_has_audio = true
      init_recording = false
      waveviz_reel = true
      softcut.render_buffer(1, 1, splice[#splice].e - 1, 128)
      clock.run(
        function()
          clock.sleep(0.2)
          set_active_splice(0)
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
  norns.crow.add = crow_connect
  norns.crow.remove = crow_disconnect

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
    crow.input[1].stream = crow_in_stream_1
    crow.input[1].mode("stream", 0.01)
    crow.input[2].stream = crow_in_stream_2
    crow.input[2].mode("stream", 0.01)
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

  -- threshold rec poll
  amp_in = {}
  amp_src = {"amp_in_l", "amp_in_r"}
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
        dirtygrid = true
      end
    end
  end

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
  end
  -- ensure that recording stops when the rec head reaches the end of the reel.
  if i == rec_voice and is_recording and (params:get("rec_dest") == 3 or init_recording) then
    if voice[rec_voice].pos_abs >= MAX_REEL and not reel_is_full then
      rec = false
      set_rec()
      reel_is_full = true
      print("no more space left :(")
    end
  end
end


-------- norns UI --------
function key(n, z)
  _key.action(n, z)
end

function enc(n, d)
  _enc.delta(n, d)
end

function redraw()
  _draw.screen()
end


-------- arc UI --------
function a.delta(n, d)
  _arc.delta(n, d)
end

function arcredraw()
  _arc.draw()
end


-------- grid UI --------
function g.key(x, y, z)
  _grd.key_one(x, y, z)
end

function gridredraw()
  _grd.draw_one()
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
  if pageNum == 1 then
    redraw()
    dirtyscreen = false
  elseif dirtyscreen then
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

function display_msg(param, name)
  view_param = ""
  view_name = ""
  if g_lfo_depth then
    view_name = "lfo depth"
  elseif g_lfo_rate then
    view_name = "lfo rate"
  elseif g_lfo_shape then
    view_name = "lfo shape"
  elseif g_lfo_state then
    view_name = "lfo state"
  end
  view_param = name
  if msg_timer ~= nil then
    clock.cancel(msg_timer)
  end
  local message = params:string(param)
  msg_timer = clock.run(show_message, message)
end

function show_message(message)
  view_message = message
  dirtyscreen = true
  clock.sleep(1)
  view_message = ""
  dirtyscreen = true
end

function build_menu()
  if arc_is then
    params:show("arc_params")
  else
    params:hide("arc_params")
  end
  if crow_is then
    params:show("crow_params")
  else
    params:hide("crow_params")
  end
  if g_scale_active then
    params:show("keys_scale")
    params:show("grid_interval_scale")
    params:hide("grid_interval_chrom")
  else
    params:hide("keys_scale")
    params:show("grid_interval_chrom")
    params:hide("grid_interval_scale")
  end
  _menu.rebuild_params()
  dirtyscreen = true
end

function drawarc_connect()
  hardware_redraw()
  arc_is = true
  build_menu()
end

function drawarc_disconnect()
  arc_is = false
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
  print("all nice and tidy here")
end
