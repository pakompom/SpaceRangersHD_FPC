package org.spacerangershd.android;

import org.libsdl.app.SDLActivity;
import android.os.Bundle;
import android.view.*;
import android.widget.*;
import java.io.File;

public final class GameActivity extends SDLActivity {
    private static native void nativeKey(int key, boolean down);
    private static native void nativeRight(boolean right);
    private static native void nativeHover(boolean hover);
    private static native void nativeWheel(int delta);
    private boolean right;
    private boolean hover;
    private LinearLayout panel;

    @Override
    protected String[] getLibraries() {
        return new String[] {"SDL2", "okgf", "gamenative", "main"};
    }
    @Override
    protected String[] getArguments() {
        File root = getFilesDir();
        return new String[] {
            "--game-dir=" + new File(root, "game"), "--user-dir=" + new File(root, "user"),
            "--language=" + getIntent().getStringExtra("language"), "--renderer=software"};
    }
    @Override
    protected void onCreate(Bundle state) {
        super.onCreate(state);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        if (mLayout == null)
            return;
        LinearLayout tools = new LinearLayout(this);
        tools.setOrientation(LinearLayout.VERTICAL);
        RelativeLayout.LayoutParams position = new RelativeLayout.LayoutParams(-2, -2);
        position.addRule(RelativeLayout.ALIGN_PARENT_RIGHT);
        position.addRule(RelativeLayout.ALIGN_PARENT_TOP);
        mLayout.addView(tools, position);
        Button toggle = new Button(this);
        toggle.setText("Controls");
        toggle.setAlpha(.75f);
        tools.addView(toggle);
        panel = new LinearLayout(this);
        panel.setOrientation(LinearLayout.VERTICAL);
        panel.setBackgroundColor(0xdd18202a);
        ScrollView scroll = new ScrollView(this);
        scroll.addView(panel);
        tools.addView(scroll,
                      new LinearLayout.LayoutParams(
                          -2, Math.round(290 * getResources().getDisplayMetrics().density)));
        scroll.setVisibility(View.GONE);
        toggle.setOnClickListener(v
                                  -> scroll.setVisibility(scroll.getVisibility() == View.VISIBLE
                                                              ? View.GONE
                                                              : View.VISIBLE));
        LinearLayout row = row();
        Button mouse = button(row, "Right click");
        mouse.setOnClickListener(v -> {
            right = !right;
            nativeRight(right);
            mouse.setText(right ? "Right click ON" : "Right click");
        });
        button(row, "Keyboard").setOnClickListener(v -> showTextInput(0, 0, 400, 40));
        row = row();
        Button inspect = button(row, "Inspect / hover");
        inspect.setOnClickListener(v -> {
            hover = !hover;
            nativeHover(hover);
            inspect.setText(hover ? "Hover ON (tap to disable)" : "Inspect / hover");
        });
        row = row();
        key(row, "Esc", 27);
        key(row, "Enter", 13);
        key(row, "Space", 32);
        row = row();
        key(row, "Save", 113);
        key(row, "Load", 114);
        row = row();
        button(row, "Scroll ↑").setOnClickListener(v -> nativeWheel(1));
        button(row, "Scroll ↓").setOnClickListener(v -> nativeWheel(-1));
        row = row();
        key(row, "←", 37);
        key(row, "↑", 38);
        key(row, "↓", 40);
        key(row, "→", 39);
        row = row();
        key(row, "Z / Fire", 90);
        key(row, "X / Fire", 88);
        row = row();
        for (int i = 1; i <= 5; i++)
            key(row, Integer.toString(i), 48 + i);
    }
    private LinearLayout row() {
        LinearLayout row = new LinearLayout(this);
        panel.addView(row);
        return row;
    }
    private Button button(LinearLayout row, String title) {
        Button b = new Button(this);
        b.setText(title);
        b.setTextSize(12);
        b.setMinWidth(0);
        b.setMinimumWidth(0);
        row.addView(b, new LinearLayout.LayoutParams(-2, -2));
        return b;
    }
    private void key(LinearLayout row, String title, int key) {
        button(row, title).setOnTouchListener((v, event) -> {
            if (event.getActionMasked() == MotionEvent.ACTION_DOWN) {
                nativeKey(key, true);
                v.setPressed(true);
                return true;
            }
            if (event.getActionMasked() == MotionEvent.ACTION_UP ||
                event.getActionMasked() == MotionEvent.ACTION_CANCEL) {
                nativeKey(key, false);
                v.setPressed(false);
                return true;
            }
            return true;
        });
    }
    @Override
    protected void onPause() {
        for (int i = 0; i < 256; i++)
            nativeKey(i, false);
        super.onPause();
    }
    @Override
    protected void onDestroy() {
        super.onDestroy();
        android.os.Process.killProcess(android.os.Process.myPid());
    }
}
