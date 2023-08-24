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

----- Global Variables ----
LRM = utf8.char(0x200E)
RLE = utf8.char(0x202B)
RLM = utf8.char(0x200F)
PDF = utf8.char(0x202C)
subtitles = nil

----- Global Functions -----
local function removeRleChars(text)
    text = re.sub(text, RLE, "")
    return text
end

local function unrtl(text)
    text, _ = re.sub(text, "^((?:\\{.*?\\})*)" .. RLE, "\\1")
    text, _ = re.sub(text, "(\\\\[Nn])((?:\\{.*?\\})*)" .. RLE, "\\1\\2")
    return text
end

local function rtl(text)
    text = unrtl(text)
    text, _ = re.sub(text, "^((?:\\{.*?\\})*)", "\\1" .. RLE)
    text, _ = re.sub(text, "(\\\\[Nn])((?:\\{.*?\\})*)", "\\1\\2" .. RLE)
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

-- expand to table of tag-text
local function expand(text)
    local result = {}

    local firstPart = re.match(text, "^([^{].*?)(?:\\{|$)")
    if firstPart ~= nil then
        table.insert(result, { tag = "", text = firstPart[2].str })
    end

    for f in re.gfind(text, "(\\{.*?\\})([^{]*)") do
        local m = re.match(f, "(\\{.*?\\})([^{]*)")
        if m[2] == nil then m[2] = { str = "" } end
        if m[3] == nil then m[3] = { str = "" } end
        table.insert(result, { tag = m[2].str, text = m[3].str })
    end

    return result
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
            line.text = utf8.gsub(line.text, '^([' .. ending_punc .. ']+)([^\\]+)$', '%2gce') -- ending puncs
            line.text = utf8.gsub(line.text, '^([' .. ending_punc .. ']+)([^\\]+)(\\[Nn])', '%2gce%3') -- ending puncs
            line.text = utf8.gsub(line.text, '(\\[Nn])([' .. ending_punc .. ']+)([^\\]+)(\\[Nn])', '%1%3gce%4') -- ending puncs
            line.text = utf8.gsub(line.text, '(\\[Nn])([' .. ending_punc .. ']+)([^\\]+)$', '%1%3gce') -- ending puncs
            line.text = utf8.gsub(line.text, '^([^\\]+[^' .. starting_punc .. '])([' .. starting_punc .. ']+)(g?c?e?)$',
                'gcs%1%3') -- starting puncs
            line.text = utf8.gsub(line.text, '^([^\\]+[^' .. starting_punc ..
                '])([' .. starting_punc .. ']+)(g?c?e?)(\\[Nn])', 'gcs%1%3%4') -- starting puncs
            line.text = utf8.gsub(line.text,
                '(\\[Nn])([^\\]+[^' .. starting_punc .. '])([' .. starting_punc .. ']+)(g?c?e?)(\\[Nn])', '%1gcs%2%4%5') -- starting puncs
            line.text = utf8.gsub(line.text, '(\\[Nn])([^\\]+[^' .. starting_punc ..
                '])([' .. starting_punc .. ']+)(g?c?e?)$', '%1gcs%2%3') -- starting puncs
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
function Rtl(sub, sel, act)
    fixinline(sub, sel, act)
    for z, i in ipairs(sel) do
        local l = sub[i]
        text = l.text

        text = text:gsub("££££££££££",LRM)
        :gsub("₩₩₩₩₩₩₩₩₩₩",RLE)
        :gsub("€€€€€€€€€€",RLM)
        :gsub("¥¥¥¥¥¥¥¥¥¥",PDF)

        l.text = text
        sub[i] = l
    end
    aegisub.set_undo_point(rtl_script_name)
end

----- Un-RTL -----
function Unrtl(sub, sel, act)
    for z, i in ipairs(sel) do
        local line = sub[i]
        text = line.text

        text=text:gsub("{([^\\{}]-)}","《《%1》》")
        if text:match("}[^{}]+{") then
            fixinline(sub, {i}, act)
        end
    end
    for zz, ii in ipairs(sel) do
        local line = sub[ii]
        text = line.text

        text = text:gsub("££££££££££","")
        :gsub("₩₩₩₩₩₩₩₩₩₩","")
        :gsub("€€€€€€€€€€","")
        :gsub("¥¥¥¥¥¥¥¥¥¥","")
        :gsub(LRM, "")
        :gsub(RLE , "")
        :gsub(RLM, "")
        :gsub(PDF, "")

        line.text = text
        sub[ii] = line
    end
    aegisub.set_undo_point(unrtl_script_name)
end

----- RTL (w/o Reverse) -----
function rtlwo_reverse(sub, sel, act)
    for z, i in ipairs(sel) do
        local line = sub[i]
        text1 = line.text
        text1 = text1:gsub("{([^\\{}]-)}","《《%1》》")
        text = (text1:match("^{") == nil) and "{}" .. text1 or text1

        text = text:gsub("}([^{]+)", "}"..LRM..RLE.."%1"..RLM..PDF)
        :gsub("\\N", RLM..PDF.."\\N"..LRM..RLE)
        tablo = {}
        for tg, tx in text:gmatch("({[^}]*})([^{]*)") do
            table.insert(tablo, { tag = tg, text = tx})
        end
        local warp = nil
        for q = 1,#sub do
            if sub[q].class == "info" then
                local qq = sub[q]
                if qq.key == "WrapStyle" then
                    warp = qq.value
                    break
                end
            end
        end
        if warp ~= nil and tablo[1].tag:match("\\q") == nil then
            tablo[1].tag=tablo[1].tag:gsub("{","{\\q"..warp)
        end
        for wq = 1,#tablo do
            if tablo[wq].text:match("\\n") then
                for wwq = wq,1,-1 do
                    if tablo[wwq].tag:match("\\q") then
                        if tablo[wwq].tag:match("\\q2") then
                            tablo[wq].text=tablo[wq].text:gsub("\\n",RLM..PDF.."\\n"..LRM..RLE)
                        end
                        break
                    end
                end
            end
        end
        tablo[1].tag=tablo[1].tag:gsub("{\\q"..warp,"{")
        stext = ""
        for s = 1,#tablo do
            stext = stext .. tablo[s].tag .. tablo[s].text
        end
        stext = stext:gsub("{}","")
        :gsub("《《([^\\{}]-)》》","{%1}")

        line.text = stext
        sub[i] = line
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
        { class = "label", label = "Press Ctrl+Shift at the right side of your keyboard to switch to RTL mode.", x = 0,
            y = 0 },
        { class = "textbox", name = "editor", value = str, x = 0, y = 1, width = 33, height = 11 }
    }
    local btn, result = aegisub.dialog.display(config, btns, { ok = "OK", cancel = "Cancel" })
    if btn == true then btn = "OK" elseif btn == false then btn = "Cancel" end
    return btn_switch_case[btn], result.editor
end

function RtlEditor(subtitles, selected_lines)
    if #selected_lines > 1 then
        return
    end
    local line = subtitles[selected_lines[1]]

    local text = unrtl(line.text)
    text = utf8.gsub(text, "\\[Nn]", "\n")
    local btn, newText = openEditor(text)

    if btn == editor_btn.Cancel then
        return
    end
    newText = utf8.gsub(newText, "\n", "\\N")
    if btn == editor_btn.Ok then
        newText = rtl(newText)
    end
    line.text = newText

    subtitles[selected_lines[1]] = line

    aegisub.set_undo_point(rtleditor_script_name)
end

----- Split at Tags -----
local Split = {}

Split.puncs = '.:!،«[(»\\])\\- <>'
Split.line_type_tags = {
    'pos', 'move', 'clip', 'iclip', 'org', 'fade', 'fad', 'an', 'q'
}
Split.style_tags = {
    'i', 'b', 'u', 's', 'bord', 'xbord', 'ybord', 'shad', 'xshad', 'yshad',
    'fn', 'fs', 'fscx', 'fscy', 'fsp', 'fe', 'c', '1c', '2c', '3c', '4c',
    'alpha', '1a', '2a', '3a', '4a', 'an', 'r', 'frz', 'fr'
}
Split.non_style_tags = {
    'be', 'blur', 'frx', 'fry', 'fax', 'fay', 'k', 'K', 'kf', 'ko', 'q',
    'pos', 'move', 'org', 'fad', 'fade', 't', 'clip', 'iclip', 'p', 'pbo'
}
Split.style_names_tags = {
    { 'fontname', 'fn' }, { 'fontsize', 'fs' },
    { 'color1', '1c', '1a' }, { 'color2', '2c', '2a' }, { 'color3', '3c', '3a' }, { 'color4', '4c', '4a' },
    { 'bold', 'b' }, { 'italic', 'i' }, { 'underline', 'u' }, { 'strikeout', 's' },
    { 'scale_x', 'fscx' }, { 'scale_y', 'fscy' }, { 'spacing', 'fsp' }, { 'angle', 'frz' },
    { 'outline', 'bord' }, { 'shadow', 'shad' }, { 'align', 'an' }, { 'encoding', 'fe' }
}
Split.simple_text_value_tags = {
    'fn', 'alpha', '1a', '2a', '3a', '4a', 'c', '1c', '2c', '3c', '4c', 'r'
}
Split.boolean_style_fields = {
    'bold', 'italic', 'underline', 'strikeout'
}

function Split:parse_style(styleref)
    local tags = {}
    -- extract Split.style_names_tags
    for i = 1, #Split.style_names_tags do
        local table = Split.style_names_tags[i]
        local style_name = table[1]
        local tag_name1 = table[2]
        local value = styleref[style_name]
        if re.match(style_name, 'color') ~= nil then
            tags[tag_name1] = re.sub(value, '&H..(.+)', '&H\\1')
            tags[table[3]] = re.match(value, '&H..')[1].str
        else
            if has_value(Split.boolean_style_fields, style_name) then
                if value then
                    value = 1
                else
                    value = 0
                end
            end
            tags[tag_name1] = value
        end
    end
    -- add other defaults
    tags['be'] = 0
    tags['blur'] = 0
    tags['frx'] = 0
    tags['fry'] = 0
    tags['fax'] = 0
    tags['fay'] = 0
    tags['pbo'] = 0
    return tags
end

function Split:parse_tags(tags, line_tags, current_appearance) -- TODO: add r support
    -- handle t tags
    local t_tags = {}
    for t in tags:gmatch("\\t%b()") do -- Thanks lyger!
        table.insert(t_tags, t)
    end
    tags = tags:gsub("\\t%b()", "") -- remove t tags
    if #t_tags > 0 then -- add to table
        current_appearance["t"] = t_tags
    end

    -- other tags
    for t in tags:gmatch("\\[^\\{}]*") do
        local tag, value = "", ""
        if t:match("\\fn") ~= nil then
            tag, value = t:match("\\(fn)(.*)")
        else
            tag, value = t:match("\\([1-4]?%a+)(%A.*)")
        end

        if tag == 'fr' then
            tag = 'frz'
        elseif tag == 'c' then
            tag = '1c'
        end

        -- add line tags to the appropriate list and others to appearance
        if has_value(Split.line_type_tags, tag) == true then
            if has_value(line_tags, tag) == false then
                if tag == 'q' or tag == 'an' then
                    value = tonumber(value)
                end
                line_tags[tag] = value
            end
        else
            if has_value(Split.simple_text_value_tags, tag) == false then
                value = tonumber(value)
            end
            current_appearance[tag] = value
        end
    end
end

function Split:reverse(line)
    local line = util.copy(line)
    -- read in styles and meta
    local meta, styles = karaskel.collect_head(subtitles, false)

    karaskel.preproc_line(subtitles, meta, styles, line)

    -- clean tags and text
    line.text = re.sub(line.text, '}{', '') -- combine redundant back to back tag parts
    line.text = re.sub(line.text, '^ +', '') -- trim redundant spaces
    line.text = re.sub(line.text, '^({[^{}]*}) +', '\\1')
    line.text = re.sub(line.text, ' +$', '')

    -- make tags-text table
    local tag_text_table = expand(line.text)
    -- aegisub.log('Parts:\n'..serializeTable(tag_text_table)..'\n')

    -- reverse process
    local line_tags = {}
    line.text = ''
    -- extract default appearance
    local parsed_style = Split:parse_style(line.styleref)
    -- aegisub.log('Parsed Style:\n'..serializeTable(parsed_style)..'\n')
    local current_appearance = util.deep_copy(parsed_style)
    -- 1nd step (parse)
    for i, val in ipairs(tag_text_table) do
        -- parse tags
        Split:parse_tags(val.tag, line_tags, current_appearance)
        val.tag_list = util.deep_copy(current_appearance)
    end
    -- aegisub.log('New Parts:\n'..serializeTable(tag_text_table)..'\n')

    -- 2nd step (rebuild)
    local last_tag_list = parsed_style
    for i = #tag_text_table, 1, -1 do
        -- get diff and rebuild tags
        local val = tag_text_table[i]
        -- get diff
        -- aegisub.log('Tag List:\n'..serializeTable(val.tag_list)..'\n')
        -- aegisub.log('Last Tag List:\n'..serializeTable(last_tag_list)..'\n')
        local diff = difference(val.tag_list, last_tag_list)
        last_tag_list = val.tag_list
        -- aegisub.log('Diff:\n'..serializeTable(diff)..'\n')
        -- rebuild tags
        local rebuilt_tag = '{}'
        for tag, value in pairs(diff) do
            if tag == "t" then
                for _, t_tag in ipairs(value) do
                    rebuilt_tag = rebuilt_tag:gsub("}", t_tag .. "}")
                end
            else
                rebuilt_tag = rebuilt_tag:gsub("{", "{\\" .. tag .. value)
            end
        end
        if i == #tag_text_table then
            for tag, value in pairs(line_tags) do
                rebuilt_tag = rebuilt_tag:gsub("{", "{\\" .. tag .. value)
            end
        end
        val.tag = rebuilt_tag

        -- flip spaces
        val.text, _ = re.sub(val.text, "^( *)(.*?)( *)$", "\\3\\2\\1")

        -- rebuild line
        line.text = line.text .. val.tag .. val.text
    end

    return line
end

function Split:splitAtTags(line)
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
    -- Supports fn but ignores r because fuck r
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
    line.text = re.sub(line.text, '}{', '') -- combine redundant back to back tag parts
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
    local line_table = expand(line.text)
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
        end]] --

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
        end]] --

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
        end]] --

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
    result.reverse = Split:reverse(line)
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
        local parts = expand(line.text)
        line.text = ""
        for _, p in ipairs(parts) do
            p.text, _ = re.sub(p.text, "( +)", "{}" .. RLE .. "\\1")
            line.text = line.text .. p.tag .. p.text
        end
        lines[i] = line
    end

    local lines_added = 0
    for i, line in ipairs(lines) do
        -- split at tags
        local result = Split:splitAtTagsWreverse(line)

        -- add lines
        local num = selected_lines[i]

        local l = subtitles[num + lines_added]
        l.comment = true
        subtitles[num + lines_added] = l

        for _, s in ipairs(result.splits) do
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

        new_line.text = unrtl(new_line.text);
        local reverse = Split:reverse(new_line);

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

function fixinline(sub, sel, act)
  local meta,styles=karaskel.collect_head(sub,false)
  for si, li in ipairs(sel) do
    local line = sub[li]
    karaskel.preproc_line(sub,meta,styles,line)
    style1 = line.style
    text1 = line.text
    text1 = text1:gsub("{([^\\{}]-)}","《《%1》》")
    otext = (text1:match("^{") == nil) and "{}" .. text1 or text1
    otext = otext:gsub("}{","")
    :gsub(LRM, "")
    :gsub(RLE , "")
    :gsub(RLM, "")
    :gsub(PDF, "")
    :gsub("\\c&","\\1c&")
    :gsub("\\fr([^xyz])","\\frz%1")
    :gsub("\\r([\\}])","\\r"..style1.."%1")
    :gsub("\\s([01])","\\str%1")
    :gsub("\\i([01])","\\ita%1")
    :gsub("\\fs([%d%.])","\\fsize%1")
    :gsub("\\b(%d)","\\bold%1")
    :gsub("\\a(%d)","\\alig%1")
    :gsub("\\p(%d)","\\pic%1")
    :gsub("\\N","\\N\\N")
    otext=otext:gsub("(\\t%([^\\%(%)]-)(\\[^%(%)]-)(\\i?clip%([^%)]-%))([^%)]-%))","%1%2%4%1%3%)")
    :gsub("(\\t%([^\\%(%)]-)(\\i?clip%([^%)]-%))(\\[^%)]-%))","%1%3%1%2%)")
    :gsub("(\\t%([^%(%)]-)%(([^%)]-)%)([^%)]-%))","%1#%2%$%3")
    trnsfrm=""
    for otto in otext:gmatch("\\i?clip%([^%(%)]-%)") do
      trnsfrm=trnsfrm..otto
    end
    for toot in otext:gmatch("\\t%([^%(%)]-#[^%)]-%$[^%)]-%)") do
      trnsfrm=trnsfrm..toot
    end
    otext=otext:gsub("\\i?clip%([^%(%)]-%)","")
    :gsub("\\t%([^%(%)]-#[^%)]-%$[^%)]-%)","")
    otext = "\\N"..otext.."\\N"
    ss_table = {}
    for tgs, txs in otext:gmatch("({[^}]*})([^{]*)") do
      table.insert(ss_table, { tag = tgs, text = txs })
    end
    local warp = nil
    for qq = 1,#sub do
      if sub[qq].class == "info" then
        local qw = sub[qq]
        if qw.key == "WrapStyle" then
          warp = qw.value
          break
        end
      end
    end
    if warp ~= nil and ss_table[1].tag:match("\\q") == nil then
      ss_table[1].tag=ss_table[1].tag:gsub("{","{\\q"..warp)
    end
    for wq = 1,#ss_table do
      if ss_table[wq].text:match("\\n") then
        for wwq = wq,1,-1 do
          if ss_table[wwq].tag:match("\\q") then
            if ss_table[wwq].tag:match("\\q2") then
              ss_table[wq].text=ss_table[wq].text:gsub("\\n","\\N\\Nth¡s ¡s soft not hard")
            end
            break
          end
        end
      end
    end
    stext = ""
    for ss = 1,#ss_table do
      stext = stext .. ss_table[ss].tag .. ss_table[ss].text
    end
    stext = "\\N"..stext
    ar_table = {}
    for tg, tx in stext:gmatch("({[^}]*})([^{]*)") do
      table.insert(ar_table, { tag = tg, text = tx })
    end
    repeat
      local tagt = false
      for l = 1,#ar_table do
        if ar_table[l].tag:match("\\t%([^%(%)\\]-\\") then
          tagt = true
          ar_table[l].tag=ar_table[l].tag:gsub("(\\t%([^%(%)\\]-)\\","%1¡")
        end
      end
    until not tagt
    stags = {"\\fsize","\\fscx","\\fscy","\\fsp","\\1c","\\2c","\\3c","\\4c","\\1a","\\2a","\\3a","\\4a","\\bord","\\shad","\\bold","\\ita","\\u","\\str","\\frz","\\fn","\\fe","\\blur","\\be","\\frx","\\fry","\\fax","\\fay","\\xbord","\\xshad","\\ybord","\\yshad","\\pic","\\pbo","\\q"}
    for ord = 1,#ar_table do
      for ats = 1,#stags do
        if ar_table[ord].tag:match(stags[ats]) then
          local clean = {}
          for dro in ar_table[ord].tag:gmatch(stags[ats]) do
            table.insert(clean,  dro)
          end
          ar_table[ord].tag=ar_table[ord].tag:gsub(stags[ats].."[^\\}]+","", #clean - 1)
        end
      end
    end
    for bb = 1,#ar_table do
      if ar_table[bb].tag:match("\\alpha") then
        local cleana = {}
        for droa in ar_table[bb].tag:gmatch("(\\alpha)") do
          table.insert(cleana,  droa)
        end
        ar_table[bb].tag=ar_table[bb].tag:gsub("\\alpha[^\\}]+","", #cleana - 1)
        local beforea = ar_table[bb].tag:match("(.+)\\alpha")
        local aftera = ar_table[bb].tag:match("\\alpha[^\\}]+(.+)")
        local alpha = ar_table[bb].tag:match("\\alpha[^\\}]+")
        for cc = 1,4 do
          beforea=beforea:gsub("\\"..cc.."a[^\\}]+","")
          if aftera:match("\\"..cc.."a") == nil then
            alpha=alpha:gsub("\\alpha([^\\}]+)","\\alpha%1\\"..cc.."a%1")
          end
        end
        ar_table[bb].tag = beforea..alpha..aftera
      end
    end
    for dd = 1,#ar_table do
      ar_table[dd].tag=ar_table[dd].tag:gsub("\\alpha([^\\}]+)","")
    end
    local ff = nil
    rtags = {"\\fsize","\\fscx","\\fscy","\\fsp","\\1c","\\2c","\\3c","\\4c","\\1a","\\2a","\\3a","\\4a","\\bord","\\shad","\\bold","\\ita","\\u","\\str","\\frz","\\fn","\\fe"}
    rsty = {"fontsize","scale_x","scale_y","spacing","color1","color2","color3","color4","color1","color2","color3","color4","outline","shadow","bold","italic","underline","strikeout","angle","fontname","encoding"}
    for ee = 1,#ar_table do
      if ar_table[ee].tag:match("\\r") then
        local cleanr = {}
        for dror in ar_table[ee].tag:gmatch("(\\r)") do
          table.insert(cleanr,  dror)
        end
        ar_table[ee].tag=ar_table[ee].tag:gsub("\\r[^\\}]+","", #cleanr -1)
        ff = ar_table[ee].tag:match("\\r([^\\}]+)")
        rtagsty = {}
        for ir = 1,#sub do
          if sub[ir].class == "style" then
            local rst = sub[ir]
            if ff == rst.name then
              rstyref = rst
              break
            end
          end
        end
        for hr = 1,#rsty do
          rtagsty[hr] = rstyref[rsty[hr]]
        end
        for hh = 5,8 do
          rtagsty[hh] = rtagsty[hh]:gsub("H%x%x","H")
        end
        for ii = 9,12 do
          rtagsty[ii] = rtagsty[ii]:match("&H%x%x").."&"
        end
        local beforer = ar_table[ee].tag:match("(.+)\\r")
        local afterr = ar_table[ee].tag:match("\\r[^\\}]+(.+)")
        local rtag = ar_table[ee].tag:match("\\r[^\\}]+")
        for jj = 1,#rtags do
          beforer=beforer:gsub(rtags[jj].."[^\\}]+","")
          if afterr:match(rtags[jj]) == nil then
            local tag3 = rtagsty[jj]
            if type(tag3) == "string" or type(tag3) == "number" then
              rtag=rtag:gsub("(\\r[^\\}]+)","%1"..rtags[jj]..tag3)
            else
              if tag3 then
                rtag=rtag:gsub("(\\r[^\\}]+)","%1"..rtags[jj].."1")
              else
                rtag=rtag:gsub("(\\r[^\\}]+)","%1"..rtags[jj].."0")
              end
            end
          end
        end
        ar_table[ee].tag = beforer..rtag..afterr
      end
    end
    for kk = 1,#ar_table do
      ar_table[kk].tag=ar_table[kk].tag:gsub("\\r[^\\}]+","")
    end
    ttags = {"\\fsize","\\fsp","\\1c","\\2c","\\3c","\\4c","\\1a","\\2a","\\3a","\\4a","\\fscx","\\fscy","\\frz","\\bord","\\shad","\\fax","\\fay","\\fry","\\frx","\\blur","\\be","\\xbord","\\xshad","\\ybord","\\yshad"}
    ttags2 = {"¡fsize","¡fsp","¡1c","¡2c","¡3c","¡4c","¡1a","¡2a","¡3a","¡4a","¡fscx","¡fscy","¡frz","¡bord","¡shad","¡fax","¡fay","¡fry","¡frx","¡blur","¡be","¡xbord","¡xshad","¡ybord","¡yshad"}
    repeat
      local cleant = false
      for tcl = 1,#ar_table do
        for tcle = 1,#ttags do
          if ar_table[tcl].tag:match(ttags2[tcle]) then
            local aftert = ar_table[tcl].tag:match(ttags2[tcle].."[^¡%)]+(.+)")
            if aftert:match(ttags[tcle]) then
              cleant = true
              ar_table[tcl].tag=ar_table[tcl].tag:gsub(ttags2[tcle].."[^¡%)]+","",1)
              ar_table[tcl].tag=ar_table[tcl].tag:gsub("\\t%([^¡%)]-%)","")
            end
          end
        end
      end
    until not cleant
    repeat
      local tagt2 = false
      for l = 1,#ar_table do
        if ar_table[l].tag:match("\\t%([^%(%)¡]-¡") then
          tagt2 = true
          ar_table[l].tag=ar_table[l].tag:gsub("(\\t%([^%(%)¡]-)¡","%1\\")
        end
      end
    until not tagt2
    artext = ""
    for ar = 1,#ar_table do
      artext = artext .. ar_table[ar].tag .. ar_table[ar].text
    end
    artext = "\\N"..artext
    t_table = {}
    for t in artext:gmatch("(\\N.-)\\N") do
      table.insert(t_table, t)
    end
    for aaat = 1,#t_table do
      t_table[aaat]=t_table[aaat]:gsub("\\N","")
    end
    for bbbt = 1,#t_table do
      t_table[bbbt] = (t_table[bbbt]:match("^{") == nil) and "{}" .. t_table[bbbt] or t_table[bbbt]
    end
    ttag = {}
    tt_table = {}
    for xt = 1,#t_table do
      ttt_table = {}
      for tgt, txt in t_table[xt]:gmatch("({[^}]*})([^{]*)") do
        table.insert(ttt_table, { tag = tgt, text = txt })
      end
      tt_table[xt] = ttt_table
      tag = {}
      for tnt = 1,#tt_table[xt] do
        ag = {}
        if tt_table[xt][tnt].tag:match("\\t") then
          for tt in tt_table[xt][tnt].tag:gmatch("(\\t%([^%(%)]-%))") do
            table.insert(ag, tt)
          end
        else
          ag[1] = ""
        end
        for ddt = 1,#ag do
          ag[ddt]=ag[ddt]:gsub("\\alpha([^\\%)]+)","\\1a%1\\2%1\\3a%1\\4a%1")
        end
        for ttt = 1,#ag do
          if tag[tnt] == nil then
            tag[tnt] = ag[ttt]
          else
            tag[tnt] = tag[tnt]..ag[ttt]
          end
        end
      end
      ttag[xt] = tag
    end
    local tft = nil
    repeat
      local found = false
      for yt = 1,#ttag do
        for it = 1,#ttag[yt] do
          if ttag[yt][it]:match("\\t%([^\\%(%)]-\\[^\\%(%)]+\\") then
            found = true
            ttag[yt][it]=ttag[yt][it]:gsub("\\t%(([^\\%(%)]-)\\([^\\%)]+)","\\t%(%1\\%2%)\\t%(%1")
            ttag[yt][it]=ttag[yt][it]:gsub("\\t%([^\\%)]-%)","")
          end
        end
      end
    until not found
    for tov = 1,#tt_table do
      for lt = 1,#tt_table[tov] do
        tt_table[tov][lt].tag=tt_table[tov][lt].tag:gsub("(\\t%([^%(%)]+%))","")
      end
    end
    for mot = 1,#ttags do
      poitt = {}
      for got = 1,#ttag do
        poit = {}
        for tog = 1,#ttag[got] do
          xot = 1
          yot = 1
          local found_ttag = false
          for sot = tog,1,-1 do
            if tt_table[got][sot].tag:match(ttags[mot]) then
              yot = got
              xot = sot
              found_ttag = true
              break
            end
          end
          if not found_ttag then
            for tos = got-1,1,-1 do
              for fot = #tt_table[tos],1,-1 do
                if tt_table[tos][fot].tag:match(ttags[mot]) then
                  yot = tos
                  xot = fot
                  break
                  break
                end
              end
            end
          end
          poi = {}
          if yot < got then
            for aot = xot,#ttag[yot] do
              for tesu in ttag[yot][aot]:gmatch("\\t%([^\\%(%)]-"..ttags[mot].."[^\\%(%)]+%)") do
                table.insert(poi, tesu)
              end
            end
            for sgot = yot+1,got-1 do
              for stog = 1,#ttag[sgot] do
                for tou in ttag[sgot][stog]:gmatch("\\t%([^\\%(%)]-"..ttags[mot].."[^\\%(%)]+%)") do
                  table.insert(poi, tou)
                end
              end
            end
            for kot = 1,tog do
              for stou in ttag[got][kot]:gmatch("\\t%([^\\%(%)]-"..ttags[mot].."[^\\%(%)]+%)") do
                table.insert(poi, stou)
              end
            end
          else
            for toa = xot,tog do
              for tous in ttag[got][toa]:gmatch("\\t%([^\\%(%)]-"..ttags[mot].."[^\\%(%)]+%)") do
                table.insert(poi, tous)
              end
            end
          end
          poit[tog] = poi
        end
        poitt[got] = poit
      end
      for wot = 1,#poitt do
        for tow = 1,#poitt[wot] do
          ttag[wot][tow]=ttag[wot][tow]:gsub("\\t%([^\\%(%)]-"..ttags[mot].."[^\\%(%)]+%)","")
          for owt = #poitt[wot][tow],1,-1 do
            ttag[wot][tow] = poitt[wot][tow][owt]..ttag[wot][tow]
          end
        end
      end
    end
    n_table = {}
    for n in artext:gmatch("(\\N.-)\\N") do
      table.insert(n_table, n)
    end
    for aaa = 1,#n_table do
      n_table[aaa]=n_table[aaa]:gsub("\\N","")
    end
    for bbb = 1,#n_table do
      n_table[bbb] = (n_table[bbb]:match("^{") == nil) and "{}" .. n_table[bbb] or n_table[bbb]
    end
    yy_table = {}
    for y = 1,#n_table do
      yyy_table = {}
      for tg, tx in n_table[y]:gmatch("({[^}]*})([^{]*)") do
        table.insert(yyy_table, { tag = tg, text = tx })
      end
      yy_table[y] = yyy_table
    end
    for ll = 1,#yy_table do
      for lll = 1,#yy_table[ll] do
        yy_table[ll][lll].tag=yy_table[ll][lll].tag:gsub("(\\t%([^%(%)]+%))","")
      end
    end
    for vn = 1,#stags do
      local cn = nil
      for z = 1,#n_table do
        for iin = z-1,1,-1 do
          if yy_table[z][1].tag ~= nil and yy_table[z][1].tag:match(stags[vn]) then
            break
          else
            for jn = #yy_table[iin],1,-1 do
              if yy_table[iin][jn].tag ~= nil and yy_table[iin][jn].tag:match(stags[vn].."[^\\}]+") then
                cn = yy_table[iin][jn].tag:match(stags[vn].."[^\\}]+")
                yy_table[z][1].tag=yy_table[z][1].tag:gsub("{","{"..cn)
                goto donec
              end
            end
          end
        end
        ::donec::
      end
    end
    for nnn = 1,#n_table do
      n_table[nnn] = ""
      for mm = 1,#yy_table[nnn] do
        n_table[nnn] = n_table[nnn] .. yy_table[nnn][mm].tag .. yy_table[nnn][mm].text
      end
    end
    alt = {}
    tagii = {}
    jj_table = {}
    for x = 1,#n_table do
      jjj_table = {}
      for tg, tx in n_table[x]:gmatch("({[^}]*})([^{]*)") do
        table.insert(jjj_table, { tag = tg, text = tx })
      end
      jj_table[x] = jjj_table
      btags = {"\\an","\\alig","\\pos","\\move","\\org","\\fad(","\\fade"}
      for ba = 1,#btags do
        b_table = {}
        for bp = 1,#jj_table[x] do
          if jj_table[x][bp].tag:match(btags[ba]) then
            b_table[bp] = jj_table[x][bp].tag:match(btags[ba].."[^\\}]+")
            jj_table[x][bp].tag=jj_table[x][bp].tag:gsub(btags[ba].."[^\\}]+","")
          else
            b_table[bp] = ""
          end
        end
        for pb = 1,#jj_table[x] do
          jj_table[x][pb].tag=jj_table[x][pb].tag:gsub("{","{"..b_table[#jj_table[x]-pb+1])
        end
      end
      sty = {"fontsize","scale_x","scale_y","spacing","color1","color2","color3","color4","color1","color2","color3","color4","outline","shadow","bold","italic","underline","strikeout","angle","fontname","encoding"}
      tagsty = {}
      for h = 1,#sty do
        tagsty[h] = line.styleref[sty[h]]
      end
      for n = 5,8 do
        tagsty[n]=tagsty[n]:gsub("H%x%x","H")
      end
      for m = 9,12 do
        tagsty[m]=tagsty[m]:match("&H%x%x").."&"
      end
      for a = 22,27 do
        tagsty[a] = 0
      end
      tagsty[28] = tagsty[13]
      tagsty[29] = tagsty[14]
      tagsty[30] = tagsty[13]
      tagsty[31] = tagsty[14]
      tagsty[32] = 0
      tagsty[33] = 0
      tagsty[34] = warp
      for qo = x-1,1,-1 do
        if jj_table[qo][1].text:match("th¡s ¡s soft not hard") then
          alt[qo][#alt[qo]+1] = "{\\q2}"
        end
      end
      for om = 1,#stags do
        for op = x-1,1,-1 do
          for po = 1,#alt[op] do
            if alt[op][po]:match(stags[om]) then
              tagsty[om] = alt[op][po]:match(stags[om].."([^\\}]+)")
              goto dones
            end
          end
        end
        ::dones::
      end
      for oqo = x-1,1,-1 do
        if jj_table[oqo][1].text:match("th¡s ¡s soft not hard") then
          alt[oqo][#alt[oqo]] = nil
        end
      end
      if jj_table[x][1].text:match("th¡s ¡s soft not hard") then
        tagsty[34] = 2
      end
      local c = nil
      for v = 1,#stags do
        for i = #jj_table[x],1,-1 do
          for j = i-1,1,-1 do
            if jj_table[x][i].tag ~= nil and jj_table[x][i].tag:match(stags[v]) then
              break
            else
              if jj_table[x][j].tag ~= nil and jj_table[x][j].tag:match(stags[v].."[^\\}]+") then
                c = jj_table[x][j].tag:match(stags[v].."[^\\}]+")
                jj_table[x][i].tag=jj_table[x][i].tag:gsub("{","{"..c)
                break
              end
            end
          end
        end
      end
      for o = 1,#stags do
        for u = 1,#jj_table[x] do
          if jj_table[x][u].tag:match(stags[o]) == nil then
            local tag = tagsty[o]
            if type(tag) == "string" or type(tag) == "number" then
              jj_table[x][u].tag=jj_table[x][u].tag:gsub("{","{"..stags[o]..tag)
            else
              if tag then
                jj_table[x][u].tag=jj_table[x][u].tag:gsub("{","{"..stags[o].."1")
              else
                jj_table[x][u].tag=jj_table[x][u].tag:gsub("{","{"..stags[o].."0")
              end
            end
          end
        end
      end
      for oo = 1,#stags do
        for uu = #jj_table[x],1,-1 do
          if jj_table[x][uu].tag:match(stags[oo]) then
            for ww = uu+1,#jj_table[x] do
              if jj_table[x][ww].tag:match(stags[oo]) then
                if jj_table[x][ww].tag:match(stags[oo].."[^\\}]+") == jj_table[x][uu].tag:match(stags[oo].."[^\\}]+") then
                  jj_table[x][uu].tag=jj_table[x][uu].tag:gsub(stags[oo].."[^\\}]+","")
                end
                break
              end
            end
          end
        end
      end
      tsty = {"fontsize","spacing","color1","color2","color3","color4","color1","color2","color3","color4","scale_x","scale_y","angle","outline","shadow"}
      tagtsty = {}
      for ht = 1,#tsty do
        tagtsty[ht] = line.styleref[tsty[ht]]
      end
      for nt = 3,6 do
        tagtsty[nt]=tagtsty[nt]:gsub("H%x%x","H")
      end
      for mt = 7,10 do
        tagtsty[mt]=tagtsty[mt]:match("&H%x%x").."&"
      end
      for tat = 16,21 do
        tagtsty[tat] = 0
      end
      tagtsty[22] = tagtsty[14]
      tagtsty[23] = tagtsty[15]
      tagtsty[24] = tagtsty[14]
      tagtsty[25] = tagtsty[15]
      for omt = 1,#ttags do
        for opt = x-1,1,-1 do
          for pot = 1,#alt[opt] do
            if alt[opt][pot]:match(ttags[omt]) then
              tagtsty[omt] = alt[opt][pot]:match(ttags[omt].."([^\\}]+)")
              goto donet
            end
          end
        end
        ::donet::
      end
      for at = 1,#ttags do
        for ta = 1,#jj_table[x] do
          if ttag[x][ta]:match(ttags[at]) then
            jjj = ta-1
            if jjj > 0 then
              for jjjj = jjj+1,#jj_table[x] do
                if jj_table[x][jjj].tag:match(ttags[at]) then
                  break
                else
                  if jj_table[x][jjjj].tag:match(ttags[at]) then
                    tar = jj_table[x][jjjj].tag:match(ttags[at].."[^\\}]+")
                    jj_table[x][jjj].tag=jj_table[x][jjj].tag:gsub("{","{"..tar)
                  end
                end
              end
              if jj_table[x][jjj].tag:match(ttags[at]) == nil then
                jj_table[x][jjj].tag=jj_table[x][jjj].tag:gsub("{","{"..ttags[at]..tagtsty[at])
              end
            end
          end
        end
      end
      for tot = 1,#jj_table[x] do
        jj_table[x][tot].tag=jj_table[x][tot].tag:gsub("{","{"..ttag[x][tot])
      end
      local ct = 0
      local ctt = -1
      local rar = nil
      for vt = 1,#ttags do
        for it = #jj_table[x],1,-1 do
          if jj_table[x][it].tag:match(ttags[vt]) == nil then
            for jt = it-1,1,-1 do
              if jj_table[x][jt].tag ~= nil and jj_table[x][jt].tag:match(ttags[vt]) then
                ct = jt
                break
              end
            end
            for jtt = it-1,1,-1 do
              if jj_table[x][jtt].tag ~= nil and jj_table[x][jtt].tag:match("\\t%([^\\%(%)]-"..ttags[vt]) then
                ctt = jtt
                break
              end
            end
            if ct <= ctt then
              if jj_table[x][ctt].tag:match("\\t%([^\\%(%)]-"..ttags[vt]) ~= nil then
                for uou = 1,#jj_table[x][ctt].tag:match("\\t%([^\\%(%)]-"..ttags[vt]) do
                  rar = jj_table[x][ctt].tag:match("\\t%([^\\%(%)]-"..ttags[vt].."[^\\%(%)]+%)")
                  if rar ~= nil then
                    jj_table[x][it].tag=jj_table[x][it].tag:gsub("{","{"..rar)
                    jj_table[x][ctt].tag=jj_table[x][ctt].tag:gsub(rar,"")
                  end
                end
              end
            end
          end
        end
      end
      tag2 = {}
      for tnts = 1,#jj_table[x] do
        ag2 = {}
        if jj_table[x][tnts].tag:match("\\t") then
          for tts in jj_table[x][tnts].tag:gmatch("(\\t%([^%(%)]-%))") do
            table.insert(ag2, tts)
          end
        else
          ag2[1] = ""
        end
        local lo = nil
        for lol = 1,#ag2 do
          if ag2[lol] ~= "" then
            for lool = lol+1,#ag2 do
              if ag2[lool] ~= "" and ag2[lol]:match("\\t%(([^\\%(%)]*)") == ag2[lool]:match("\\t%(([^\\%(%)]*)") then
                lo = ag2[lool]:match("\\t%([^\\%(%)]-(\\[^%(%)]+)%)")
                ag2[lol]=ag2[lol]:gsub("%)",lo.."%)")
                ag2[lool] = ""
              end
            end
          end
        end
        repeat
          local foundalp = false
          for aat = 1,#ag2 do
            if ag2[aat]:match("\\1a") then
              if ag2[aat]:match("\\2a") then
                if ag2[aat]:match("\\3a") then
                  if ag2[aat]:match("\\4a") then
                    if ag2[aat]:match("\\1a([^\\%)]+)") == ag2[aat]:match("\\2a([^\\%)]+)") then
                      if ag2[aat]:match("\\2a([^\\%)]+)") == ag2[aat]:match("\\3a([^\\%)]+)") then
                        if ag2[aat]:match("\\3a([^\\%)]+)") == ag2[aat]:match("\\4a([^\\%)]+)") then
                          foundalp = true
                          ag2[aat]=ag2[aat]:gsub("\\2a[^\\%)]+","",1)
                          ag2[aat]=ag2[aat]:gsub("\\3a[^\\%)]+","",1)
                          ag2[aat]=ag2[aat]:gsub("\\4a[^\\%)]+","",1)
                          ag2[aat]=ag2[aat]:gsub("\\1a([^\\%)]+)","\\alpha%1",1)
                        end
                      end
                    end
                  end
                end
              end
            end
          end
        until not foundalp
        for ttts = 1,#ag2 do
          if tag2[tnts] == nil then
            tag2[tnts] = ag2[ttts]
          else
            tag2[tnts] = tag2[tnts]..ag2[ttts]
          end
        end
      end
      for ollo = 1,#jj_table[x] do
        jj_table[x][ollo].tag=jj_table[x][ollo].tag:gsub("(\\t%([^%(%)]+%))","")
      end
      for b = 1,#stags do
        for q = #jj_table[x],1,-1 do
          if jj_table[x][q].tag:match(stags[b]) then
            local found_next_tag = false
            for w = q+1,#jj_table[x] do
              if jj_table[x][w].tag ~= nil and jj_table[x][w].tag:match(stags[b]) or tag2[w]:match(stags[b]) then
                found_next_tag = true
                break
              end
            end
            if not found_next_tag then
              local tag2 = tagsty[b]
              if type(tag2) == "string" or type(tag2) == "number" then
                tag2 = tostring(tag2)
                if jj_table[x][q].tag:match(stags[b].."[^\\}]+") ~= stags[b]..tag2 then
                  break
                else
                  jj_table[x][q].tag=jj_table[x][q].tag:gsub(stags[b].."[^\\}]+","")
                end
              else
                if tag2 then
                  if jj_table[x][q].tag:match(stags[b].."[^\\}]+") ~= stags[b].."1" then
                    break
                  else
                    jj_table[x][q].tag=jj_table[x][q].tag:gsub(stags[b].."[^\\}]+","")
                  end
                else
                  if jj_table[x][q].tag:match(stags[b].."[^\\}]+") ~= stags[b].."0" then
                    break
                  else
                    jj_table[x][q].tag=jj_table[x][q].tag:gsub(stags[b].."[^\\}]+","")
                  end
                end
              end
            end
          end
        end
      end
      for tr = 1,#ttags do
        if jj_table[x][#jj_table[x]].tag:match(ttags[tr]) == nil then
          tba = 0
          abt = 0
          for rt = x-1,1,-1 do
            for tup = 1,#tagii[rt] do
              if tagii[rt][tup]:match(ttags[tr]) then
                tba = rt
                abt = tup
                goto donet2
              end
            end
          end
          ::donet2::
          uop = 0
          pou = -1
          for rtp = x-1,1,-1 do
            for tupp = 1,#tagii[rtp] do
              if alt[rtp][tupp]:match(ttags[tr]) then
                uop = rtp
                pou = tupp
                goto donet3
              end
            end
          end
          ::donet3::
          if uop <= tba then
            if abt <= pou then
              jj_table[x][#jj_table[x]].tag=jj_table[x][#jj_table[x]].tag:gsub("{","{"..ttags[tr]..tagtsty[tr])
            end
          end
        end
      end
      alt2 = {}
      for vgd = 1,#jj_table[x] do
       alt2[vgd] = jj_table[x][vgd].tag
      end
      alt[x] = alt2
      for ry = 1,#jj_table[x] do
        local jtagr = {}
        local foundr3 = false
        for ryo = 1,#rtags do
          local foundr1 = false
          for yr = ry,#jj_table[x] do
            if jj_table[x][yr].tag:match(rtags[ryo]) then
              foundr1 = true
              jtagr[ryo] = jj_table[x][yr].tag:match(rtags[ryo].."([^\\}]+)")
              break
            end
          end
          if foundr1 then
            foundr3 = true
          else
            jtagr[ryo] = tagsty[ryo]
          end
        end
        if foundr3 then
          for touy = 1,#jtagr do
            if type(jtagr[touy]) == "string" or type(jtagr[touy]) == "number" then
              jtagr[touy] = tostring(jtagr[touy])
            else
              if jtagr[touy] then
                jtagr[touy] = "1"
              else
                jtagr[touy] = "0"
              end
            end
          end
          local rtagr = nil
          for ryu = 1,#sub do
            local jtagr2 = {}
            if sub[ryu].class == "style" then
              ror = sub[ryu]
              for oro = 1,#rsty do
                jtagr2[oro] = ror[rsty[oro]]
              end
              for hhr = 5,8 do
                jtagr2[hhr] = jtagr2[hhr]:gsub("H%x%x","H")
              end
              for iir = 9,12 do
                jtagr2[iir] = jtagr2[iir]:match("&H%x%x").."&"
              end
              for touyy = 1,#jtagr2 do
                if type(jtagr2[touyy]) == "string" or type(jtagr2[touyy]) == "number" then
                  jtagr2[touyy] = tostring(jtagr2[touyy])
                else
                  if jtagr2[touyy] then
                    jtagr2[touyy] = "1"
                  else
                    jtagr2[touyy] = "0"
                  end
                end
              end
              local foundr2 = false
              for iri = 1,#rsty do
                if jtagr[iri] ~= jtagr2[iri] then
                  foundr2 = true
                end
              end
              if not foundr2 then
                rtagr = ror.name
                break
              end
            end
          end
          if rtagr ~= nil then
            for oyr = 1,#rtags do
              jj_table[x][ry].tag=jj_table[x][ry].tag:gsub(rtags[oyr].."[^\\}]+","")
            end
            jj_table[x][ry].tag=jj_table[x][ry].tag:gsub("{","{\\r"..rtagr)
          end
        end
      end
      for aa = 1,#jj_table[x] do
        if jj_table[x][aa].tag:match("\\1a") then
          if jj_table[x][aa].tag:match("\\2a") then
            if jj_table[x][aa].tag:match("\\3a") then
              if jj_table[x][aa].tag:match("\\4a") then
                if jj_table[x][aa].tag:match("\\1a([^\\}]+)") == jj_table[x][aa].tag:match("\\2a([^\\}]+)") then
                  if jj_table[x][aa].tag:match("\\2a([^\\}]+)") == jj_table[x][aa].tag:match("\\3a([^\\}]+)") then
                    if jj_table[x][aa].tag:match("\\3a([^\\}]+)") == jj_table[x][aa].tag:match("\\4a([^\\}]+)") then
                      jj_table[x][aa].tag=jj_table[x][aa].tag:gsub("\\2a[^\\}]+","")
                      jj_table[x][aa].tag=jj_table[x][aa].tag:gsub("\\3a[^\\}]+","")
                      jj_table[x][aa].tag=jj_table[x][aa].tag:gsub("\\4a[^\\}]+","")
                      jj_table[x][aa].tag=jj_table[x][aa].tag:gsub("\\1a([^\\}]+)","\\alpha%1")
                    end
                  end
                end
              end
            end
          end
        end
      end
      for oto = 1,#jj_table[x] do
        jj_table[x][oto].tag=jj_table[x][oto].tag:gsub("}",tag2[oto].."}")
      end
      tagii[x] = tag2
      if x == 1 then
        jj_table[x][#jj_table[x]].tag=jj_table[x][#jj_table[x]].tag:gsub("{","{"..trnsfrm)
      end
      n_table[x] = ""
      for tn = #jj_table[x],1,-1 do
        n_table[x] = n_table[x] .. jj_table[x][tn].tag .. jj_table[x][tn].text
      end
      n_table[x]=n_table[x]:gsub("}([^{]+)","}££££££££££₩₩₩₩₩₩₩₩₩₩%1€€€€€€€€€€¥¥¥¥¥¥¥¥¥¥")
      :gsub("([^{}]+)€€€€€€€€€€¥¥¥¥¥¥¥¥¥¥{}££££££££££₩₩₩₩₩₩₩₩₩₩([^{}]+)","%1%2")
    end
    for nn = 2,#n_table do
      if n_table[nn]:match("th¡s ¡s soft not hard") then
        n_table[nn]=n_table[nn]:gsub("th¡s ¡s soft not hard","")
        n_table[nn] = "\\n"..n_table[nn]
        local found_q = false
        for nnq = nn-1,1,-1 do
          for qnn = 1,#jj_table[nnq] do
            if jj_table[nnq][qnn].tag:match("\\q") then
              found_q = true
              if jj_table[nnq][qnn].tag:match("\\q(%d)") ~= "2" then
                n_table[nn] = "{\\q2}"..n_table[nn]
              end
              goto doneq
            end
          end
        end
        ::doneq::
        if not found_q then
          if warp ~= "2" then
            n_table[nn] = "{\\q2}"..n_table[nn]
          end
        end
      else
        n_table[nn] = "\\N"..n_table[nn]
      end
    end
    pt = ""
    for tt = 1,#n_table do
      pt = pt .. n_table[tt]
    end
    pt=pt:gsub("\\1c&","\\c&")
    :gsub("\\frz","\\fr")
    :gsub("\\str","\\s")
    :gsub("\\ita","\\i")
    :gsub("\\fsize","\\fs")
    :gsub("\\bold","\\b")
    :gsub("\\alig","\\a")
    :gsub("\\pic","\\p")
    :gsub("\\r"..style1.."([\\}])","\\r%1")
    :gsub("(\\t%([^%(%)]-)#([^%)]-)%$([^%)]-%))","%1%(%2%)%3")
    :gsub("{}","")
    :gsub("《《([^\\{}]-)》》","{%1}")
    line.text=pt
    sub[li]=line
  end
  return sel
end

----- Register Scripts -----
aegisub.register_macro(paknevis_script_name, 'Fix your shity writing habbits! (Unretarded Lines Only)', PakNevis)
aegisub.register_macro(extend_move_script_name, 'Extend \\move based on line\'s time.', ExtendMove)
aegisub.register_macro(unretard_script_name, 'Unretard your retarted Persian typing! (Retarded Lines Only)', Unretard)
aegisub.register_macro(rtl_script_name, 'Fix RTL languages displaying issues. (Unretarded Lines Only)', Rtl)
aegisub.register_macro(rtlwo_reverse_script_name, 'Fixes RTL languages displaying issues without reversing.', rtlwo_reverse)
aegisub.register_macro(unrtl_script_name, 'Undo RTL function effects.', Unrtl)
aegisub.register_macro(rtleditor_script_name, 'An editor for easy editing of RTL language lines.', RtlEditor)
aegisub.register_macro(split_at_tags_script_name, 'A splitter (at tags) for RTL language lines.', SplitAtTags)
aegisub.register_macro(split_at_spaces_script_name, 'A splitter (at spaces) for RTL language lines.', SplitAtSpaces)
aegisub.register_macro(reverse_split_at_tags_script_name, 'Split / Reverse at Tags + Split / Split at Tags.',
    ReverseSplitAtTags)
aegisub.register_macro(reverse_at_tags_script_name, 'Reverse line at tags to use it with other LTR automations.',
    ReverseAtTags)
