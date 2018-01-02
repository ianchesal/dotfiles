if [ -d /usr/local/opt/chruby/share/chruby ]; then
  source /usr/local/opt/chruby/share/chruby/chruby.sh
  # To enable auto-switching of Rubies specified by .ruby-version files,
  # add the following to ~/.bash_profile or ~/.zshrc:
  source /usr/local/opt/chruby/share/chruby/auto.sh
  
  function current_ruby() {
      local _ruby
      _ruby="$(chruby |grep \* |tr -d '* ')"
      if [[ $(chruby |grep -c \*) -eq 1 ]]; then
          echo ${_ruby}
      else
          echo "system"
      fi
  }
  
  function chruby_prompt_info() {
      echo "$(current_ruby)"
  }
fi
