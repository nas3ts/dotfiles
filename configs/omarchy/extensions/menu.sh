# Override omarchy-menu style functions to use vicinae instead of walker

show_theme_menu() {
  omarchy-launch-vicinae themes
}

show_background_menu() {
  omarchy-launch-vicinae backgrounds
}

show_style_menu() {
  case $(menu "Style" "󰸌  Theme\n󰟵  Unlock\n  Font\n  Background\n  Hyprland\n󱄄  Screensaver\n  About") in
  *Theme*) show_theme_menu ;;
  *Unlock*) omarchy-launch-vicinae unlocks ;;
  *Font*) show_font_menu ;;
  *Background*) show_background_menu ;;
  *Hyprland*) open_in_editor ~/.config/hypr/looknfeel.conf ;;
  *Screensaver*) show_screensaver_menu ;;
  *About*) show_about_menu ;;
  *) show_main_menu ;;
  esac
}
