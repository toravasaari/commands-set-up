#!/usr/bin/env bash

# Autocompletion for s3cmd subcommands: ls and get
# Does not support any additional variables and might not work at all,
# if optional args are used before or after the subcommands.
# Should be "easy" to expand for other usages.
#
# To make this work automatically, copy this to
#   /etc/bash_completion.d/
#
# Inspired by:
#   https://opensource.com/article/18/3/creating-bash-completion-script
#   https://github.com/git/git/blob/master/contrib/completion/git-completion.bash
#
# - Tero Oravasaari, 2023-04-25


# $1 - path or partial match of path
_s3cmd_comp_ls() {
  local IFS=$'\n'
  local path="$1"
  local last=""
  local suggestions=()

  for line in $(s3cmd ls s3:$path); do
    suggestions+=(${line:34})
    last=${line:26:3}  # "DIR" or some number like "226"
  done

  if [ "${#suggestions[@]}" == "1" ]; then
    if [ "$last" = "DIR" ]; then
      _s3cmd_comp_ls ${suggestions[0]}
    else
      COMPREPLY=("${suggestions[0]}")
    fi
  else
    COMPREPLY=("${suggestions[@]}")
  fi
}


# $1 - Match bucket name
_s3cmd_comp_ls_bucket() {
  local IFS=$'\n'
  local buck="$1"
  local suggestions=()

  for line in $(s3cmd ls); do
    if [[ "${line:21}" = "${cur}"* ]]; then
      suggestions+=(${line:21})
    fi
  done

  if [ "${#suggestions[@]}" == "1" ]; then
    _s3cmd_comp_ls ${suggestions[0]}
  else
    COMPREPLY=("${suggestions[@]}")
  fi
}


_s3cmd_comp() {
  if [ "${#COMP_WORDS[@]}" == "2" ]; then
    COMPREPLY=($(compgen -W "ls get" -- "${COMP_WORDS[1]}"))
    return
  fi

  local cmd=${COMP_WORDS[1]}
  local cur=${COMP_WORDS[$COMP_CWORD]}

  case "$cmd" in
  ls|get)
    # ":" is also word boundary, so "s3://" is actually three words: "s3", ":" and "//"
    local nwords="${#COMP_WORDS[@]}"
    if [ "$nwords" = "3" ]; then
      # "s3cmd ls ", "s3cmd ls s", "s3cmd ls s3"
      COMPREPLY=($(compgen -W "$(s3cmd ls | cut -d" " -f4)"))
    elif [ "$nwords" = "4" ]; then
      # "s3cmd ls s3:"
      COMPREPLY=($(compgen -W "$(s3cmd ls | cut -d":" -f3)"))
    elif [ "$nwords" = "5" ]; then
      # Hereonout we check the fifth word that starts with "//"
      local slashes=${cur//[^\/]}
      if [ "${#slashes}" = "1" ]; then
        if [ "${cur}" = "/" ]; then
          _s3cmd_comp_ls_bucket "//"
        else
          COMPREPLY=()
        fi
      elif [ "${#slashes}" = "2" ]; then
        _s3cmd_comp_ls_bucket $cur
      else
        _s3cmd_comp_ls $cur
      fi
    else
      # default to empty
      COMPREPLY=()
    fi

    ;;
  *)
    COMPREPLY=()
    ;;
  esac
}

complete -F _s3cmd_comp s3cmd
