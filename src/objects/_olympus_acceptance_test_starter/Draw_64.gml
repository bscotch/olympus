/// @desc Render UI
draw_set_color(c_white);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
var screen_mid_x = display_get_gui_width()/2;
var screen_mid_y = display_get_gui_height()/2;
var scale = 1;
draw_text_ext_transformed(screen_mid_x, screen_mid_y,  @"Tests starts in:
" + string(ceil(_count_down_timer)) + @"

To start fresh:
Click anywhere or Press Gamepad A Button", 70, room_width * .8, scale, scale, 0);