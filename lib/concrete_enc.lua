 local encdr = {}

 function encdr.delta(n, d)
  if n == 1 then
    if shift then
      if pageNum == 1 and focus_page1 == 0 then
        nudge_splice_window(d)
      else
        params:delta("global_level", d)
      end
    else
      local last_page = params:get("adsr_active") == 1 and 3 or 4
      pageNum = util.clamp(pageNum + d, 1, last_page)
      dirtygrid = true
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
  elseif pageNum == 2 and n > 1 then
    local param = {"morph", "gene_size", "varispeed", "slide"}
    local name = {"morph", "size", "varispeed", "slide"}
    local i = (n - 1) + (focus_page2 * 2)
    if shift and n == 2 and focus_page2 == 1 then
      local idx = util.clamp(get_snap(d), 1, #scale[params:get("scale")])
      local rate = scale[params:get("scale")][idx]
      params:set("varispeed", rate)
    elseif g_lfo_state then
      params:delta("lfo_"..param[i].."_lfo", d)
      display_msg("lfo_"..param[i].."_lfo", name[i])
    elseif g_lfo_depth then
      params:delta("lfo_depth_"..param[i].."_lfo", d)
      display_msg("lfo_depth_"..param[i].."_lfo", name[i])
    elseif g_lfo_rate then
      if params:get("lfo_mode_"..param[i].."_lfo") == 1 then
        params:delta("lfo_clocked_"..param[i].."_lfo", d)
        display_msg("lfo_clocked_"..param[i].."_lfo", name[i])
      else
        params:delta("lfo_free_"..param[i].."_lfo", d)
        display_msg("lfo_clocked_"..param[i].."_lfo", name[i])
      end
    elseif g_lfo_shape then
      params:delta("lfo_shape_"..param[i].."_lfo", d)
      display_msg("lfo_shape_"..param[i].."_lfo", name[i])
    else
      if params:get("lfo_"..param[i].."_lfo") == 2 and params:get("lfo_depth_"..param[i].."_lfo") > 0 then
        params:delta("lfo_offset_"..param[i].."_lfo", d)
      else
        params:delta(param[i], d)
      end
    end
  elseif pageNum == 3 and n > 1 then
    if shift and n == 2 then
      local glb_param = options.params_gbl[param_page3]
      params:delta(glb_param, d)
    else
      local i = (n - 1) + (focus_page3 * 2)
      local param = options.params[param_page3]
      local name = {"level", "pan", "cutoff", "filter q"}
      if g_lfo_state then
        params:delta("lfo_"..param.."_lfo"..i, d)
        display_msg("lfo_"..param.."_lfo"..i, name[param_page3].." "..i)
      elseif g_lfo_depth then
        params:delta("lfo_depth_"..param.."_lfo"..i, d)
        display_msg("lfo_depth_"..param.."_lfo"..i, name[param_page3].." "..i)
      elseif g_lfo_rate then
        if params:get("lfo_mode_"..param.."_lfo"..i) == 1 then
          params:delta("lfo_clocked_"..param.."_lfo"..i, d)
          display_msg("lfo_clocked_"..param.."_lfo"..i, name[param_page3].." "..i)
        else
          params:delta("lfo_free_"..param.."_lfo"..i, d)
          display_msg("lfo_free_"..param.."_lfo"..i, name[param_page3].." "..i)
        end
      elseif g_lfo_shape then
        params:delta("lfo_shape_"..param.."_lfo"..i, d)
        display_msg("lfo_shape_"..param.."_lfo"..i, name[param_page3].." "..i)
      else
        if params:get("lfo_"..param.."_lfo"..i) == 2 and params:get("lfo_depth_"..param.."_lfo"..i) > 0 then
          params:delta("lfo_offset_"..param.."_lfo"..i, d)
        else
          params:delta(param..i, d)
        end
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

 return encdr