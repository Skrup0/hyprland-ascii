# HYPRLAND-ASCII (Dialog)

Patching Hyprbars:

```sh
git clone https://github.com/hyprwm/hyprland-plugins && mv hyprland-plugins ~/Documents/hyprland-plugins
git -C ~/Documents/hyprland-plugins checkout 00862ca
patch -d ~/Documents/hyprland-plugins -p1 < hyprbars-ascii.patch
CXXFLAGS="-O2 $(pkg-config --cflags lua)" make -C ~/Documents/hyprland-plugins/hyprbars
```

Patching Imgborders:

```sh
git clone https://codeberg.org/zacoons/imgborders && mv imgborders ~/Documents/imgborders
git -C ~/Documents/imgborders checkout 08be222
patch -d ~/Documents/imgborders -p1 < imgborders-ascii.patch
cmake -S ~/Documents/imgborders -B ~/Documents/imgborders/build
cmake --build ~/Documents/imgborders/build
```
