package io.github.pakompom.spacerangershd;

import android.content.Context;
import android.content.res.Configuration;
import android.os.Bundle;
import android.view.KeyEvent;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewConfiguration;
import android.view.WindowManager;
import android.widget.*;
import java.io.File;
import java.io.IOException;
import java.util.HashSet;
import java.util.Locale;
import org.libsdl.app.SDLActivity;
import org.libsdl.app.SDLSurface;

/** SDL owns rendering, audio, external input, and background lifecycle. */
public final class GameActivity extends SDLActivity {
    static native void nativeCancelTouch();
    private static native void nativeInputMode(int flags);
    private static native void nativeScroll(int direction);
    private final HashSet<Integer> heldKeys = new HashSet<>();
    private boolean right, hover;
    private LinearLayout panel;
    private Context textContext;
    private GameFiles files;

    @Override
    public void loadLibraries() {
        // SDL calls this before JNI setup or starting the game thread. Only
        // nonblocking locking and at most two recovery renames happen here;
        // recursive cleanup belongs to the launcher's transfer worker.
        try {
            files = GameFiles.acquire(this);
            files.recover();
        } catch (IOException | SecurityException error) {
            closeFiles(files);
            files = null;
            String message;
            if (error instanceof GameFiles.Failure) {
                GameFiles.Failure failure = (GameFiles.Failure)error;
                message = failure.detail == null
                              ? textContext.getString(failure.resource)
                              : textContext.getString(failure.resource, failure.detail);
            } else {
                message =
                    textContext.getString(R.string.launcher_error_access_files, error.toString());
            }
            // SDL displays this reason and follows its normal safe teardown
            // path for a failed startup, without initializing native state.
            throw new IllegalStateException(message, error);
        }
        super.loadLibraries();
    }

    @Override
    protected void onCreate(Bundle state) {
        Configuration configuration = new Configuration(getResources().getConfiguration());
        configuration.setLocale(
            new Locale("english".equals(getIntent().getStringExtra("language")) ? "en" : "ru"));
        textContext = createConfigurationContext(configuration);
        super.onCreate(state);
        setTitle(textContext.getString(R.string.app_name));
        if (!mBrokenLibraries)
            createControls();
    }

    private static void closeFiles(GameFiles files) {
        if (files != null) {
            try {
                files.close();
            } catch (IOException ignored) {
                // Process exit also releases the OS lease.
            }
        }
    }

    @Override
    protected SDLSurface createSDLSurface(Context context) {
        return new SDLSurface(context) {
            @Override
            public boolean onTouch(View view, MotionEvent event) {
                // SDL2 converts cancellation to finger-up. Notify Pascal first,
                // then let SDL release its fingers without committing a tap.
                if (event.getActionMasked() == MotionEvent.ACTION_CANCEL)
                    nativeCancelTouch();
                return super.onTouch(view, event);
            }
        };
    }

    @Override
    protected String[] getLibraries() {
        return new String[] {"SDL2", "okgf", "main"};
    }

    @Override
    protected String[] getArguments() {
        File user = new File(getFilesDir(), "user");
        user.mkdirs();
        String language = getIntent().getStringExtra("language");
        return new String[] {
            "--game-dir",   new File(getFilesDir(), "game").toString(),
            "--user-dir",   user.toString(),
            "--language",   language == null ? "russian" : language,
            "--touch-slop", Integer.toString(ViewConfiguration.get(this).getScaledTouchSlop())};
    }

    private void createControls() {
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        LinearLayout tools = new LinearLayout(this);
        tools.setOrientation(LinearLayout.VERTICAL);
        RelativeLayout.LayoutParams position = new RelativeLayout.LayoutParams(-2, -2);
        position.addRule(RelativeLayout.ALIGN_PARENT_LEFT);
        position.addRule(RelativeLayout.ALIGN_PARENT_TOP);
        mLayout.addView(tools, position);
        Button toggle = new Button(this);
        toggle.setText(textContext.getString(R.string.controls_title));
        toggle.setAlpha(.4f);
        tools.addView(toggle);
        panel = new LinearLayout(this);
        panel.setOrientation(LinearLayout.VERTICAL);
        panel.setBackgroundColor(0xee18202a);
        ScrollView scroll = new ScrollView(this);
        scroll.addView(panel);
        tools.addView(scroll,
                      new LinearLayout.LayoutParams(
                          -2, Math.round(280 * getResources().getDisplayMetrics().density)));
        scroll.setVisibility(View.GONE);
        toggle.setOnClickListener(v -> {
            nativeCancelTouch();
            scroll.setVisibility(scroll.getVisibility() == View.VISIBLE ? View.GONE : View.VISIBLE);
        });
        LinearLayout row = row();
        Button mouse = button(row, R.string.controls_right_click);
        mouse.setOnClickListener(v -> {
            right = !right;
            nativeInputMode((right ? 1 : 0) | (hover ? 2 : 0));
            mouse.setText(textContext.getString(right ? R.string.controls_right_click_on
                                                      : R.string.controls_right_click));
        });
        button(row, R.string.controls_keyboard)
            .setOnClickListener(v -> showTextInput(0, 0, 400, 40));
        row = row();
        Button inspect = button(row, R.string.controls_hover);
        inspect.setOnClickListener(v -> {
            hover = !hover;
            nativeInputMode((right ? 1 : 0) | (hover ? 2 : 0));
            inspect.setText(textContext.getString(hover ? R.string.controls_hover_on
                                                        : R.string.controls_hover));
        });
        row = row();
        key(row, "Esc", KeyEvent.KEYCODE_ESCAPE);
        key(row, "Enter", KeyEvent.KEYCODE_ENTER);
        key(row, textContext.getString(R.string.controls_space), KeyEvent.KEYCODE_SPACE);
        row = row();
        key(row, textContext.getString(R.string.controls_save), KeyEvent.KEYCODE_F2);
        key(row, textContext.getString(R.string.controls_load), KeyEvent.KEYCODE_F3);
        row = row();
        button(row, R.string.controls_scroll_up).setOnClickListener(v -> nativeScroll(1));
        button(row, R.string.controls_scroll_down).setOnClickListener(v -> nativeScroll(-1));
        row = row();
        key(row, "←", KeyEvent.KEYCODE_DPAD_LEFT);
        key(row, "↑", KeyEvent.KEYCODE_DPAD_UP);
        key(row, "↓", KeyEvent.KEYCODE_DPAD_DOWN);
        key(row, "→", KeyEvent.KEYCODE_DPAD_RIGHT);
        row = row();
        key(row, "Z", KeyEvent.KEYCODE_Z);
        key(row, "X", KeyEvent.KEYCODE_X);
    }

    private LinearLayout row() {
        LinearLayout row = new LinearLayout(this);
        panel.addView(row);
        return row;
    }
    private Button button(LinearLayout row, String title) {
        Button button = new Button(this);
        button.setText(title);
        button.setTextSize(12);
        button.setMinWidth(0);
        button.setMinimumWidth(0);
        row.addView(button, new LinearLayout.LayoutParams(-2, -2));
        return button;
    }
    private Button button(LinearLayout row, int title) {
        return button(row, textContext.getString(title));
    }
    private void key(LinearLayout row, String title, int key) {
        button(row, title).setOnTouchListener((view, event) -> {
            int action = event.getActionMasked();
            if (action == MotionEvent.ACTION_DOWN) {
                heldKeys.add(key);
                onNativeKeyDown(key);
                view.setPressed(true);
            } else if (action == MotionEvent.ACTION_UP || action == MotionEvent.ACTION_CANCEL) {
                heldKeys.remove(key);
                onNativeKeyUp(key);
                view.setPressed(false);
            }
            return true;
        });
    }
    @Override
    public void onBackPressed() {
        // Navigation gestures can reach this callback without hardware key
        // events. SDL's trapped-back default would simply discard them.
        if (!mBrokenLibraries) {
            nativeCancelTouch();
            onNativeKeyDown(KeyEvent.KEYCODE_ESCAPE);
            onNativeKeyUp(KeyEvent.KEYCODE_ESCAPE);
        } else {
            finish();
        }
    }

    @Override
    protected void onPause() {
        if (!mBrokenLibraries) {
            nativeCancelTouch();
            for (int key : heldKeys)
                onNativeKeyUp(key);
            heldKeys.clear();
        }
        super.onPause();
    }
    @Override
    protected void onDestroy() {
        super.onDestroy();
        closeFiles(files);
        // This activity has a private :game process. A relaunch needs fresh FPC
        // globals and runtime state; the launcher/import worker stays alive.
        android.os.Process.killProcess(android.os.Process.myPid());
    }
}
