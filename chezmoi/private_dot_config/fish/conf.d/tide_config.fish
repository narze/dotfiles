
# Prompt
# Left default: os pwd git newline character
set -U tide_left_prompt_items fish arch pwd git newline character

# Right default: status cmd_duration context jobs node virtual_env rustc php go kubectl time
set -U tide_right_prompt_items status cmd_duration context jobs node virtual_env rustc php go kube time

# Kube
function _tide_item_kube
  set -l context (kubectl config view --minify --output 'jsonpath={.current-context}/{..namespace}' 2>/dev/null) &&
      _tide_print_item kube $tide_kubectl_icon' ' (string replace --regex '.*:(cluster/)?' '' $context)
end
set -U tide_kube_color black
set -U tide_kube_bg_color 326CE5

# Arch
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

# Fish
function _tide_item_fish
  _tide_print_item fish ''
end
set -U tide_fish_color black

# Day color
switch (date +%a)
  case Sun
    set -U tide_fish_bg_color FF5555
  case Mon
    set -U tide_fish_bg_color yellow
  case Tue
    set -U tide_fish_bg_color FF55FF
  case Wed
    set -U tide_fish_bg_color green
  case Thu
    set -U tide_fish_bg_color FFA500
  case Fri
    set -U tide_fish_bg_color blue
  case Sat
    set -U tide_fish_bg_color purple
  case '*'
    set -U tide_fish_bg_color white
end
