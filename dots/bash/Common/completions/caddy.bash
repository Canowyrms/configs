# bash completion for caddy                                -*- shell-script -*-

__caddy_debug()
{
    if [[ -n ${BASH_COMP_DEBUG_FILE:-} ]]; then
        echo "$*" >> "${BASH_COMP_DEBUG_FILE}"
    fi
}

# Homebrew on Macs have version 1.3 of bash-completion which doesn't include
# _init_completion. This is a very minimal version of that function.
__caddy_init_completion()
{
    COMPREPLY=()
    _get_comp_words_by_ref "$@" cur prev words cword
}

__caddy_index_of_word()
{
    local w word=$1
    shift
    index=0
    for w in "$@"; do
        [[ $w = "$word" ]] && return
        index=$((index+1))
    done
    index=-1
}

__caddy_contains_word()
{
    local w word=$1; shift
    for w in "$@"; do
        [[ $w = "$word" ]] && return
    done
    return 1
}

__caddy_handle_go_custom_completion()
{
    __caddy_debug "${FUNCNAME[0]}: cur is ${cur}, words[*] is ${words[*]}, #words[@] is ${#words[@]}"

    local shellCompDirectiveError=1
    local shellCompDirectiveNoSpace=2
    local shellCompDirectiveNoFileComp=4
    local shellCompDirectiveFilterFileExt=8
    local shellCompDirectiveFilterDirs=16

    local out requestComp lastParam lastChar comp directive args

    # Prepare the command to request completions for the program.
    # Calling ${words[0]} instead of directly caddy allows handling aliases
    args=("${words[@]:1}")
    # Disable ActiveHelp which is not supported for bash completion v1
    requestComp="CADDY_ACTIVE_HELP=0 ${words[0]} __completeNoDesc ${args[*]}"

    lastParam=${words[$((${#words[@]}-1))]}
    lastChar=${lastParam:$((${#lastParam}-1)):1}
    __caddy_debug "${FUNCNAME[0]}: lastParam ${lastParam}, lastChar ${lastChar}"

    if [ -z "${cur}" ] && [ "${lastChar}" != "=" ]; then
        # If the last parameter is complete (there is a space following it)
        # We add an extra empty parameter so we can indicate this to the go method.
        __caddy_debug "${FUNCNAME[0]}: Adding extra empty parameter"
        requestComp="${requestComp} \"\""
    fi

    __caddy_debug "${FUNCNAME[0]}: calling ${requestComp}"
    # Use eval to handle any environment variables and such
    out=$(eval "${requestComp}" 2>/dev/null)

    # Extract the directive integer at the very end of the output following a colon (:)
    directive=${out##*:}
    # Remove the directive
    out=${out%:*}
    if [ "${directive}" = "${out}" ]; then
        # There is not directive specified
        directive=0
    fi
    __caddy_debug "${FUNCNAME[0]}: the completion directive is: ${directive}"
    __caddy_debug "${FUNCNAME[0]}: the completions are: ${out}"

    if [ $((directive & shellCompDirectiveError)) -ne 0 ]; then
        # Error code.  No completion.
        __caddy_debug "${FUNCNAME[0]}: received error from custom completion go code"
        return
    else
        if [ $((directive & shellCompDirectiveNoSpace)) -ne 0 ]; then
            if [[ $(type -t compopt) = "builtin" ]]; then
                __caddy_debug "${FUNCNAME[0]}: activating no space"
                compopt -o nospace
            fi
        fi
        if [ $((directive & shellCompDirectiveNoFileComp)) -ne 0 ]; then
            if [[ $(type -t compopt) = "builtin" ]]; then
                __caddy_debug "${FUNCNAME[0]}: activating no file completion"
                compopt +o default
            fi
        fi
    fi

    if [ $((directive & shellCompDirectiveFilterFileExt)) -ne 0 ]; then
        # File extension filtering
        local fullFilter filter filteringCmd
        # Do not use quotes around the $out variable or else newline
        # characters will be kept.
        for filter in ${out}; do
            fullFilter+="$filter|"
        done

        filteringCmd="_filedir $fullFilter"
        __caddy_debug "File filtering command: $filteringCmd"
        $filteringCmd
    elif [ $((directive & shellCompDirectiveFilterDirs)) -ne 0 ]; then
        # File completion for directories only
        local subdir
        # Use printf to strip any trailing newline
        subdir=$(printf "%s" "${out}")
        if [ -n "$subdir" ]; then
            __caddy_debug "Listing directories in $subdir"
            __caddy_handle_subdirs_in_dir_flag "$subdir"
        else
            __caddy_debug "Listing directories in ."
            _filedir -d
        fi
    else
        while IFS='' read -r comp; do
            COMPREPLY+=("$comp")
        done < <(compgen -W "${out}" -- "$cur")
    fi
}

__caddy_handle_reply()
{
    __caddy_debug "${FUNCNAME[0]}"
    local comp
    case $cur in
        -*)
            if [[ $(type -t compopt) = "builtin" ]]; then
                compopt -o nospace
            fi
            local allflags
            if [ ${#must_have_one_flag[@]} -ne 0 ]; then
                allflags=("${must_have_one_flag[@]}")
            else
                allflags=("${flags[*]} ${two_word_flags[*]}")
            fi
            while IFS='' read -r comp; do
                COMPREPLY+=("$comp")
            done < <(compgen -W "${allflags[*]}" -- "$cur")
            if [[ $(type -t compopt) = "builtin" ]]; then
                [[ "${COMPREPLY[0]}" == *= ]] || compopt +o nospace
            fi

            # complete after --flag=abc
            if [[ $cur == *=* ]]; then
                if [[ $(type -t compopt) = "builtin" ]]; then
                    compopt +o nospace
                fi

                local index flag
                flag="${cur%=*}"
                __caddy_index_of_word "${flag}" "${flags_with_completion[@]}"
                COMPREPLY=()
                if [[ ${index} -ge 0 ]]; then
                    PREFIX=""
                    cur="${cur#*=}"
                    ${flags_completion[${index}]}
                    if [ -n "${ZSH_VERSION:-}" ]; then
                        # zsh completion needs --flag= prefix
                        eval "COMPREPLY=( \"\${COMPREPLY[@]/#/${flag}=}\" )"
                    fi
                fi
            fi

            if [[ -z "${flag_parsing_disabled}" ]]; then
                # If flag parsing is enabled, we have completed the flags and can return.
                # If flag parsing is disabled, we may not know all (or any) of the flags, so we fallthrough
                # to possibly call handle_go_custom_completion.
                return 0;
            fi
            ;;
    esac

    # check if we are handling a flag with special work handling
    local index
    __caddy_index_of_word "${prev}" "${flags_with_completion[@]}"
    if [[ ${index} -ge 0 ]]; then
        ${flags_completion[${index}]}
        return
    fi

    # we are parsing a flag and don't have a special handler, no completion
    if [[ ${cur} != "${words[cword]}" ]]; then
        return
    fi

    local completions
    completions=("${commands[@]}")
    if [[ ${#must_have_one_noun[@]} -ne 0 ]]; then
        completions+=("${must_have_one_noun[@]}")
    elif [[ -n "${has_completion_function}" ]]; then
        # if a go completion function is provided, defer to that function
        __caddy_handle_go_custom_completion
    fi
    if [[ ${#must_have_one_flag[@]} -ne 0 ]]; then
        completions+=("${must_have_one_flag[@]}")
    fi
    while IFS='' read -r comp; do
        COMPREPLY+=("$comp")
    done < <(compgen -W "${completions[*]}" -- "$cur")

    if [[ ${#COMPREPLY[@]} -eq 0 && ${#noun_aliases[@]} -gt 0 && ${#must_have_one_noun[@]} -ne 0 ]]; then
        while IFS='' read -r comp; do
            COMPREPLY+=("$comp")
        done < <(compgen -W "${noun_aliases[*]}" -- "$cur")
    fi

    if [[ ${#COMPREPLY[@]} -eq 0 ]]; then
        if declare -F __caddy_custom_func >/dev/null; then
            # try command name qualified custom func
            __caddy_custom_func
        else
            # otherwise fall back to unqualified for compatibility
            declare -F __custom_func >/dev/null && __custom_func
        fi
    fi

    # available in bash-completion >= 2, not always present on macOS
    if declare -F __ltrim_colon_completions >/dev/null; then
        __ltrim_colon_completions "$cur"
    fi

    # If there is only 1 completion and it is a flag with an = it will be completed
    # but we don't want a space after the =
    if [[ "${#COMPREPLY[@]}" -eq "1" ]] && [[ $(type -t compopt) = "builtin" ]] && [[ "${COMPREPLY[0]}" == --*= ]]; then
       compopt -o nospace
    fi
}

# The arguments should be in the form "ext1|ext2|extn"
__caddy_handle_filename_extension_flag()
{
    local ext="$1"
    _filedir "@(${ext})"
}

__caddy_handle_subdirs_in_dir_flag()
{
    local dir="$1"
    pushd "${dir}" >/dev/null 2>&1 && _filedir -d && popd >/dev/null 2>&1 || return
}

__caddy_handle_flag()
{
    __caddy_debug "${FUNCNAME[0]}: c is $c words[c] is ${words[c]}"

    # if a command required a flag, and we found it, unset must_have_one_flag()
    local flagname=${words[c]}
    local flagvalue=""
    # if the word contained an =
    if [[ ${words[c]} == *"="* ]]; then
        flagvalue=${flagname#*=} # take in as flagvalue after the =
        flagname=${flagname%=*} # strip everything after the =
        flagname="${flagname}=" # but put the = back
    fi
    __caddy_debug "${FUNCNAME[0]}: looking for ${flagname}"
    if __caddy_contains_word "${flagname}" "${must_have_one_flag[@]}"; then
        must_have_one_flag=()
    fi

    # if you set a flag which only applies to this command, don't show subcommands
    if __caddy_contains_word "${flagname}" "${local_nonpersistent_flags[@]}"; then
      commands=()
    fi

    # keep flag value with flagname as flaghash
    # flaghash variable is an associative array which is only supported in bash > 3.
    if [[ -z "${BASH_VERSION:-}" || "${BASH_VERSINFO[0]:-}" -gt 3 ]]; then
        if [ -n "${flagvalue}" ] ; then
            flaghash[${flagname}]=${flagvalue}
        elif [ -n "${words[ $((c+1)) ]}" ] ; then
            flaghash[${flagname}]=${words[ $((c+1)) ]}
        else
            flaghash[${flagname}]="true" # pad "true" for bool flag
        fi
    fi

    # skip the argument to a two word flag
    if [[ ${words[c]} != *"="* ]] && __caddy_contains_word "${words[c]}" "${two_word_flags[@]}"; then
        __caddy_debug "${FUNCNAME[0]}: found a flag ${words[c]}, skip the next argument"
        c=$((c+1))
        # if we are looking for a flags value, don't show commands
        if [[ $c -eq $cword ]]; then
            commands=()
        fi
    fi

    c=$((c+1))

}

__caddy_handle_noun()
{
    __caddy_debug "${FUNCNAME[0]}: c is $c words[c] is ${words[c]}"

    if __caddy_contains_word "${words[c]}" "${must_have_one_noun[@]}"; then
        must_have_one_noun=()
    elif __caddy_contains_word "${words[c]}" "${noun_aliases[@]}"; then
        must_have_one_noun=()
    fi

    nouns+=("${words[c]}")
    c=$((c+1))
}

__caddy_handle_command()
{
    __caddy_debug "${FUNCNAME[0]}: c is $c words[c] is ${words[c]}"

    local next_command
    if [[ -n ${last_command} ]]; then
        next_command="_${last_command}_${words[c]//:/__}"
    else
        if [[ $c -eq 0 ]]; then
            next_command="_caddy_root_command"
        else
            next_command="_${words[c]//:/__}"
        fi
    fi
    c=$((c+1))
    __caddy_debug "${FUNCNAME[0]}: looking for ${next_command}"
    declare -F "$next_command" >/dev/null && $next_command
}

__caddy_handle_word()
{
    if [[ $c -ge $cword ]]; then
        __caddy_handle_reply
        return
    fi
    __caddy_debug "${FUNCNAME[0]}: c is $c words[c] is ${words[c]}"
    if [[ "${words[c]}" == -* ]]; then
        __caddy_handle_flag
    elif __caddy_contains_word "${words[c]}" "${commands[@]}"; then
        __caddy_handle_command
    elif [[ $c -eq 0 ]]; then
        __caddy_handle_command
    elif __caddy_contains_word "${words[c]}" "${command_aliases[@]}"; then
        # aliashash variable is an associative array which is only supported in bash > 3.
        if [[ -z "${BASH_VERSION:-}" || "${BASH_VERSINFO[0]:-}" -gt 3 ]]; then
            words[c]=${aliashash[${words[c]}]}
            __caddy_handle_command
        else
            __caddy_handle_noun
        fi
    else
        __caddy_handle_noun
    fi
    __caddy_handle_word
}

_caddy_adapt()
{
    last_command="caddy_adapt"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--adapter=")
    two_word_flags+=("--adapter")
    two_word_flags+=("-a")
    local_nonpersistent_flags+=("--adapter")
    local_nonpersistent_flags+=("--adapter=")
    local_nonpersistent_flags+=("-a")
    flags+=("--config=")
    two_word_flags+=("--config")
    two_word_flags+=("-c")
    local_nonpersistent_flags+=("--config")
    local_nonpersistent_flags+=("--config=")
    local_nonpersistent_flags+=("-c")
    flags+=("--envfile=")
    two_word_flags+=("--envfile")
    local_nonpersistent_flags+=("--envfile")
    local_nonpersistent_flags+=("--envfile=")
    flags+=("--pretty")
    flags+=("-p")
    local_nonpersistent_flags+=("--pretty")
    local_nonpersistent_flags+=("-p")
    flags+=("--validate")
    local_nonpersistent_flags+=("--validate")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_caddy_add-package()
{
    last_command="caddy_add-package"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--keep-backup")
    flags+=("-k")
    local_nonpersistent_flags+=("--keep-backup")
    local_nonpersistent_flags+=("-k")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_caddy_build-info()
{
    last_command="caddy_build-info"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()


    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_caddy_completion()
{
    last_command="caddy_completion"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--help")
    flags+=("-h")
    local_nonpersistent_flags+=("--help")
    local_nonpersistent_flags+=("-h")

    must_have_one_flag=()
    must_have_one_noun=()
    must_have_one_noun+=("bash")
    must_have_one_noun+=("fish")
    must_have_one_noun+=("powershell")
    must_have_one_noun+=("zsh")
    noun_aliases=()
}

_caddy_environ()
{
    last_command="caddy_environ"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--envfile=")
    two_word_flags+=("--envfile")
    local_nonpersistent_flags+=("--envfile")
    local_nonpersistent_flags+=("--envfile=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_caddy_file-server_export-template()
{
    last_command="caddy_file-server_export-template"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()


    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_caddy_file-server()
{
    last_command="caddy_file-server"

    command_aliases=()

    commands=()
    commands+=("export-template")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--access-log")
    flags+=("-a")
    local_nonpersistent_flags+=("--access-log")
    local_nonpersistent_flags+=("-a")
    flags+=("--browse")
    flags+=("-b")
    local_nonpersistent_flags+=("--browse")
    local_nonpersistent_flags+=("-b")
    flags+=("--debug")
    flags+=("-v")
    local_nonpersistent_flags+=("--debug")
    local_nonpersistent_flags+=("-v")
    flags+=("--domain=")
    two_word_flags+=("--domain")
    two_word_flags+=("-d")
    local_nonpersistent_flags+=("--domain")
    local_nonpersistent_flags+=("--domain=")
    local_nonpersistent_flags+=("-d")
    flags+=("--listen=")
    two_word_flags+=("--listen")
    two_word_flags+=("-l")
    local_nonpersistent_flags+=("--listen")
    local_nonpersistent_flags+=("--listen=")
    local_nonpersistent_flags+=("-l")
    flags+=("--no-compress")
    local_nonpersistent_flags+=("--no-compress")
    flags+=("--precompressed=")
    two_word_flags+=("--precompressed")
    two_word_flags+=("-p")
    local_nonpersistent_flags+=("--precompressed")
    local_nonpersistent_flags+=("--precompressed=")
    local_nonpersistent_flags+=("-p")
    flags+=("--reveal-symlinks")
    local_nonpersistent_flags+=("--reveal-symlinks")
    flags+=("--root=")
    two_word_flags+=("--root")
    two_word_flags+=("-r")
    local_nonpersistent_flags+=("--root")
    local_nonpersistent_flags+=("--root=")
    local_nonpersistent_flags+=("-r")
    flags+=("--templates")
    flags+=("-t")
    local_nonpersistent_flags+=("--templates")
    local_nonpersistent_flags+=("-t")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_caddy_fmt()
{
    last_command="caddy_fmt"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--diff")
    flags+=("-d")
    local_nonpersistent_flags+=("--diff")
    local_nonpersistent_flags+=("-d")
    flags+=("--overwrite")
    flags+=("-w")
    local_nonpersistent_flags+=("--overwrite")
    local_nonpersistent_flags+=("-w")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_caddy_hash-password()
{
    last_command="caddy_hash-password"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--algorithm=")
    two_word_flags+=("--algorithm")
    two_word_flags+=("-a")
    local_nonpersistent_flags+=("--algorithm")
    local_nonpersistent_flags+=("--algorithm=")
    local_nonpersistent_flags+=("-a")
    flags+=("--plaintext=")
    two_word_flags+=("--plaintext")
    two_word_flags+=("-p")
    local_nonpersistent_flags+=("--plaintext")
    local_nonpersistent_flags+=("--plaintext=")
    local_nonpersistent_flags+=("-p")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_caddy_help()
{
    last_command="caddy_help"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()


    must_have_one_flag=()
    must_have_one_noun=()
    has_completion_function=1
    noun_aliases=()
}

_caddy_list-modules()
{
    last_command="caddy_list-modules"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--packages")
    local_nonpersistent_flags+=("--packages")
    flags+=("--skip-standard")
    flags+=("-s")
    local_nonpersistent_flags+=("--skip-standard")
    local_nonpersistent_flags+=("-s")
    flags+=("--versions")
    local_nonpersistent_flags+=("--versions")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_caddy_manpage()
{
    last_command="caddy_manpage"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--directory=")
    two_word_flags+=("--directory")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--directory")
    local_nonpersistent_flags+=("--directory=")
    local_nonpersistent_flags+=("-o")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_caddy_reload()
{
    last_command="caddy_reload"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--adapter=")
    two_word_flags+=("--adapter")
    two_word_flags+=("-a")
    local_nonpersistent_flags+=("--adapter")
    local_nonpersistent_flags+=("--adapter=")
    local_nonpersistent_flags+=("-a")
    flags+=("--address=")
    two_word_flags+=("--address")
    local_nonpersistent_flags+=("--address")
    local_nonpersistent_flags+=("--address=")
    flags+=("--config=")
    two_word_flags+=("--config")
    two_word_flags+=("-c")
    local_nonpersistent_flags+=("--config")
    local_nonpersistent_flags+=("--config=")
    local_nonpersistent_flags+=("-c")
    flags+=("--force")
    flags+=("-f")
    local_nonpersistent_flags+=("--force")
    local_nonpersistent_flags+=("-f")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_caddy_remove-package()
{
    last_command="caddy_remove-package"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--keep-backup")
    flags+=("-k")
    local_nonpersistent_flags+=("--keep-backup")
    local_nonpersistent_flags+=("-k")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_caddy_respond()
{
    last_command="caddy_respond"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--access-log")
    local_nonpersistent_flags+=("--access-log")
    flags+=("--body=")
    two_word_flags+=("--body")
    two_word_flags+=("-b")
    local_nonpersistent_flags+=("--body")
    local_nonpersistent_flags+=("--body=")
    local_nonpersistent_flags+=("-b")
    flags+=("--debug")
    flags+=("-v")
    local_nonpersistent_flags+=("--debug")
    local_nonpersistent_flags+=("-v")
    flags+=("--header=")
    two_word_flags+=("--header")
    two_word_flags+=("-H")
    local_nonpersistent_flags+=("--header")
    local_nonpersistent_flags+=("--header=")
    local_nonpersistent_flags+=("-H")
    flags+=("--listen=")
    two_word_flags+=("--listen")
    two_word_flags+=("-l")
    local_nonpersistent_flags+=("--listen")
    local_nonpersistent_flags+=("--listen=")
    local_nonpersistent_flags+=("-l")
    flags+=("--status=")
    two_word_flags+=("--status")
    two_word_flags+=("-s")
    local_nonpersistent_flags+=("--status")
    local_nonpersistent_flags+=("--status=")
    local_nonpersistent_flags+=("-s")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_caddy_reverse-proxy()
{
    last_command="caddy_reverse-proxy"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--access-log")
    local_nonpersistent_flags+=("--access-log")
    flags+=("--change-host-header")
    flags+=("-c")
    local_nonpersistent_flags+=("--change-host-header")
    local_nonpersistent_flags+=("-c")
    flags+=("--debug")
    flags+=("-v")
    local_nonpersistent_flags+=("--debug")
    local_nonpersistent_flags+=("-v")
    flags+=("--disable-redirects")
    flags+=("-r")
    local_nonpersistent_flags+=("--disable-redirects")
    local_nonpersistent_flags+=("-r")
    flags+=("--from=")
    two_word_flags+=("--from")
    two_word_flags+=("-f")
    local_nonpersistent_flags+=("--from")
    local_nonpersistent_flags+=("--from=")
    local_nonpersistent_flags+=("-f")
    flags+=("--header-down=")
    two_word_flags+=("--header-down")
    two_word_flags+=("-d")
    local_nonpersistent_flags+=("--header-down")
    local_nonpersistent_flags+=("--header-down=")
    local_nonpersistent_flags+=("-d")
    flags+=("--header-up=")
    two_word_flags+=("--header-up")
    two_word_flags+=("-H")
    local_nonpersistent_flags+=("--header-up")
    local_nonpersistent_flags+=("--header-up=")
    local_nonpersistent_flags+=("-H")
    flags+=("--insecure")
    local_nonpersistent_flags+=("--insecure")
    flags+=("--internal-certs")
    flags+=("-i")
    local_nonpersistent_flags+=("--internal-certs")
    local_nonpersistent_flags+=("-i")
    flags+=("--to=")
    two_word_flags+=("--to")
    two_word_flags+=("-t")
    local_nonpersistent_flags+=("--to")
    local_nonpersistent_flags+=("--to=")
    local_nonpersistent_flags+=("-t")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_caddy_run()
{
    last_command="caddy_run"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--adapter=")
    two_word_flags+=("--adapter")
    two_word_flags+=("-a")
    local_nonpersistent_flags+=("--adapter")
    local_nonpersistent_flags+=("--adapter=")
    local_nonpersistent_flags+=("-a")
    flags+=("--config=")
    two_word_flags+=("--config")
    two_word_flags+=("-c")
    local_nonpersistent_flags+=("--config")
    local_nonpersistent_flags+=("--config=")
    local_nonpersistent_flags+=("-c")
    flags+=("--envfile=")
    two_word_flags+=("--envfile")
    local_nonpersistent_flags+=("--envfile")
    local_nonpersistent_flags+=("--envfile=")
    flags+=("--environ")
    flags+=("-e")
    local_nonpersistent_flags+=("--environ")
    local_nonpersistent_flags+=("-e")
    flags+=("--pidfile=")
    two_word_flags+=("--pidfile")
    local_nonpersistent_flags+=("--pidfile")
    local_nonpersistent_flags+=("--pidfile=")
    flags+=("--pingback=")
    two_word_flags+=("--pingback")
    local_nonpersistent_flags+=("--pingback")
    local_nonpersistent_flags+=("--pingback=")
    flags+=("--resume")
    flags+=("-r")
    local_nonpersistent_flags+=("--resume")
    local_nonpersistent_flags+=("-r")
    flags+=("--watch")
    flags+=("-w")
    local_nonpersistent_flags+=("--watch")
    local_nonpersistent_flags+=("-w")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_caddy_start()
{
    last_command="caddy_start"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--adapter=")
    two_word_flags+=("--adapter")
    two_word_flags+=("-a")
    local_nonpersistent_flags+=("--adapter")
    local_nonpersistent_flags+=("--adapter=")
    local_nonpersistent_flags+=("-a")
    flags+=("--config=")
    two_word_flags+=("--config")
    two_word_flags+=("-c")
    local_nonpersistent_flags+=("--config")
    local_nonpersistent_flags+=("--config=")
    local_nonpersistent_flags+=("-c")
    flags+=("--envfile=")
    two_word_flags+=("--envfile")
    local_nonpersistent_flags+=("--envfile")
    local_nonpersistent_flags+=("--envfile=")
    flags+=("--pidfile=")
    two_word_flags+=("--pidfile")
    local_nonpersistent_flags+=("--pidfile")
    local_nonpersistent_flags+=("--pidfile=")
    flags+=("--watch")
    flags+=("-w")
    local_nonpersistent_flags+=("--watch")
    local_nonpersistent_flags+=("-w")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_caddy_stop()
{
    last_command="caddy_stop"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--adapter=")
    two_word_flags+=("--adapter")
    two_word_flags+=("-a")
    local_nonpersistent_flags+=("--adapter")
    local_nonpersistent_flags+=("--adapter=")
    local_nonpersistent_flags+=("-a")
    flags+=("--address=")
    two_word_flags+=("--address")
    local_nonpersistent_flags+=("--address")
    local_nonpersistent_flags+=("--address=")
    flags+=("--config=")
    two_word_flags+=("--config")
    two_word_flags+=("-c")
    local_nonpersistent_flags+=("--config")
    local_nonpersistent_flags+=("--config=")
    local_nonpersistent_flags+=("-c")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_caddy_storage_export()
{
    last_command="caddy_storage_export"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--config=")
    two_word_flags+=("--config")
    two_word_flags+=("-c")
    local_nonpersistent_flags+=("--config")
    local_nonpersistent_flags+=("--config=")
    local_nonpersistent_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("--output")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--output")
    local_nonpersistent_flags+=("--output=")
    local_nonpersistent_flags+=("-o")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_caddy_storage_import()
{
    last_command="caddy_storage_import"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--config=")
    two_word_flags+=("--config")
    two_word_flags+=("-c")
    local_nonpersistent_flags+=("--config")
    local_nonpersistent_flags+=("--config=")
    local_nonpersistent_flags+=("-c")
    flags+=("--input=")
    two_word_flags+=("--input")
    two_word_flags+=("-i")
    local_nonpersistent_flags+=("--input")
    local_nonpersistent_flags+=("--input=")
    local_nonpersistent_flags+=("-i")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_caddy_storage()
{
    last_command="caddy_storage"

    command_aliases=()

    commands=()
    commands+=("export")
    commands+=("import")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()


    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_caddy_trust()
{
    last_command="caddy_trust"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--adapter=")
    two_word_flags+=("--adapter")
    two_word_flags+=("-a")
    local_nonpersistent_flags+=("--adapter")
    local_nonpersistent_flags+=("--adapter=")
    local_nonpersistent_flags+=("-a")
    flags+=("--address=")
    two_word_flags+=("--address")
    local_nonpersistent_flags+=("--address")
    local_nonpersistent_flags+=("--address=")
    flags+=("--ca=")
    two_word_flags+=("--ca")
    local_nonpersistent_flags+=("--ca")
    local_nonpersistent_flags+=("--ca=")
    flags+=("--config=")
    two_word_flags+=("--config")
    two_word_flags+=("-c")
    local_nonpersistent_flags+=("--config")
    local_nonpersistent_flags+=("--config=")
    local_nonpersistent_flags+=("-c")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_caddy_untrust()
{
    last_command="caddy_untrust"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--adapter=")
    two_word_flags+=("--adapter")
    two_word_flags+=("-a")
    local_nonpersistent_flags+=("--adapter")
    local_nonpersistent_flags+=("--adapter=")
    local_nonpersistent_flags+=("-a")
    flags+=("--address=")
    two_word_flags+=("--address")
    local_nonpersistent_flags+=("--address")
    local_nonpersistent_flags+=("--address=")
    flags+=("--ca=")
    two_word_flags+=("--ca")
    local_nonpersistent_flags+=("--ca")
    local_nonpersistent_flags+=("--ca=")
    flags+=("--cert=")
    two_word_flags+=("--cert")
    two_word_flags+=("-p")
    local_nonpersistent_flags+=("--cert")
    local_nonpersistent_flags+=("--cert=")
    local_nonpersistent_flags+=("-p")
    flags+=("--config=")
    two_word_flags+=("--config")
    two_word_flags+=("-c")
    local_nonpersistent_flags+=("--config")
    local_nonpersistent_flags+=("--config=")
    local_nonpersistent_flags+=("-c")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_caddy_upgrade()
{
    last_command="caddy_upgrade"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--keep-backup")
    flags+=("-k")
    local_nonpersistent_flags+=("--keep-backup")
    local_nonpersistent_flags+=("-k")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_caddy_validate()
{
    last_command="caddy_validate"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--adapter=")
    two_word_flags+=("--adapter")
    two_word_flags+=("-a")
    local_nonpersistent_flags+=("--adapter")
    local_nonpersistent_flags+=("--adapter=")
    local_nonpersistent_flags+=("-a")
    flags+=("--config=")
    two_word_flags+=("--config")
    two_word_flags+=("-c")
    local_nonpersistent_flags+=("--config")
    local_nonpersistent_flags+=("--config=")
    local_nonpersistent_flags+=("-c")
    flags+=("--envfile=")
    two_word_flags+=("--envfile")
    local_nonpersistent_flags+=("--envfile")
    local_nonpersistent_flags+=("--envfile=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_caddy_version()
{
    last_command="caddy_version"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()


    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_caddy_root_command()
{
    last_command="caddy"

    command_aliases=()

    commands=()
    commands+=("adapt")
    commands+=("add-package")
    commands+=("build-info")
    commands+=("completion")
    commands+=("environ")
    commands+=("file-server")
    commands+=("fmt")
    commands+=("hash-password")
    commands+=("help")
    commands+=("list-modules")
    commands+=("manpage")
    commands+=("reload")
    commands+=("remove-package")
    commands+=("respond")
    commands+=("reverse-proxy")
    commands+=("run")
    commands+=("start")
    commands+=("stop")
    commands+=("storage")
    commands+=("trust")
    commands+=("untrust")
    commands+=("upgrade")
    commands+=("validate")
    commands+=("version")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()


    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

__start_caddy()
{
    local cur prev words cword split
    declare -A flaghash 2>/dev/null || :
    declare -A aliashash 2>/dev/null || :
    if declare -F _init_completion >/dev/null 2>&1; then
        _init_completion -s || return
    else
        __caddy_init_completion -n "=" || return
    fi

    local c=0
    local flag_parsing_disabled=
    local flags=()
    local two_word_flags=()
    local local_nonpersistent_flags=()
    local flags_with_completion=()
    local flags_completion=()
    local commands=("caddy")
    local command_aliases=()
    local must_have_one_flag=()
    local must_have_one_noun=()
    local has_completion_function=""
    local last_command=""
    local nouns=()
    local noun_aliases=()

    __caddy_handle_word
}

if [[ $(type -t compopt) = "builtin" ]]; then
    complete -o default -F __start_caddy caddy
else
    complete -o default -o nospace -F __start_caddy caddy
fi

# ex: ts=4 sw=4 et filetype=sh
