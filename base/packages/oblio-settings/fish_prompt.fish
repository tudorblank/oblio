# Oblio's prompt: fish's default without the exit status of the last command.
# Your own ~/.config/fish/functions/fish_prompt.fish replaces it.
function fish_prompt --description 'Write out the prompt'
    set -l color_cwd $fish_color_cwd
    set -l suffix '>'
    if functions -q fish_is_root_user; and fish_is_root_user
        set -q fish_color_cwd_root; and set color_cwd $fish_color_cwd_root
        set suffix '#'
    end
    echo -n -s (prompt_login) ' ' (set_color $color_cwd) (prompt_pwd) (set_color normal) (fish_vcs_prompt) (set_color normal) ' ' $suffix ' '
end
