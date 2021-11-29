function dir
  basename $PWD
end

function zsh_odd_fish_even
  if test (math (date +%d) % 2) -eq 1
    if command -v zsh >/dev/null 2>&1
      echo "You should use zsh on odd days!"
      zsh
    end
  end
end
