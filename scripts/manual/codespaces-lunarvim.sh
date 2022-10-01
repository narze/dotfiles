#!/bin/bash

asdf plugin add rust
asdf install rust latest
asdf global rust latest
bash <(curl -s https://raw.githubusercontent.com/lunarvim/lunarvim/master/utils/installer/install.sh) --install-dependencies --yes
