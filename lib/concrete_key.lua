local keys = {}

function keys.action(n, z)
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
      param_page3 = util.wrap(param_page3 + 1, 1, 4)
    end
  elseif pageNum == 4 then
    if n == 2 and z == 1 then
      focus_page4 = 1 - focus_page4
    end
  end
  dirtyscreen = true
end

return keys