--  This is file `novelette-pdftc.lua', part of novelette document class.
--  Nearly all of its code has been shamelessly copied from code by others,
--  released under appropriate license(s), and attributed.
--  Novelette version 0.36.

--  Next code is modified from `pdftexcmds.lua', in package `pdftexcmds'.
--  Copyright © 2007, 2009-2011 Heiko Oberdiek, and
--  2016-2019 Oberdiek Package Support Group.
--  This work may be distributed and/or modified under the
--  conditions of the LaTeX Project Public License, version 1.3.

novelette = novelette or {}
local pdftc = novelette.pdftc or {}
novelette.pdftc = pdftc
function pdftc.filesize(filename)
  local foundfile = kpse.find_file(filename, "tex", true)
  if foundfile then
    local size = lfs.attributes(foundfile, "size")
    if size then
      tex.write(size)
    end
  end
end
local function nvt_utf8_to_byte(str)
  local i = 0
  local n = string.len(str)
  local t = {}
  while i < n do
    i = i + 1
    local a = string.byte(str, i)
    if a < 128 then
      table.insert(t, string.char(a))
    else
      if a >= 192 and i < n then
        i = i + 1
        local b = string.byte(str, i)
        if b < 128 or b >= 192 then
          i = i - 1
        elseif a == 194 then
          table.insert(t, string.char(b))
        elseif a == 195 then
          table.insert(t, string.char(b + 64))
        end
      end
    end
  end
  return table.concat(t)
end
function pdftc.escapehex(str, mode)
  if mode == "byte" then
    str = nvt_utf8_to_byte(str)
  end
  tex.write((string.gsub(str, ".",
    function (ch)
      return string.format("%02X", string.byte(ch))
    end
  )))
end
function pdftc.mdfivesum(str, mode)
  if mode == "byte" then
    str = nvt_utf8_to_byte(str)
  end
  pdftc.escapehex(md5.sum(str))
end
--  End of code from `pdftexcmds'.



-- 
--  End of File `novelette-pdftc.lua'.
