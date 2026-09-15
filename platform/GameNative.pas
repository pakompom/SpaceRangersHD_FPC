unit GameNative;
{$MODE delphi}
{$EXCESSPRECISION OFF}
interface
type
  TNativeEvent = record
    Message, WParam: Cardinal;
  LParam: Integer
  end;
function sr_window_focused: Integer; cdecl; external 'gamenative';
function sr_double_click_ms: Integer; cdecl; external 'gamenative';
function sr_error: PAnsiChar; cdecl; external 'gamenative';
function sr_message_box(
    Text, Title: PAnsiChar;
    Flags: Cardinal
): Integer; cdecl; external 'gamenative';
function sr_window_open(W, H: Integer): Integer; cdecl; external 'gamenative';
function sr_display_mode_count: Integer; cdecl; external 'gamenative';
function sr_display_mode(
    Index: Integer;
    out W, H, Refresh: Cardinal
): Integer; cdecl; external 'gamenative';
function sr_display_size(out W, H: Integer): Integer; cdecl; external 'gamenative';
function sr_renderer_select(Hardware: Integer): Integer; cdecl; external 'gamenative';
function sr_renderer_name: PAnsiChar; cdecl; external 'gamenative';
function sr_gpu_software_pixels(
    Pixels: Pointer;
    Pitch: Integer
): Integer; cdecl; external 'gamenative';
function sr_gpu_active: Integer; cdecl; external 'gamenative';
function sr_gpu_image_create(W, H, Format, Target: Integer): Pointer; cdecl; external 'gamenative';
procedure sr_gpu_image_free(Image: Pointer); cdecl; external 'gamenative';
function sr_gpu_image_upload(
    Image, Pixels: Pointer;
    Pitch: Integer
): Integer; cdecl; external 'gamenative';
function sr_gpu_target(Image: Pointer): Integer; cdecl; external 'gamenative';
function sr_gpu_view(
    Scale, X, Y: Single;
    Left, Top, Right, Bottom: LongInt
): LongInt; cdecl; external 'gamenative';
function sr_gpu_clip(Left, Top, Right, Bottom: Integer): Integer; cdecl; external 'gamenative';
function sr_gpu_clear(Color: Cardinal): Integer; cdecl; external 'gamenative';
function sr_gpu_read(
    Image, Pixels: Pointer;
    Pitch, Format: Integer
): Integer; cdecl; external 'gamenative';
function sr_gpu_draw(
    Image: Pointer;
    Kind, Count: Integer;
    Data: Pointer;
    Stride, Linear, Flat: Integer
): Integer; cdecl; external 'gamenative';
function sr_gpu_present: Integer; cdecl; external 'gamenative';
function sr_window_options(Windowed, VSync: Integer): Integer; cdecl; external 'gamenative';
procedure sr_set_gamma(Red, Green, Blue: PWord); cdecl; external 'gamenative';
procedure sr_window_close; cdecl; external 'gamenative';
function sr_present(Pixels: Pointer; Pitch: Integer): Integer; cdecl; external 'gamenative';
function sr_present_count: QWord; cdecl; external 'gamenative';
function sr_poll(out Event: TNativeEvent): Integer; cdecl; external 'gamenative';
procedure sr_mouse(out X, Y: Integer); cdecl; external 'gamenative';
procedure sr_warp(X, Y: Integer); cdecl; external 'gamenative';
procedure sr_cursor(Visible: Integer); cdecl; external 'gamenative';
function sr_key(Key: Integer): Integer; cdecl; external 'gamenative';
function sr_audio_open: Integer; cdecl; external 'gamenative';
procedure sr_audio_close; cdecl; external 'gamenative';
function sr_sound_create(
    PCM: Pointer;
    Size, Rate, Channels, Bits: Integer
): Pointer; cdecl; external 'gamenative';
function sr_sound_playing(Sound: Pointer): Integer; cdecl; external 'gamenative';
procedure sr_sound_stop(Sound: Pointer); cdecl; external 'gamenative';
procedure sr_sound_free(Sound: Pointer); cdecl; external 'gamenative';
procedure sr_sound_volume(Sound: Pointer; VolumeDb, PanDb: Integer); cdecl; external 'gamenative';
function sr_sound_play(Sound: Pointer; Looping: Integer): Integer; cdecl; external 'gamenative';
function sr_music_load(Data: Pointer; Size: Integer): Pointer; cdecl; external 'gamenative';
procedure sr_music_free(Music: Pointer); cdecl; external 'gamenative';
function sr_music_start(Music: Pointer; VolumeDb: Integer): Integer; cdecl; external 'gamenative';
procedure sr_music_volume(VolumeDb: Integer); cdecl; external 'gamenative';
function sr_music_remaining(Music: Pointer): Double; cdecl; external 'gamenative';
procedure sr_music_stop; cdecl; external 'gamenative';
function sr_music_playing: Integer; cdecl; external 'gamenative';
procedure sr_memory(out Total, Available: QWord); cdecl; external 'gamenative';
function sr_save_jpeg(
    Path: PAnsiChar;
    Pixels: Pointer;
    Width, Height, Pitch, Bpp, Quality: Integer
): Integer; cdecl; external 'gamenative';
procedure sr_set_headless(Value: Integer); cdecl; external 'gamenative';
function sr_is_headless: Integer; cdecl; external 'gamenative';
function sr_post(Message, WParam: Cardinal; LParam: Integer): Integer; cdecl; external 'gamenative';
function sr_clipboard_get: PAnsiChar; cdecl; external 'gamenative';
procedure sr_clipboard_set(Text: PAnsiChar); cdecl; external 'gamenative';
procedure sr_window_minimize; cdecl; external 'gamenative';
implementation
end.
