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
    \     '{"profile":{"status_emoji":":zero:","status_text":"bar"}}',
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
    let g:slacky_build_status_text = 'BuildText'
    let g:slacky_build_status_emoji = 'BuildEmoji'

    Expect g:args_history ==# []

    edit foo
    Expect g:args_history ==# []

    sleep 100m
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
    \     '{"profile":{"status_emoji":":barbar:","status_text":"foofoo"}}',
    \     'https://slack.com/api/users.profile.set',
    \   ],
    \ ]
  end
end
