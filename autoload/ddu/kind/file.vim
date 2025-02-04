let s:is_windows = has('win32') || has('win64')

function! ddu#kind#file#open(filename) abort
  let filename = fnamemodify(a:filename, ':p')

  let is_cygwin = has('win32unix')
  let is_mac = !s:is_windows && !is_cygwin
        \ && (has('mac') || has('macunix') || has('gui_macvim') ||
        \   (!isdirectory('/proc') && executable('sw_vers')))
  let is_wsl = s:check_wsl()

  " Detect desktop environment.
  if s:is_windows
    " For URI only.
    " Note:
    "   # and % required to be escaped (:help cmdline-special)
    silent execute printf(
          \ '!start rundll32 url.dll,FileProtocolHandler %s',
          \ escape(filename, '#%'),
          \)
  elseif is_cygwin
    " Cygwin.
    call system(printf('%s %s', 'cygstart',
          \ shellescape(filename)))
  elseif executable('xdg-open')
    " Linux.
    call system(printf('%s %s &', 'xdg-open',
          \ shellescape(filename)))
  elseif executable('lemonade')
    call system(printf('%s %s &', 'lemonade open',
          \ shellescape(filename)))
  elseif exists('$KDE_FULL_SESSION') && $KDE_FULL_SESSION ==# 'true'
    " KDE.
    call system(printf('%s %s &', 'kioclient exec',
          \ shellescape(filename)))
  elseif exists('$GNOME_DESKTOP_SESSION_ID')
    " GNOME.
    call system(printf('%s %s &', 'gnome-open',
          \ shellescape(filename)))
  elseif executable('exo-open')
    " Xfce.
    call system(printf('%s %s &', 'exo-open',
          \ shellescape(filename)))
  elseif is_mac && executable('open')
    " Mac OS.
    call system(printf('%s %s &', 'open',
          \ shellescape(filename)))
  elseif is_wsl && executable('cmd.exe')
    " WSL and not installed any open commands

    " Open the same way as Windows.
    " I don't know why, but the method using execute requires redraw <C-l>
    " after execution in vim.
    call system(printf('cmd.exe /c start rundll32 %s %s',
          \ 'url.dll,FileProtocolHandler',
          \ escape(filename, '#%')))
  else
    " Give up.
    throw 'Not supported.'
  endif
endfunction

function! ddu#kind#file#cwd_input(cwd, prompt, text, completion) abort
  let prev = getcwd()
  try
    call chdir(a:cwd)
    return input(a:prompt, a:text, a:completion)
  finally
    call chdir(prev)
  endtry

  return ''
endfunction

function! s:check_wsl() abort
  if has('nvim')
    return has('wsl')
  endif
  if has('unix') && executable('uname')
    return match(system('uname -r'), "\\cMicrosoft") >= 0
  endif
  return v:false
endfunction

function! ddu#kind#file#confirm(msg, choices, default) abort
  try
    return confirm(a:msg, a:choices, a:default)
  catch
    " ignore the errors
  endtry

  return a:default
endfunction
