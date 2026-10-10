package io.github.pakompom.spacerangershd;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;
import android.widget.RelativeLayout;

/** Separate touch targets let steering, firing and game HUD taps share the screen. */
final class ArcadeControls {
    private final ViewGroup parent;
    private final ControlView stick;
    private final ControlView[] fire = new ControlView[2];
    private int controls, lastControls = -1, lastAxes, lastButtons;
    private float unit, axisX, axisY;

    ArcadeControls(Context context, ViewGroup parent) {
        this.parent = parent;
        stick = new ControlView(context, -1);
        for (int i = 0; i < fire.length; i++)
            fire[i] = new ControlView(context, i);
        // Each new finger can target a control or SDL's surface independently.
        parent.setMotionEventSplittingEnabled(true);
        parent.addView(stick, new RelativeLayout.LayoutParams(0, 0));
        for (ControlView button : fire)
            parent.addView(button, new RelativeLayout.LayoutParams(0, 0));
        parent.addOnLayoutChangeListener(
            (view, left, top, right, bottom, oldLeft, oldTop, oldRight, oldBottom) -> {
                if (right - left != oldRight - oldLeft || bottom - top != oldBottom - oldTop) {
                    cancelInput();
                    layoutControls();
                }
            });
    }

    void setControls(int value) {
        if (controls == value)
            return;
        controls = value;
        cancelInput();
        stick.setVisibility((value & 1) != 0 ? View.VISIBLE : View.GONE);
        for (int i = 0; i < fire.length; i++)
            fire[i].setVisibility((value & 1) != 0 && (value & (2 << i)) != 0 ? View.VISIBLE
                                                                              : View.GONE);
        layoutControls();
    }

    void cancelInput() {
        stick.release();
        for (ControlView button : fire)
            button.release();
        sendInput();
    }

    void refreshLayout() {
        cancelInput();
        layoutControls();
    }

    private void layoutControls() {
        int width = parent.getWidth(), height = parent.getHeight();
        if (width <= 0 || height <= 0)
            return;
        unit = Math.min(parent.getResources().getDisplayMetrics().density,
                        Math.min(height / 400f, width / 360f));
        float stickRadius = 82 * unit, buttonRadius = 38 * unit;
        place(stick, 16 * unit + stickRadius, height - 16 * unit - stickRadius, stickRadius);
        float right = width - 16 * unit - buttonRadius;
        float bottom = height - 16 * unit - buttonRadius;
        place(fire[0], right - (((controls & 6) == 6) ? 88 * unit : 0), bottom, buttonRadius);
        place(fire[1], right, bottom, buttonRadius);
    }

    private void place(ControlView view, float x, float y, float radius) {
        int size = (int)Math.ceil(2 * (radius + unit));
        view.radius = radius;
        view.setLayoutParams(new RelativeLayout.LayoutParams(size, size));
        view.setX(Math.round(x - size / 2f));
        view.setY(Math.round(y - size / 2f));
        view.invalidate();
    }

    private void sendInput() {
        int axes = (Math.round(axisX * 100) & 0xffff) | (Math.round(axisY * 100) << 16);
        int buttons = 0;
        for (int i = 0; i < fire.length; i++)
            if (fire[i].isPressed())
                buttons |= 1 << i;
        // A new generation always gets its own neutral state, even if the old release was queued.
        if (controls != lastControls || axes != lastAxes || buttons != lastButtons) {
            GameActivity.nativeArcadeInput(controls, axes, buttons);
            lastControls = controls;
            lastAxes = axes;
            lastButtons = buttons;
        }
    }

    private final class ControlView extends View {
        private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
        private final int fireGroup;
        private int pointer = -1;
        private float radius;

        ControlView(Context context, int fireGroup) {
            super(context);
            this.fireGroup = fireGroup;
            setVisibility(GONE);
            setImportantForAccessibility(IMPORTANT_FOR_ACCESSIBILITY_NO);
        }

        void release() {
            pointer = -1;
            setPressed(false);
            if (fireGroup < 0)
                axisX = axisY = 0;
            invalidate();
        }

        @Override
        public void onWindowFocusChanged(boolean focused) {
            super.onWindowFocusChanged(focused);
            if (!focused)
                cancelInput();
        }

        private boolean inside(float x, float y, float extent) {
            float dx = x - getWidth() / 2f, dy = y - getHeight() / 2f;
            return dx * dx + dy * dy <= extent * extent;
        }

        @Override
        public boolean onTouchEvent(MotionEvent event) {
            int action = event.getActionMasked();
            int index = event.getActionIndex();
            if (action == MotionEvent.ACTION_CANCEL) {
                release();
                sendInput();
                return true;
            }
            if (action == MotionEvent.ACTION_DOWN || action == MotionEvent.ACTION_POINTER_DOWN) {
                if (pointer < 0 && inside(event.getX(index), event.getY(index), radius))
                    pointer = event.getPointerId(index);
                else if (action == MotionEvent.ACTION_DOWN)
                    return false;
            } else if (action == MotionEvent.ACTION_UP || action == MotionEvent.ACTION_POINTER_UP) {
                if (pointer == event.getPointerId(index))
                    release();
            }
            int active = event.findPointerIndex(pointer);
            if (fireGroup < 0) {
                axisX = axisY = 0;
                if (active >= 0 && radius > 0) {
                    float x = (event.getX(active) - getWidth() / 2f) / (radius * .6f);
                    float y = (getHeight() / 2f - event.getY(active)) / (radius * .6f);
                    float length = (float)Math.hypot(x, y);
                    if (length > .18f) {
                        float magnitude = Math.min(1, (length - .18f) / .82f);
                        axisX = x / length * magnitude;
                        axisY = y / length * magnitude;
                    }
                }
                setPressed(active >= 0);
            } else {
                setPressed(active >= 0 &&
                           inside(event.getX(active), event.getY(active), radius * 1.2f));
            }
            sendInput();
            invalidate();
            return true;
        }

        @Override
        protected void onDraw(Canvas canvas) {
            super.onDraw(canvas);
            float x = getWidth() / 2f, y = getHeight() / 2f;
            paint.setStrokeWidth(2 * unit);
            circle(canvas, x, y, radius);
            paint.setStyle(Paint.Style.STROKE);
            if (fireGroup < 0) {
                paint.setColor(0x709dc6dd);
                canvas.drawLine(x - radius * .65f, y, x + radius * .65f, y, paint);
                canvas.drawLine(x, y - radius * .65f, x, y + radius * .65f, paint);
                circle(canvas, x + axisX * radius * .6f, y - axisY * radius * .6f, radius * .36f);
            } else {
                paint.setColor(0xffecf6ff);
                canvas.drawCircle(x, y, radius * .34f, paint);
                canvas.drawLine(x - radius * .6f, y, x - radius * .18f, y, paint);
                canvas.drawLine(x + radius * .18f, y, x + radius * .6f, y, paint);
                canvas.drawLine(x, y - radius * .6f, x, y - radius * .18f, paint);
                canvas.drawLine(x, y + radius * .18f, x, y + radius * .6f, paint);
                if ((controls & 6) == 6) {
                    paint.setStyle(Paint.Style.FILL);
                    paint.setTextSize(14 * unit);
                    paint.setTextAlign(Paint.Align.CENTER);
                    canvas.drawText(fireGroup == 0 ? "1" : "2", x + radius * .55f,
                                    y + radius * .65f, paint);
                }
            }
        }

        private void circle(Canvas canvas, float x, float y, float radius) {
            paint.setStyle(Paint.Style.FILL);
            paint.setColor(isPressed() ? 0xc047708d : 0x80202c38);
            canvas.drawCircle(x, y, radius, paint);
            paint.setStyle(Paint.Style.STROKE);
            paint.setColor(isPressed() ? 0xffd5ecff : 0xb09dc6dd);
            canvas.drawCircle(x, y, radius, paint);
        }
    }
}
