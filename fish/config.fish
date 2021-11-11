if status is-interactive
  # Commands to run in interactive sessions can go here
  function fish_greeting
    echo ~~~  Hello (date +%A)!  ~~~
  end
end

set -Ux EDITOR nvim
