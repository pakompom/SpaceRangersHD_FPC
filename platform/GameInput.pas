unit GameInput;

{$MODE DELPHI}

interface

type
  TGameMessage = record
    Message, WParam: Cardinal;
    LParam: Integer;
  end;

// Message and key values used by the game UI and configuration files.
const
  MK_LBUTTON = 1;
  MK_RBUTTON = 2;
  VK_ADD = 107;
  VK_BACK = 8;
  VK_CONTROL = 17;
  VK_DECIMAL = 110;
  VK_DELETE = 46;
  VK_DOWN = 40;
  VK_END = 35;
  VK_ESCAPE = 27;
  VK_F1 = 112;
  VK_F11 = 122;
  VK_F2 = 113;
  VK_F3 = 114;
  VK_F5 = 116;
  VK_F6 = 117;
  VK_F7 = 118;
  VK_F8 = 119;
  VK_F9 = 120;
  VK_HOME = 36;
  VK_INSERT = 45;
  VK_LEFT = 37;
  VK_MENU = 18;
  VK_NEXT = 34;
  VK_NUMPAD0 = 96;
  VK_OEM_3 = 192;
  VK_OEM_PLUS = 187;
  VK_PAUSE = 19;
  VK_PRIOR = 33;
  VK_RETURN = 13;
  VK_RIGHT = 39;
  VK_SHIFT = 16;
  VK_SPACE = 32;
  VK_SUBTRACT = 109;
  VK_TAB = 9;
  VK_UP = 38;
  WM_ACTIVATEAPP = 28;
  WM_CANCELMODE = 31;
  WM_CHAR = 258;
  WM_CLOSE = 16;
  WM_DESTROY = 2;
  WM_ERASEBKGND = 20;
  WM_KEYDOWN = 256;
  WM_KEYUP = 257;
  WM_LBUTTONDBLCLK = 515;
  WM_LBUTTONDOWN = 513;
  WM_LBUTTONUP = 514;
  WM_MBUTTONDOWN = 519;
  WM_MOUSELEAVE = 675;
  WM_MOUSEMOVE = 512;
  WM_MOUSEWHEEL = 522;
  WM_PAINT = 15;
  WM_QUIT = 18;
  WM_RBUTTONDBLCLK = 518;
  WM_RBUTTONDOWN = 516;
  WM_RBUTTONUP = 517;
  WM_SETCURSOR = 32;
  WM_SYSKEYDOWN = 260;
  WM_SYSKEYUP = 261;
  WM_TIMER = 275;
  // Internal notification: SDL discarded render targets or the whole device.
  WM_GAME_RENDER_RESET = $8001;
  // Signed 1/64 logical-pixel scroll deltas in WParam; gesture anchor in LParam.
  WM_GAME_PAN = $8002;
  WM_GAME_TOUCH_DRAG_BEGIN = $8003;
  WM_GAME_TOUCH_DRAG_MOVE = $8004;
  WM_GAME_TOUCH_DRAG_END = $8005;
  WM_GAME_PAN_BEGIN = $8006;
  WM_GAME_CANCEL_INPUT = $8007;

  WHEEL_DELTA = 120;
  MK_MBUTTON = $10;
  MK_SHIFT = $4;
  MK_CONTROL = $8;

function PackGamePoint(X, Y: Integer): Integer;
function PackGamePan(X, Y: Double): Cardinal;

implementation

uses
  Math;

function PackGamePoint(X, Y: Integer): Integer;
begin
  Result := Integer(Cardinal(Word(X)) or (Cardinal(Word(Y)) shl 16));
end;

function PackGamePan(X, Y: Double): Cardinal;
begin
  Result :=
      Cardinal(
          PackGamePoint(
              Round(EnsureRange(X * 64, -32768.0, 32767.0)),
              Round(EnsureRange(Y * 64, -32768.0, 32767.0))
          )
      );
end;

end.
