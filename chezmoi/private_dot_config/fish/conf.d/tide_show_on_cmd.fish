# Bind space as our trigger to read the current command
bind ' ' 'commandline -f expand-abbr; _tide_show_on_cmd; commandline -i " "'

# Wrap matching items to control when they are shown
set -n | string match -r '^tide_show_(.*)_on$' | while read -Ll match item
    set -l func _tide_item_$item
    functions -q _$func && continue
    functions --copy $func _$func
    echo "
function $func --description (functions --details --verbose $func)[5]
    if set -q _tide_show_$item || set -q tide_"$item"_always_display
        tide_"$item"_always_display=1 __tide_item_$item
    end
end" | source
end

function _tide_show_on_cmd_clear --on-event fish_preexec --on-event fish_cancel
    set -e (set -n | string match '_tide_show_*') 2>/dev/null
end

function _tide_show_on_cmd_uninstall --on-event tide_show_on_cmd_uninstall
    bind --erase " "
end
