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

let s:queued_bufnr = 0
let s:post_timer = 0

" TODO: Configurable
let s:throttling_duration = 30 * 1000 " milliseconds

function! slacky#_scope()
  return s:
endfunction

function! slacky#push()
  " TODO: Rate limit - 50 per minutes
  let s:queued_bufnr = bufnr('')
  call timer_stop(s:post_timer)
  let s:post_timer = timer_start(s:throttling_duration, 'slacky#_post')
endfunction

function! slacky#_post(_timer)
  call s:.curl_in_background([
  \   '--silent',
  \   '--request',
  \   'POST',
  \   '--header',
  \   printf('Authorization: Bearer %s', s:.get_slack_access_token()),
  \   '--header',
  \   'Content-Type: application/json',
  \   '--data',
  \   json_encode({'profile': s:make_status(s:queued_bufnr)}),
  \   'https://slack.com/api/users.profile.set',
  \ ])
endfunction

" TODO: Configurable
function! s:make_status(bufnr)
  let abbreviated_path = fnamemodify(bufname(a:bufnr), ':~:.')
  let emojis = [':zero:', ':one:', ':two:', ':three:']
  return {
  \   'status_text': matchstr(abbreviated_path, '^.\{,100}'),
  \   'status_emoji': emojis[localtime() % len(emojis)]
  \ }
endfunction

function! s:.curl_in_background(args)
  call job_start(['curl'] + a:args)
endfunction

function! s:.get_slack_access_token()
  return readfile(expand('~/.vim-slacky-token'))[0]
endfunction

" __END__  "{{{1
" vim: foldmethod=marker
