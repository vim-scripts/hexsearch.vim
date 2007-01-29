" Vim script -- hex search command
"
" File:		hexsearch.vim
" Last Change:	2007 Jan 29
" Author:	Andy Wokula <anwoku@yahoo.de>
" Version:	1
" Vim Version:	6

" Description:
"   This is a preprocessor to Vim's search command.  It converts a sequence
"   of hex numbers into a usual search pattern.  Searching is literal.
"
" Installation:
"   :source hexsearch.vim
"   
" Usage:
"   :HexSearch {hexpat}		Search for hexadecimal pattern.  {hexpat}
"				must be a sequence of hex numbers and
"   optional white space.  The options 'fileformat' and 'ignorecase' (for
"   the resulting search pattern) are considered.
"
" Notes:
"   The command does not work for non-ASCII or multi byte encodings.
"
"   Hex numbers: Two hex digits find one character in the buffer.  Do not
"   use prefixes ('0x', '$', etc) or suffixes ('h', etc) to specify hex
"   codes.
"
"   A linebreak (Unix 0A, DOS 0D0A, Mac 0D) is matched at EOF if 'bin' and
"   'noeol' is set, because it is translated into '\n'.
"	:help /\n
"
" Flaws:
"   Sometimes you get no highlighting of the match.  Use "nN" or ":set hls".
"   Is this a "bug" in Vim?  There are vim tipps where this is mentioned
"   too.
"
"   When fileformat=dos is enabled do not search for "## 0A" (where "##" is
"   not "0D" or empty).  It doesn't make sense, because if Vim detected a
"   single 0A in the file it would have switched to fileformat=unix anyway.
"
" Alternative: xxd
"   Searching in the output of xxd is difficult, because addresses and the
"   ASCII part are in the way.  Therefore xxd has the -p option, but now it
"   becomes difficult to jump to a specific address.

let cpo_save = &cpo
set cpo&vim

" search for an argument hex string in the buffer
command! -nargs=+ HexSearch call HexSearch(<q-args>)

function! HexSearch(hexstr)
    " hexstr: sequence of hex numbers and possible whitespace
    " (white space can be used to separate single hex digits)

    " check if arg is valid hex string
    if a:hexstr =~ '\X\&\S'
	echoerr "HexSearch: only hex digits and white space allowed in the pattern."
	return
    endif

    " avoid case issues:
    let str = toupper(a:hexstr)

    " augment single hex chars with leading zero
    let str = substitute(str, '\<\x\>', '0&', 'g')

    " separate codes by one space
    let str = ' '.substitute(str, '\(\x\x\)\x\@=', '\1 ', 'g')
    let str = substitute(str, '\s\+', ' ', 'g')
    let str = substitute(str, ' $', '', '')
    " now each code is preceded by one space

    " report error if there is still an odd number of hex digits
    if str =~ '\<\x\>'
	echoerr "HexSearch: odd number of hex digits in the pattern"
	return
    endif

    " linebreak substitution for current fileformat
    if &ff == "unix"
	let str = substitute(str, ' 0A', '\\n', 'g')
    elseif &ff == "dos"
	let str = substitute(str, ' 0D 0A', '\\n', 'g')
    else " mac
	let str = substitute(str, ' 0D', '\\n', 'g')
	let str = substitute(str, ' 0A', ' 0D', 'g')
    endif

    " represent NUL with NL
    let str = substitute(str, ' 00', "\n", 'g')

    " make search literal - convert backslashes, precede with nomagic
    let str = '\V'.substitute(str, ' 5C', '\\\\', 'g')
    " fortunately, '\', 'n', "\n" and 'V' are not hex digits

    " convert the rest of the search string
    let str = substitute(str, ' \(\x\x\)', '\=nr2char("0x".submatch(1))', 'g')

    " execute the search:
    call search(str)
    let @/ = str
    call histadd("search", str)
    " should highlight the pattern if 'hls' set:
    let &hls = &hls
    redraw
endfunction

let &cpo = cpo_save
