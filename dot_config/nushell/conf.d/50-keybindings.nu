$env.config.keybindings = ($env.config.keybindings | append [
    { name: shells_bol modifier: control keycode: char_a mode: [vi_insert vi_normal emacs] event: { edit: MoveToLineStart } }
    { name: shells_eol modifier: control keycode: char_e mode: [vi_insert vi_normal emacs] event: { edit: MoveToLineEnd } }
    { name: shells_fwd modifier: control keycode: char_f mode: [vi_insert vi_normal emacs] event: { edit: MoveRight } }
    { name: shells_bwd modifier: control keycode: char_b mode: [vi_insert vi_normal emacs] event: { edit: MoveLeft } }
    { name: shells_killln modifier: control keycode: char_k mode: [vi_insert vi_normal emacs] event: { edit: CutToLineEnd } }
    { name: shells_unixln modifier: control keycode: char_u mode: [vi_insert vi_normal emacs] event: { edit: CutFromLineStart } }
    { name: shells_killw modifier: control keycode: char_w mode: [vi_insert vi_normal emacs] event: { edit: BackspaceWord } }
    { name: shells_hist_menu modifier: control keycode: char_r mode: [vi_insert vi_normal emacs] event: { send: menu name: history_menu } }
    { name: shells_prev_hist modifier: control keycode: char_p mode: [vi_insert vi_normal emacs] event: { send: PreviousHistory } }
    { name: shells_next_hist modifier: control keycode: char_n mode: [vi_insert vi_normal emacs] event: { send: NextHistory } }
    { name: shells_edit modifier: none keycode: char_v mode: [vi_normal] event: { send: OpenEditor } }
])
