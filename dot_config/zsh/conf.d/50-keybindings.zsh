ZVM_INSERT_MODE_CURSOR=$ZVM_CURSOR_BEAM
ZVM_NORMAL_MODE_CURSOR=$ZVM_CURSOR_BLOCK
ZVM_VISUAL_MODE_CURSOR=$ZVM_CURSOR_BLOCK

ZVM_VI_HIGHLIGHT_BACKGROUND=none
ZVM_VI_HIGHLIGHT_FOREGROUND=none
ZVM_VI_HIGHLIGHT_EXTRASTYLE=none

zvm_after_init() {
  (( $+widgets[forward-word] )) && bindkey '^[[1;5C' forward-word
  (( $+widgets[backward-word] )) && bindkey '^[[1;5D' backward-word
  (( $+widgets[_fzf_file_no_hidden] )) && bindkey '^F' _fzf_file_no_hidden
  (( $+widgets[autosuggest-toggle] )) && bindkey '^\' autosuggest-toggle
  (( $+widgets[history-substring-search-up] )) && bindkey '^[[A' history-substring-search-up
  (( $+widgets[history-substring-search-down] )) && bindkey '^[[B' history-substring-search-down
}
