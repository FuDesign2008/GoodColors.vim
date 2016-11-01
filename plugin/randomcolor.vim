"randomcolor.vim
"
"author: fudesign2008@163.com
"
" This plugin will set random color scheme when the vim starts up.
" Use `:RandomColor` command to random scheme manually
"
"
"

if &cp || exists('g:random_color_loaded')
    if exists(':RandomColor')

        if exists('g:random_color_start') && g:random_color_start
            execute ':silent RandomColor'
        endif

        finish
    endif
endif

let g:random_color_loaded = 1
let s:save_cpo = &cpo
set cpo&vim

" commands for special color schemes
let s:specialSchemeCommands = {
            \ 'lucius': [
                    \ 'LuciusBlack',
                    \ 'LuciusBlackHighContrast',
                    \ 'LuciusBlackLowContrast',
                    \ 'LuciusDark',
                    \ 'LuciusDarkHighContrast',
                    \ 'LuciusDarkLowContrast',
                    \ 'LuciusLight',
                    \ 'LuciusLightHighContrast',
                    \ 'LuciusLightLowContrast',
                    \ 'LuciusWhite',
                    \ 'LuciusWhiteHighContrast',
                    \ 'LuciusWhiteLowContrast'
                \],
            \ 'solarized': [
                    \ 'SolarizedDark',
                    \ 'SolarizedLight'
                \],
            \ 'gruvbox': [
                    \ 'GruvboxDark',
                    \ 'GruvboxDarkHighContrast',
                    \ 'GruvboxDarkLowContrast',
                    \ 'GruvboxLight',
                    \ 'GruvboxLightHighContrast',
                    \ 'GruvboxLightLowContrast'
                \],
            \ 'hybrid': [
                    \ 'HybridDark',
                    \ 'HybridDarkLowContrast'
                \]
        \}



"@param {List} schemes
"@return {List}
function! s:convertColorSchemes(schemes)
    let colorSchemes = []

    for name in a:schemes
        if has_key(s:specialSchemeCommands, name)
            let commands = get(s:specialSchemeCommands, name)
            for command in commands
                if index(colorSchemes, command) == -1
                    call add(colorSchemes, command)
                endif
            endfor
        else
            if index(colorSchemes, name) == -1
                call add(colorSchemes, name)
            endif
        endif
    endfor

    return colorSchemes
endfunction

let filePaths = globpath(&runtimepath, 'colors/*.vim')
let filePathList = split(filePaths, '\n')

let temp = []
for filePath in filePathList
    let colorSchemeName = fnamemodify(filePath, ':t:r')
    call add(temp, colorSchemeName)
endfor

let s:allColorSchemes = s:convertColorSchemes(temp)

if exists('g:favorite_color_schemes')
    let s:favoriteColorSchemes = s:convertColorSchemes(g:favorite_color_schemes)
elseif exists('g:random_color_schemes')
    " compatible with old setting
    let s:favoriteColorSchemes = s:convertColorSchemes(g:random_color_schemes)
else
    let s:favoriteColorSchemes = []
endif


"==============================================================================
" RandomNumber is taken from
" https://github.com/dahu/vim-rng/blob/master/plugin/rng.vim
"==============================================================================
let s:m_w = 1 + getpid()
let s:m_z = localtime()

" not sure of the wisdom of generating a full 32-bit RN here
" and then using abs() on the sucker. Feedback welcome.
function! s:RandomNumber(...)
  if a:0 == 0
    let s:m_z = (36969 * and(s:m_z, 0xffff)) + (s:m_z / 65536)
    let s:m_w = (18000 * and(s:m_w, 0xffff)) + (s:m_w / 65536)
    return (s:m_z * 65536) + s:m_w      " 32-bit result
  elseif a:0 == 1 " We return a number in [0, a:1] or [a:1, 0]
    return a:1 < 0 ? s:RandomNumber(a:1,0) : s:RandomNumber(0,a:1)
  else " if a:2 >= 2
    return abs(s:RandomNumber()) % (abs(a:2 - a:1) + 1) + a:1
  endif
endfunction
" end RNG }}}
"============


"@param {Integer} max
"@return {Integer} return a integer between [0, max - 1]
function! s:RandomInt(max)
    return s:RandomNumber(a:max)
endfunction


"@param {List} colorSchemes
function! s:RandomColorSchemes(colorSchemes)

    if empty(a:colorSchemes)
        return
    endif

    let item = remove(a:colorSchemes, 0)
    let color = item
    let command = ''

    let specialColorNames = keys(s:specialSchemeCommands)

    for name in specialColorNames
        let commandList = get(s:specialSchemeCommands, name, [])
        if index(commandList, item) > -1
            let color = name
            let command = item
            break
        endif
    endfor

    execute 'colo ' . color
    if len(command) > 1
        execute ':' . command
    endif
endfunction

"@param {List} theList should be unique
"@return {List}
function! s:RandomOrder(theList)
    let length = len(a:theList)
    let newList = []
    let counter = 0

    while counter < length
        let index = s:RandomInt(length)
        let item = get(a:theList, index)

        while index(newList, item) != -1
            let index = s:RandomInt(length)
            let item = get(a:theList, index)
        endwhile

        call add(newList, item)
        let counter = counter + 1
    endwhile

    return newList
endfunction


let s:allColorSchemesWithRandom = []
function! s:RandomAll()
    if empty(s:allColorSchemesWithRandom)
        let s:allColorSchemesWithRandom = s:RandomOrder(s:allColorSchemes)
    endif

    call s:RandomColorSchemes(s:allColorSchemesWithRandom)
endfunction


let s:favoriteColorSchemesWithRandom = []
function! s:RandomFavorite()
    if empty(s:favoriteColorSchemesWithRandom)
        let s:favoriteColorSchemesWithRandom = s:RandomOrder(s:favoriteColorSchemes)
    endif
    call s:RandomColorSchemes(s:favoriteColorSchemesWithRandom)
endfunction


function! s:RandomColor()
    if empty(s:favoriteColorSchemes)
        call s:RandomAll()
    else
        call s:RandomFavorite()
    endif
endfunction

"------  create commands for solarized
function! s:SolarizedColor(light)
    execute 'set background=' . (a:light ? 'light' : 'dark')
    colo solarized
endfunction
command! -nargs=0 SolarizedLight call s:SolarizedColor(1)
command! -nargs=0 SolarizedDark  call s:SolarizedColor(0)
"------


"------  create commands for gruvbox
"@ {String} contrast `soft`, `medium`, `hard`
function! s:GruvboxColor(contrast, light)

    if a:contrast ==? 'soft' || a:contrast ==? 'hard'
        let contrast = a:contrast
    else
        let contrast = 'medium'
    endif

    if a:light
        let g:gruvbox_contrast_light = contrast
    else
        let g:gruvbox_contrast_dark = contrast
    endif

    execute 'set background=' . (a:light ? 'light' : 'dark')
    colo gruvbox
endfunction

command! -nargs=0 GruvboxLight call s:GruvboxColor('' , 1)
command! -nargs=0 GruvboxLightLowContrast call s:GruvboxColor('soft' , 1)
command! -nargs=0 GruvboxLightHighContrast call s:GruvboxColor('hard' , 1)
command! -nargs=0 GruvboxDark call s:GruvboxColor('' , 0)
command! -nargs=0 GruvboxDarkLowContrast call s:GruvboxColor('soft' , 0)
command! -nargs=0 GruvboxDarkHighContrast call s:GruvboxColor('hard' , 0)
"------

"------  create commands for hybrid
function! s:HybridColor(lowContrast, light)
    execute 'set background=' . (a:light ? 'light' : 'dark')
    let g:hybrid_reduced_contrast = a:lowContrast ? 1 : 0
    colo hybrid
endfunction

command! -nargs=0 HybridDark call s:HybridDark(0 , 0)
command! -nargs=0 HybridDarkLowContrast call s:HybridDark(1 , 0)

"------


command! -nargs=0 RandomColor call s:RandomColor()
command! -nargs=0 RandomAll   call s:RandomAll()
command! -nargs=0 RandomFavorite   call s:RandomFavorite()

let s:randomOnStart = 1
if exists('g:random_color_start')
    let s:randomOnStart = g:random_color_start
endif

if s:randomOnStart != 0
    let guiRunning = has('gui_running')
    if s:randomOnStart == 2
        if guiRunning
            execute ':silent RandomColor'
        endif
    elseif s:randomOnStart == 3
        if !guiRunning
            execute ':silent RandomColor'
        endif
    else
        execute ':silent RandomColor'
    endif
endif

let &cpo = s:save_cpo


