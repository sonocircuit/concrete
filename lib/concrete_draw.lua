local draw = {}

function draw.screen()
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
      screen.level(8)
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

    if (shift and focus_page1 == 1) or g_rec_dest then
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

    -- display messages
    if view_message ~= "" then
      screen.clear()
      screen.level(15)
      screen.line_width(1)
      screen.rect(18, 18, 92, 30)
      screen.fill()
      screen.level(0)
      screen.move(64, 30)
      screen.text_center(view_param)
      screen.move(64, 40)
      screen.text_center(view_name..": "..view_message)
    end

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
    screen.move(util.linlin(-4, 4, 28, 98, voice_rate), 13)
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

     -- display messages
    if view_message ~= "" then
      screen.clear()
      screen.level(15)
      screen.line_width(1)
      screen.rect(18, 18, 92, 30)
      screen.fill()
      screen.level(0)
      screen.move(64, 30)
      screen.text_center(view_param)
      screen.move(64, 40)
      screen.text_center(view_name..": "..view_message)
    end
    
  elseif pageNum == 3 then
    local param_name = options.params_view[param_page3]
    local parameter = options.params[param_page3]
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
        screen.rect(57 + off_x, 8, - util.linlin(0.01, 4, 0, 49, voice[i].fq), 15)
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
        screen.rect(57 + off_x, 40, - util.linlin(0.01, 4, 0, 49, voice[i].fq), 15)
        screen.fill()
      end
    end
    
    -- display messages
    if view_message ~= "" then
      screen.clear()
      screen.level(15)
      screen.line_width(1)
      screen.rect(18, 18, 92, 30)
      screen.fill()
      screen.level(0)
      screen.move(64, 30)
      screen.text_center(view_param)
      screen.move(64, 40)
      screen.text_center(view_name..": "..view_message)
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

return draw
