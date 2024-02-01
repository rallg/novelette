-- This is file `novelette-typo.lua', part of `novelette' document class.
-- Novelette version 0.37b.
-- It is modified from `lua-typo.sty' v.0.84 by Daniel Flipo.
-- lua-typo.sty: Copyright © 2020-2023 by Daniel Flipo.
-- This program can be distributed and/or modified under the terms
-- of the LaTeX Project Public License, version 1.3c.
-- Modifications by Robert Allgeyer, 2023. Same license.

nvttypo = nvttypo or { }
nvttypo.pagelist = ""
nvttypo.failedlist = ""
emsize = emsize or 700000
parindent = parindent or 700000
msgt = "File generated " .. os.localtime() .. ".\n"
msgf = "Typographic flaws found in " .. tex.jobname .. ".pdf:\n"
msgp = "rm->roman pagenum, pg->arabic pagenum, ln->line, fn->footnote line.\n"
msgu = "More space, from line number to descrption, means less important.\n"
msgs = "These are suggestions for improvement, not errors.\n"
msgm = "Sometimes, you do not need to fix flaws, or only fix a few of them.\n"
msgw = "The only way to fix flaws is to re-write your text.\n\n"
msgn = "No typo flaws found in " .. tex.jobname .. ".pdf.\n"
nvttypo.flawheader = msgt .. msgf .. msgp .. msgu .. msgs .. msgm .. msgw
nvttypo.noflawheader = msgt .. msgn
nvttypo.buffer = ""
-- Although lua-typo allows user to choose settings, Novelette sets them:
-- parindent and emsize were set via \directlua in novelette-interior.sty.
-- no more than 1 consecutive lines ending in hyphen
-- minimum number of lines in page body (ignores blanks) = 5
-- maximum line stretch = 1.06
MinFull = 1 -- min chars in whole word on consecutive lines 
MinPart = 3 -- min chars in part words on consecutive lines
MinLen = 5 -- minimum chars of first word on continued page
LLminWD = parindent + emsize -- min width of last line in paragraph
BackPI = emsize -- min space after last line in paragraph
BackFuzz = .01*emsize -- tolerance for BackPI at margin.
-- Some of the above values may be changed, prior to release.

local char_to_discard = { }
char_to_discard[string.byte(",")] = true
char_to_discard[string.byte(".")] = true
char_to_discard[string.byte("!")] = true
char_to_discard[string.byte("?")] = true
char_to_discard[string.byte(":")] = true
char_to_discard[string.byte(";")] = true
char_to_discard[string.byte("-")] = true
char_to_discard[utf8.codepoint("¡")] = true
char_to_discard[utf8.codepoint("¿")] = true

-- end of word:
local eow_char = { }
eow_char[string.byte(".")] = true
eow_char[string.byte("!")] = true
eow_char[string.byte("?")] = true
eow_char[utf8.codepoint("…")] = true -- ellipsis
eow_char[utf8.codepoint("–")] = true -- endash
eow_char[utf8.codepoint("—")] = true -- emdash
eow_char[utf8.codepoint("―")] = true -- U+2015 horizontal bar
eow_char[utf8.codepoint(" ")] = true -- U+2009 thin space

local DISC  = node.id("disc")
local GLYPH = node.id("glyph")
local GLUE  = node.id("glue")
local KERN  = node.id("kern")
local RULE  = node.id("rule")
local HLIST = node.id("hlist")
local VLIST = node.id("vlist")
local LPAR  = node.id("local_par")
local MKERN = node.id("margin_kern")
local PENALTY = node.id("penalty")
local WHATSIT = node.id("whatsit")
local USRSKIP  = 0
local PARSKIP  = 3
local LFTSKIP  = 8
local RGTSKIP  = 9
local TOPSKIP = 10
local PARFILL = 15
local LINE    = 1
local BOX     = 2
local INDENT  = 3
local ALIGN   = 4
local EQN     = 6
local USER = 0
local HYPH = 0x2D
local LIGA = 0x102
local parline = 0
local dimensions = node.dimensions
local rangedimensions = node.rangedimensions
local effective_glue = node.effective_glue
local set_attribute = node.set_attribute
local get_attribute = node.get_attribute
local slide = node.slide
local traverse = node.traverse
local traverse_id = node.traverse_id
local is_glyph  = node.is_glyph
local utf8_len  = utf8.len
local utf8_find = unicode.utf8.find
local utf8_gsub = unicode.utf8.gsub

-- Single characters at end of line:
local string = "A À Á E È É I O Ô U Y"
nvttypo.reqsingle = ""
for p, c in utf8.codes(string) do
  local s = utf8.char(c)
  nvttypo.reqsingle = nvttypo.reqsingle .. s
end

-- Called AtEndDocument. Writes *.typo file:
typowritefile = function ()
  local fileout= tex.jobname .. ".typo"
  local out=io.open(fileout,"w+")
  if nvttypo.buffer == "" then
    out:write(nvttypo.noflawheader)
  else
    out:write(nvttypo.flawheader .. nvttypo.buffer)
  end
  io.close(out)
end

local utf8_reverse = function (s)
  if utf8_len(s) > 1 then
    local so = ""
    for p, c in utf8.codes(s) do
      so = utf8.char(c) .. so
    end
    s = so
  end
  return s
end

local utf8_sub = function (s,i,j)
  i=utf8.offset(s,i)
  j=utf8.offset(s,j+1)-1
  return string.sub(s,i,j)
end

local color_node = function (node, color)
  local attr = oberdiek.luacolor.getattribute()
  if node and node.id == DISC then
    local pre = node.pre
    local post = node.post
    local repl = node.replace
    if pre then set_attribute(pre,attr,color) end
    if post then set_attribute(post,attr,color) end
    if repl then set_attribute(repl,attr,color) end
  elseif node then
    set_attribute(node,attr,color)
  end
end

local color_line = function (head, color)
  local first = head.head
  local color_node_if = function (node, color)
    local c = oberdiek.luacolor.getattribute()
    local att = get_attribute(node,c)
    color_node (node, color)
  end
  for n in traverse(first) do
    if n.id == HLIST or n.id == VLIST then
      local ff = n.head
      for nn in traverse(ff) do
        if nn.id == HLIST or nn.id == VLIST then
          local f3 = nn.head
          for n3 in traverse(f3) do
            if n3.id == HLIST or n3.id == VLIST then
              local f4 = n3.head
              for n4 in traverse(f4) do
                if n4.id == HLIST or n4.id == VLIST then
                  local f5 = n4.head
                  for n5 in traverse(f5) do
                     if n5.id == HLIST or n5.id == VLIST then
                       local f6 = n5.head
                       for n6 in traverse(f6) do
                         color_node_if(n6, color)
                       end
                     else
                       color_node_if(n5, color)
                     end
                   end
                 else
                   color_node_if(n4, color)
                 end
               end
             else
               color_node_if(n3, color)
             end
           end
         else
           color_node_if(nn, color)
         end
       end
     else
       color_node_if(n, color)
     end
  end
end

log_flaw= function (msg, line, colno, footnote)
  local pageno = tex.getcount("c@page")
  local matter = tex.getcount("c@bookmatter")
  local pn = "pg. "
  if matter < 2 then pn = "rm. " end
  prt = pn .. string.format("%3d, ", pageno)
  if colno then prt = prt .. ", col." .. colno end
  if line then
    local l = string.format("%2d: ", line)
    if footnote then
      prt = prt .. "fn " .. l
    else
      prt = prt .. "ln " .. l
    end
  end
  prt =  prt .. msg
  nvttypo.buffer = nvttypo.buffer .. prt .. "\n"
end

local signature = function (node, string, swap)
  local n = node
  local str = string
  if n and n.id == GLYPH then
    local b = n.char
    if b and not char_to_discard[b] then
      if n.components then
        local c = ""
        for nn in traverse_id(GLYPH, n.components) do
          c = c .. utf8.char(nn.char)
        end
        if swap then
          str = str .. utf8_reverse(c)
        else
          str = str .. c
        end
      else
        str = str .. utf8.char(b)
      end
    end
  elseif n and n.id == DISC then
    local pre = n.pre
    local post = n.post
    local c1 = ""
    local c2 = ""
    if pre and pre.char then
      if pre.components then
        for nn in traverse_id(GLYPH, pre.components) do
          c1 = c1 .. utf8.char(nn.char)
        end
      else
        c1 = utf8.char(pre.char)
      end
      c1 = utf8_gsub(c1, "-", "")
    end
    if post and post.char then
      if post.components then
        for nn in traverse_id(GLYPH, post.components) do
          c2 = c2 .. utf8.char(nn.char)
        end
      else
        c2 = utf8.char(post.char)
      end
    end
    if swap then
      str = str .. utf8_reverse(c2) .. c1
    else
      str = str .. c1 .. c2
    end
  elseif n and n.id == GLUE then
    str = str .. "_"
  end
  local s = utf8_gsub(str, "_", "")
  local len = utf8_len(s)
  return len, str
end

local check_line_last_word = function (old, node, line, colno, flag, footnote)
  local match = false
  local new = ""
  local maxlen = 0
  if node then
    local swap = true
    local box, go
    local lastn = node
    while lastn and lastn.id ~= GLYPH and lastn.id ~= DISC and
          lastn.id ~= HLIST
    do
      lastn = lastn.prev
    end
    local n = lastn
    local words = 0
    while n and (words <= 2 or maxlen < MinPart)
    do
      if n and n.id == HLIST then
        box = n
        local first = n.head
        local lastn = slide(first)
        n = lastn
        while n
        do
          maxlen, new = signature (n, new, swap)
          n = n.prev
        end
        n = box.prev
        local w = utf8_gsub(new, "_", "")
        words = words + utf8_len(new) - utf8_len(w) + 1
      else
        repeat
          maxlen, new = signature (n, new, swap)
          n = n.prev
        until not n or n.id == GLUE or n.id == HLIST
        if n and n.id == GLUE then
          maxlen, new = signature (n, new, swap)
          words = words + 1
          n = n.prev
        end
      end
    end
    new = utf8_reverse(new)
    new = utf8_gsub(new, "_+$", "")
    new = utf8_gsub(new, "^_+", "")
    maxlen = math.min(utf8_len(old), utf8_len(new))
    if flag and old ~= "" then
      local oldlast = utf8_gsub (old, ".*_", "")
      local newlast = utf8_gsub (new, ".*_", "")
      local oldsub = ""
      local newsub = ""
      local dlo = utf8_reverse(old)
      local wen = utf8_reverse(new)
      for p, c in utf8.codes(dlo) do
        local s = utf8_gsub(oldsub, "_", "")
        if utf8_len(s) < MinPart then oldsub = utf8.char(c) .. oldsub end
      end
      for p, c in utf8.codes(wen) do
        local s = utf8_gsub(newsub, "_", "")
        if utf8_len(s) < MinPart then newsub = utf8.char(c) .. newsub end
      end
      if oldsub == newsub then match = true end
      if oldlast == newlast and utf8_len(newlast) >= MinFull then
        if utf8_len(newlast) > MinPart or not match then
          oldsub = oldlast
          newsub = newlast
        end
        match = true
      end
      if match then
        local k = utf8_len(newsub)
        local osub = utf8_reverse(oldsub)
        local nsub = utf8_reverse(newsub)
        while osub == nsub and k < maxlen
        do
          k = k + 1
          osub = utf8_sub(dlo,1,k)
          nsub = utf8_sub(wen,1,k)
          if osub == nsub then newsub = utf8_reverse(nsub) end
        end
        newsub = utf8_gsub(newsub, "^_+", "")
        local msg = "  Consecutive lines end with same word = " .. newsub
        log_flaw(msg, line, colno, footnote)
        local ns = utf8_gsub(newsub, "_", "")
        k = utf8_len(ns)
        oldsub = utf8_reverse(newsub)
        local newsub = ""
        local n = lastn
        local l = 0
        local lo = 0
        local li = 0
        while n and newsub ~= oldsub and l < k
        do
          if n and n.id == HLIST then
            local first = n.head
            for nn in traverse_id(GLYPH, first) do
              color_node(nn, TypoColor)
              local c = nn.char
              if not char_to_discard[c] then l = l + 1 end
            end
          elseif n then
            color_node(n, TypoColor)
            li, newsub = signature(n, newsub, swap)
            l = l + li - lo
            lo = li
          end
          n = n.prev
        end
      end
    end
  end
  return new, match
end

local check_line_first_word = function (old, node, line, colno, flag, footnote)
  local match = false
  local swap = false
  local new = ""
  local maxlen = 0
  local n = node
  local box, go
  while n and n.id ~= GLYPH and n.id ~= DISC and
        (n.id ~= HLIST or n.subtype == INDENT)
  do
    n = n.next
  end
  start = n
  local words = 0
  while n and (words <= 2 or maxlen < MinPart)
  do
    if n and n.id == HLIST then
      box = n
      n = n.head
      while n
      do
        maxlen, new = signature (n, new, swap)
        n = n.next
      end
      n = box.next
      local w = utf8_gsub(new, "_", "")
      words = words + utf8_len(new) - utf8_len(w) + 1
    else
      repeat
        maxlen, new = signature (n, new, swap)
        n = n.next
      until not n or n.id == GLUE or n.id == HLIST
      if n and n.id == GLUE then
        maxlen, new = signature (n, new, swap)
        words = words + 1
        n = n.next
      end
    end
  end
  new = utf8_gsub(new, "_+$", "")
  new = utf8_gsub(new, "^_+", "")
  maxlen = math.min(utf8_len(old), utf8_len(new))
  if flag and old ~= "" then
    local oldfirst = utf8_gsub (old, "_.*", "")
    local newfirst = utf8_gsub (new, "_.*", "")
    local oldsub = ""
    local newsub = ""
    for p, c in utf8.codes(old) do
      local s = utf8_gsub(oldsub, "_", "")
      if utf8_len(s) < MinPart then oldsub = oldsub .. utf8.char(c) end
    end
    for p, c in utf8.codes(new) do
      local s = utf8_gsub(newsub, "_", "")
      if utf8_len(s) < MinPart then newsub = newsub .. utf8.char(c) end
    end
    if oldsub == newsub then match = true end
    if oldfirst == newfirst and utf8_len(newfirst) >= MinFull then
      if utf8_len(newfirst) > MinPart or not match then
        oldsub = oldfirst
        newsub = newfirst
      end
       match = true
    end
    if match then
      local k = utf8_len(newsub)
      local osub = oldsub
      local nsub = newsub
      while osub == nsub and k < maxlen
      do
        k = k + 1
        osub = utf8_sub(old,1,k)
        nsub = utf8_sub(new,1,k)
        if osub == nsub then newsub = nsub end
      end
      newsub = utf8_gsub(newsub, "_+$", "")
      local msg = "Consecutive lines begin with same word = " .. newsub
      log_flaw(msg, line, colno, footnote)
      local ns = utf8_gsub(newsub, "_", "")
      k = utf8_len(ns)
      oldsub = newsub
      local newsub = ""
      local n = start
      local l = 0
      local lo = 0
      local li = 0
      while n and newsub ~= oldsub and l < k
      do
        if n and n.id == HLIST then
          local nn = n.head
          for nnn in traverse(nn) do
            color_node(nnn, TypoColor)
            local c = nn.char
            if not char_to_discard[c] then l = l + 1 end
          end
        elseif n then
          color_node(n, TypoColor)
          li, newsub = signature(n, newsub, swap)
          l = l + li - lo
          lo = li
        end
        n = n.next
      end
    end
  end
  return new, match
end

local check_page_first_word = function (node, colno, footnote)
  local match = false
  local swap = false
  local new = ""
  local len = 0
  local n = node
  local pn
  while n and n.id ~= GLYPH and n.id ~= DISC and
        (n.id ~= HLIST or n.subtype == INDENT)
  do
    n = n.next
  end
  local start = n
  if n and n.id == HLIST then
    start = n.head
    n = n.head
  end
  repeat
    len, new = signature (n, new, swap)
    n = n.next
  until len > MinLen or (n and n.id == GLYPH and eow_char[n.char]) or
        (n and n.id == GLUE) or
        (n and n.id == KERN and n.subtype == 1)
  if n and (n.id == GLUE or n.id == KERN) then
    pn = n
    n = n.next
  end
  if len <= MinLen and n and n.id == GLYPH and eow_char[n.char] then
    repeat
      n = n.next
    until not n or n.id == GLYPH or
          (n.id == GLUE and n.subtype == PARFILL)
    if n and n.id == GLYPH then match = true end
  end
  if match then
    local msg = "  Page begins with short word = " .. new
    log_flaw(msg, 1, colno, footnote)
    local n = start
    repeat
      color_node(n, TypoColor)
      n = n.next
    until eow_char[n.char]
    color_node(n, TypoColor)
  end
  return match
end

local check_regexpr = function (glyph, line, colno, footnote)
  local match = false
  local retflag = false
  local lchar, id = is_glyph(glyph)
  local previous = glyph.prev
    if lchar and previous and previous.id == GLUE then
      match = utf8_find(nvttypo.reqsingle, utf8.char(lchar))
      if match then
        retflag = true
        local msg = "One-char word at line end = " .. utf8.char(lchar)
        log_flaw(msg, line, colno, footnote)
        color_node(glyph,TypoColor)
      end
    end
    if lchar and previous and previous.id == GLUE then
      match = utf8_find(nvttypo.single, utf8.char(lchar))
      if match then
        retflag = true
        local msg = "  One-char word at line end = " .. utf8.char(lchar)
        log_flaw(msg, line, colno, footnote)
        color_node(glyph,TypoColor)
      end
    end
    if lchar and previous and previous.id == GLYPH then
      local pchar, id = is_glyph(previous)
      local pprev = previous.prev
      if pchar and pprev and pprev.id == GLUE then
        local pattern = utf8.char(pchar) .. utf8.char(lchar)
        match = utf8_find(nvttypo.double, pattern)
        if match then
          retflag = true
          local msg = "  Two-char word at line end = " .. pattern
          log_flaw(msg, line, colno, footnote)
          color_node(previous,TypoColor)
          color_node(glyph,TypoColor)
        end
        match = utf8_find(nvttypo.doublest, pattern)
        if match then
          retflag = true
          local msg = "    Two-char word at line end = " .. pattern
          log_flaw(msg, line, colno, footnote)
          color_node(previous,TypoColor)
          color_node(glyph,TypoColor)
        end
      end
    elseif lchar and previous and previous.id == KERN then
      local pprev = previous.prev
      if pprev and pprev.id == GLYPH then
        local pchar, id = is_glyph(pprev)
        local ppprev = pprev.prev
        if pchar and ppprev and ppprev.id == GLUE then
          local pattern = utf8.char(pchar) .. utf8.char(lchar)
          match = utf8_find(nvttypo.double, pattern)
          if match then
            retflag = true
            local msg = "  Two-char word at line end = " .. pattern
            log_flaw(msg, line, colno, footnote)
            color_node(pprev,TypoColor)
            color_node(glyph,TypoColor)
          end
          match = utf8_find(nvttypo.doublest, pattern)
          if match then
            retflag = true
            local msg = "    Two-char word at line end = " .. pattern
            log_flaw(msg, line, colno, footnote)
            color_node(pprev,TypoColor)
            color_node(glyph,TypoColor)
          end
        end
      end
    end
  return retflag
end

local show_pre_disc = function (disc, color)
  local n = disc
  while n and n.id ~= GLUE
  do
    color_node(n, color)
    n = n.prev
  end
  return n
end

local footnoterule_ahead = function (head)
  local n = head
  local flag = false
  local totalht, ruleht, ht1, ht2, ht3
  if n and n.id == KERN and n.subtype == 1 then
    totalht = n.kern
    n = n.next
    while n and n.id == GLUE
    do
      n = n.next
    end
    if n and n.id == RULE and n.subtype == 0 then
      ruleht = n.height
      totalht = totalht + ruleht
      n = n.next
      if n and n.id == KERN and n.subtype == 1 then
        totalht = totalht + n.kern
        if totalht == 0 or totalht == ruleht then
          flag = true
        end
      end
    end
  end
  return flag
end

local check_EOP = function (node)
  local n = node
  local page_bot = false
  local body_bot = false
  while n and (n.id == GLUE or n.id == PENALTY or n.id == WHATSIT )
  do
    n = n.next
  end
  if not n then
    page_bot = true
    body_bot = true
  elseif footnoterule_ahead(n) then
    body_bot = true
  end
  return page_bot, body_bot
end

local get_pagebody = function (head)
  local textht = tex.getdimen("textheight")
  local fn = head.list
  local body = nil
  repeat
    fn = fn.next
  until fn.id == VLIST and fn.height > 0
  first = fn.list
  for n in traverse_id(VLIST,first) do
    if n.subtype == 0 and n.height == textht then
      body = n
      break
    else
      first = n.list
      for n in traverse_id(VLIST,first) do
        if n.subtype == 0 and n.height == textht then
          body = n
          break
        end
      end
    end
  end
  if not body then -- there were other errors during compile
    texio.write_nl('*** ERROR: PAGE BODY NOT FOUND! ***')
  end
  return body
end

-- Called by nvttypo.check, then calls the various checks:
check_vtop = function (top, colno, vpos)
  local head = top.list
  local blskip   = tex.getglue("baselineskip")
  local vpos_min = 5 * blskip
  vpos_min = vpos_min * 1.5
  local linewd = tex.getdimen("textwidth")
  local first_bot  = true
  local done       = false
  local footnote   = false
  local ftnsplit   = false
  local orphanflag = false
  local widowflag  = false
  local pageshort  = false
  local overfull   = false
  local underfull  = false
  local shortline  = false
  local backpar    = false
  local firstwd = ""
  local lastwd  = ""
  local hyphcount = 0
  local pageline = 0
  local ftnline = 0
  local line = 0
  local bpmn = 0
  local body_bottom = false
  local page_bottom = false
  local pageflag = false
  local pageno = tex.getcount("c@page")
  while head
  do
    local nextnode = head.next
    if head.id == HLIST and head.subtype == LINE and
         (head.height > 0 or head.depth > 0) then
      vpos = vpos + head.height + head.depth
      done = true
      local linewd = head.width
      local first = head.head
      local ListItem = false
      if footnote then
        ftnline = ftnline + 1
        line = ftnline
      else
        pageline = pageline + 1
        line = pageline
      end
      page_bottom, body_bottom = check_EOP(nextnode)
      local hmax = linewd + tex.hfuzz
      local w,h,d = dimensions(1,2,0, first)
      if w > hmax then
        pageflag = true
        overfull = true
        local wpt = string.format("%.2fpt", (w-head.width)/65536)
        local msg = "Overfull line (badbox) = " .. wpt
        log_flaw(msg, line, colno, footnote)
      elseif head.glue_set > 1.06 and head.glue_sign == 1 and
             head.glue_order == 0 then
        pageflag = true
        underfull = true
        local s = string.format("%.0f%s", 100*head.glue_set, "%")
        local msg = "Excessive line stretch = " .. s
        log_flaw(msg, line, colno, footnote)
      elseif head.glue_set > 1.04 and head.glue_sign == 1 and
             head.glue_order == 0 then
        pageflag = true
        underfull = true
        local s = string.format("%.0f%s", 100*head.glue_set, "%")
        local msg = "  Excessive line stretch = " .. s
        log_flaw(msg, line, colno, footnote)
      end
      if footnote and page_bottom then ftnsplit = true end
      while first.id == MKERN or
            (first.id == GLUE and first.subtype == LFTSKIP)
      do
        first = first.next
      end
      if first.id == LPAR then
        hyphcount = 0
        firstwd = ""
        lastwd = ""
        if not footnote then
          parline = 1
          if body_bottom then orphanflag = true end
        end
        local nn = first.next
        if nn and nn.id == HLIST and nn.subtype == BOX then
          ListItem = true
        end
      elseif not footnote then
        parline = parline + 1
      end
      local flag = not ListItem and (line > 1)
      firstwd, flag =
          check_line_first_word(firstwd, first, line, colno, flag, footnote)
      if flag then pageflag = true end
      if pageline == 1 and parline > 1 and
           check_page_first_word(first, colno, footnote) then
        pageflag = true
      end
      local ln = slide(first)
      if ln.id == RULE and ln.subtype == 0 then ln = ln.prev end
      local pn = ln.prev
      if pn and pn.id == GLUE and pn.subtype == PARFILL then
        hyphcount = 0
        ftnsplit = false
        orphanflag = false
        if pageline == 1 and parline > 1 then widowflag = true end
        local PFskip = effective_glue(pn,head)
        local llwd = linewd - PFskip
        if llwd < LLminWD and llwd > 1 then
          pageflag = true
          shortline = true
          local msg = "Short last line of paragraph = " ..
                      string.format("%.2fem", llwd/emsize)
          log_flaw(msg, line, colno, footnote)
        end
        if PFskip < BackPI and PFskip >= BackFuzz and parline > 1 then
          pageflag = true
          backpar = true
          local msg = "  Nearly full last line of paragraph = " ..
                      string.format("%.2fem", PFskip/emsize)
          log_flaw(msg, line, colno, footnote)
        end
        local flag = true
        if PFskip > BackPI or line == 1 then flag = false end
        local pnp = pn.prev
        lastwd, flag =
            check_line_last_word(lastwd, pnp, line, colno, flag, footnote)
        if flag then pageflag = true end
      elseif pn and pn.id == DISC then
        hyphcount = hyphcount + 1
        if hyphcount > 1 then
          local pg = show_pre_disc (pn,TypoColor)
          pageflag = true
          local msg = "Consecutive hyphens, more than " .. 1 .. " = "
          log_flaw(msg, line, colno, footnote)
        end
        if (page_bottom or body_bottom) then
          pageflag = true
          local msg = "Page ends with hyphenation = "
          log_flaw(msg, line, colno, footnote)
          local pg = show_pre_disc (pn,TypoColor)
        end
        local flag = true
        lastwd, flag =
             check_line_last_word(lastwd, pn, line, colno, flag, footnote)
        if flag then pageflag = true end
        if nextnode then
          local nn = nextnode.next
          local nnn = nil
          if nn and nn.next then
            nnn = nn.next
            if nnn.id == HLIST and nnn.subtype == LINE and
                  nnn.glue_order == 2 then
              pageflag = true
              local msg = "Paragraph ends with hyphenation = "
              log_flaw(msg, line, colno, footnote)
              local pg = show_pre_disc (pn,TypoColor)
            end
          end
        end
      else
        hyphcount = 0
        if pn then
          local flag = true
          lastwd, flag =
                check_line_last_word(lastwd, pn, line, colno, flag, footnote)
          if flag then pageflag = true end
        end
        while pn and pn.id ~= GLYPH and pn.id ~= HLIST
        do
          pn = pn.prev
        end
        if pn and pn.id == GLYPH then
          if check_regexpr(pn, line, colno, footnote) then
            pageflag = true
          end
        end
      end
      if widowflag then
        pageflag = true
        local msg = "Widow (isolated first line on page)"
        log_flaw(msg, line, colno, footnote)
        if backpar or shortline or overfull or underfull then
          if backpar then backpar = false end
          if shortline then shortline = false end
          if overfull then overfull = false end
          if underfull then underfull = false end
        end
        color_line (head, TypoColor)
        widowflag = false
      elseif orphanflag then
        pageflag = true
        local msg = "  Orphan (isolated last line on page)"
        log_flaw(msg, line, colno, footnote)
        color_line (head, TypoColor)
      elseif ftnsplit then
        pageflag = true
        local msg = "Footnote split across pages = "
        log_flaw(msg, line, colno, footnote)
        color_line (head, TypoColor)
      elseif shortline then
        color_line (head, TypoColor)
        shortline = false
      elseif overfull then
        color_line (head, TypoColor)
        overfull = false
      elseif underfull then
        color_line (head, TypoColor)
        underfull = false
      elseif backpar then
        color_line (head, TypoColor)
        backpar = false
      end
    elseif head and head.id == HLIST and head.subtype == BOX
           and head.width > 0 then
      if head.height ~= 0 then
        local hf = head.list
        if hf and hf.id == VLIST and hf.subtype == 0 then
          break
        else
          vpos = vpos + head.height + head.depth
          pageline = pageline + 1
          line = pageline
          page_bottom, body_bottom = check_EOP (nextnode)
        end
      end
    elseif head.id == HLIST and
           (head.subtype == EQN or head.subtype == ALIGN) and
           (head.height > 0 or head.depth > 0) then
      vpos = vpos + head.height + head.depth
      if footnote then
        ftnline = ftnline + 1
        line = ftnline
      else
        pageline = pageline + 1
        line = pageline
      end
      page_bottom, body_bottom = check_EOP (nextnode)
      local fl = true
      local wd = 0
      local hmax = 0
      if head.subtype == EQN then -- equation? hah!
        local f = head.list
        wd = rangedimensions(head,f)
        hmax = head.width + tex.hfuzz
      else
        wd = head.width
        hmax = tex.getdimen("linewidth") + tex.hfuzz
      end
      if wd > hmax then
        if head.subtype == ALIGN then
          local first = head.list
          for n in traverse_id(HLIST, first) do
            local last = slide(n.list)
            if last.id == GLUE and last.subtype == USER
            then
              wd = wd - effective_glue(last,n)
              if wd <= hmax then fl = false end
            end
          end
        end
        if fl then
          pageflag = true
          local w = wd - hmax + tex.hfuzz
          local wpt = string.format("%.2fpt", w/65536)
          local msg = "Overfull equation = " .. wpt -- equation ?! bah.
          log_flaw(msg, line, colno, footnote)
          color_line (head, TypoColor)
        end
      end
    elseif head and head.id == RULE and head.subtype == 0 then
      vpos = vpos + head.height + head.depth
      local prev = head.prev
      if body_bottom or footnoterule_ahead (prev) then
        footnote = true
        ftnline = 0
        body_bottom = false
        orphanflag = false
        hyphcount = 0
        firstwd = ""
        lastwd = ""
      end
    elseif body_bottom and head.id == GLUE and head.subtype == 0 then
      if first_bot then
        if pageline > 1 and pageline < 3 and vpos < vpos_min then
          pageshort = true
          pageflag = true
          local msg = "Short page: only " .. pageline .. " lines = "
          log_flaw(msg, line, colno, footnote)
          local n = head
          repeat
            n = n.prev
          until n.id == HLIST
          color_line (n, TypoColor)
        end
        if pageline > 2 and pageline < 5 and vpos < vpos_min then
          pageshort = true
          pageflag = true
          local msg = "  Short page: only " .. pageline .. " lines = "
          log_flaw(msg, line, colno, footnote)
          local n = head
          repeat
            n = n.prev
          until n.id == HLIST
          color_line (n, TypoColor)
        end
        first_bot = false
      end
    elseif head.id == GLUE then
      vpos = vpos + effective_glue(head,top)
    elseif head.id == KERN and head.subtype == 1 then
      vpos = vpos + head.kern
    elseif head.id == VLIST then
      vpos = vpos + head.height + head.depth
    end
  head = nextnode
  end
  if pageflag then
    local plist = nvttypo.pagelist
    local lastp = tonumber(string.match(plist, "%s(%d+),%s$"))
    if not lastp or pageno > lastp then
      nvttypo.pagelist = nvttypo.pagelist .. tostring(pageno) .. ", "
    end
  end
  return head, done
end

-- The master function that calls check_vtop:
nvttypo.check = function (head)
  local textwd = tex.getdimen("textwidth")
  local textht = tex.getdimen("textheight")
  local checked, boxed, n2, n3, col, colno
  local body = get_pagebody(head)
  local pageno = tex.getcount("c@page")
  local vpos = 0
  local footnote = false
  local top = body
  local first = body.list
  local next
  local count = 0
  if ((first and first.id == HLIST and first.subtype == BOX) or
       (first and first.id == VLIST and first.subtype == 0))      and
       (first.width == textwd and first.height > 0 and not boxed) then
    top = body.list
    if first.id == VLIST then boxed = body end
  end
  while top
  do
    first = top.list
    next = top.next
    if top and top.id == VLIST and top.subtype == 0 and
           top.width > textwd/2 then
      local n, ok = check_vtop(top,colno,vpos)
      if ok then checked = true end
      if n then next = n end
    elseif (top and top.id == HLIST and top.subtype == BOX) and
           (first and first.id == VLIST and first.subtype == 0) and
           (first.height > 0 and first.width > 0) then
      colno = 0
      for col in traverse_id(VLIST, first) do
        colno = colno + 1
        local n, ok = check_vtop(col,colno,vpos)
        if ok then checked = true end
      end
      colno = nil
      top = top.next
    elseif (top and top.id == HLIST and top.subtype == BOX) and
           (first and first.id == HLIST and first.subtype == BOX) and
           (first.height > 0 and first.width > 0) then
      colno = 0
      for n in traverse_id(HLIST, first) do
        colno = colno + 1
        local col = n.list
        if col and col.list then
          local n, ok = check_vtop(col,colno,vpos)
          if ok then checked = true end
        end
      end
      colno = nil
    end
    if boxed and not next then
      next = boxed
      boxed = nil
    end
    top = next
  end
  if not checked then
    nvttypo.failedlist = nvttypo.failedlist .. tostring(pageno) .. ", "
  end
  return true
end

-- Tells TeX to run this:
return nvttypo.check


-- End of file `novelette-typo.lua'.
