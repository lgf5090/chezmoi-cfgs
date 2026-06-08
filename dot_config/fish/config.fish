# Fish-style entrypoint.
#
# Supports both:
#   source /tmp/fish/config.fish
#   ln -s /tmp/fish ~/.config/fish

set -l _fish_config_dir (path dirname (status filename))
set -g FISH_CONFIG_DIR "$_fish_config_dir"

contains -- "$_fish_config_dir/functions" $fish_function_path
or set -g fish_function_path "$_fish_config_dir/functions" $fish_function_path

contains -- "$_fish_config_dir/completions" $fish_complete_path
or set -g fish_complete_path "$_fish_config_dir/completions" $fish_complete_path

# fish loads $__fish_config_dir/conf.d before config.fish during native startup.
# If this file is sourced from another location, load this project's conf.d here.
if test "$_fish_config_dir" != "$__fish_config_dir"
    for file in "$_fish_config_dir"/conf.d/*.fish
        test -r "$file"; and source "$file"
    end
end
