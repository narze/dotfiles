## Arch
function _tide_item_arch
  set -l arch (uname -m)

  if [ $arch = arm64 ]
    _tide_print_item arch 'arm'
  else if [ $arch = x86_64 ]
    _tide_print_item arch 'x86'
  end
end
set -U tide_arch_color white
set -U tide_arch_bg_color black

## Fish
function _tide_item_fish
  _tide_print_item fish ''
end
set -U tide_fish_color black
set -U tide_fish_bg_color red

## Prompt
set -U tide_left_prompt_items fish arch pwd git newline character
