call vspec#hint({'scope': 'slacky#_scope()'})

runtime plugin/slacky.vim

describe 'slacky'
  before
    ResetContext

    let g:args_history = []

    call Set('s:curl_in_background', {args -> add(g:args_history, args)})
    call Set('s:get_slack_access_token', {-> 'xyzzy'})
    let g:slacky_throttling_duration = 100
  end

  after
    call timer_stop(Ref('s:post_timer'))
  end

  it 'updates Slack status after throttling duration'
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
end
