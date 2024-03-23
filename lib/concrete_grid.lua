local grd = {}

function grd.key_one(x, y, z)
  --- momentary keys
  if y == 7 and x < 9 then
    if x == 1 then
      g_slotinit = z == 1 and true or false
    elseif x == 8 then
      g_slotmod = z == 1 and true or false
    end
  end

  if y == 8 and x < 9 then
    if x == 3 then
      g_pos_reset = z == 1 and true or false
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
  --- toggles
  -- left quardrant
  if x < 9 then
    if z == 1 then
      if y < 4 then
        local i = x + (y - 1) * 8 + 24 * (splice_page - 1)
        if i <= #splice then
          local inc = i - active_splice
          set_active_splice(inc)
          if g_slotmod then
            remove_splice()
            if clearing ~= nil then
              clock.cancel(clearing)
            end
            clearing = clock.run(clear_all_splice_markers)
          end
        else
          if play then add_splice() end
        end
        dirtyscreen = true
      elseif y == 4 then
        if (x == 1 or x == 8) then
          local max_page = util.round_up((#splice + 1) / 24, 1)
          splice_page = util.clamp(splice_page + (x == 1 and -1 or 1), 1, max_page)
        elseif x == 2 then
          params:set("varispeed", 0)
        elseif x > 2 and x < 8 then
          local rate = scale[1][x + 3]
          params:set("varispeed", rate)
        end
      elseif y == 5 then
        if x == 7 then
          params:set("varispeed", 0)
        elseif x > 1 and x < 7 then
          local rate = scale[1][x - 1]
          params:set("varispeed", rate)
        end
      elseif (y == 6 or y == 7) then
        local i = x - 2 + (y - 6) * 4
        if x == 1 then
          init_param_state()
        elseif x > 2 and x < 7 then
          if g_slotmod then
            clear_param_state(i)
          else
            if state_slot[i].has_data then
              load_param_state(i)
            else
              save_param_state(i)
            end
          end
        end
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
              if not recording then
                amp_in[1]:start()
                amp_in[2]:start()
                rec_at_threshold = true
              end
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
      if y < 4 and x < 9 then
        if clearing ~= nil then
          clock.cancel(clearing)
        end
      elseif y == 8 then
        if x == 2 then
          set_play()
        end
      end
    end
  -- right quadrant
  else
    if y < 7 then
      g_key[x][y].state = z == 1 and true or false
      dirtygrid = true
      if g_scale_active then
        local octave = #scale_intervals[current_scale] - 1
        g_note_val = (x - 8) + ((6 - y) * g_interval_scale) + octave
        g_note_rate = math.pow(2, (scale_notes[g_note_val] - midi_root) / 12)
      else 
        g_note_val = (key_root + x) + g_interval_chrom * (6 - y)
        g_note_rate = math.pow(2, g_note_val / 12)
      end
      if z == 1 then
        if params:get("keys_mode") == 1 then
          for i = 1, GENE_NUM do
            voice[i].trsp_value = g_note_rate
            if params:get("adsr_active") == 2 then env_gate_on(i) end
          end
          set_rate()
        else
          for i, v in ipairs(voicetab) do
            if v == 0 then
              g_key[x][y].voice = i
              voicetab[i] = 1
              voice[i].trsp_value = g_note_rate
              for vox = 1, GENE_NUM do
                if voicetab[vox] == 0 then
                  voice[vox].trsp_value = g_note_rate
                end
              end
              set_rate()
              if params:get("adsr_active") == 2 then env_gate_on(i) end
              return
            end
          end
        end
      else
        if params:get("keys_mode") == 1 then
          for i = 1, GENE_NUM do
            if params:get("adsr_active") == 2 then env_gate_off(i) end
          end
        else
          voicetab[g_key[x][y].voice] = 0
          for i, v in ipairs(voicetab) do
            if v == 0 then
              if params:get("adsr_active") == 2 then env_gate_off(i) end
            end
          end
        end
      end
    elseif y == 7 then
      if x == 11 then
        g_lfo_state = z == 1 and true or false
      elseif x == 12 then
        g_lfo_depth = z == 1 and true or false
      elseif x == 13 then
        g_lfo_rate = z == 1 and true or false
      elseif x == 14 then
        g_lfo_shape = z == 1 and true or false
      end
    elseif y == 8 then
      if x == 14 then g_set_env = z == 1 and true or false end
      if x > 10 and x < 15 and z == 1 then
        pageNum = x - 10
        dirtyscreen = true
      elseif x == 16 and z == 1 then
        if g_set_env then
          params:set("adsr_active", params:get("adsr_active") == 1 and 2 or 1)
        else
          params:set("keys_mode", params:get("keys_mode") == 1 and 2 or 1)
        end
      end
    end
  end
  dirtygrid = true
end

function grd.draw_one()
  g:all(0)
  -- splices
  for i = 1, 8 do
    for j = 1, 4 do
      g:led(i, j, 1)
    end
  end
  for i = 1, #splice do
    if i < 9 + 24 * (splice_page - 1) then
      g:led(i - 24 * (splice_page - 1), 1, i == active_splice and 12 or 8)
    elseif i < 17 + 24 * (splice_page - 1) then
      g:led(i - 8 - 24 * (splice_page - 1), 2, i == active_splice and 12 or 5)
    elseif i < 25 + 24 * (splice_page - 1) then
      g:led(i - 16 - 24 * (splice_page - 1), 3, i == active_splice and 12 or 3)
    end
  end
  -- speed
  for i = 1, 6 do
    g:led(i + 1, 4, i * 2)
    g:led(i + 1, 5, 14 - i * 2)
  end
  -- slots
  g:led(1, 7, g_slotinit and 15 or 4)
  g:led(8, 7, g_slotmod and 15 or 4)
  for i = 1, 4 do
    g:led(i + 2, 6, state_slot[i].has_data and 4 or 2)
    g:led(i + 2, 7, state_slot[i + 4].has_data and 4 or 2)
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
    g:led(8, 8 , rec and 15 or 6)
  end
  -- right quadrant
  for x = 9, 16 do
    for y = 1, 6 do
      if g_scale_active then
        local octave = #scale_intervals[current_scale] - 1
        g:led(x, y, g_key[x][y].state and 15 or ((((x - 8) + g_interval_scale * (6 - y)) % octave) == 1 and 10 or 2))
      else
        local note = (-21 + x) + g_interval_chrom * (6 - y)
        local semitone = note % 12
        if semitone == 0 then
          g:led(x, y, g_key[x][y].state and 15 or 12)
        elseif (semitone == 2 or semitone == 4 or semitone == 5 or semitone == 7 or semitone == 9 or semitone == 11) then -- white keys
          g:led(x, y, g_key[x][y].state and 15 or 6)
        else
          g:led(x, y, g_key[x][y].state and 15 or 2) -- black keys
        end
      end
    end
  end
  g:led(11, 7, g_lfo_state and 15 or 0)
  g:led(12, 7, g_lfo_depth and 15 or 0)
  g:led(13, 7, g_lfo_rate and 15 or 0)
  g:led(14, 7, g_lfo_shape and 15 or 0)
  for i = 1, 4 do
    g:led(10 + i, 8, pageNum == i and 14 or 6)
  end
  if g_set_env then
    g:led(16, 8, params:get("adsr_active") == 2 and 15 or 8)
  else
    g:led(16, 8, params:get("keys_mode") == 2 and 4 or 2)
  end
  g:refresh()
end

return grd
