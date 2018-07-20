call vspec#hint({'scope': 'slacky#_scope()'})

runtime plugin/slacky.vim

describe 'slacky'
  before
    ResetContext

    let g:args_history = []

    call Set('s:curl_in_background', {args -> add(g:args_history, args)})
    call Set('s:get_slack_access_token', {-> 'xyzzy'})
    let g:slacky_debouncing_wait = 100
    let g:slacky_build_status_text = 'slacky#_build_status_text'
    let g:slacky_build_status_emoji = 'slacky#_build_status_emoji'
    let g:slacky_build_display_name = 'slacky#_build_display_name'

    call slacky#enable()
  end

  after
    call timer_stop(Ref('s:post_timer'))
  end

  it 'updates Slack status after debouncing wait'
    Expect g:args_history ==# []

    edit foo
    Expect g:args_history ==# []

    sleep 50m
    Expect g:args_history ==# []

    edit bar
    Expect g:args_history ==# []

    sleep 50m
    Expect g:args_history ==# []

    sleep 50m
    Expect g:args_history ==# [
    \   [
    \     '--silent',
    \     '--request',
    \     'POST',
    \     '--header',
    \     'Authorization: Bearer xyzzy',
    \     '--header',
    \     'Content-Type: application/json',
    \     '--data',
    \     '{"profile":{"status_emoji":":memo:","status_text":"bar"}}',
    \     'https://slack.com/api/users.profile.set',
    \   ],
    \ ]
  end

  it 'uses configured builders'
    function! BuildText()
      return 'foofoo'
    endfunction
    function! BuildEmoji()
      return ':barbar:'
    endfunction
    function! BuildDisplayName()
      return 'Display Name'
    endfunction
    let g:slacky_build_status_text = 'BuildText'
    let g:slacky_build_status_emoji = 'BuildEmoji'
    let g:slacky_build_display_name = 'BuildDisplayName'

    Expect g:args_history ==# []

    edit foo
    Expect g:args_history ==# []

    sleep 150m
    Expect g:args_history ==# [
    \   [
    \     '--silent',
    \     '--request',
    \     'POST',
    \     '--header',
    \     'Authorization: Bearer xyzzy',
    \     '--header',
    \     'Content-Type: application/json',
    \     '--data',
    \     '{"profile":{"display_name":"Display Name","status_emoji":":barbar:","status_text":"foofoo"}}',
    \     'https://slack.com/api/users.profile.set',
    \   ],
    \ ]
  end

  it 'automatically truncates too long text'
    function! BuildText()
      return repeat('laid-back camp', 10)
    endfunction
    function! BuildEmoji()
      return ':barbar:'
    endfunction
    let g:slacky_build_status_text = 'BuildText'
    let g:slacky_build_status_emoji = 'BuildEmoji'

    Expect g:args_history ==# []

    edit foo
    Expect g:args_history ==# []

    sleep 150m
    Expect g:args_history ==# [
    \   [
    \     '--silent',
    \     '--request',
    \     'POST',
    \     '--header',
    \     'Authorization: Bearer xyzzy',
    \     '--header',
    \     'Content-Type: application/json',
    \     '--data',
    \     '{"profile":{"status_emoji":":barbar:","status_text":"laid-back camplaid-back camplaid-back camplaid-back camplaid-back camplaid-back camplaid-back campla"}}',
    \     'https://slack.com/api/users.profile.set',
    \   ],
    \ ]
  end

  it 'disables itself if token becomes unavailable'
    call Set('s:get_slack_access_token', {-> 0})
    Expect Ref('s:post_timer') == 0
    Expect g:args_history ==# []

    edit foo
    Expect Ref('s:post_timer') != 0
    Expect g:args_history ==# []
    let post_timer_foo = Ref('s:post_timer')

    sleep 100m
    Expect Ref('s:post_timer') == post_timer_foo
    Expect g:args_history ==# []

    edit bar
    Expect Ref('s:post_timer') == post_timer_foo
    Expect g:args_history ==# []

    sleep 100m
    Expect Ref('s:post_timer') == post_timer_foo
    Expect g:args_history ==# []
  end
end
