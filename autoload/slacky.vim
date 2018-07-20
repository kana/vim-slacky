" slacky - Update Slack status with fancy stuffs
" Version: 0.0.0
" Copyright (C) 2018 Kana Natsuno <https://whileimautomaton.net/>
" License: MIT license  {{{
"     Permission is hereby granted, free of charge, to any person obtaining
"     a copy of this software and associated documentation files (the
"     "Software"), to deal in the Software without restriction, including
"     without limitation the rights to use, copy, modify, merge, publish,
"     distribute, sublicense, and/or sell copies of the Software, and to
"     permit persons to whom the Software is furnished to do so, subject to
"     the following conditions:
"
"     The above copyright notice and this permission notice shall be included
"     in all copies or substantial portions of the Software.
"
"     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
"     OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
"     MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
"     IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
"     CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
"     TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
"     SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
" }}}

let s:post_timer = 0

if !exists('g:slacky_debouncing_wait')
  let g:slacky_debouncing_wait = 30 * 1000 " milliseconds, should be >= 1200
endif

if !exists('g:slacky_build_status_text')
  let g:slacky_build_status_text = 'slacky#_build_status_text'
endif

if !exists('g:slacky_build_status_emoji')
  let g:slacky_build_status_emoji = 'slacky#_build_status_emoji'
endif

if !exists('g:slacky_build_display_name')
  let g:slacky_build_display_name = 'slacky#_build_display_name'
endif

function! slacky#_scope()
  return s:
endfunction

function! slacky#enable()
  augroup slacky
    autocmd!
    autocmd BufEnter * call slacky#_push()
  augroup END
endfunction

function! slacky#disable()
  augroup slacky
    autocmd!
  augroup END
endfunction

function! slacky#_push()
  call timer_stop(s:post_timer)
  let s:post_timer = timer_start(g:slacky_debouncing_wait, 'slacky#_post')
endfunction

function! slacky#_post(_timer)
  let token = s:.get_slack_access_token()
  if token is 0
    call slacky#disable()
    return
  endif

  let profile = {
  \   'status_text': matchstr({g:slacky_build_status_text}(), '^.\{,100}'),
  \   'status_emoji': {g:slacky_build_status_emoji}(),
  \ }

  call s:.curl_in_background([
  \   '--silent',
  \   '--request',
  \   'POST',
  \   '--header',
  \   printf('Authorization: Bearer %s', s:.get_slack_access_token()),
  \   '--header',
  \   'Content-Type: application/json',
  \   '--data',
  \   json_encode({
  \     'profile': profile,
  \   }),
  \   'https://slack.com/api/users.profile.set',
  \ ])
endfunction

function! slacky#_build_status_text()
  return fnamemodify(bufname(''), ':~:.')
endfunction

function! slacky#_build_status_emoji()
  return ':memo:'
endfunction

function! slacky#_build_display_name()
  return 0
endfunction

function! slacky#_is_slack_access_token_available()
  return s:.get_slack_access_token() isnot 0
endfunction

function! s:.curl_in_background(args)
  call job_start(['curl'] + a:args)
endfunction

function! s:.get_slack_access_token()
  let token_path = expand('~/.vim-slacky-token')
  return filereadable(token_path) ? readfile(token_path, 0, 1)[0] : 0
endfunction

" __END__  "{{{1
" vim: foldmethod=marker
