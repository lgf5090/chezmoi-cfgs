$env.config.keybindings = ($env.config.keybindings | append [
    # Basic movement and editing.
    { name: shells_bol modifier: control keycode: char_a mode: [vi_insert vi_normal emacs] event: { edit: MoveToLineStart } }
    { name: shells_eol modifier: control keycode: char_e mode: [vi_insert vi_normal emacs] event: { edit: MoveToLineEnd } }
    { name: shells_fwd modifier: control keycode: char_f mode: [vi_insert vi_normal emacs] event: { edit: MoveRight } }
    { name: shells_bwd modifier: control keycode: char_b mode: [vi_insert vi_normal emacs] event: { edit: MoveLeft } }
    { name: shells_del modifier: control keycode: char_d mode: [vi_insert] event: { edit: Delete } }
    { name: shells_bksp modifier: control keycode: char_h mode: [vi_insert vi_normal emacs] event: { edit: Backspace } }
    { name: shells_killln modifier: control keycode: char_k mode: [vi_insert vi_normal emacs] event: { edit: CutToLineEnd } }
    { name: shells_unixln modifier: control keycode: char_u mode: [vi_insert vi_normal emacs] event: { edit: CutFromLineStart } }
    { name: shells_killw modifier: control keycode: char_w mode: [vi_insert vi_normal emacs] event: { edit: BackspaceWord } }
    { name: shells_yank modifier: control keycode: char_y mode: [vi_insert vi_normal emacs] event: { edit: PasteCutBufferBefore } }

    # History.
    { name: shells_hist_menu modifier: control keycode: char_r mode: [vi_insert vi_normal emacs] event: { send: menu name: history_menu } }
    { name: shells_prev_hist modifier: control keycode: char_p mode: [vi_insert vi_normal emacs] event: { send: PreviousHistory } }
    { name: shells_next_hist modifier: control keycode: char_n mode: [vi_insert vi_normal emacs] event: { send: NextHistory } }

    # Meta key bindings.
    { name: shells_fwdw modifier: alt keycode: char_f mode: [vi_insert vi_normal emacs] event: { edit: MoveWordRight } }
    { name: shells_bwdw modifier: alt keycode: char_b mode: [vi_insert vi_normal emacs] event: { edit: MoveWordLeft } }
    { name: shells_delw modifier: alt keycode: char_d mode: [vi_insert vi_normal emacs] event: { edit: DeleteWord } }
    { name: shells_bkspw modifier: alt keycode: backspace mode: [vi_insert vi_normal emacs] event: { edit: BackspaceWord } }

    # Completion.
    { name: shells_tab modifier: none keycode: tab mode: [vi_insert emacs] event: { until: [{ send: menu name: completion_menu }, { send: menunext }, { edit: Complete }] } }

    # Special editing.
    { name: shells_xchars modifier: control keycode: char_t mode: [vi_insert vi_normal emacs] event: { edit: SwapGraphemes } }
    { name: shells_xwords modifier: alt keycode: char_t mode: [vi_insert vi_normal emacs] event: { edit: SwapWords } }
    { name: shells_upw modifier: alt keycode: char_u mode: [vi_insert vi_normal emacs] event: { edit: UppercaseWord } }
    { name: shells_dnw modifier: alt keycode: char_l mode: [vi_insert vi_normal emacs] event: { edit: LowercaseWord } }
    { name: shells_capc modifier: alt keycode: char_c mode: [vi_insert vi_normal emacs] event: { edit: CapitalizeChar } }

    # Vi-style additions.
    { name: shells_edit modifier: none keycode: char_v mode: [vi_normal] event: { send: OpenEditor } }

    # Navigation keys.
    { name: shells_home modifier: none keycode: home mode: [vi_insert vi_normal emacs] event: { edit: MoveToLineStart } }
    { name: shells_end modifier: none keycode: end mode: [vi_insert vi_normal emacs] event: { edit: MoveToLineEnd } }
    { name: shells_del2 modifier: none keycode: delete mode: [vi_insert vi_normal emacs] event: { edit: Delete } }
])
