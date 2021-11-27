# Path
if [ (arch) = arm64 ]
  if [ -e /usr/local/bin/brew ]
    eval (/usr/local/bin/brew shellenv)
  end

  if [ -e /opt/homebrew/bin/brew ]
    eval (/opt/homebrew/bin/brew shellenv)
  end
else
  if [ -e /opt/homebrew/bin/brew ]
    eval (/opt/homebrew/bin/brew shellenv)
  end

  if [ -e /usr/local/bin/brew ]
    eval (/usr/local/bin/brew shellenv)
  end
end

if [ -e ~/homebrew/bin/brew ]
  eval (~/homebrew/bin/brew shellenv)
end
