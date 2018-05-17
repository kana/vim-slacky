call vspec#hint({'scope': 'slacky#_scope()'})

runtime plugin/slacky.vim

describe 'slacky'
  before
    ResetContext

    let g:args_history = []

    call Set('s:curl_in_background', {args -> add(g:args_history, args)})
    call Set('s:get_slack_access_token', {-> 'xyzzy'})
    call Set('s:throttling_duration', 100)
  end

  after
    call timer_stop(Ref('s:post_timer'))
  end

  it 'keeps the last entered buffer'
    Expect Ref('s:queued_bufnr') == 0
    let first_bufnr = 0

    edit foo
    let second_bufnr = bufnr('')

    Expect second_bufnr != first_bufnr
    Expect Ref('s:queued_bufnr') == second_bufnr

    edit bar
    let third_bufnr = bufnr('')

    Expect third_bufnr != first_bufnr
    Expect third_bufnr != second_bufnr
    Expect Ref('s:queued_bufnr') == third_bufnr
  end

  it 'updates Slack status after throttling duration'
    Expect Ref('s:queued_bufnr') == 0
    Expect g:args_history ==# []

    edit foo
    Expect Ref('s:queued_bufnr') != 0
    Expect g:args_history ==# []

    sleep 50m
    Expect g:args_history ==# []

    edit bar
    Expect Ref('s:queued_bufnr') != 0
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
