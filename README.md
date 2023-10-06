- to setup vim - `curl http://j.mp/spf13-vim3 -L -o - | sh`
- to setup lazyvim -

  ```shell
  # required
  mv ~/.config/nvim{,.bak}
  
  # optional but recommended
  mv ~/.local/share/nvim{,.bak}
  mv ~/.local/state/nvim{,.bak}
  mv ~/.cache/nvim{,.bak}

  git clone https://github.com/LazyVim/starter ~/.config/nvim

  rm -rf ~/.config/nvim/.git

  nvim
  ```
- to install starship - `curl -sS https://starship.rs/install.sh | sh`
- to configure starship
  ```shell
  # create the toml file
  vi ~/.config/starship.toml

  # add the content of starship.toml from this repo
  ```
