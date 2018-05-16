call vspec#hint({'scope': 'slacky#_scope()'})

runtime plugin/slacky.vim

describe 'slacky'
  before
    ResetContext
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
end
