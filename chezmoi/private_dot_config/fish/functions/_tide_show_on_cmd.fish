function _tide_show_on_cmd
    if test (count (commandline -poc)) -eq 0
        set -l cmd (commandline -t)
        abbr -q $cmd && set -l var _fish_abbr_$cmd && set cmd $$var # expand abbr
        set -n | string match -r '^tide_show_(.*)_on$' | while read -Ll match item
            contains $cmd $$match && set -gx _tide_show_$item 1 || set -e _tide_show_$item
        end
        commandline -f repaint
    end
end
