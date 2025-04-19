# Using fzf to make common git commands and workflows for interactive meant to be put in .bashrc and called with git alias
# dependancies: git, fzf, less

git_switch_interactive() {
  local branch
  branch=$(
    git branch --format='%(refname:short)' --sort=-committerdate |
      fzf --height 40% --reverse --no-sort \
        --preview 'git log --oneline --graph --date=short --pretty="format:%C(auto)%cd %h%d %s" --color=always {}' \
        --preview-window=right:50%:wrap \
        --bind 'ctrl-l:execute(git log --date=short --pretty="format:%C(auto)%cd %h%d %s" --color=always {} | less -r)' \
        --header 'CTRL-l to view full log'
  )
  if [ -n "$branch" ]; then
    git switch "$branch"
  else
    echo "No branch selected. Operation cancelled."
    return 1
  fi
}

# Create function for git stash
git_stash_interactive() {
  local copy_cmd
  case "$(uname -s)" in
  Darwin*) copy_cmd="pbcopy" ;;
  Linux*) copy_cmd="xclip -selection clipboard 2>/dev/null || xsel --clipboard 2>/dev/null" ;;
  MINGW* | MSYS*) copy_cmd="clip.exe" ;;
  *) copy_cmd="echo 'Clipboard not supported'" ;;
  esac

  local options=()
  if [[ "$1" == "drop" ]]; then
    options=(--multi)
  elif [ -n "$1" ]; then
    echo option not recognized: "$1"
    return 1
  fi
  local stash=$(
    git stash list |
      fzf --height 40% --reverse \
        "${options[@]}" \
        --no-sort \
        --preview 'git stash show --stat -p --color=always {1}' \
        --preview-window=right:50%:wrap \
        --bind 'ctrl-l:execute(git stash show --stat -p --color=always {1} | less -r)' \
        --bind "ctrl-y:execute-silent(echo {1} | pbcopy)+change-header('Copied {1} to clipboard!')" \
        --header 'ctrl-l to view full log, ctrl-y to copy' \
        --delimiter ":" |
      awk -F: '{print $1}'
  )
  if [ -n "$stash" ]; then
    if [[ "$1" == "drop" ]]; then
      echo "$stash" | xargs git stash drop
    else
      echo "$stash" | xargs git stash pop
    fi
  fi
}

# Create function for git add
# ctl-l inspect (like normal)
# ctl-shift-p add with -p (I will need to refresh list after this)
# multi select where all selected get added
git_add_interactive() {

  local files=$(
    git status --porcelain |
      fzf --height 40% --reverse --no-sort \
        --preview 'echo {} | awk "{ print $NF }" | xargs git diff --color=always' \
        --preview-window=right:50%:wrap \
        --bind 'ctrl-l:execute(git diff --color=always {2} | less -r)' \
        --header 'CTRL-l to view full diff' \
        --delimiter " "
  )
  if [ -n "$files" ]; then
    git switch "$files"
  fi
}
