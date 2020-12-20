-- Special thanks to Majid110 for inspiring us the great feature of RTL Editor.
-- https://github.com/Majid110/MasafAutomation

-- Authers of each section:
-- PakNevis: SSgumS
-- RTL: Shinsekai_Yuri & SSgumS
-- Un-RTL: Shinsekai_Yuri & SSgumS
-- Unretard: SSgumS & MD
-- RTL Editor: Majid Shamkhani (Edited by SSgumS)

local script_name = 'AnimeList Persian Toolkit'
local script_description = 'A toolkit for easier persian fansubbing.'
local script_author = 'AnimeList Team'
local script_version = '1.1.0'

----- Script Names -----
local paknevis_script_name = 'AL Persian Toolkit/PakNevis'
local rtl_script_name = 'AL Persian Toolkit/RTL'
local unrtl_script_name = 'AL Persian Toolkit/Un-RTL'
local unretard_script_name = 'AL Persian Toolkit/Unretard'
local rtleditor_script_name = 'AL Persian Toolkit/RTL Editor'

----- Global Dependencies -----
utf8 = require 'AL.utf8':init()

----- Global Variables ----
RLE = utf8.char(0x202B)

----- Global Functions -----
local function removeRtlChars(s)
    s = utf8.gsub(s, '['..RLE..']', '')
    return s
end

local function rtl(s)
    if '{' ~= string.sub(s, 0, 1) then
        s = RLE..s
    end
    s = utf8.gsub(s, '(\\[Nn])([^\\{])', '%1'..RLE..'%2')
    s = utf8.gsub(s, '}([^{])', '}'..RLE..'%1')
    return s
end

local function unrtl(s)
    s = removeRtlChars(s)
    return s
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
        line.text = utf8.gsub(line.text, ' (['..punc_after..'])', '%1') -- remove space before
        line.text = utf8.gsub(line.text, '(['..punc_before..']) ', '%1') -- remove space after
        line.text = utf8.gsub(line.text, '([^%d'..persian_digits..']%.)([^ '..punc_after..'])', '%1 %2') -- put space after .
        line.text = utf8.gsub(line.text, '([%d'..persian_digits..']%.)([^ %d'..persian_digits..punc_after..'])', '%1 %2') -- put space after .
        line.text = utf8.gsub(line.text, '(['..punc_after:sub(3)..'])([^ '..punc_after..'])', '%1 %2') -- put space after
        line.text = utf8.gsub(line.text, '([^ '..punc_before..'])(['..punc_before..'])', '%1 %2') -- put space before
        -- affix spacing patterns
        line.text = utf8.gsub(line.text, '([^ ]ه) ی ', '%1‌ی ') -- fix ی space
        line.text = utf8.gsub(line.text, ' (ن?می) ', ' %1‌') -- put zwnj after می, نمی
        line.text = utf8.gsub(line.text, '^(ن?می) ', '%1‌') -- put zwnj after می, نمی
        line.text = utf8.gsub(line.text, '(['..persian_alphabets..']['..persian_alphabets..']) (های?)([^'..persian_alphabets..'])', '%1‌%2%3') -- put zwnj before تر, تری, ترین, گر, گری, ها, های
        line.text = utf8.gsub(line.text, '(['..persian_alphabets..']['..persian_alphabets..']) (گری?)([^'..persian_alphabets..'])', '%1‌%2%3') -- put zwnj before تر, تری, ترین, گر, گری, ها, های
        line.text = utf8.gsub(line.text, '(['..persian_alphabets..']['..persian_alphabets..']) (تری?ن?)([^'..persian_alphabets..'])', '%1‌%2%3') -- put zwnj before تر, تری, ترین, گر, گری, ها, های
        line.text = utf8.gsub(line.text, '(['..persian_alphabets..']['..persian_alphabets..']) (های?)$', '%1‌%2') -- put zwnj before تر, تری, ترین, گر, گری, ها, های
        line.text = utf8.gsub(line.text, '(['..persian_alphabets..']['..persian_alphabets..']) (گری?)$', '%1‌%2') -- put zwnj before تر, تری, ترین, گر, گری, ها, های
        line.text = utf8.gsub(line.text, '(['..persian_alphabets..']['..persian_alphabets..']) (تری?ن?)$', '%1‌%2') -- put zwnj before تر, تری, ترین, گر, گری, ها, های
        line.text = utf8.gsub(line.text, '([^ ]ه) (ا[میشنت][مد]?)([^'..persian_alphabets..'])', '%1‌%2%3') -- join ام, ایم, اش, اند, ای, اید, ات
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
            line.text = utf8.gsub(line.text, '^(['..ending_punc..']+)([^\\]+)$', '%2gce') -- ending puncs
            line.text = utf8.gsub(line.text, '^(['..ending_punc..']+)([^\\]+)(\\[Nn])', '%2gce%3') -- ending puncs
            line.text = utf8.gsub(line.text, '(\\[Nn])(['..ending_punc..']+)([^\\]+)(\\[Nn])', '%1%3gce%4') -- ending puncs
            line.text = utf8.gsub(line.text, '(\\[Nn])(['..ending_punc..']+)([^\\]+)$', '%1%3gce') -- ending puncs
            line.text = utf8.gsub(line.text, '^([^\\]+[^'..starting_punc..'])(['..starting_punc..']+)(g?c?e?)$', 'gcs%1%3') -- starting puncs
            line.text = utf8.gsub(line.text, '^([^\\]+[^'..starting_punc..'])(['..starting_punc..']+)(g?c?e?)(\\[Nn])', 'gcs%1%3%4') -- starting puncs
            line.text = utf8.gsub(line.text, '(\\[Nn])([^\\]+[^'..starting_punc..'])(['..starting_punc..']+)(g?c?e?)(\\[Nn])', '%1gcs%2%4%5') -- starting puncs
            line.text = utf8.gsub(line.text, '(\\[Nn])([^\\]+[^'..starting_punc..'])(['..starting_punc..']+)(g?c?e?)$', '%1gcs%2%3') -- starting puncs
            -- replace
            line.text = replace(linetext_copy, line.text, '^(['..ending_punc..']+)[^\\]+$', 'gce')
            line.text = replace(linetext_copy, line.text, '^(['..ending_punc..']+)[^\\]+\\[Nn]', 'gce')
            line.text = replace(linetext_copy, line.text, '\\[Nn](['..ending_punc..']+)[^\\]+\\[Nn]', 'gce')
            line.text = replace(linetext_copy, line.text, '\\[Nn](['..ending_punc..']+)[^\\]+$', 'gce')
            line.text = replace(linetext_copy, line.text, '^[^\\]+[^'..starting_punc..'](['..starting_punc..']+)$', 'gcs')
            line.text = replace(linetext_copy, line.text, '^[^\\]+[^'..starting_punc..'](['..starting_punc..']+)\\[Nn]', 'gcs')
            line.text = replace(linetext_copy, line.text, '\\[Nn][^\\]+[^'..starting_punc..'](['..starting_punc..']+)\\[Nn]', 'gcs')
            line.text = replace(linetext_copy, line.text, '\\[Nn][^\\]+[^'..starting_punc..'](['..starting_punc..']+)$', 'gcs')
        end

		subtitles[i] = line
	end
	aegisub.set_undo_point(unretard_script_name)
end

----- RTL -----
function Rtl(subtitles, selected_lines, active_line)
	for z, i in ipairs(selected_lines) do
        local l = subtitles[i]
        
        l.text = unrtl(l.text)
        
		l.text = rtl(l.text)
        
		subtitles[i] = l
	end
	aegisub.set_undo_point(rtl_script_name)
end

----- Un-RTL -----
function Unrtl(subtitles, selected_lines, active_line)
    for z, i in ipairs(selected_lines) do
        local line = subtitles[i]

        line.text = unrtl(line.text)

        subtitles[i] = line
    end
    aegisub.set_undo_point(unrtl_script_name)
end

----- RTL Editor -----
local editor_btn = {
    Ok = 1,
    OkWORtl = 2,
    Cancel = 3,
}

local function openEditor(str)
    local btns = {"OK", "OK w/o RTL", "Cancel"}

    local btn_switch_case = {}
    for key, value in pairs(btns) do
        btn_switch_case[value] = key
    end

	local config = {
		{class="label", label="Press Ctrl+Shift to switch to RTL mode.", x=0, y=0},
		{class="textbox", name="editor", value=str, x=0, y=1, width=12, height=8}
    }
    local btn, result = aegisub.dialog.display(config, btns, {ok="OK", cancel="Cancel"})
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

----- Register Scripts -----
aegisub.register_macro(paknevis_script_name, 'Fix your shity writing habbits! (Unretarded Lines Only)', PakNevis)
aegisub.register_macro(unretard_script_name, 'Unretard your retarted Persian typing! (Retarded Lines Only)', Unretard)
aegisub.register_macro(rtl_script_name, 'Fix RTL languages displaying issues. (Unretarded Lines Only)', Rtl)
aegisub.register_macro(unrtl_script_name, 'Undo RTL function effects.', Unrtl)
aegisub.register_macro(rtleditor_script_name, 'An editor for easy editing of RTL language lines.', RtlEditor)
