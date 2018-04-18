# Variant of sjlosh's prose theme.

#### hg prompt
function hg_prompt_info {
    local prompt
    prompt="$(hg prompt --angle-brackets "\
< on %{%F{047}%}<bookmark>%{$reset_color%}>\
< %{%f{047}%}(<branch>)%{$reset_color%}>\
< at %{%F{228}%}<tags|%{$reset_color%}, %{%F{228}%}>%{$reset_color%}>\
%{%F{116}%}<status|modified|unknown><update>%{$reset_color%}<
patches: <patches|join( → )|pre_applied(%{%F{228}%})|post_applied(%{$reset_color%})|pre_unapplied(%{$fg_bold[black]%})|post_unapplied(%{$reset_color%})>>" 2>/dev/null)"
    # In case hg-prompt is not installed.
    if ! [[ "$prompt" =~ "Mercurial Distributed SCM" ]]; then
        printf '%s' "$prompt"
    fi
}

##### git prompt, includes tag if any.
ZSH_THEME_GIT_PROMPT_PREFIX=" on %{%F{046}%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIRTY="%{%F{116}%}!"
ZSH_THEME_GIT_PROMPT_UNTRACKED="%{%F{116}%}?"
ZSH_THEME_GIT_PROMPT_CLEAN=""

function git_prompt_info {
    local ref
    if [[ "$(command git config --get oh-my-zsh.hide-status 2>/dev/null)" != "1" ]]; then
        # 1) current branch? (needed as HEAD may correspond to multiple branches)
        #    (remove refs/heads/)
        # 2) current tag? (remove tags/)
        # 3) current hash
        ref="$(set -o pipefail
               { command git symbolic-ref HEAD | cut -d/ -f3- ||
                 command git describe --exact-match --all | cut -d/ -f2- ||
                 command git rev-parse --short HEAD } 2>/dev/null )" ||
            return 0
        echo "$ZSH_THEME_GIT_PROMPT_PREFIX$ref$(parse_git_dirty)$ZSH_THEME_GIT_PROMPT_SUFFIX"
    fi
}

zstyle ':vcs_info:git:prompt:*' actionformats " %{$fg_bold[cyan]%}%a%{$reset_color%}"
zstyle ':vcs_info:git:prompt:*' formats "%a"
#zstyle ':vcs_info:git:prompt:*' formats ''
# ------------------------------
# update the vcs_info_msg_ magic variables, but only as little as possible

# This variable dictates whether we are going to do the git prompt update
# before printing the next prompt.  On some setups this saves 10s of work.
PR_GIT_UPDATE=1

# called before command excution
# here we decide if we should update the prompt next time
function zsh_git_prompt_preexec {
    case "$(history $HISTCMD)" in
        *git*)
            PR_GIT_UPDATE=1
            ;;
    esac
}
preexec_functions+='zsh_git_prompt_preexec'

# called after directory change
# we just assume that we have to update git prompt
function zsh_git_prompt_chpwd {
    PR_GIT_UPDATE=1
}
chpwd_functions+='zsh_git_prompt_chpwd'

# called before prompt generation
# if needed, we will update the prompt info
function zsh_git_prompt_precmd {
    if [[ -n "$PR_GIT_UPDATE" ]]; then
        vcs_info 'prompt'
        PR_GIT_UPDATE=
    fi
}
precmd_functions+='zsh_git_prompt_precmd'

#####

function _save_timestamp {
    cmd_timestamp="$(date +%s)"
}
preexec_functions+='_save_timestamp'

# Not sure why unsetting cmd_timestamp doesn't work from PROMPT.
function _report_elapsed_time {
    local stop="$(date +%s)"
    local start="${cmd_timestamp:-$stop}"
    cmd_timestamp=
    local elapsed="$(($stop-$start))"
    if [[ $elapsed -gt 3 ]]; then printf "\e[3melapsed: ${elapsed}s\n\e[0m"; fi
}
precmd_functions+='_report_elapsed_time'

#####

function _prompt_char {
    if git branch >/dev/null 2>/dev/null; then echo '(git)'
    else if hg root >/dev/null 2>/dev/null; then echo '(hg)'
    else echo '$'; fi; fi
}

function _virtualenv_info {
    local conda_env
    if [[ "$VIRTUAL_ENV" ]]; then echo "($(basename "$VIRTUAL_ENV")) "; fi
    if [[ "$CONDA_DEFAULT_ENV" ]]; then
        conda_env="$(basename $CONDA_DEFAULT_ENV)"
        if [[ "$conda_env" != "$_PROMPT_IGNORE_CONDA" ]]; then
            echo "($conda_env) "
        fi
    fi
}

function _box_name {
    if [[ -f ~/.box-name ]]; then cat ~/.box-name; else hostname; fi
}

function _is_ssh_prefix {
    if [[ -n $SSH_CLIENT ]]; then echo "\e[3m"; fi
}

function _return_status {
    echo "%{%B%F{210}%}%(?..[%?])%{$reset_color%}"
}

function _count_screens {
    count="$({ screen -ls | grep Socket | grep -o "^[0-9]\+" } 2>/dev/null)"
    if [[ $STY ]]; then count=$(( $count - 1 )); fi
    if [[ $count -ne 0 ]]; then echo "[screen: $count] "; fi
}

function _count_tmuxen {
    count="$(tmux list-sessions 2>/dev/null | wc -l)"
    if [[ $TMUX ]]; then count=$(( $count - 1 )); fi
    if [[ $count -ne 0 ]]; then echo "[tmux: $count] "; fi
}

function _set_prompts {
    # Using prompt_subst sometimes fails to evaluate RPROMPT after SIGINT.
    PROMPT="
$(_is_ssh_prefix)%{%F{046}%}%n%{%f%b%}%{%F{7}%}$(_is_ssh_prefix)@%{%F{116}%}$(_is_ssh_prefix)$(_box_name)%{%f%b%}$(_return_status):%{%F{223}%}${PWD/#$HOME/~}%{$reset_color%}$(hg_prompt_info)$(git_prompt_info)
$(_virtualenv_info)$(_prompt_char)${vcs_info_msg_0_} %{%b%F{7}%}"
    RPROMPT="%{$reset_color%}$(vi_mode_prompt_info) %(1j.[jobs: %j] .)$(_count_screens)$(_count_tmuxen)[%D %*]"
}

precmd_functions+='_set_prompts'

typeset -gA FAST_HIGHLIGHT_STYLES
FAST_HIGHLIGHT_STYLES[default]=none
FAST_HIGHLIGHT_STYLES[unknown-token]=fg=210,bold
FAST_HIGHLIGHT_STYLES[reserved-word]=fg=229
FAST_HIGHLIGHT_STYLES[alias]=fg=229
FAST_HIGHLIGHT_STYLES[suffix-alias]=fg=229
FAST_HIGHLIGHT_STYLES[builtin]=fg=229
FAST_HIGHLIGHT_STYLES[function]=fg=229
FAST_HIGHLIGHT_STYLES[command]=fg=229
FAST_HIGHLIGHT_STYLES[precommand]=fg=229
FAST_HIGHLIGHT_STYLES[commandseparator]=none
FAST_HIGHLIGHT_STYLES[hashed-command]=fg=229
FAST_HIGHLIGHT_STYLES[path]=underline
FAST_HIGHLIGHT_STYLES[path_pathseparator]=
FAST_HIGHLIGHT_STYLES[globbing]=fg=116,bold
FAST_HIGHLIGHT_STYLES[history-expansion]=fg=116,bold
FAST_HIGHLIGHT_STYLES[single-hyphen-option]=fg=115
FAST_HIGHLIGHT_STYLES[double-hyphen-option]=fg=115
FAST_HIGHLIGHT_STYLES[back-quoted-argument]=none
FAST_HIGHLIGHT_STYLES[single-quoted-argument]=fg=174
FAST_HIGHLIGHT_STYLES[double-quoted-argument]=fg=174
FAST_HIGHLIGHT_STYLES[dollar-quoted-argument]=fg=174
FAST_HIGHLIGHT_STYLES[back-or-dollar-double-quoted-argument]=fg=223
FAST_HIGHLIGHT_STYLES[back-dollar-quoted-argument]=fg=223
FAST_HIGHLIGHT_STYLES[assign]=none
FAST_HIGHLIGHT_STYLES[redirection]=none
FAST_HIGHLIGHT_STYLES[comment]=fg=black,bold
FAST_HIGHLIGHT_STYLES[variable]=none

# vim: ft=zsh
