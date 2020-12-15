-- Authers of each section:
-- PakNevis: SSgumS
-- Fix RTL: Shinsekai_Yuri
-- Unretard: SSgumS & MD

script_name = 'AnimeList Persian Toolkit'
script_description = 'A toolkit for easier persian fansubbing.'
script_author = 'AnimeList Team'
script_version = "1.0.0"

utf8 = require 'utf8':init()

function paknevis(subtitles, selected_lines, active_line)
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
	aegisub.set_undo_point(script_name)
end

function unretard(subtitles, selected_lines, active_line)
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
	aegisub.set_undo_point(script_name)
end

function fix_rtl(subtitles, selected_lines, active_line)
    local u202b = "\226\128\171"
    local n = "\\n"
    local N = "\\N"
    local rbracket = "}"
    local lbracket = "{"

    local function starts_with(str, start)
        return str:sub(1, #start) == start
    end

	for z, i in ipairs(selected_lines) do
		local l = subtitles[i]
		if string.match(l.text, u202b) then l.text = l.text:gsub(u202b, "") end
		l.text = u202b .. l.text
		if string.match(l.text, N) then l.text = l.text:gsub(N, N .. u202b) end
		if string.match(l.text, n) then l.text = l.text:gsub(n, n .. u202b) end
		if string.match(l.text, rbracket) then l.text = l.text:gsub(rbracket, rbracket .. u202b) end
		if string.match(l.text, u202b..lbracket) then l.text = l.text:gsub(u202b..lbracket, lbracket) end
		subtitles[i] = l
	end
	aegisub.set_undo_point(script_name)
end

aegisub.register_macro('AL Persian Toolkit/PakNevis', 'Fix your shity writing habbits! (Unretarded Lines Only)', paknevis)
aegisub.register_macro('AL Persian Toolkit/Unretard', 'Unretard your retarted Persian typing! (Retarded Lines Only)', unretard)
aegisub.register_macro('AL Persian Toolkit/Fix RTL', 'Fix Persian displaying issues. (Unretarded Lines Only)', fix_rtl)
