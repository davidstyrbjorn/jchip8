// Monochrome display, variable width and height
// 64 x 32 display
// Supported functions
// - Clear screen (sets all pixels to 0)
// - Draw sprite 
//    - Set pixel 

WHITE :: Vector4.{1, 1, 1, 1};
BLACK :: Vector4.{0, 0, 0, 1};

V2 :: struct {
  x, y: int;
}

Display :: struct {
  window_size: V2;
  pixel_count: V2;
  pixel_size: int;
  clear_color: [4]float;
  pixels: [..]u8;

  on_color: Vector4;
  off_color: Vector4;

  window: Window_Type;
}

display_init :: (dp: *Display, width: int, height: int, pixel_count_x: int, pixel_count_y: int, name: string, on_color: Vector4 = WHITE, off_color: Vector4 = BLACK) {
  dp.window_size.x = width;
  dp.window_size.y = height;
  dp.pixel_count.x = pixel_count_x;
  dp.pixel_count.y = pixel_count_y;

  // I'm very unsure about this part...
  assert(width % height == 0);
  dp.pixel_size = dp.window_size.x / dp.pixel_count.x;

  dp.off_color = off_color;
  dp.on_color = on_color;

  print("pixel_size = %", dp.pixel_size);

  // array_reserve(*dp.pixels, pixel_count_x * pixel_count_y);
  for 0..pixel_count_x * pixel_count_y array_add(*dp.pixels, 0);

  dp.window = create_window(width, height, name);
  Simp.set_render_target(dp.window);
}

display_begin :: (dp: *Display) {
  Simp.clear_render_target(dp.clear_color[0], dp.clear_color[1], dp.clear_color[2], 1);
}

display_end :: (dp: *Display) {
  Simp.swap_buffers(dp.window);
}

display_clear :: (dp: *Display) {
  for dp.pixels {
    it = 0;
  }
}

display_set :: (dp: *Display, x: int, y: int, value: u8) {
  assert(x >= 0 && x < dp.pixel_count.x);
  assert(y >= 0 && y < dp.pixel_count.y);

  index := x + y * dp.pixel_count.x;
  assert(index >= 0 && index < dp.pixel_count.x * dp.pixel_count.y);

  dp.pixels[index] = value;
}

display_show_pixels :: (dp: *Display) {
  Simp.set_shader_for_color();

  size := dp.pixel_count.x * dp.pixel_count.y;
  y := 0;
  for 0..size-1 {
    x := it % dp.pixel_count.x;

    color := dp.off_color;
    if dp.pixels[it] == 1 then color = dp.on_color;

    x0 := cast(float)(x * dp.pixel_size);
    x1 := cast(float)(x0 + dp.pixel_size);
    y0 := cast(float)(y * dp.pixel_size);
    y1 := cast(float)(y0 + dp.pixel_size);

    Simp.immediate_begin();
    Simp.immediate_quad(x0, y0, x1, y1, color);
    Simp.immediate_flush();

    if x == dp.pixel_count.x-1 then y += 1;
  }
}

display_free :: (dp: *Display) {
  array_free(dp.pixels);
}


RED :: Vector4.{1, 0, 0, 1};
GREEN :: Vector4.{0, 1, 0, 1};

display_test :: () {
  should_quit := false;
  display: Display;
  display_init(*display, 512, 256, 64, 32, "Monochrome Display");

  // Go through all pixels, set to random 0 or 1
  for x : 0..63 {
    for y : 0..31 {
      if random_get_within_range(0.0, 1.0) > 0.5 then display_set(*display, x, y, 1);
    }
  }

  while !should_quit {
    update_window_events();
    for event : events_this_frame {
      if event.type == .QUIT {
        should_quit = true;
      }
    }

    display_begin(*display);

    display_show_pixels(*display);

    display_end(*display);
  }

  display_free(*display);
}

Simp :: #import "Simp";
#import "Window_Creation";
#import "Math";