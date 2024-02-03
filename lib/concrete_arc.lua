local arcenc = {}

local enc_count = {}
for i = 1, 4 do
  enc_count[i] = 0
end


function arcenc.delta(n, d)
  if pageNum < 3 then
    if shift then
      if n == 1 then
        arc_enc1_count = (arc_enc1_count + 1) % 25
        if arc_enc1_count == 0 then
          local idx = util.clamp(get_snap(d), 1, #scale[params:get("scale")])
          local rate = scale[params:get("scale")][idx]
          params:set("varispeed", rate)
        end
      elseif n == 2 then
        local add = d / 400
        for i = 1, GENE_NUM do
          local curr_pos = voice[i].pos_abs
          local new_pos = curr_pos + add
          softcut.position(i, new_pos)
        end
      end
    else
      local param = {"varispeed", "slide", "gene_size", "morph"}
      local name = {"varispeed", "slide", "size", "morph"}
      local delta = n == 1 and (d / arc_vs_sens) or (d / 20)
      enc_count[n] = (enc_count[n] + 1) % 20
      if g_lfo_state then
        params:delta("lfo_"..param[n].."_lfo", delta)
        display_msg("lfo_"..param[n].."_lfo", name[n])
      elseif g_lfo_depth then
        if enc_count[n] == 0 then
          params:delta("lfo_depth_"..param[n].."_lfo", delta * 2)
          display_msg("lfo_depth_"..param[n].."_lfo", name[n])
        end
      elseif g_lfo_rate then
        if enc_count[n] == 0 then
          if params:get("lfo_mode_"..param[n].."_lfo") == 1 then
            params:delta("lfo_clocked_"..param[n].."_lfo", delta)
            display_msg("lfo_clocked_"..param[n].."_lfo", name[n])
          else
            params:delta("lfo_free_"..param[n].."_lfo", delta)
            display_msg("lfo_clocked_"..param[n].."_lfo", name[n])
          end
        end
      elseif g_lfo_shape then
        if enc_count[n] == 0 then
          params:delta("lfo_shape_"..param[n].."_lfo", delta)
          display_msg("lfo_shape_"..param[n].."_lfo", name[n])
        end
      else
        if params:get("lfo_"..param[n].."_lfo") == 2 and params:get("lfo_depth_"..param[n].."_lfo") > 0 then
          params:delta("lfo_offset_"..param[n].."_lfo", delta)
        else
          params:delta(param[n], delta)
        end
      end
    end
  elseif pageNum == 3 then
    enc_count[n] = (enc_count[n] + 1) % 20
    if shift then
      local glb_param = options.params_gbl[param_page3]
      params:delta(glb_param, d / 20)
    else
      local param = options.params[param_page3]
      local name = {"level", "pan", "cutoff", "filter q"}
      if g_lfo_state then
        if enc_count[n] == 0 then
          params:delta("lfo_"..param.."_lfo"..n, d / 20)
          display_msg("lfo_"..param.."_lfo"..n, name[param_page3].." "..n)
        end
      elseif g_lfo_depth then
        if enc_count[n] == 0 then
          params:delta("lfo_depth_"..param.."_lfo"..n, d / 10)
          display_msg("lfo_depth_"..param.."_lfo"..n, name[param_page3].." "..n)
        end
      elseif g_lfo_rate then
        if enc_count[n] == 0 then
          if params:get("lfo_mode_"..param.."_lfo"..n) == 1 then
            params:delta("lfo_clocked_"..param.."_lfo"..n, d / 20)
            display_msg("lfo_clocked_"..param.."_lfo"..n, name[param_page3].." "..n)
          else
            params:delta("lfo_free_"..param.."_lfo"..n, d / 20)
            display_msg("lfo_free_"..param.."_lfo"..n, name[param_page3].." "..n)
          end
        end
      elseif g_lfo_shape then
        if enc_count[n] == 0 then
          params:delta("lfo_shape_"..param.."_lfo"..n, d / 20)
          display_msg("lfo_shape_"..param.."_lfo"..n, name[param_page3].." "..n)
        end
      else
        if params:get("lfo_"..param.."_lfo"..n) == 2 and params:get("lfo_depth_"..param.."_lfo"..n) > 0 then
          params:delta("lfo_offset_"..param.."_lfo"..n, d / 20)
        else
          params:delta(param..n, d / 20)
        end
      end
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

function arcenc.draw()
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
    a:led(1, 22 - arc_off, 6)
    a:led(1, -20 - arc_off, 6)
    if voice_rate > 0 then
      if rate_pos == 22 then rate_pos = 21 end
      a:led(1, rate_pos + 1 - arc_off, 15)        
    elseif voice_rate <= 0 then
      a:led(1, rate_pos - arc_off, 15)
    end
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
    local parameter = options.params[param_page3]
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

return arcenc