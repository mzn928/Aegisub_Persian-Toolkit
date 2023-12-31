-- Special thanks to Majid110 for inspiring us the great feature of RTL Editor.
-- https://github.com/Majid110/MasafAutomation
-- Special thanks to lyger for writing the base of an excelent splitter
-- https://github.com/lyger/Aegisub_automation_scripts

-- Authers of each section:
-- PakNevis: SSgumS
-- Extend Move: SSgumS
-- RTL: Shinsekai_Yuri & SSgumS
-- Un-RTL: Shinsekai_Yuri & SSgumS
-- Unretard: SSgumS & MD
-- RTL Editor: Majid Shamkhani (Edited by SSgumS)
-- Split at Tags: SSgumS (based on lyger's Split at Tags)

----- Global Dependencies -----
include('karaskel.lua')

local utf8 = require 'AL.utf8':init()
local re = require 'aegisub.re'

----- Script Info -----
script_name = 'AnimeList Persian Toolkit'
script_description = 'A toolkit for easier persian fansubbing.'
script_author = 'AnimeList Team'
script_version = '1.3.1'

----- Script Names -----
local paknevis_script_name = 'AL Persian Toolkit/PakNevis'
local extend_move_script_name = 'AL Persian Toolkit/Extend Move'
local rtl_script_name = 'AL Persian Toolkit/RTL/RTL'
local rtlwo_reverse_script_name = 'AL Persian Toolkit/RTL/RTL (wo Reverse)'
local unrtl_script_name = 'AL Persian Toolkit/RTL/Un-RTL'
local unretard_script_name = 'AL Persian Toolkit/Unretard'
local rtleditor_script_name = 'AL Persian Toolkit/RTL Editor'
local split_at_tags_script_name = 'AL Persian Toolkit/Split/Split at Tags'
local split_at_spaces_script_name = 'AL Persian Toolkit/Split/Split at Spaces'
local reverse_split_at_tags_script_name = 'AL Persian Toolkit/Split/Reverse + Split (at Tags)'
local reverse_at_tags_script_name = 'AL Persian Toolkit/Split/Reverse at Tags'

----- Global Variables -----
LRM = utf8.char(0x200E)
RLE = utf8.char(0x202B)
RLM = utf8.char(0x200F)
PDF = utf8.char(0x202C)
subtitles = nil

----- Global Functions -----
function removeRTLChars(text)
    text = re.sub(text, LRM, "")
    text = re.sub(text, RLE, "")
    text = re.sub(text, RLM, "")
    text = re.sub(text, PDF, "")
    return text
end

local function serializeTable(val, name, skipnewlines, depth)
    skipnewlines = skipnewlines or false
    depth = depth or 0

    local tmp = string.rep(" ", depth)

    if name then tmp = tmp .. name .. " = " end

    if type(val) == "table" then
        tmp = tmp .. "{" .. (not skipnewlines and "\n" or "")

        for k, v in pairs(val) do
            tmp = tmp .. serializeTable(v, k, skipnewlines, depth + 1) .. "," .. (not skipnewlines and "\n" or "")
        end

        tmp = tmp .. string.rep(" ", depth) .. "}"
    elseif type(val) == "number" then
        tmp = tmp .. tostring(val)
    elseif type(val) == "string" then
        tmp = tmp .. string.format("%q", val)
    elseif type(val) == "boolean" then
        tmp = tmp .. (val and "true" or "false")
    else
        tmp = tmp .. "\"[inserializeable datatype:" .. type(val) .. "]\""
    end

    return tmp
end

local function has_value(tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end

local function difference(a, b)
    local aa = {}
    for k, v in pairs(a) do aa[k] = v end
    for k, v in pairs(b) do
        if aa[k] == v then
            aa[k] = nil
        end
    end
    local ret = {}
    for k, v in pairs(aa) do -- skips nil
        ret[k] = v
    end
    return ret
end

-- source: https://github.com/unanimated/luaegisub/blob/master/ua.Relocator.lua#L2555
local function round(n, dec)
    dec = dec or 0
    n = math.floor(n * 10 ^ dec + 0.5) / 10 ^ dec
    return n
end

----- PakNevis -----
function PakNevis(subtitles, selected_lines, active_line)
    -- local translation_src = ' كي“”0123456789?⸮,’‘ﺑﺗﺛﺟﺣﺧﺳﺷﺻﺿﻃﻇﻋﻏﻓﻗﻛﻟﻣﻧﻫﻳﺋﺍﺏﺕﺙﺝﺡﺥﺩﺫﺭﺯﺱﺵﺹﺽﻁﻅﻉﻍﻑﻕﻙﻝﻡﻥﻩﻭﻱﺁﺃﺅﺇﺉˈﯿٱھ《》'
    -- local translation_dst = ' کی""۰۱۲۳۴۵۶۷۸۹؟؟،\'\'بتثجحخسشصضطظعغفقکلمنهیئابتثجحخدذرزسشصضطظعغفقکلمنهویآأؤإئ\'یاه«»'
    local persian_alphabets = 'ابپتثجچحخدذرزژسشصضطظعغفقکگلمنوهی'
    local persian_digits = '۰۱۲۳۴۵۶۷۸۹'
    local english_digits = '0123456789'
    local punc_after = '%.:!،؛؟»%]%)'
    local punc_before = '«%[%('

    for z, i in ipairs(selected_lines) do
        local line = subtitles[i]
        -- translation
        -- for j = 0, translation_src:len() do
        --     line.text = utf8.gsub(line.text, '(?!{)(?=[^}])*'..utf8.sub(translation_src, j, j)..'', utf8.sub(translation_dst, j, j))
        -- end
        -- line.text = utf8.gsub(line.text, '%%', '٪')
        -- character refinement patterns
        line.text = utf8.gsub(line.text, ' +', ' ') -- remove extra spaces
        line.text = utf8.gsub(line.text, '‌+', '‌') -- remove extra zwnj
        line.text = utf8.gsub(line.text, '"([^"]+)"', '«%1»') -- replace quotation with gyoome
        line.text = utf8.gsub(line.text, 'ﻻ', 'لا') -- replace لا
        line.text = utf8.gsub(line.text, '： ', ': ') -- replace full-width colon
        line.text = utf8.gsub(line.text, '：', ': ') -- replace full-width colon
        line.text = utf8.gsub(line.text, '-+', '-') -- remove extra -
        -- line.text = utf8.gsub(line.text, '-(\\[Nn])', '–%1') -- replace ending - with –
        -- line.text = utf8.gsub(line.text, '-$', '–') -- replace ending - with –
        -- punctuation spacing patterns
        line.text = utf8.gsub(line.text, ' ([' .. punc_after .. '])', '%1') -- remove space before
        line.text = utf8.gsub(line.text, '([' .. punc_before .. ']) ', '%1') -- remove space after
        line.text = utf8.gsub(line.text, '([^%d' .. persian_digits .. ']%.)([^ ' .. punc_after .. '])', '%1 %2') -- put space after .
        line.text = utf8.gsub(line.text, '([%d' .. persian_digits .. ']%.)([^ %d' .. persian_digits .. punc_after .. '])'
        , '%1 %2') -- put space after .
        line.text = utf8.gsub(line.text, '([' .. punc_after:sub(3) .. '])([^ ' .. punc_after .. '])', '%1 %2') -- put space after
        line.text = utf8.gsub(line.text, '([^ ' .. punc_before .. '])([' .. punc_before .. '])', '%1 %2') -- put space before
        -- affix spacing patterns
        line.text = utf8.gsub(line.text, '([^ ]ه) ی ', '%1‌ی ') -- fix ی space
        line.text = utf8.gsub(line.text, ' (ن?می) ', ' %1‌') -- put zwnj after می, نمی
        line.text = utf8.gsub(line.text, '^(ن?می) ', '%1‌') -- put zwnj after می, نمی
        line.text = utf8.gsub(line.text,
            '([' .. persian_alphabets .. '][' .. persian_alphabets .. ']) (های?)([^' .. persian_alphabets .. '])',
            '%1‌%2%3') -- put zwnj before تر, تری, ترین, گر, گری, ها, های
        line.text = utf8.gsub(line.text,
            '([' .. persian_alphabets .. '][' .. persian_alphabets .. ']) (گری?)([^' .. persian_alphabets .. '])',
            '%1‌%2%3') -- put zwnj before تر, تری, ترین, گر, گری, ها, های
        line.text = utf8.gsub(line.text,
            '([' .. persian_alphabets .. '][' .. persian_alphabets .. ']) (تری?ن?)([^' .. persian_alphabets .. '])',
            '%1‌%2%3') -- put zwnj before تر, تری, ترین, گر, گری, ها, های
        line.text = utf8.gsub(line.text, '([' .. persian_alphabets .. '][' .. persian_alphabets .. ']) (های?)$',
            '%1‌%2') -- put zwnj before تر, تری, ترین, گر, گری, ها, های
        line.text = utf8.gsub(line.text, '([' .. persian_alphabets .. '][' .. persian_alphabets .. ']) (گری?)$',
            '%1‌%2') -- put zwnj before تر, تری, ترین, گر, گری, ها, های
        line.text = utf8.gsub(line.text, '([' .. persian_alphabets .. '][' .. persian_alphabets .. ']) (تری?ن?)$',
            '%1‌%2') -- put zwnj before تر, تری, ترین, گر, گری, ها, های
        line.text = utf8.gsub(line.text, '([^ ]ه) (ا[میشنت][مد]?)([^' .. persian_alphabets .. '])', '%1‌%2%3') -- join ام, ایم, اش, اند, ای, اید, ات
        line.text = utf8.gsub(line.text, '([^ ]ه) (ا[میشنت][مد]?)$', '%1‌%2') -- join ام, ایم, اش, اند, ای, اید, ات
        subtitles[i] = line
    end
    aegisub.set_undo_point(paknevis_script_name)
end

----- Unretard -----
function Unretard(subtitles, selected_lines, active_line)
    local ending_punc = '%.:!،«%[%(- '
    local starting_punc = '»%]%)- '

    local function replace(original_text, text, search_pattern, replace_pattern)
        local match = utf8.gmatch
        if '^' == string.sub(search_pattern, 0, 1) then
            match = function(str, pattern)
                return function()
                    return utf8.match(str, pattern)
                end
            end
        end
        for m in match(original_text, search_pattern) do
            local puncs = utf8.reverse(m)
            puncs = utf8.gsub(puncs, '«', 't2')
            puncs = utf8.gsub(puncs, '»', 't1')
            puncs = utf8.gsub(puncs, 't2', '»')
            puncs = utf8.gsub(puncs, 't1', '«')
            puncs = utf8.gsub(puncs, '%(', 't2')
            puncs = utf8.gsub(puncs, '%)', 't1')
            puncs = utf8.gsub(puncs, 't2', '%)')
            puncs = utf8.gsub(puncs, 't1', '%(')
            puncs = utf8.gsub(puncs, '%[', 't2')
            puncs = utf8.gsub(puncs, '%]', 't1')
            puncs = utf8.gsub(puncs, 't2', '%]')
            puncs = utf8.gsub(puncs, 't1', '%[')
            text = utf8.gsub(text, replace_pattern, puncs, 1)
            if '^' == string.sub(search_pattern, 0, 1) then
                break
            end
        end
        return text
    end

    for z, i in ipairs(selected_lines) do
        local line = subtitles[i]

        -- trim
        line.text = utf8.gsub(line.text, '^ *([^\\]+) *$', '%1')
        line.text = utf8.gsub(line.text, '^ *([^\\]+) *(\\[Nn])', '%1%2')
        line.text = utf8.gsub(line.text, '^(\\[Nn]) *([^\\]+) *(\\[Nn])', '%1%2%3')
        line.text = utf8.gsub(line.text, '^(\\[Nn]) *([^\\]+) *$', '%1%2')

        if utf8.match(line.text, '%{') == nil then
            -- unretard
            -- find
            local linetext_copy = line.text
            line.text = utf8.gsub(line.text, '^([' .. ending_punc .. ']+)([^\\]+)$', '%2gce')                            -- ending puncs
            line.text = utf8.gsub(line.text, '^([' .. ending_punc .. ']+)([^\\]+)(\\[Nn])', '%2gce%3')                   -- ending puncs
            line.text = utf8.gsub(line.text, '(\\[Nn])([' .. ending_punc .. ']+)([^\\]+)(\\[Nn])', '%1%3gce%4')          -- ending puncs
            line.text = utf8.gsub(line.text, '(\\[Nn])([' .. ending_punc .. ']+)([^\\]+)$', '%1%3gce')                   -- ending puncs
            line.text = utf8.gsub(line.text, '^([^\\]+[^' .. starting_punc .. '])([' .. starting_punc .. ']+)(g?c?e?)$',
                'gcs%1%3')                                                                                               -- starting puncs
            line.text = utf8.gsub(line.text, '^([^\\]+[^' .. starting_punc ..
                '])([' .. starting_punc .. ']+)(g?c?e?)(\\[Nn])', 'gcs%1%3%4')                                           -- starting puncs
            line.text = utf8.gsub(line.text,
                '(\\[Nn])([^\\]+[^' .. starting_punc .. '])([' .. starting_punc .. ']+)(g?c?e?)(\\[Nn])', '%1gcs%2%4%5') -- starting puncs
            line.text = utf8.gsub(line.text, '(\\[Nn])([^\\]+[^' .. starting_punc ..
                '])([' .. starting_punc .. ']+)(g?c?e?)$', '%1gcs%2%3')                                                  -- starting puncs
            -- replace
            line.text = replace(linetext_copy, line.text, '^([' .. ending_punc .. ']+)[^\\]+$', 'gce')
            line.text = replace(linetext_copy, line.text, '^([' .. ending_punc .. ']+)[^\\]+\\[Nn]', 'gce')
            line.text = replace(linetext_copy, line.text, '\\[Nn]([' .. ending_punc .. ']+)[^\\]+\\[Nn]', 'gce')
            line.text = replace(linetext_copy, line.text, '\\[Nn]([' .. ending_punc .. ']+)[^\\]+$', 'gce')
            line.text = replace(linetext_copy, line.text, '^[^\\]+[^' .. starting_punc .. ']([' .. starting_punc ..
                ']+)$', 'gcs')
            line.text = replace(linetext_copy, line.text, '^[^\\]+[^' .. starting_punc ..
                ']([' .. starting_punc .. ']+)\\[Nn]', 'gcs')
            line.text = replace(linetext_copy, line.text,
                '\\[Nn][^\\]+[^' .. starting_punc .. ']([' .. starting_punc .. ']+)\\[Nn]', 'gcs')
            line.text = replace(linetext_copy, line.text, '\\[Nn][^\\]+[^' .. starting_punc ..
                ']([' .. starting_punc .. ']+)$', 'gcs')
        end

        subtitles[i] = line
    end
    aegisub.set_undo_point(unretard_script_name)
end

----- RTL -----
local RTl = {}

RTl.all_override_tags = {
    "\\\\fsize", "\\\\fscx", "\\\\fscy", "\\\\fsp", "\\\\1c", "\\\\2c", "\\\\3c", "\\\\4c",
    "\\\\1a", "\\\\2a", "\\\\3a", "\\\\4a", "\\\\bord", "\\\\shad", "\\\\bold", "\\\\ita",
    "\\\\u", "\\\\str", "\\\\frz", "\\\\fn", "\\\\fe", "\\\\blur", "\\\\be", "\\\\frx",
    "\\\\fry", "\\\\fax", "\\\\fay", "\\\\xbord", "\\\\xshad", "\\\\ybord", "\\\\yshad",
    "\\\\pic", "\\\\pbo", "\\\\q"
}
RTl.style_tags = {
    "\\\\fsize", "\\\\fscx", "\\\\fscy", "\\\\fsp", "\\\\1c", "\\\\2c", "\\\\3c", "\\\\4c",
    "\\\\1a", "\\\\2a", "\\\\3a", "\\\\4a", "\\\\bord", "\\\\shad", "\\\\bold", "\\\\ita",
    "\\\\u", "\\\\str", "\\\\frz", "\\\\fn", "\\\\fe"
}
RTl.transform_tags = {
    "\\\\fsize", "\\\\fsp", "\\\\1c", "\\\\2c", "\\\\3c", "\\\\4c", "\\\\1a", "\\\\2a", "\\\\3a", "\\\\4a",
    "\\\\fscx", "\\\\fscy", "\\\\frz", "\\\\bord", "\\\\shad", "\\\\fax", "\\\\fay", "\\\\fry", "\\\\frx",
    "\\\\blur", "\\\\be", "\\\\xbord", "\\\\xshad", "\\\\ybord", "\\\\yshad"
}
RTl.changed_transform_tags = {
    "¡fsize", "¡fsp", "¡1c", "¡2c", "¡3c", "¡4c", "¡1a", "¡2a", "¡3a", "¡4a",
    "¡fscx", "¡fscy", "¡frz", "¡bord", "¡shad", "¡fax", "¡fay", "¡fry", "¡frx",
    "¡blur", "¡be", "¡xbord", "¡xshad", "¡ybord", "¡yshad"
}
RTl.non_override_tags = {
    "\\\\an", "\\\\alig", "\\\\pos", "\\\\move", "\\\\org", "\\\\fad\\(", "\\\\fade"
}
RTl.style_names = {
    "fontsize", "scale_x", "scale_y", "spacing", "color1", "color2", "color3", "color4",
    "color1", "color2", "color3", "color4", "outline", "shadow", "bold", "italic",
    "underline", "strikeout", "angle", "fontname", "encoding"
}
RTl.transform_style_names = {
    "fontsize", "spacing", "color1", "color2", "color3", "color4", "color1", "color2",
    "color3", "color4", "scale_x", "scale_y", "angle", "outline", "shadow"
}

function get_initial_values(styleref, wrapstyle)
    local result = {}

    local all_initial_values = {}
    for i = 1, #RTl.style_names do
        all_initial_values[i] = styleref[RTl.style_names[i]]
    end
    for i = 5, 8 do
        all_initial_values[i] = re.sub(all_initial_values[i], "H[0-9a-fA-F][0-9a-fA-F]", "H")
    end
    for i = 9, 12 do
        all_initial_values[i] = re.match(all_initial_values[i], "&H[0-9a-fA-F][0-9a-fA-F]")[1]["str"] .. "&"
    end
    for i = 22, 27 do
        all_initial_values[i] = 0
    end
    all_initial_values[28] = all_initial_values[13]
    all_initial_values[29] = all_initial_values[14]
    all_initial_values[30] = all_initial_values[13]
    all_initial_values[31] = all_initial_values[14]
    all_initial_values[32] = 0
    all_initial_values[33] = 0
    all_initial_values[34] = wrapstyle

    local transform_initial_values = {}
    for i = 1, #RTl.transform_style_names do
        transform_initial_values[i] = styleref[RTl.transform_style_names[i]]
    end
    for i = 3, 6 do
        transform_initial_values[i] = re.sub(transform_initial_values[i], "H[0-9a-fA-F][0-9a-fA-F]", "H")
    end
    for i = 7, 10 do
        transform_initial_values[i] = re.match(transform_initial_values[i], "&H[0-9a-fA-F][0-9a-fA-F]")[1]["str"] .. "&"
    end
    for i = 16, 21 do
        transform_initial_values[i] = 0
    end
    transform_initial_values[22] = transform_initial_values[14]
    transform_initial_values[23] = transform_initial_values[15]
    transform_initial_values[24] = transform_initial_values[14]
    transform_initial_values[25] = transform_initial_values[15]

    result[1] = all_initial_values
    result[2] = transform_initial_values
    return result
end

function get_warpstyle(subtitles)
    local result = nil

    for q = 1, #subtitles do
        if subtitles[q].class == "info" then
            local infoclass = subtitles[q]
            if infoclass.key == "WrapStyle" then
                result = infoclass.value
                break
            end
        end
    end

    return result
end

function segmentation_based_on_tags(text)
    local result = {}

    for tags_and_texts in re.gfind(text, "({[^}]*})([^{]*)") do
        table.insert(result,
            {
                tag = re.match(tags_and_texts, "({[^}]*})([^{]*)")[2]["str"],
                text = re.match(tags_and_texts, "({[^}]*})([^{]*)")[3]["str"]
            })
    end

    return result
end

function segmentation_based_on_breaks(text)
    local result = {}

    for N in re.gfind(text, "\\\\N.*?\\\\N") do
        table.insert(result, re.match(N, "\\\\N(.*?)\\\\N")[2]["str"])
    end

    return result
end

function convert_the_tags_to_a_usable_form(text, style)
    text = re.sub(text, "\\\\c&", "\\\\1c&")
    text = re.sub(text, "\\\\fr([^xyz])", "\\\\frz$1")
    if style ~= nil then
        text = re.sub(text, "\\\\r([\\\\}])", "\\\\r" .. style .. "$1")
    end
    text = re.sub(text, "\\\\s([01])", "\\\\str$1")
    text = re.sub(text, "\\\\i([01])", "\\\\ita$1")
    text = re.sub(text, "\\\\fs([\\d\\.])", "\\\\fsize$1")
    text = re.sub(text, "\\\\b(\\d)", "\\\\bold$1")
    text = re.sub(text, "\\\\a(\\d)", "\\\\alig$1")
    text = re.sub(text, "\\\\p(\\d)", "\\\\pic$1")

    return text
end

function return_the_tags_to_their_correct_form(text, style)
    text = re.sub(text, "\\\\1c&", "\\\\c&")
    text = re.sub(text, "\\\\frz", "\\\\fr")
    text = re.sub(text, "\\\\str", "\\\\s")
    text = re.sub(text, "\\\\ita", "\\\\i")
    text = re.sub(text, "\\\\fsize", "\\\\fs")
    text = re.sub(text, "\\\\bold", "\\\\b")
    text = re.sub(text, "\\\\alig", "\\\\a")
    text = re.sub(text, "\\\\pic", "\\\\p")
    if style ~= nil then
        text = re.sub(text, "\\\\r" .. style .. "([\\\\}])", "\\\\r$1")
    end

    return text
end

function replace_r_with_tags(text, style)
    local result = ""

    text = (re.match(text, "^{") == nil) and "{}" .. text or text

    text = convert_the_tags_to_a_usable_form(text, style)

    local tag_text_table = segmentation_based_on_tags(text)

    tag_text_table = change_tags_inside_t(tag_text_table)

    tag_text_table = remove_effectless_tags(tag_text_table)

    tag_text_table = handle_r(tag_text_table)

    tag_text_table = retutn_tags_inside_t_to_notmal(tag_text_table)


    for i = 1, #tag_text_table do
        result = result .. tag_text_table[i].tag .. tag_text_table[i].text
    end

    result = return_the_tags_to_their_correct_form(result, style)

    return result
end

function remove_t_tags(breaks_tag_text_table)
    for x1 = 1, #breaks_tag_text_table do
        for x2 = 1, #breaks_tag_text_table[x1] do
            breaks_tag_text_table[x1][x2].tag = re.sub(breaks_tag_text_table[x1][x2].tag, "(\\\\t\\([^\\(\\)]+\\))", "")
        end
    end

    return breaks_tag_text_table
end

function prepare_first_step(line, wrapstyle)
    local result = ""

    local tag_text_table = segmentation_based_on_tags(line.text)

    tag_text_table = change_tags_inside_t(tag_text_table)

    tag_text_table = remove_effectless_tags(tag_text_table)

    tag_text_table = handle_soft_line_breaks(tag_text_table, wrapstyle)

    tag_text_table = handle_alpha(tag_text_table)

    tag_text_table = handle_r(tag_text_table)

    tag_text_table = remove_effectless_tags_inside_t(tag_text_table)

    tag_text_table = retutn_tags_inside_t_to_notmal(tag_text_table)

    for i = 1, #tag_text_table do
        result = result .. tag_text_table[i].tag .. tag_text_table[i].text
    end
    result = "\\N" .. result

    return result
end

function change_tags_inside_t(tag_text_table)
    repeat
        local there_is_backslash_inside_t = false
        for i = 1, #tag_text_table do
            if re.match(tag_text_table[i].tag, "\\\\t\\([^\\(\\)\\\\]*?\\\\") then
                there_is_backslash_inside_t = true
                tag_text_table[i].tag = re.sub(tag_text_table[i].tag, "(\\\\t\\([^\\(\\)\\\\]*?)\\\\", "$1¡")
            end
        end
    until not there_is_backslash_inside_t

    return tag_text_table
end

function remove_effectless_tags(tag_text_table)
    for i = 1, #tag_text_table do
        for x = 1, #RTl.all_override_tags do
            if re.match(tag_text_table[i].tag, RTl.all_override_tags[x]) then
                local tags_of_the_same_type = {}
                for tags_in_order in re.gfind(tag_text_table[i].tag, RTl.all_override_tags[x]) do
                    table.insert(tags_of_the_same_type, tags_in_order)
                end
                if #tags_of_the_same_type > 1 then
                    tag_text_table[i].tag = re.sub(tag_text_table[i].tag, RTl.all_override_tags[x] .. "[^\\\\}]+", "",
                        #tags_of_the_same_type - 1)
                end
            end
        end
    end

    return tag_text_table
end

function handle_soft_line_breaks(tag_text_table, wrapstyle)
    if wrapstyle ~= nil and re.match(tag_text_table[1].tag, "\\\\q") == nil then
        tag_text_table[1].tag = re.sub(tag_text_table[1].tag, "{", "{\\\\q" .. wrapstyle)
    end

    for n = 1, #tag_text_table do
        if re.match(tag_text_table[n].text, "\\\\n") then
            for n2 = n, 1, -1 do
                if re.match(tag_text_table[n2].tag, "\\\\q") then
                    if re.match(tag_text_table[n2].tag, "\\\\q2") then
                        tag_text_table[n].text = re.sub(tag_text_table[n].text, "\\\\n",
                            "\\\\N\\\\Nth¡s ¡s soft not hard")
                    end
                    break
                end
            end
        end
    end

    tag_text_table[1].tag = re.sub(tag_text_table[1].tag, "{\\\\q" .. wrapstyle, "{")

    return tag_text_table
end

function handle_alpha(tag_text_table)
    for i = 1, #tag_text_table do
        if re.match(tag_text_table[i].tag, "\\\\alpha") then
            local alpha_tags = {}
            for alpha_tags_in_order in re.gfind(tag_text_table[i].tag, "(\\\\alpha)") do
                table.insert(alpha_tags, alpha_tags_in_order)
            end
            if #alpha_tags > 1 then
                tag_text_table[i].tag = re.sub(tag_text_table[i].tag, "\\\\alpha[^\\\\}]+", "", #alpha_tags - 1)
            end
            local before_alpha = re.match(tag_text_table[i].tag, "(.+)\\\\alpha")[2]["str"]
            local after_alpha = re.match(tag_text_table[i].tag, "\\\\alpha[^\\\\}]+(.+)")[2]["str"]
            local alpha = re.match(tag_text_table[i].tag, "\\\\alpha[^\\\\}]+")[1]["str"]
            for a = 1, 4 do
                before_alpha = re.sub(before_alpha, "\\\\" .. a .. "a[^\\\\}]+", "")
                if re.match(after_alpha, "\\\\" .. a .. "a") == nil then
                    alpha = re.sub(alpha, "\\\\alpha([^\\\\}]+)", "\\\\alpha$1\\\\" .. a .. "a$1")
                end
            end
            tag_text_table[i].tag = before_alpha .. alpha .. after_alpha
            tag_text_table[i].tag = re.sub(tag_text_table[i].tag, "\\\\alpha([^\\\\}]+)", "")
        end
    end

    return tag_text_table
end

function handle_r(tag_text_table)
    for i1 = 1, #tag_text_table do
        if re.match(tag_text_table[i1].tag, "\\\\r") then
            local r_tags = {}
            for r_tags_in_order in re.gfind(tag_text_table[i1].tag, "(\\\\r)") do
                table.insert(r_tags, r_tags_in_order)
            end
            if #r_tags > 1 then
                tag_text_table[i1].tag = re.sub(tag_text_table[i1].tag, "\\\\r[^\\\\}]+", "", #r_tags - 1)
            end
            local r_style_name = re.match(tag_text_table[i1].tag, "\\\\r([^\\\\}]+)")[2]["str"]
            r_style_values = {}
            for i2 = 1, #subtitles do
                if subtitles[i2].class == "style" then
                    local styleclass = subtitles[i2]
                    if r_style_name == styleclass.name then
                        required_style = styleclass
                        break
                    end
                end
            end
            for i3 = 1, #RTl.style_names do
                r_style_values[i3] = required_style[RTl.style_names[i3]]
            end
            for i4 = 5, 8 do
                r_style_values[i4] = re.sub(r_style_values[i4], "H[0-9a-fA-F][0-9a-fA-F]", "H")
            end
            for i5 = 9, 12 do
                r_style_values[i5] = re.match(r_style_values[i5], "&H[0-9a-fA-F][0-9a-fA-F]")[1]["str"] .. "&"
            end
            local before_r = re.match(tag_text_table[i1].tag, "(.+)\\\\r")[2]["str"]
            local after_r = re.match(tag_text_table[i1].tag, "\\\\r[^\\\\}]+(.+)")[2]["str"]
            local rtag = re.match(tag_text_table[i1].tag, "\\\\r[^\\\\}]+")[1]["str"]
            for i6 = 1, #RTl.style_tags do
                before_r = re.sub(before_r, RTl.style_tags[i6] .. "[^\\\\}]+", "")
                if re.match(after_r, RTl.style_tags[i6]) == nil then
                    local val = r_style_values[i6]
                    if type(val) == "string" or type(val) == "number" then
                        rtag = re.sub(rtag, "(\\\\r[^\\\\}]+)", "$1" .. RTl.style_tags[i6] .. val)
                    else
                        if val then
                            rtag = re.sub(rtag, "(\\\\r[^\\\\}]+)", "$1" .. RTl.style_tags[i6] .. "1")
                        else
                            rtag = re.sub(rtag, "(\\\\r[^\\\\}]+)", "$1" .. RTl.style_tags[i6] .. "0")
                        end
                    end
                end
            end
            tag_text_table[i1].tag = before_r .. rtag .. after_r
            tag_text_table[i1].tag = re.sub(tag_text_table[i1].tag, "\\\\r[^\\\\}]+", "")
        end
    end
    return tag_text_table
end

function remove_effectless_tags_inside_t(tag_text_table)
    repeat
        local there_is_effectless_t_tag = false
        for i = 1, #tag_text_table do
            for x = 1, #RTl.transform_tags do
                if re.match(tag_text_table[i].tag, RTl.changed_transform_tags[x]) then
                    local after_t_tag = re.match(tag_text_table[i].tag, RTl.changed_transform_tags[x] .. "[^¡\\)]+(.+)")
                        [2]["str"]
                    if re.match(after_t_tag, RTl.transform_tags[x]) then
                        there_is_effectless_t_tag = true
                        tag_text_table[i].tag = re.sub(tag_text_table[i].tag,
                            RTl.changed_transform_tags[x] .. "[^¡\\)]+", "", 1)
                        tag_text_table[i].tag = re.sub(tag_text_table[i].tag, "\\\\t\\([^¡\\)]*?\\)", "")
                    end
                end
            end
        end
    until not there_is_effectless_t_tag

    return tag_text_table
end

function retutn_tags_inside_t_to_notmal(tag_text_table)
    repeat
        local there_is_¡_inside_t = false
        for i = 1, #tag_text_table do
            if re.match(tag_text_table[i].tag, "\\\\t\\([^\\(\\)¡]*?¡") then
                there_is_¡_inside_t = true
                tag_text_table[i].tag = re.sub(tag_text_table[i].tag, "(\\\\t\\([^\\(\\)¡]*?)¡", "$1\\\\")
            end
        end
    until not there_is_¡_inside_t

    return tag_text_table
end

function prepare_t_tags(text)
    local result = {}

    local breaks_table = segmentation_based_on_breaks(text)

    local breaks_tag_text_table = {}
    for i = 1, #breaks_table do
        breaks_table[i] = (re.match(breaks_table[i], "^{") == nil) and "{}" .. breaks_table[i] or breaks_table[i]
        breaks_tag_text_table[i] = segmentation_based_on_tags(breaks_table[i])
    end

    result = separate_t_tags(breaks_tag_text_table)

    result = handle_alpha_inside_t(result)

    result = ensure_there_is_one_tag_inside_each_t(result)

    result = find_out_what_t_tags_are_given_to_each_section(breaks_tag_text_table, result)

    return result
end

function separate_t_tags(breaks_tag_text_table)
    local result = {}

    for x1 = 1, #breaks_tag_text_table do
        local t_tags_for_each_line = {}
        for x2 = 1, #breaks_tag_text_table[x1] do
            local t_tags_for_each_override_block = {}
            if re.match(breaks_tag_text_table[x1][x2].tag, "\\\\t") then
                for each_t_tag in re.gfind(breaks_tag_text_table[x1][x2].tag, "(\\\\t\\([^\\(\\)]*?\\))") do
                    table.insert(t_tags_for_each_override_block, each_t_tag)
                end
            else
                t_tags_for_each_override_block[1] = ""
            end
            for x3 = 1, #t_tags_for_each_override_block do
                if t_tags_for_each_line[x2] == nil then
                    t_tags_for_each_line[x2] = t_tags_for_each_override_block[x3]
                else
                    t_tags_for_each_line[x2] = t_tags_for_each_line[x2] .. t_tags_for_each_override_block[x3]
                end
            end
        end
        result[x1] = t_tags_for_each_line
    end

    return result
end

function handle_alpha_inside_t(separated_t_tags)
    for x1 = 1, #separated_t_tags do
        for x2 = 1, #separated_t_tags[x1] do
            separated_t_tags[x1][x2] = re.sub(separated_t_tags[x1][x2], "\\\\alpha([^\\\\\\)]+)",
                "\\\\1a$1\\\\2a$1\\\\3a$1\\\\4a$1")
        end
    end

    return separated_t_tags
end

function ensure_there_is_one_tag_inside_each_t(separated_t_tags)
    repeat
        local there_is_more_than_one_tag_inside_each_t = false
        for x1 = 1, #separated_t_tags do
            for x2 = 1, #separated_t_tags[x1] do
                if re.match(separated_t_tags[x1][x2], "\\\\t\\([^\\\\\\(\\)]*?\\\\[^\\\\\\(\\)]+\\\\") then
                    there_is_more_than_one_tag_inside_each_t = true
                    separated_t_tags[x1][x2] = re.sub(separated_t_tags[x1][x2],
                        "\\\\t\\(([^\\\\\\(\\)]*?)\\\\([^\\\\\\)]+)", "\\\\t\\($1\\\\$2\\)\\\\t\\($1")
                    separated_t_tags[x1][x2] = re.sub(separated_t_tags[x1][x2], "\\\\t\\([^\\\\\\)]*?\\)", "")
                end
            end
        end
    until not there_is_more_than_one_tag_inside_each_t

    return separated_t_tags
end

function find_out_what_t_tags_are_given_to_each_section(breaks_tag_text_table, separated_t_tags)
    breaks_tag_text_table = remove_t_tags(breaks_tag_text_table)

    for i = 1, #RTl.transform_tags do
        desierd_t_tags = {}
        for x1 = 1, #separated_t_tags do
            desierd_t_tags_for_each_line = {}
            for x2 = 1, #separated_t_tags[x1] do
                the_line_that_has_the_first_tag_outside_t = 1
                the_block_that_has_the_first_tag_outside_t = 1

                local the_first_real_tag_is_in_the_same_line = false
                for y2 = x2, 1, -1 do
                    if re.match(breaks_tag_text_table[x1][y2].tag, RTl.transform_tags[i]) then
                        the_line_that_has_the_first_tag_outside_t = x1
                        the_block_that_has_the_first_tag_outside_t = y2
                        the_first_real_tag_is_in_the_same_line = true
                        break
                    end
                end
                if not the_first_real_tag_is_in_the_same_line then
                    for y1 = x1 - 1, 1, -1 do
                        for y2 = #breaks_tag_text_table[y1], 1, -1 do
                            if re.match(breaks_tag_text_table[y1][y2].tag, RTl.transform_tags[i]) then
                                the_line_that_has_the_first_tag_outside_t = y1
                                the_block_that_has_the_first_tag_outside_t = y2
                                goto found_real_tag
                            end
                        end
                    end
                    ::found_real_tag::
                end

                desierd_t_tags_for_each_block = {}
                if the_line_that_has_the_first_tag_outside_t < x1 then
                    for z2 = the_block_that_has_the_first_tag_outside_t, #separated_t_tags[the_line_that_has_the_first_tag_outside_t] do
                        for required_t_tags in re.gfind(separated_t_tags[the_line_that_has_the_first_tag_outside_t][z2], "\\\\t\\([^\\\\\\(\\)]*?" .. RTl.transform_tags[i] .. "[^\\\\\\(\\)]+\\)") do
                            table.insert(desierd_t_tags_for_each_block, required_t_tags)
                        end
                    end
                    for z1 = the_line_that_has_the_first_tag_outside_t + 1, x1 - 1 do
                        for z2 = 1, #separated_t_tags[z1] do
                            for required_t_tags in re.gfind(separated_t_tags[z1][z2], "\\\\t\\([^\\\\\\(\\)]*?" .. RTl.transform_tags[i] .. "[^\\\\\\(\\)]+\\)") do
                                table.insert(desierd_t_tags_for_each_block, required_t_tags)
                            end
                        end
                    end
                    for z2 = 1, x2 do
                        for required_t_tags in re.gfind(separated_t_tags[x1][z2], "\\\\t\\([^\\\\\\(\\)]*?" .. RTl.transform_tags[i] .. "[^\\\\\\(\\)]+\\)") do
                            table.insert(desierd_t_tags_for_each_block, required_t_tags)
                        end
                    end
                else
                    for z2 = the_block_that_has_the_first_tag_outside_t, x2 do
                        for required_t_tags in re.gfind(separated_t_tags[x1][z2], "\\\\t\\([^\\\\\\(\\)]*?" .. RTl.transform_tags[i] .. "[^\\\\\\(\\)]+\\)") do
                            table.insert(desierd_t_tags_for_each_block, required_t_tags)
                        end
                    end
                end

                desierd_t_tags_for_each_line[x2] = desierd_t_tags_for_each_block
            end
            desierd_t_tags[x1] = desierd_t_tags_for_each_line
        end

        for a1 = 1, #desierd_t_tags do
            for a2 = 1, #desierd_t_tags[a1] do
                separated_t_tags[a1][a2] = re.sub(separated_t_tags[a1][a2],
                    "\\\\t\\([^\\\\\\(\\)]*?" .. RTl.transform_tags[i] .. "[^\\\\\\(\\)]+\\)", "")
                for a3 = #desierd_t_tags[a1][a2], 1, -1 do
                    separated_t_tags[a1][a2] = desierd_t_tags[a1][a2][a3] .. separated_t_tags[a1][a2]
                end
            end
        end
    end

    return separated_t_tags
end

function prepare_2nd_step(text)
    local result = {}

    local breaks_table = segmentation_based_on_breaks(text)

    local breaks_tag_text_table = {}
    for i = 1, #breaks_table do
        breaks_table[i] = (re.match(breaks_table[i], "^{") == nil) and "{}" .. breaks_table[i] or breaks_table[i]
        breaks_tag_text_table[i] = segmentation_based_on_tags(breaks_table[i])
    end

    breaks_tag_text_table = remove_t_tags(breaks_tag_text_table)

    breaks_tag_text_table = add_required_tags_to_each_line(breaks_tag_text_table)

    for x1 = 1, #breaks_tag_text_table do
        result[x1] = ""
        for x2 = 1, #breaks_tag_text_table[x1] do
            result[x1] = result[x1] .. breaks_tag_text_table[x1][x2].tag .. breaks_tag_text_table[x1][x2].text
        end
    end

    return result
end

function add_required_tags_to_each_line(breaks_tag_text_table)
    for i = 1, #RTl.all_override_tags do
        local the_tag_that_should_be_added = nil
        for x1 = 1, #breaks_tag_text_table do
            if re.match(breaks_tag_text_table[x1][1].tag, RTl.all_override_tags[i]) == nil then
                for y1 = x1 - 1, 1, -1 do
                    for y2 = #breaks_tag_text_table[y1], 1, -1 do
                        if re.match(breaks_tag_text_table[y1][y2].tag, RTl.all_override_tags[i] .. "[^\\\\}]+") then
                            the_tag_that_should_be_added = re.match(breaks_tag_text_table[y1][y2].tag,
                                RTl.all_override_tags[i] .. "[^\\\\}]+")[1]["str"]
                            breaks_tag_text_table[x1][1].tag = "{" ..
                                the_tag_that_should_be_added .. re.sub(breaks_tag_text_table[x1][1].tag, "{", "", 1)
                            goto found_the_tag
                        end
                    end
                end
            end
            ::found_the_tag::
        end
    end

    return breaks_tag_text_table
end

function reverse_each_line(initial_values, breaks_table, t_tags)
    local result = ""

    local btt_table = {} -- breaks_tag_text_table
    for i = 1, #breaks_table do
        breaks_table[i] = (re.match(breaks_table[i], "^{") == nil) and "{}" .. breaks_table[i] or breaks_table[i]
        btt_table[i] = segmentation_based_on_tags(breaks_table[i])
    end

    local reversed_tags_without_t_alpha_r = {}
    local reversed_t_tags = {}
    for x1 = 1, #btt_table do
        btt_table[x1] = reverse_non_override_tags(btt_table[x1])

        for y1 = x1 - 1, 1, -1 do
            if re.match(btt_table[y1][1].text, "th¡s ¡s soft not hard") then
                if reversed_tags_without_t_alpha_r[y1][#reversed_tags_without_t_alpha_r[y1]] ~= "{\\\\q2}" then
                    reversed_tags_without_t_alpha_r[y1][#reversed_tags_without_t_alpha_r[y1] + 1] = "{\\\\q2}"
                end
            end
        end
        local all_initial_values = adjust_initial_values_for_all_tags(initial_values[1], reversed_tags_without_t_alpha_r,
            x1)
        if re.match(btt_table[x1][1].text, "th¡s ¡s soft not hard") then
            all_initial_values[34] = 2
        end

        btt_table[x1] = give_appropriate_tags_to_each_block_based_on_other_blocks(btt_table[x1])

        btt_table[x1] = give_appropriate_tags_to_each_block_based_on_initial_values(btt_table[x1], all_initial_values)

        btt_table[x1] = remove_unnecessary_tags_from_each_block_based_on_other_blocks(btt_table[x1])

        local transform_initial_values = adjust_initial_values_for_transform_tags(initial_values[2],
            reversed_tags_without_t_alpha_r, x1)

        btt_table[x1] = control_the_scope_of_t_tags_effect_by_adding_tag(btt_table[x1], t_tags[x1],
            transform_initial_values)

        btt_table[x1] = add_t_tags(btt_table[x1], t_tags[x1])

        btt_table[x1] = control_the_scope_of_t_tags_effect_by_replacing_t_tags(btt_table[x1])

        local finalized_t_tags = separate_and_adjust_t_tags(btt_table[x1])
        for x2 = 1, #btt_table[x1] do
            btt_table[x1][x2].tag = re.sub(btt_table[x1][x2].tag, "(\\\\t\\([^\\(\\)]+\\))", "")
        end

        btt_table[x1] = remove_unnecessary_tags_from_each_block_based_on_initial_values(btt_table[x1], all_initial_values,
            finalized_t_tags)

        btt_table[x1] = ensure_t_tags_from_different_lines_do_not_effect_this_line(btt_table[x1], reversed_t_tags,
            reversed_tags_without_t_alpha_r, transform_initial_values)


        reversed_tags_without_t_alpha_r_for_this_line = {}
        for x2 = 1, #btt_table[x1] do
            reversed_tags_without_t_alpha_r_for_this_line[x2] = btt_table[x1][x2].tag
        end
        reversed_tags_without_t_alpha_r[x1] = reversed_tags_without_t_alpha_r_for_this_line


        btt_table[x1] = return_r(btt_table[x1], all_initial_values)

        btt_table[x1] = return_ahpha(btt_table[x1])

        btt_table[x1] = add_t_tags(btt_table[x1], finalized_t_tags)


        reversed_t_tags[x1] = finalized_t_tags


        breaks_table[x1] = ""
        for x2 = #btt_table[x1], 1, -1 do
            breaks_table[x1] = breaks_table[x1] .. btt_table[x1][x2].tag .. btt_table[x1][x2].text
        end

        breaks_table[x1] = re.sub(breaks_table[x1], "([^{}]+){}([^{}]+)", "$1$2")
    end

    local wrapstyle = get_warpstyle(subtitles)
    breaks_table = add_N_and_n(breaks_table, btt_table, wrapstyle)

    for i = 1, #breaks_table do
        result = result .. breaks_table[i]
    end

    return result
end

function reverse_non_override_tags(tag_text_table)
    local tt_table = tag_text_table
    for i = 1, #RTl.non_override_tags do
        non_override_tags_table = {}
        for j1 = 1, #tt_table do
            if re.match(tt_table[j1].tag, RTl.non_override_tags[i]) then
                non_override_tags_table[j1] = re.match(tt_table[j1].tag, RTl.non_override_tags[i] .. "[^\\\\}]+")[1]
                    ["str"]
                tt_table[j1].tag = re.sub(tt_table[j1].tag, RTl.non_override_tags[i] .. "[^\\\\}]+", "")
            else
                non_override_tags_table[j1] = ""
            end
        end
        for j2 = 1, #tt_table do
            tt_table[j2].tag = "{" .. non_override_tags_table[#tt_table - j2 + 1] .. re.sub(tt_table[j2].tag, "{", "", 1)
        end
    end

    return tt_table
end

function adjust_initial_values_for_all_tags(initial_val, reversed_tags_wo_tar, x1)
    for i = 1, #RTl.all_override_tags do
        for y1 = x1 - 1, 1, -1 do
            for y2 = 1, #reversed_tags_wo_tar[y1] do
                if re.match(reversed_tags_wo_tar[y1][y2], RTl.all_override_tags[i]) then
                    initial_val[i] = re.match(reversed_tags_wo_tar[y1][y2], RTl.all_override_tags[i] .. "([^\\\\}]+)")
                        [2]["str"]
                    goto found_the_required_tag
                end
            end
        end
        ::found_the_required_tag::
    end

    return initial_val
end

function give_appropriate_tags_to_each_block_based_on_other_blocks(tt_table)
    local the_tag_that_should_be_added = nil
    for i = 1, #RTl.all_override_tags do
        for j = #tt_table, 1, -1 do
            if re.match(tt_table[j].tag, RTl.all_override_tags[i]) == nil then
                for g = j - 1, 1, -1 do
                    if re.match(tt_table[g].tag, RTl.all_override_tags[i]) then
                        the_tag_that_should_be_added = re.match(tt_table[g].tag, RTl.all_override_tags[i] .. "[^\\\\}]+")
                            [1]["str"]
                        tt_table[j].tag = "{" .. the_tag_that_should_be_added .. re.sub(tt_table[j].tag, "{", "", 1)
                        break
                    end
                end
            end
        end
    end

    return tt_table
end

function give_appropriate_tags_to_each_block_based_on_initial_values(tt_table, all_initial_values)
    for i = 1, #RTl.all_override_tags do
        for j = 1, #tt_table do
            if re.match(tt_table[j].tag, RTl.all_override_tags[i]) == nil then
                local int = all_initial_values[i]
                if type(int) == "string" or type(int) == "number" then
                    tt_table[j].tag = re.sub(tt_table[j].tag, "{", "{" .. RTl.all_override_tags[i] .. int)
                else
                    if int then
                        tt_table[j].tag = re.sub(tt_table[j].tag, "{", "{" .. RTl.all_override_tags[i] .. "1")
                    else
                        tt_table[j].tag = re.sub(tt_table[j].tag, "{", "{" .. RTl.all_override_tags[i] .. "0")
                    end
                end
            end
        end
    end

    return tt_table
end

function remove_unnecessary_tags_from_each_block_based_on_other_blocks(tt_table)
    local first_tag = nil
    local found_tag = nil
    for i = 1, #RTl.all_override_tags do
        for j = #tt_table, 1, -1 do
            if re.match(tt_table[j].tag, RTl.all_override_tags[i]) then
                for g = j + 1, #tt_table do
                    if re.match(tt_table[g].tag, RTl.all_override_tags[i]) then
                        first_tag = re.match(tt_table[j].tag, RTl.all_override_tags[i] .. "[^\\\\}]+")[1]["str"]
                        found_tag = re.match(tt_table[g].tag, RTl.all_override_tags[i] .. "[^\\\\}]+")[1]["str"]
                        if first_tag == found_tag then
                            tt_table[j].tag = re.sub(tt_table[j].tag, RTl.all_override_tags[i] .. "[^\\\\}]+", "")
                        end
                        break
                    end
                end
            end
        end
    end

    return tt_table
end

function remove_unnecessary_tags_from_each_block_based_on_initial_values(tt_table, all_initial_values, finalized_t_tags)
    for i = 1, #RTl.all_override_tags do
        for j = #tt_table, 1, -1 do
            if re.match(tt_table[j].tag, RTl.all_override_tags[i]) then
                local found_next_tag = false
                for g = j + 1, #tt_table do
                    if re.match(tt_table[g].tag, RTl.all_override_tags[i]) or re.match(finalized_t_tags[g], RTl.all_override_tags[i]) then
                        found_next_tag = true
                        break
                    end
                end
                if not found_next_tag then
                    local int = all_initial_values[i]
                    if type(int) == "string" or type(int) == "number" then
                        int = tostring(int)
                        if re.match(tt_table[j].tag, RTl.all_override_tags[i] .. "[^\\\\}]+")[1]["str"] ~= "\\" .. re.sub(RTl.all_override_tags[i], "\\\\", "") .. int then
                            break
                        else
                            tt_table[j].tag = re.sub(tt_table[j].tag, RTl.all_override_tags[i] .. "[^\\\\}]+", "")
                        end
                    else
                        if int then
                            if re.match(tt_table[j].tag, RTl.all_override_tags[i] .. "[^\\\\}]+")[1]["str"] ~= "\\" .. re.sub(RTl.all_override_tags[i], "\\\\", "") .. "1" then
                                break
                            else
                                tt_table[j].tag = re.sub(tt_table[j].tag, RTl.all_override_tags[i] .. "[^\\\\}]+", "")
                            end
                        else
                            if re.match(tt_table[j].tag, RTl.all_override_tags[i] .. "[^\\\\}]+")[1]["str"] ~= "\\" .. re.sub(RTl.all_override_tags[i], "\\\\", "") .. "0" then
                                break
                            else
                                tt_table[j].tag = re.sub(tt_table[j].tag, RTl.all_override_tags[i] .. "[^\\\\}]+", "")
                            end
                        end
                    end
                end
            end
        end
    end

    return tt_table
end

function adjust_initial_values_for_transform_tags(initial_val, reversed_tags_wo_tar, x1)
    for i = 1, #RTl.transform_tags do
        for y1 = x1 - 1, 1, -1 do
            for y2 = 1, #reversed_tags_wo_tar[y1] do
                if re.match(reversed_tags_wo_tar[y1][y2], RTl.transform_tags[i]) then
                    initial_val[i] = re.match(reversed_tags_wo_tar[y1][y2], RTl.transform_tags[i] .. "([^\\\\}]+)")[2]
                        ["str"]
                    goto found_the_required_tag_for_t
                end
            end
        end
        ::found_the_required_tag_for_t::
    end

    return initial_val
end

function control_the_scope_of_t_tags_effect_by_adding_tag(tt_table, t_tags, t_initial_values)
    local the_tag_that_should_be_added = nil
    for i = 1, #RTl.transform_tags do
        for j = 1, #tt_table do
            if re.match(t_tags[j], RTl.transform_tags[i]) then
                if j > 1 then
                    if re.match(tt_table[j - 1].tag, RTl.transform_tags[i]) == nil then
                        for g = j, #tt_table do
                            if re.match(tt_table[g].tag, RTl.transform_tags[i]) then
                                the_tag_that_should_be_added = re.match(tt_table[g].tag,
                                    RTl.transform_tags[i] .. "[^\\\\}]+")[1]["str"]
                                tt_table[j - 1].tag = "{" ..
                                    the_tag_that_should_be_added .. re.sub(tt_table[j - 1].tag, "{", "", 1)
                            end
                        end
                    end
                    if re.match(tt_table[j - 1].tag, RTl.transform_tags[i]) == nil then
                        tt_table[j - 1].tag = re.sub(tt_table[j - 1].tag, "{",
                            "{" .. RTl.transform_tags[i] .. t_initial_values[i])
                    end
                end
            end
        end
    end

    return tt_table
end

function add_t_tags(tt_table, t_tags)
    for j = 1, #tt_table do
        tt_table[j].tag = re.sub(tt_table[j].tag, "}", "", 1) .. t_tags[j] .. "}"
    end

    return tt_table
end

function control_the_scope_of_t_tags_effect_by_replacing_t_tags(tt_table)
    local last_tag_place = 0
    local last_t_tag_place = -1
    local the_t_tag_that_should_be_moved = nil
    for i = 1, #RTl.transform_tags do
        for j = #tt_table, 1, -1 do
            if re.match(tt_table[j].tag, RTl.transform_tags[i]) == nil then
                for g1 = j - 1, 1, -1 do
                    if re.match(tt_table[g1].tag, RTl.transform_tags[i]) then
                        last_tag_place = g1
                        break
                    end
                end
                for g2 = j - 1, 1, -1 do
                    if re.match(tt_table[g2].tag, "\\\\t\\([^\\\\\\(\\)]*?" .. RTl.transform_tags[i]) then
                        last_t_tag_place = g2
                        break
                    end
                end
                if last_tag_place <= last_t_tag_place then
                    if re.match(tt_table[last_t_tag_place].tag, "\\\\t\\([^\\\\\\(\\)]*?" .. RTl.transform_tags[i]) then
                        for a = 1, #re.find(tt_table[last_t_tag_place].tag, "\\\\t\\([^\\\\\\(\\)]*?" .. RTl.transform_tags[i]) do
                            the_t_tag_that_should_be_moved = re.match(tt_table[last_t_tag_place].tag,
                                "\\\\t\\([^\\\\\\(\\)]*?" .. RTl.transform_tags[i] .. "[^\\\\\\(\\)]+\\)")[1]["str"]
                            if the_t_tag_that_should_be_moved ~= nil then
                                tt_table[j].tag = "{" ..
                                    the_t_tag_that_should_be_moved .. re.sub(tt_table[j].tag, "{", "", 1)
                                tt_table[last_t_tag_place].tag = re.sub(tt_table[last_t_tag_place].tag,
                                    "\\\\t\\([^\\\\\\(\\)]*?" .. RTl.transform_tags[i] .. "[^\\\\\\(\\)]+\\)", "", 1)
                            end
                        end
                    end
                end
            end
        end
    end

    return tt_table
end

function ensure_t_tags_from_different_lines_do_not_effect_this_line(tt_table, reversed_t_tags, reversed_tags_wo_tar,
                                                                    t_initial_values)
    for i = 1, #RTl.transform_tags do
        if re.match(tt_table[#tt_table].tag, RTl.transform_tags[i]) == nil then
            last_t_tag_line = 0
            last_t_tag_block = 0
            for y1 = #reversed_t_tags, 1, -1 do
                for y2 = 1, #reversed_t_tags[y1] do
                    if re.match(reversed_t_tags[y1][y2], RTl.transform_tags[i]) then
                        last_t_tag_line = y1
                        last_t_tag_block = y2
                        goto found_last_t_tag
                    end
                end
            end
            ::found_last_t_tag::
            last_real_tag_line = 0
            last_real_tag_block = -1
            for z1 = #reversed_tags_wo_tar, 1, -1 do
                for z2 = 1, #reversed_tags_wo_tar[z1] do
                    if re.match(reversed_tags_wo_tar[z1][z2], RTl.transform_tags[i]) then
                        last_real_tag_line = z1
                        last_real_tag_block = z2
                        goto found_last_real_tag
                    end
                end
            end
            ::found_last_real_tag::
            if last_real_tag_line <= last_t_tag_line then
                if last_t_tag_block <= last_real_tag_block then
                    tt_table[#tt_table].tag = re.sub(tt_table[#tt_table].tag, "{",
                        "{" .. RTl.transform_tags[i] .. t_initial_values[i])
                end
            end
        end
    end

    return tt_table
end

function separate_and_adjust_t_tags(tt_table)
    local result = {}

    for j = 1, #tt_table do
        t_tags_for_each_override_block = {}
        if re.match(tt_table[j].tag, "\\\\t") then
            for each_t_tag in re.gfind(tt_table[j].tag, "(\\\\t\\([^\\(\\)]*?\\))") do
                table.insert(t_tags_for_each_override_block, each_t_tag)
            end
        else
            t_tags_for_each_override_block[1] = ""
        end

        t_tags_for_each_override_block = merge_t_tags_with_same_tta(t_tags_for_each_override_block) -- tta: start time, end time and accel

        t_tags_for_each_override_block = return_alpha_for_t(t_tags_for_each_override_block)

        for i = 1, #t_tags_for_each_override_block do
            if result[j] == nil then
                result[j] = t_tags_for_each_override_block[i]
            else
                result[j] = result[j] .. t_tags_for_each_override_block[i]
            end
        end
    end

    return result
end

function merge_t_tags_with_same_tta(t_tags_for_each_override_block)
    local t_tags = t_tags_for_each_override_block

    local the_t_tag_that_should_be_merged = nil
    for i1 = 1, #t_tags do
        if t_tags[i1] ~= "" then
            for i2 = i1 + 1, #t_tags do
                if t_tags[i2] ~= "" and re.match(t_tags[i1], "\\\\t\\(([^\\\\\\(\\)]*)")[2]["str"] == re.match(t_tags[i2], "\\\\t\\(([^\\\\\\(\\)]*)")[2]["str"] then
                    the_t_tag_that_should_be_merged = re.match(t_tags[i2], "\\\\t\\([^\\\\\\(\\)]*?(\\\\[^\\(\\)]+)\\)")
                        [2]["str"]
                    t_tags[i1] = re.sub(t_tags[i1], "\\)", "", 1) .. the_t_tag_that_should_be_merged .. ")"
                    t_tags[i2] = ""
                end
            end
        end
    end

    return t_tags
end

function return_alpha_for_t(t_tags_for_each_override_block)
    local t_tags = t_tags_for_each_override_block

    repeat
        local there_is_a_tag_that_should_be_replaced_with_alpha = false
        for i = 1, #t_tags do
            if re.match(t_tags[i], "\\\\1a") then
                if re.match(t_tags[i], "\\\\2a") then
                    if re.match(t_tags[i], "\\\\3a") then
                        if re.match(t_tags[i], "\\\\4a") then
                            if re.match(t_tags[i], "\\\\1a([^\\\\\\)]+)")[2]["str"] == re.match(t_tags[i], "\\\\2a([^\\\\\\)]+)")[2]["str"] then
                                if re.match(t_tags[i], "\\\\2a([^\\%)]+)")[2]["str"] == re.match(t_tags[i], "\\\\3a([^\\\\\\)]+)")[2]["str"] then
                                    if re.match(t_tags[i], "\\\\3a([^\\%)]+)")[2]["str"] == re.match(t_tags[i], "\\\\4a([^\\\\\\)]+)")[2]["str"] then
                                        there_is_a_tag_that_should_be_replaced_with_alpha = true
                                        t_tags[i] = re.sub(t_tags[i], "\\\\2a[^\\\\\\)]+", "", 1)
                                        t_tags[i] = re.sub(t_tags[i], "\\\\3a[^\\\\\\)]+", "", 1)
                                        t_tags[i] = re.sub(t_tags[i], "\\\\4a[^\\\\\\)]+", "", 1)
                                        t_tags[i] = re.sub(t_tags[i], "\\\\1a([^\\\\\\)]+)", "\\\\alpha$1", 1)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    until not there_is_a_tag_that_should_be_replaced_with_alpha

    return t_tags
end

function return_r(tt_table, all_initial_values)
    for j = 1, #tt_table do
        local tag_values = {}
        local at_least_one_value_is_from_tags = false
        for i = 1, #RTl.style_tags do
            local found_value_in_tags = false
            for g = j, #tt_table do
                if re.match(tt_table[g].tag, RTl.style_tags[i]) then
                    found_value_in_tags = true
                    tag_values[i] = re.match(tt_table[g].tag, RTl.style_tags[i] .. "([^\\\\}]+)")[2]["str"]
                    break
                end
            end
            if found_value_in_tags then
                at_least_one_value_is_from_tags = true
            else
                tag_values[i] = all_initial_values[i]
            end
        end
        if at_least_one_value_is_from_tags then
            for a = 1, #tag_values do
                if type(tag_values[a]) == "string" or type(tag_values[a]) == "number" then
                    tag_values[a] = tostring(tag_values[a])
                else
                    if tag_values[a] then
                        tag_values[a] = "1"
                    else
                        tag_values[a] = "0"
                    end
                end
            end
            local desierd_style_name = nil
            for z = 1, #subtitles do
                local style_values = {}
                if subtitles[z].class == "style" then
                    styleclass = subtitles[z]
                    for b = 1, #RTl.style_names do
                        style_values[b] = styleclass[RTl.style_names[b]]
                    end
                    for b = 5, 8 do
                        style_values[b] = re.sub(style_values[b], "H[0-9a-fA-F][0-9a-fA-F]", "H")
                    end
                    for b = 9, 12 do
                        style_values[b] = re.match(style_values[b], "&H[0-9a-fA-F][0-9a-fA-F]")[1]["str"] .. "&"
                    end
                    for a = 1, #style_values do
                        if type(style_values[a]) == "string" or type(style_values[a]) == "number" then
                            style_values[a] = tostring(style_values[a])
                        else
                            if style_values[a] then
                                style_values[a] = "1"
                            else
                                style_values[a] = "0"
                            end
                        end
                    end
                    local at_least_one_value_does_not_match = false
                    for r = 1, #RTl.style_names do
                        if tag_values[r] ~= style_values[r] then
                            at_least_one_value_does_not_match = true
                        end
                    end
                    if not at_least_one_value_does_not_match then
                        desierd_style_name = styleclass.name
                        break
                    end
                end
            end
            if desierd_style_name ~= nil then
                for i2 = 1, #RTl.style_tags do
                    tt_table[j].tag = re.sub(tt_table[j].tag, RTl.style_tags[i2] .. "[^\\\\}]+", "")
                end
                tt_table[j].tag = re.sub(tt_table[j].tag, "{", "{\\\\r" .. desierd_style_name)
            end
        end
    end

    return tt_table
end

function return_ahpha(tt_table)
    for j = 1, #tt_table do
        if re.match(tt_table[j].tag, "\\\\1a") then
            if re.match(tt_table[j].tag, "\\\\2a") then
                if re.match(tt_table[j].tag, "\\\\3a") then
                    if re.match(tt_table[j].tag, "\\\\4a") then
                        if re.match(tt_table[j].tag, "\\\\1a([^\\\\}]+)")[2]["str"] == re.match(tt_table[j].tag, "\\\\2a([^\\\\}]+)")[2]["str"] then
                            if re.match(tt_table[j].tag, "\\\\2a([^\\\\}]+)")[2]["str"] == re.match(tt_table[j].tag, "\\\\3a([^\\\\}]+)")[2]["str"] then
                                if re.match(tt_table[j].tag, "\\\\3a([^\\\\}]+)")[2]["str"] == re.match(tt_table[j].tag, "\\\\4a([^\\\\}]+)")[2]["str"] then
                                    tt_table[j].tag = re.sub(tt_table[j].tag, "\\\\2a[^\\\\}]+", "")
                                    tt_table[j].tag = re.sub(tt_table[j].tag, "\\\\3a[^\\\\}]+", "")
                                    tt_table[j].tag = re.sub(tt_table[j].tag, "\\\\4a[^\\\\}]+", "")
                                    tt_table[j].tag = re.sub(tt_table[j].tag, "\\\\1a([^\\\\}]+)", "\\\\alpha$1")
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return tt_table
end

function add_N_and_n(breaks_table, btt_table, wrapstyle)
    local b_table = breaks_table
    for x1 = 2, #b_table do
        if re.match(b_table[x1], "th¡s ¡s soft not hard") then
            b_table[x1] = re.sub(b_table[x1], "th¡s ¡s soft not hard", "")
            b_table[x1] = "\\n" .. b_table[x1]
            local found_q_tag = false
            for y1 = x1 - 1, 1, -1 do
                for y2 = 1, #btt_table[y1] do
                    if re.match(btt_table[y1][y2].tag, "\\\\q") then
                        found_q_tag = true
                        if re.match(btt_table[y1][y2].tag, "\\\\q(\\d)")[2]["str"] ~= "2" then
                            b_table[x1] = "{\\q2}" .. b_table[x1]
                        end
                        goto found_q
                    end
                end
            end
            ::found_q::
            if not found_q_tag then
                if wrapstyle ~= "2" then
                    b_table[x1] = "{\\q2}" .. b_table[x1]
                end
            end
        else
            b_table[x1] = "\\N" .. b_table[x1]
        end
    end

    return b_table
end

function reverse(line)
    local line = util.copy(line)

    -- read in styles and meta
    local meta, styles = karaskel.collect_head(subtitles, false)

    karaskel.preproc_line(subtitles, meta, styles, line)

    -- convert comments to part of the text
    line.text = re.sub(line.text, "{([^\\\\{}]*?)}", "《《$1》》")

    -- ensure the line begins with an override tag block
    line.text = (re.match(line.text, "^{") == nil) and "{}" .. line.text or line.text

    -- clean tags and text
    line.text = re.sub(line.text, "}{", "")
    line.text = convert_the_tags_to_a_usable_form(line.text, line.style)

    -- handle \clip and \iclip
    line.text = re.sub(line.text, "(\\\\t\\([^\\\\\\(\\)]*?)(\\\\[^\\(\\)]*?)(\\\\i?clip\\([^\\)]*?\\))([^\\)]*?\\))",
        "$1$2$4$1$3\\)")
    line.text = re.sub(line.text, "(\\\\t\\([^\\\\\\(\\)]*?)(\\\\i?clip\\([^\\)]*?\\))(\\\\[^\\)]*?\\))", "$1$3$1$2\\)")
    line.text = re.sub(line.text, "(\\\\t\\([^\\(\\)]*?)\\(([^\\)]*?)\\)([^\\)]*?\\))", "$1#$2\\$$3")
    clip_and_iclip = ""
    for find_clip_and_iclip_outside_t in re.gfind(line.text, "\\\\i?clip\\([^\\(\\)]*?\\)") do
        clip_and_iclip = clip_and_iclip .. find_clip_and_iclip_outside_t
    end
    for find_clip_and_iclip_inside_t in re.gfind(line.text, "\\\\t\\([^\\(\\)]*?#[^\\)]*?\\$[^\\)]*?\\)") do
        clip_and_iclip = clip_and_iclip .. find_clip_and_iclip_inside_t
    end
    line.text = re.sub(line.text, "\\\\i?clip\\([^\\(\\)]*?\\)", "")
    line.text = re.sub(line.text, "\\\\t\\([^\\(\\)]*?#[^\\)]*?\\$[^\\)]*?\\)", "")

    -- prepare the text for segmentations
    line.text = re.sub(line.text, "\\\\N", "\\\\N\\\\N")
    line.text = "\\N" .. line.text .. "\\N"

    -- prepare the text and tags for the reverse process
    local wrapstyle = get_warpstyle(subtitles)
    line.text = prepare_first_step(line, wrapstyle)

    local sorted_and_separated_t_tags = prepare_t_tags(line.text)

    local ready_to_reverse_lines = prepare_2nd_step(line.text)

    local initial_values = get_initial_values(line.styleref, wrapstyle)

    -- reverse
    line.text = reverse_each_line(initial_values, ready_to_reverse_lines, sorted_and_separated_t_tags)

    -- return \clip and \iclip
    line.text = "{" .. clip_and_iclip .. re.sub(line.text, "{", "", 1)

    -- convert tags to the appropriate form for output
    line.text = return_the_tags_to_their_correct_form(line.text, line.style)
    line.text = re.sub(line.text, "(\\\\t\\([^\\(\\)]*?)#([^\\)]*?)\\$([^\\)]*?\\))", "$1\\($2\\)$3")

    -- remove empty blocks
    line.text = re.sub(line.text, "{}", "")

    -- return comments to their correct form
    line.text = re.sub(line.text, "《《([^\\\\{}]*?)》》", "{$1}")

    return line
end

function rtl(text)
    text = removeRTLChars(text)

    text = re.sub(text, "{([^\\\\{}]*?)}", "《《$1》》")

    text = (re.match(text, "^{") == nil) and "{}" .. text or text

    text = convert_the_tags_to_a_usable_form(text)

    text = re.sub(text, "\\\\N", "\\\\N\\\\N")
    text = "\\N" .. text .. "\\N"

    local tag_text_table = segmentation_based_on_tags(text)

    tag_text_table = change_tags_inside_t(tag_text_table)

    tag_text_table = remove_effectless_tags(tag_text_table)

    local wrapstyle = get_warpstyle(subtitles)
    tag_text_table = handle_soft_line_breaks(tag_text_table, wrapstyle)

    tag_text_table = retutn_tags_inside_t_to_notmal(tag_text_table)

    local prepared_text = ""
    for i = 1, #tag_text_table do
        prepared_text = prepared_text .. tag_text_table[i].tag .. tag_text_table[i].text
    end
    prepared_text = "\\N" .. prepared_text

    local breaks_table = segmentation_based_on_breaks(prepared_text)

    for i = 1, #breaks_table do
        breaks_table[i] = re.sub(breaks_table[i], "}([^{]+)", "}" .. LRM .. RLE .. "$1" .. RLM .. PDF)
    end

    for i = 2, #breaks_table do
        if re.match(breaks_table[i], "th¡s ¡s soft not hard") then
            breaks_table[i] = re.sub(breaks_table[i], "th¡s ¡s soft not hard", "")
            breaks_table[i] = "\\n" .. breaks_table[i]
        else
            breaks_table[i] = "\\N" .. breaks_table[i]
        end
    end

    local text = ""
    for i = 1, #breaks_table do
        text = text .. breaks_table[i]
    end

    text = return_the_tags_to_their_correct_form(text)

    text = re.sub(text, "{}", "")

    text = re.sub(text, "《《([^\\\\{}]*?)》》", "{$1}")

    return text
end

function unrtl(line)
    if re.match(line.text, LRM) or re.match(line.text, RLE) or re.match(line.text, RLM) or re.match(line.text, PDF) then
        line.text = removeRTLChars(line.text)
        line = reverse(line)
    end
    return line.text
end

-- RTL
function Rtl(subtitles, selected_lines, active_line)
    _G.subtitles = subtitles

    for z, i in ipairs(selected_lines) do
        local line = subtitles[i]

        line = reverse(line)
        line.text = rtl(line.text)

        subtitles[i] = line
    end
    aegisub.set_undo_point(rtl_script_name)
end

-- Un-RTL
function Unrtl(subtitles, selected_lines, active_line)
    _G.subtitles = subtitles

    for z, i in ipairs(selected_lines) do
        local line = subtitles[i]

        line.text = unrtl(line)

        subtitles[i] = line
    end
    aegisub.set_undo_point(unrtl_script_name)
end

-- RTL (w/o Reverse)
function rtlwo_reverse(subtitles, selected_lines, active_line)
    _G.subtitles = subtitles

    for z, i in ipairs(selected_lines) do
        local line = subtitles[i]

        line.text = rtl(line.text)

        subtitles[i] = line
    end
    aegisub.set_undo_point(rtlwo_reverse_script_name)
end

----- RTL Editor -----
local editor_btn = {
    Ok = 1,
    OkWORtl = 2,
    Cancel = 3,
}

local function openEditor(str)
    local btns = { "OK", "OK w/o RTL", "Cancel" }

    local btn_switch_case = {}
    for key, value in pairs(btns) do
        btn_switch_case[value] = key
    end

    local config = {
        {
            class = "label",
            label = "Press Ctrl+Shift at the right side of your keyboard to switch to RTL mode.",
            x = 0,
            y = 0
        },
        { class = "textbox", name = "editor", value = str, x = 0, y = 1, width = 33, height = 11 }
    }
    local btn, result = aegisub.dialog.display(config, btns, { ok = "OK", cancel = "Cancel" })
    if btn == true then btn = "OK" elseif btn == false then btn = "Cancel" end
    return btn_switch_case[btn], result.editor
end

function RtlEditor(subtitles, selected_lines)
    _G.subtitles = subtitles

    if #selected_lines > 1 then
        return
    end
    local line = subtitles[selected_lines[1]]

    local text = unrtl(line)
    text = utf8.gsub(text, "\\[Nn]", "\n")
    local btn, newText = openEditor(text)

    if btn == editor_btn.Cancel then
        return
    end
    newText = utf8.gsub(newText, "\n", "\\N")
    line.text = newText

    if btn == editor_btn.Ok then
        line = reverse(line)
        line.text = rtl(line.text)
    end

    subtitles[selected_lines[1]] = line

    aegisub.set_undo_point(rtleditor_script_name)
end

----- Split at Tags -----
local Split = {}

function Split:splitAtTags(line)
    -- handle \r
    line.text = replace_r_with_tags(line.text, line.style)
    -- Convert float to neatly formatted string
    local function float2str(f)
        return string.format("%.3f", f):gsub("%.(%d-)0+$", "%.%1"):gsub("%.$", "")
    end

    -- Returns the position of a line
    local function get_pos(line)
        local _, _, posx, posy = line.text:find("\\pos%(([%d%.%-]*),([%d%.%-]*)%)")
        if posx == nil then
            _, _, posx, posy = line.text:find("\\move%(([%d%.%-]*),([%d%.%-]*),")
            if posx == nil then
                local _, _, align_n = line.text:find("\\an([%d%.%-]*)")
                if align_n == nil then
                    local _, _, align_dumb = line.text:find("\\a([%d]+)")
                    if align_dumb == nil then
                        -- If the line has no alignment tags
                        posx = line.x
                        posy = line.y
                    else
                        -- If the line has the \a alignment tag
                        local vid_x, vid_y = aegisub.video_size()
                        align_dumb = tonumber(align_dumb)
                        if align_dumb > 8 then
                            posy = vid_y / 2
                        elseif align_dumb > 4 then
                            posy = line.eff_margin_t
                        else
                            posy = vid_y - line.eff_margin_b
                        end
                        local _temp = align_dumb % 4
                        if _temp == 1 then
                            posx = line.eff_margin_l
                        elseif _temp == 2 then
                            posx = line.eff_margin_l +
                                (vid_x - line.eff_margin_l -
                                    line.eff_margin_r) / 2
                        else
                            posx = vid_x - line.eff_margin_r
                        end
                    end
                else
                    -- If the line has the \an alignment tag
                    local vid_x, vid_y = aegisub.video_size()
                    align_n = tonumber(align_n)
                    local _temp = align_n % 3
                    if align_n > 6 then
                        posy = line.eff_margin_t
                    elseif align_n > 3 then
                        posy = vid_y / 2
                    else
                        posy = vid_y - line.eff_margin_b
                    end
                    if _temp == 1 then
                        posx = line.eff_margin_l
                    elseif _temp == 2 then
                        posx = line.eff_margin_l +
                            (vid_x - line.eff_margin_l - line.eff_margin_r) /
                            2
                    else
                        posx = vid_x - line.eff_margin_r
                    end
                end
            end
        end
        return tonumber(posx), tonumber(posy)
    end

    -- Returns the origin of a line
    local function get_org(line)
        local _, _, orgx, orgy = line.text:find("\\org%(([%d%.%-]*),([%d%.%-]*)%)")
        if orgx == nil then return get_pos(line) end
        return tonumber(orgx), tonumber(orgy)
    end

    -- Returns a table of tag-value pairs
    -- Supports fn but ignores r because fuck r (update: now there is no r)
    local function full_state_subtable(tag)
        -- Store time tags in their own table, so they don't interfere
        local time_tags = {}
        for ttag in tag:gmatch("\\t%b()") do table.insert(time_tags, ttag) end

        -- Remove time tags from the string so we don't have to deal with them
        tag = tag:gsub("\\t%b()", "")

        local state_subtable = {}

        for t in tag:gmatch("\\[^\\{}]*") do
            local ttag, tparam = "", ""
            if t:match("\\fn") ~= nil then
                ttag, tparam = t:match("\\(fn)(.*)")
            else
                ttag, tparam = t:match("\\([1-4]?%a+)(%A.*)")
            end
            state_subtable[ttag] = tparam
        end

        -- Dump the time tags back in
        if #time_tags > 0 then state_subtable["t"] = time_tags end

        return state_subtable
    end

    local splits = {}
    local line = util.copy(line)

    -- clean tags and text
    line.text = re.sub(line.text, '}{', '')  -- combine redundant back to back tag parts
    line.text = re.sub(line.text, '^ +', '') -- trim redundant spaces
    line.text = re.sub(line.text, '^({[^{}]*}) +', '\\1')
    line.text = re.sub(line.text, ' +$', '')

    -- Read in styles and meta
    local meta, styles = karaskel.collect_head(subtitles, false)

    -- Preprocess
    karaskel.preproc_line(subtitles, meta, styles, line)

    -- Get position and origin
    local px, py = get_pos(line)
    local ox, oy = get_org(line)

    -- If there are rotations in the line, then write the origin
    local do_org = false

    if line.text:match("\\fr[xyz]") ~= nil then do_org = true end

    -- Turn all \Ns into the newline character
    -- line.text=line.text:gsub("\\N","\n")

    -- Make sure any newline followed by a non-newline character has a tag afterwards
    -- (i.e. force breaks at newlines)
    -- line.text=line.text:gsub("\n([^\n{])","\n{}%1")

    -- Make line table
    local line_table = segmentation_based_on_tags(line.text)
    local lines_added = 0
    local line_table_copy = util.copy(line_table)
    for i, e in ipairs(line_table_copy) do
        local m = re.match(e.text, "^( *)(.*?)( *)$")

        if m[2].str ~= "" then
            table.insert(line_table, i + lines_added, { tag = e.tag, text = rtl(m[2].str) })
            lines_added = lines_added + 1
        end
        e.text = rtl(m[3].str)
        if m[4].str ~= "" then
            table.insert(line_table, i + lines_added + 1, { tag = e.tag, text = rtl(m[4].str) })
            lines_added = lines_added + 1
        end
    end

    -- Stores current state of the line as style table
    local current_style = util.deep_copy(line.styleref)

    -- Stores the width of each section
    local substr_data = {}

    -- Total width of the line
    local cum_width = 0
    -- Total height of the line
    -- cum_height=0
    -- Stores the various cumulative widths for each linebreak
    -- subs_width={}
    -- subs_index=1

    -- First pass to collect size data
    for i, val in ipairs(line_table) do
        -- Create state subtable
        local subtable = full_state_subtable(val.tag)

        -- Fix style tables to reflect override tags
        current_style.fontname = subtable["fn"] or current_style.fontname
        current_style.fontsize = tonumber(subtable["fs"]) or
            current_style.fontsize
        current_style.scale_x = tonumber(subtable["fscx"]) or
            current_style.scale_x
        current_style.scale_y = tonumber(subtable["fscy"]) or
            current_style.scale_y
        current_style.spacing = tonumber(subtable["fsp"]) or
            current_style.spacing
        current_style.align = tonumber(subtable["an"]) or
            current_style.align
        if subtable["b"] ~= nil then
            if subtable["b"] == "1" then
                current_style.bold = true
            else
                current_style.bold = false
            end
        end
        if subtable["i"] ~= nil then
            if subtable["i"] == "1" then
                current_style.italic = true
            else
                current_style.italic = false
            end
        end
        if subtable["a"] ~= nil then
            local dumbalign = tonumber(subtable["a"])
            local halign = dumbalign % 4
            local valign = 0
            if dumbalign > 8 then
                valign = 3
            elseif dumbalign > 4 then
                valign = 6
            end
            current_style.align = valign + halign
        end

        -- Store this style table
        val.style = util.deep_copy(current_style)

        -- Get extents of the section. _sdesc is not used
        -- Temporarily remove all newlines first
        local swidth, sheight, _sdesc, sext =
            aegisub.text_extents(current_style, val.text:gsub("\n", ""))

        -- aegisub.log("Text: %s\n--w: %.3f\n--h: %.3f\n--d: %.3f\n--el: %.3f\n\n",
        --	val.text, swidth, sheight, _sdesc, sext)

        -- Add to cumulative width
        cum_width = cum_width + swidth

        -- Total height of the line
        local theight = 0

        -- Handle tasks for a line that has a newline
        --[[if val.text:match("\n")~=nil then
            --Add sheight for each newline, if any
            for nl in val.text:gmatch("\n") do
                theight=theight+sheight
            end

            --Add the external lead to account for the line of normal text
            --theight=theight+sext

            --Store the current cumulative width and reset it to zero
            subs_width[subs_index]=cum_width
            subs_index=subs_index+1
            cum_width=0

            --Add to cumulative height
            cum_height=cum_height+theight
        else
            theight=sheight+sext
        end]]
        --

        -- Add data to data table
        table.insert(substr_data, {
            ["width"] = swidth,
            ["height"] = theight,
            ["subtable"] = subtable
        })
    end

    -- Store the last cumulative width
    -- subs_width[subs_index]=cum_width

    -- Add the last cumulative height
    -- cum_height=cum_height+substr_data[#substr_data].height

    -- Stores current state of the line as a state subtable
    local current_subtable = {}
    --[[current_subtable=shallow_copy(substr_data[1].subtable)
    if current_subtable["t"]~=nil then
        current_subtable["t"]=shallow_copy(substr_data[1].subtable["t"])
    end]]

    -- How far to offset the x coordinate
    local xoffset = 0

    -- How far to offset the y coordinate
    -- yoffset=0

    -- Newline index
    -- nindex=1

    -- Ways of calculating the new x position
    local xpos_func = {}
    -- Left aligned
    xpos_func[1] = function(w) return px + xoffset end
    -- Center aligned
    xpos_func[2] = function(w)
        return px - cum_width / 2 + xoffset + w / 2
    end
    -- Right aligned
    xpos_func[0] = function(w) return px - cum_width + xoffset + w end

    -- Ways of calculating the new y position
    --[[ypos_func={}
    --Bottom aligned
    ypos_func[1]=function(h)
            return py-cum_height+yoffset+h
        end
    --Middle aligned
    ypos_func[2]=function(h)
            return py-cum_height/2+yoffset+w/2
        end
    --Top aligned
    ypos_func[3]=function(h)
            return py+yoffset
        end]]
    --

    -- Second pass to generate lines
    for i, val in ipairs(line_table) do
        -- Here's where the action happens
        local new_line = util.copy(line)

        -- Fix state table to reflect current state
        for tag, param in pairs(substr_data[i].subtable) do
            if tag == "t" then
                if current_subtable["t"] == nil then
                    current_subtable["t"] = util.copy(param)
                else
                    -- current_subtable["t"]={unpack(current_subtable["t"]),unpack(param)}
                    for _, subval in ipairs(param) do
                        table.insert(current_subtable["t"], subval)
                    end
                end
            else
                current_subtable[tag] = param
            end
        end

        -- Figure out where the new x and y coords should be
        local new_x = xpos_func[current_style.align % 3](substr_data[i].width)
        -- new_y=ypos_func[math.ceil(current_style.align/3)](substr_data[i].height)

        -- Check if the text ends in whitespace
        -- local wsp = val.text:gsub("\n", ""):match("%s+$")

        -- Modify positioning accordingly
        -- if wsp ~= nil then
        --     local wsp_width = aegisub.text_extents(val.style, wsp)
        --     if current_style.align % 3 == 2 then
        --         new_x = new_x - wsp_width / 2
        --     elseif current_style.align % 3 == 0 then
        --         new_x = new_x - wsp_width
        --     end
        -- end

        -- Increase x offset
        xoffset = xoffset + substr_data[i].width

        -- Handle what happens in the line contains newlines
        --[[if val.text:match("\n")~=nil then
            --Increase index and reset x offset
            nindex=nindex+1
            xoffset=0
            --Increase y offset
            yoffset=yoffset+substr_data[i].height

            --Remove the last newline and convert back to \N
            val.text=val.text:gsub("\n$","")
            val.text=val.text:gsub("\n","\\N")
        end]]
        --

        -- Start rebuilding text
        local rebuilt_tag = string.format("{\\pos(%s,%s)}", float2str(new_x),
            float2str(py))

        -- Add the remaining tags
        for tag, param in pairs(current_subtable) do
            if tag == "t" then
                for k, ttime in ipairs(param) do
                    rebuilt_tag = rebuilt_tag:gsub("}", ttime .. "}")
                end
            elseif tag ~= "pos" and tag ~= "org" then
                rebuilt_tag = rebuilt_tag:gsub("{", "{\\" .. tag .. param)
            end
        end

        if do_org then
            rebuilt_tag = rebuilt_tag:gsub("{", string.format(
                "{\\org(%s,%s)",
                float2str(ox), float2str(oy)))
        end

        -- reverse back text
        -- local match = re.match(val.text, '^(['..Split.puncs..']*)(.*[^'..Split.puncs..'])(['..Split.puncs..']*)$')
        -- aegisub.log('Matched Text 2:\n'..serializeTable(match)..'\n')
        -- if match then
        --     val.text = utf8.reverse(match[4].str)..match[3].str..utf8.reverse(match[2].str)
        -- end

        -- clean text
        val.text = re.sub(val.text, '^ +', '') -- trim redundant spaces
        val.text = re.sub(val.text, ' +$', '')
        val.text = re.sub(val.text, '^[' .. RLE .. ' ]+$', '')

        new_line.text = rebuilt_tag .. val.text

        -- Insert the new line
        if val.text ~= "" then
            table.insert(splits, 1, new_line)
        end
    end

    return splits
end

function Split:splitAtTagsWreverse(line)
    local result = {}
    local line = util.copy(line)
    result.reverse = reverse(line)
    result.splits = Split:splitAtTags(result.reverse)
    return result
end

----- Split at Tags -----
function SplitAtTags(subtitles, selected_lines, active_line)
    _G.subtitles = subtitles

    local lines_added = 0
    for i, n in ipairs(selected_lines) do
        local line = subtitles[n + lines_added]

        local result = Split:splitAtTagsWreverse(line);

        line.comment = true
        subtitles[n + lines_added] = line
        for _, l in ipairs(result.splits) do
            subtitles.insert(n + lines_added + 1, l)
            lines_added = lines_added + 1
        end
    end

    aegisub.set_undo_point(split_at_tags_script_name)
end

----- Split at Spaces -----
function SplitAtSpaces(subtitles, selected_lines, active_line)
    _G.subtitles = subtitles

    local lines = {}

    -- add {} before spaces
    for i, n in ipairs(selected_lines) do
        local line = subtitles[n]
        line = reverse(line)
        line.text = (utf8.match(line.text, "^{") == nil) and "{}" .. line.text or line.text
        local parts = segmentation_based_on_tags(line.text)
        line.text = ""
        for i = 1, #parts do
            local space_parts = {}
            for space, not_space in utf8.gmatch(parts[i].text, "( +)([^ ]*)") do
                table.insert(space_parts, { s = space, n = not_space })
            end
            parts[i].text = utf8.gsub(parts[i].text, "([^ ]-) .*", "%1")
            parts[i].text = "{}" .. parts[i].text
            for i2 = 1, #space_parts do
                parts[i].text = "{}" .. space_parts[i2].n .. space_parts[i2].s .. parts[i].text
            end
        end
        for i = 1, #parts do
            line.text = line.text .. parts[i].tag .. parts[i].text
        end
        lines[i] = line
    end

    local lines_added = 0
    for i, line in ipairs(lines) do
        -- split at tags
        result = Split:splitAtTags(line)

        -- add lines
        local num = selected_lines[i]

        local l = subtitles[num + lines_added]
        l.comment = true
        subtitles[num + lines_added] = l

        for _, s in ipairs(result) do
            subtitles.insert(num + lines_added + 1, s)
            lines_added = lines_added + 1
        end
    end

    aegisub.set_undo_point(split_at_spaces_script_name)
end

----- Reverse + Split (at Tags) -----
function ReverseSplitAtTags(subtitles, selected_lines, active_line)
    _G.subtitles = subtitles

    local lines_added = 0
    for i, n in ipairs(selected_lines) do
        local line = subtitles[n + lines_added]

        local result = Split:splitAtTags(line);

        line.comment = true
        subtitles[n + lines_added] = line
        for _, l in ipairs(result) do
            subtitles.insert(n + lines_added + 1, l)
            lines_added = lines_added + 1
        end
    end

    aegisub.set_undo_point(reverse_split_at_tags_script_name)
end

----- Reverse at Tags -----
function ReverseAtTags(subtitles, selected_lines, active_line)
    _G.subtitles = subtitles

    local lines_added = 0
    for i, n in ipairs(selected_lines) do
        local line = subtitles[n + lines_added]
        local new_line = util.copy(line);

        new_line.text = removeRTLChars(new_line.text);
        local reverse = reverse(new_line);

        line.comment = true
        subtitles[n + lines_added] = line
        subtitles.insert(n + lines_added + 1, reverse)
    end

    aegisub.set_undo_point(reverse_at_tags_script_name)
end

----- Extend Move -----
function ExtendMove(subtitles, selected_lines, active_line)
    for _, i in ipairs(selected_lines) do
        local line = subtitles[i]

        line.text = utf8.gsub(line.text,
            "\\move%(([%d%.%-]*),([%d%.%-]*),([%d%.%-]*),([%d%.%-]*),([%d%.%-]*),([%d%.%-]*)%)",
            function(x1, y1, x2, y2, t1, t2)
                local f1 = aegisub.frame_from_ms(line.start_time + t1)
                if f1 ~= nil then
                    t1 = aegisub.ms_from_frame(f1)
                    local f2 = aegisub.frame_from_ms(line.start_time + t2)
                    t2 = aegisub.ms_from_frame(f2)
                end
                local dt = t2 - t1
                local dxdt = (x2 - x1) / dt
                local dydt = (y2 - y1) / dt

                local s = aegisub.ms_from_frame(aegisub.frame_from_ms(line.start_time))
                local e = aegisub.ms_from_frame(aegisub.frame_from_ms(line.end_time))
                local ds = t1 - s
                local de = e - t2
                if ds < 0 then ds = 0 end
                if de < 0 then de = 0 end

                x1 = round(x1 - ds * dxdt, 2)
                x2 = round(x2 + de * dxdt, 2)
                y1 = round(y1 - ds * dydt, 2)
                y2 = round(y2 + de * dydt, 2)

                return "\\move(" .. x1 .. "," .. y1 .. "," .. x2 .. "," .. y2 .. ")"
            end)

        subtitles[i] = line
    end

    aegisub.set_undo_point(extend_move_script_name)
end

----- Register Scripts -----
aegisub.register_macro(paknevis_script_name, 'Fix your shity writing habbits! (Unretarded Lines Only)', PakNevis)
aegisub.register_macro(extend_move_script_name, 'Extend \\move based on line\'s time.', ExtendMove)
aegisub.register_macro(unretard_script_name, 'Unretard your retarted Persian typing! (Retarded Lines Only)', Unretard)
aegisub.register_macro(rtl_script_name, 'Fix RTL languages displaying issues. (Unretarded Lines Only)', Rtl)
aegisub.register_macro(rtlwo_reverse_script_name, 'Fixes RTL languages displaying issues without reversing.',
    rtlwo_reverse)
aegisub.register_macro(unrtl_script_name, 'Undo RTL function effects.', Unrtl)
aegisub.register_macro(rtleditor_script_name, 'An editor for easy editing of RTL language lines.', RtlEditor)
aegisub.register_macro(split_at_tags_script_name, 'A splitter (at tags) for RTL language lines.', SplitAtTags)
aegisub.register_macro(split_at_spaces_script_name, 'A splitter (at spaces) for RTL language lines.', SplitAtSpaces)
aegisub.register_macro(reverse_split_at_tags_script_name, 'Split / Reverse at Tags + Split / Split at Tags.',
    ReverseSplitAtTags)
aegisub.register_macro(reverse_at_tags_script_name, 'Reverse line at tags to use it with other LTR automations.',
    ReverseAtTags)
