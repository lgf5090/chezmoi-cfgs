# Fish-style nushell entrypoint.

const NUSHELL_CONFIG_DIR = (path self | path dirname)
$env.NUSHELL_CONFIG_DIR = $NUSHELL_CONFIG_DIR

# Custom completions must be parsed before functions that reference them.
source ($NUSHELL_CONFIG_DIR | path join "completions" "mkcd.nu")

source ($NUSHELL_CONFIG_DIR | path join "functions" "mkcd.nu")
source ($NUSHELL_CONFIG_DIR | path join "functions" "path.nu")
source ($NUSHELL_CONFIG_DIR | path join "functions" "proxy.nu")
source ($NUSHELL_CONFIG_DIR | path join "functions" "lf.nu")

source ($NUSHELL_CONFIG_DIR | path join "conf.d" "00-xdg.nu")
source ($NUSHELL_CONFIG_DIR | path join "conf.d" "01-helpers.nu")
source ($NUSHELL_CONFIG_DIR | path join "conf.d" "05-os.nu")
source ($NUSHELL_CONFIG_DIR | path join "conf.d" "10-env.nu")
source ($NUSHELL_CONFIG_DIR | path join "conf.d" "15-path.nu")
source ($NUSHELL_CONFIG_DIR | path join "conf.d" "20-history.nu")
source ($NUSHELL_CONFIG_DIR | path join "conf.d" "25-options.nu")
source ($NUSHELL_CONFIG_DIR | path join "conf.d" "40-aliases.nu")
source ($NUSHELL_CONFIG_DIR | path join "conf.d" "50-keybindings.nu")
source ($NUSHELL_CONFIG_DIR | path join "conf.d" "60-fzf.nu")
source ($NUSHELL_CONFIG_DIR | path join "conf.d" "65-zoxide.nu")
source ($NUSHELL_CONFIG_DIR | path join "conf.d" "75-node.nu")
source ($NUSHELL_CONFIG_DIR | path join "conf.d" "80-plugins.nu")
source ($NUSHELL_CONFIG_DIR | path join "conf.d" "90-prompt.nu")
