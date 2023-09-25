--
-- File novelette-frpunct.lua
-- Shamelessly copied and modified from files in polyglossia v1.60.
-- Author of polyglossia is not responsible for these code hacks.
-- Original polyglossia files, license CC0.
--
-- This file may be distributed and/or modified under the
-- conditions of the LaTeX Project Public License, version 1.3c.
--
-- The polyglossia package does many things, as does babel.
-- Nearly all of those things are irrelevant in Novelette.
-- To keep it simple, and focus on what is really needed, this file is used
-- only when extra punctuation space is needed for french or swiss french.
--

local module_name = "nvtfrpunct"
local nvtfrpunct_module = {
    name          = module_name,
    version       = 0.16, -- Based on polyglossia 1.3. 
    date          = "2023/09/24",
    description   = "nvtfrpunct",
    author        = "Elie Roux", -- Shameless modifications by Robert Allgeyer.
    copyright     = "Elie Roux",
    license       = "CC0" -- Modifications LPPL 1.3c.
}

luatexbase.provides_module(nvtfrpunct_module)

local log_info = function(message, ...)
    luatexbase.module_info(module_name, message:format(...))
end
local log_warn = function(message, ...)
    luatexbase.module_warning(module_name, message:format(...))
end

nvtfrpunct = nvtfrpunct or {}
local nvtfrpunct = nvtfrpunct

-- from luatexbase.sty
function luatexbase.priority_in_callback (name,description)
  for i,v in ipairs(luatexbase.callback_descriptions(name))
  do
    if v == description then
      return i
    end
  end
  return false
end

local add_to_callback      = luatexbase.add_to_callback
local remove_from_callback = luatexbase.remove_from_callback
local priority_in_callback = luatexbase.priority_in_callback
local new_attribute        = luatexbase.new_attribute

local node = node

local insert_node_before = node.insert_before
local insert_node_after  = node.insert_after
local remove_node        = node.remove
local has_attribute      = node.has_attribute
local node_copy          = node.copy
local new_node           = node.new
local getnext            = node.getnext
local getprev            = node.getprev

local glue_code    = node.id"glue"
local glyph_code   = node.id"glyph"
local penalty_code = node.id"penalty"
local kern_code    = node.id"kern"

local userkern = 1
local userskip = 0
local removable_skip = {
    [0]  = true, -- userskip
    [13] = true, -- spaceskip
    [14] = true, -- xspaceskip
}

local kern_node = new_node(kern_code)
kern_node.subtype = userkern

local function get_kern_node(dim)
    local n = node_copy(kern_node)
    n.kern = dim
    return n
end

local glue_node = new_node(glue_code)
glue_node.subtype = userskip

local function get_glue_node(dim, stretch, shrink)
    local n   = node_copy(glue_node)
    n.width   = dim
    n.stretch = stretch
    n.shrink  = shrink
    return n
end

local penalty_node   = new_node(penalty_code)
penalty_node.penalty = 10000

local function get_penalty_node()
    return node_copy(penalty_node)
end

local space_chars = {
    [0x20] = true, -- space
    [0xA0] = true, -- no-break space
    [0x2000] = true, -- en quad
    [0x2001] = true, -- em quad
    [0x2002] = true, -- en space
    [0x2003] = true, -- em space
    [0x2004] = true, -- three-per-em-space
    [0x2005] = true, -- four-per-em space
    [0x2006] = true, -- six-per-em space
    [0x2007] = true, -- figure space
    [0x2008] = true, -- punctuation space
    [0x2009] = true, -- thin space
    [0x200A] = true, -- hair space
    [0x202F] = true, -- narrow no-break space
}

local left_bracket_chars = {
    [0x28] = true, -- left parenthesis
    [0x5B] = true, -- left square bracket
    [0x7B] = true, -- left curly bracket
}

local right_bracket_chars = {
    [0x29] = true,  -- right parenthesis
    [0x5D] = true,  -- right square bracket
    [0x7D] = true,  -- right curly bracket
}

local question_exclamation_chars = {
    [0x21] = true,   -- exclamation mark !
    [0x3F] = true,   -- question mark ?
}

-- from nodes-tst.lua, adapted
local function somespace(n)
    if n then
        local id, subtype = n.id, n.subtype
        if id == glue_code then
            return removable_skip[subtype]
        elseif id == kern_code then
            return subtype == userkern
        elseif id == glyph_code then
            return space_chars[n.char]
        end
    end
end

local function someleftbracket(n)
    if n then
        local id = n.id
        if id == glyph_code then
            return left_bracket_chars[n.char]
        end
    end
end

local function somerightbracket(n)
    if n then
        local id = n.id
        if id == glyph_code then
            return right_bracket_chars[n.char]
        end
    end
end

local function question_exclamation_sequence(n1, n2)
    if n1 and n2 then
        local id1 = n1.id
        local id2 = n2.id
        if id1 == glyph_code and id2 == glyph_code then
            return question_exclamation_chars[n1.char] and question_exclamation_chars[n2.char]
        end
    end
end

-- idem
local function somepenalty(n, value)
    if n then
        local id = n.id
        if id == penalty_code then
            if value then
                return n.penalty == value
            else
                return true
            end
        end
    end
end

local punct_attr = new_attribute("nvtfrpunct_punct")

local lang_id      = {}
local lang_counter = 0
local left_space   = {}
local right_space  = {}

local function ensure_lang_id(lang)
    if not lang_id[lang] then
        lang_counter = lang_counter + 1
        lang_id[lang] = lang_counter
    end
    return lang_id[lang]
end

local function clear_spaced_characters(lang)
    local id = ensure_lang_id(lang)
    left_space[id]  = {}
    right_space[id] = {}
end

local function illegal_unit(unit)
    if unit then
        texio.write_nl('Illegal spacing unit "'..unit..'".')
    else
        texio.write_nl('Spacing unit is a nil value.')
    end
end

local function add_left_spaced_character(lang, char, kern, unit, rubber)
    local id = ensure_lang_id(lang)
    if unit == "quad" or unit == "space" then
        left_space[id][char] = {}
        left_space[id][char]["kern"] = kern
        left_space[id][char]["unit"] = unit
        left_space[id][char]["rubber"] = rubber
    else
        illegal_unit(unit)
    end
end

local function add_right_spaced_character(lang, char, kern, unit, rubber)
    local id = ensure_lang_id(lang)
    if unit == "quad" or unit == "space" then
        right_space[id][char] = {}
        right_space[id][char]["kern"] = kern
        right_space[id][char]["unit"] = unit
        right_space[id][char]["rubber"] = rubber
    else
        illegal_unit(unit)
    end
end

-- from typo-spa.lua, adapted
local function process(head)
    local current = head
    while current do
        local id = current.id
        if id == glyph_code then
            local attr = has_attribute(current, punct_attr)
            if attr then
                local char, leftspace, rightspace
                if current.char <= 0x10FFFF then
                    char = utf8.char(current.char)
                    leftspace  = left_space[attr][char]
                    rightspace = right_space[attr][char]
                end
                if leftspace or rightspace then
                    local fontparameters = fonts.hashes.parameters[current.font]
                    local unit, stretch, shrink, spacing_node
                    if leftspace and fontparameters then
                        local prev = getprev(current)
                        local space_exception = false
                        if prev then
                            space_exception = someleftbracket(prev) or question_exclamation_sequence(prev, current)
                            while somespace(prev) do
                                head = remove_node(head, prev)
                                prev = getprev(current)
                            end
                            if somepenalty(prev, 10000) then
                                head = remove_node(head, prev)
                            end
                        end
                        if leftspace.unit == "quad" then
                            unit = fontparameters.quad
                            spacing_node = get_kern_node(leftspace.kern*unit)
                        elseif leftspace.unit == "space" then
                            unit = fontparameters.space
                            if leftspace.rubber then
                                stretch = leftspace.kern*fontparameters.space_stretch
                                shrink  = leftspace.kern*fontparameters.space_shrink
                                spacing_node = get_glue_node(leftspace.kern*unit, stretch, shrink)
                                head = insert_node_before(head, current, get_penalty_node())
                            else
                                spacing_node = get_kern_node(leftspace.kern*unit)
                            end
                        end
                        if not space_exception then
                            head = insert_node_before(head, current, spacing_node)
                        end
                    end
                    if rightspace and fontparameters then
                        local next = getnext(current)
                        local space_exception = false
                        if next then
                            space_exception = somerightbracket(next)
                            local nextnext = getnext(next)
                            if somepenalty(next, 10000) and somespace(nextnext) then
                                head, next = remove_node(head, next)
                            end
                            while somespace(next) do
                                head, next = remove_node(head, next)
                            end
                        end
                        if rightspace.unit == "quad" then
                            unit = fontparameters.quad
                            spacing_node = get_kern_node(rightspace.kern*unit)
                        elseif rightspace.unit == "space" then
                            unit = fontparameters.space
                            if rightspace.rubber then
                                stretch = rightspace.kern*fontparameters.space_stretch
                                shrink  = rightspace.kern*fontparameters.space_shrink
                                spacing_node = get_glue_node(rightspace.kern*unit, stretch, shrink)
                                if not space_exception then
                                    head, current = insert_node_after(head, current, get_penalty_node())
                                end
                            else
                                spacing_node = get_kern_node(rightspace.kern*unit)
                            end
                        end
                        if not space_exception then
                            head, current = insert_node_after(head, current, spacing_node)
                        end
                    end
                end
            end
        end
        current = getnext(current)
    end
    return head
end

local function activate(lang)
    local id = ensure_lang_id(lang)
    tex.setattribute(punct_attr, id)
    for _, callback_name in ipairs{ "pre_linebreak_filter", "hpack_filter" } do
        if not priority_in_callback(callback_name, "nvtfrpunct.process") then
            add_to_callback(callback_name, process, "nvtfrpunct.process", 1)
        end
    end
end

local function deactivate()
    tex.setattribute(punct_attr, -0x7FFFFFFF)
    if priority_in_callback(callback_name, "nvtfrpunct.process") then
         remove_from_callback(callback_name, "nvtfrpunct.process")
    end
end

nvtfrpunct.activate_punct             = activate
nvtfrpunct.deactivate_punct           = deactivate
nvtfrpunct.add_left_spaced_character  = add_left_spaced_character
nvtfrpunct.add_right_spaced_character = add_right_spaced_character
nvtfrpunct.clear_spaced_characters    = clear_spaced_characters

local function set_left_space(lang, char, kern, rubber)
    nvtfrpunct.add_left_spaced_character(lang, char, kern, "space", rubber)
end

local function set_right_space(lang, char, kern, rubber)
    nvtfrpunct.add_right_spaced_character(lang, char, kern, "space", rubber)
end

local function activate_french_punct(thincolonspace, autospaceguillemets)
    local lang = "french"
    if thincolonspace then
        lang = lang.."-thincolon"
    end
    if autospaceguillemets then
        lang = lang.."-autospace"
    end

    nvtfrpunct.activate_punct(lang)
    nvtfrpunct.clear_spaced_characters(lang)

    if thincolonspace then
        set_left_space(lang, ':', 0.5)
    else
        set_left_space(lang, ':', 1, true)
    end

    set_left_space(lang, '!', 0.5)
    set_left_space(lang, '?', 0.5)
    set_left_space(lang, ';', 0.5)

    if autospaceguillemets then
        set_left_space(lang, '»', 0.5)
        set_left_space(lang, '›', 0.5)
        set_right_space(lang, '«', 0.5)
        set_right_space(lang, '‹', 0.5)
    end
end

local function deactivate_french_punct()
    nvtfrpunct.deactivate_punct()
end

nvtfrpunct.activate_french_punct   = activate_french_punct
nvtfrpunct.deactivate_french_punct = deactivate_french_punct

-- End of file `novelette-frpunct.lua'.
