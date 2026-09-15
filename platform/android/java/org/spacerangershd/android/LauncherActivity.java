package org.spacerangershd.android;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.widget.*;
import java.io.*;
import java.util.zip.*;

/** Resources and saves live in app storage and survive signed APK updates. */
public final class LauncherActivity extends Activity {
    private TextView status;
    private Button play, importer;
    private boolean importing;
    private File root() { return getFilesDir(); }
    private boolean ready() { return new File(root(), "game/INSTALL.TXT").isFile(); }

    @Override
    public void onCreate(Bundle state) {
        super.onCreate(state);
        LinearLayout layout = new LinearLayout(this);
        layout.setOrientation(LinearLayout.VERTICAL);
        layout.setPadding(32, 32, 32, 32);
        TextView title = new TextView(this);
        title.setText("Space Rangers HD");
        title.setTextSize(28);
        layout.addView(title);
        status = new TextView(this);
        status.setPadding(0, 24, 0, 24);
        layout.addView(status);
        RadioGroup languages = new RadioGroup(this);
        RadioButton english = new RadioButton(this);
        english.setText("English");
        english.setId(1);
        RadioButton russian = new RadioButton(this);
        russian.setText("Русский");
        russian.setId(2);
        languages.addView(english);
        languages.addView(russian);
        languages.check(getPreferences(0).getBoolean("english", false) ? 1 : 2);
        languages.setOnCheckedChangeListener(
            (g, id) -> getPreferences(0).edit().putBoolean("english", id == 1).apply());
        layout.addView(languages);
        play = new Button(this);
        play.setText("Play");
        play.setOnClickListener(v -> {
            Intent intent = new Intent(this, GameActivity.class);
            intent.putExtra("language",
                            languages.getCheckedRadioButtonId() == 1 ? "english" : "russian");
            startActivity(intent);
        });
        layout.addView(play);
        importer = new Button(this);
        importer.setText("Import game resources (once)");
        importer.setOnClickListener(v -> {
            Intent intent = new Intent(Intent.ACTION_OPEN_DOCUMENT);
            intent.setType("application/zip");
            intent.addCategory(Intent.CATEGORY_OPENABLE);
            startActivityForResult(intent, 1);
        });
        layout.addView(importer);
        Button export = new Button(this);
        export.setText("Export saves and logs");
        export.setOnClickListener(v -> {
            Intent intent = new Intent(Intent.ACTION_CREATE_DOCUMENT);
            intent.setType("application/zip");
            intent.addCategory(Intent.CATEGORY_OPENABLE);
            intent.putExtra(Intent.EXTRA_TITLE, "Rangers-saves-and-logs.zip");
            startActivityForResult(intent, 2);
        });
        layout.addView(export);
        TextView help = new TextView(this);
        help.setText("Install future APKs as updates. Resources, saves and settings stay here.\n\n"
                     + "During play: tap or drag to use the mouse. Open the Controls button for "
                     + "right-click, scrolling, keyboard, save/load and arcade keys.\n\n"
                     + "Uninstalling the app or clearing its storage removes imported data; "
                     + "export saves first.");
        help.setPadding(0, 24, 0, 0);
        layout.addView(help);
        ScrollView scroll = new ScrollView(this);
        scroll.addView(layout);
        scroll.setOnApplyWindowInsetsListener((v, insets) -> {
            v.setPadding(insets.getSystemWindowInsetLeft(), insets.getSystemWindowInsetTop(),
                         insets.getSystemWindowInsetRight(), insets.getSystemWindowInsetBottom());
            return insets;
        });
        setContentView(scroll);
        refresh();
    }
    private void refresh() {
        if (importing)
            return;
        play.setEnabled(ready());
        importer.setEnabled(!ready());
        status.setText(ready() ? "Resources installed. App updates do not need another import."
                               : "Select a ZIP of the game folder to install the game data.");
    }
    @Override
    protected void onResume() {
        super.onResume();
        if (status != null)
            refresh();
    }
    @Override
    protected void onActivityResult(int request, int result, Intent data) {
        super.onActivityResult(request, result, data);
        if (result != RESULT_OK || data == null || data.getData() == null)
            return;
        Uri uri = data.getData();
        if (request == 1) {
            importing = true;
            importer.setEnabled(false);
            play.setEnabled(false);
            status.setText("Importing resources… Keep this screen open.");
            new Thread(() -> importResources(uri), "resource-import").start();
        } else if (request == 2)
            new Thread(() -> {
                try (ZipOutputStream zip =
                         new ZipOutputStream(getContentResolver().openOutputStream(uri))) {
                    zipDirectory(new File(root(), "user"), "user/", zip);
                    runOnUiThread(
                        ()
                            -> Toast.makeText(this, "Saves and logs exported", Toast.LENGTH_LONG)
                                   .show());
                } catch (Exception e) {
                    error(e);
                }
            }, "save-export").start();
    }
    private void importResources(Uri uri) {
        File stage = new File(root(), "resource-import");
        try {
            deleteTree(stage);
            if (!stage.mkdirs())
                throw new IOException("Cannot create resource directory");
            String prefix = stage.getCanonicalPath() + File.separator;
            try (ZipInputStream zip = new ZipInputStream(
                     new BufferedInputStream(getContentResolver().openInputStream(uri)))) {
                ZipEntry entry;
                byte[] buffer = new byte[1024 * 1024];
                long total = 0, last = 0;
                while ((entry = zip.getNextEntry()) != null) {
                    File file = new File(stage, entry.getName());
                    if (!file.getCanonicalPath().startsWith(prefix))
                        throw new IOException("Invalid archive path");
                    if (entry.isDirectory()) {
                        file.mkdirs();
                        continue;
                    }
                    file.getParentFile().mkdirs();
                    try (OutputStream out = new BufferedOutputStream(new FileOutputStream(file))) {
                        int n;
                        while ((n = zip.read(buffer)) != -1) {
                            out.write(buffer, 0, n);
                            total += n;
                        }
                    }
                    if (total - last > 32 * 1024 * 1024) {
                        last = total;
                        final long mb = total / 1048576;
                        runOnUiThread(() -> status.setText("Imported " + mb + " MB…"));
                    }
                }
            }
            // Import the original game directory without a generated manifest.
            File content = new File(stage, "game");
            if (!content.isDirectory())
                content = stage;
            if (!asset(content, "INSTALL.TXT").isFile() || !asset(content, "CFG.TXT").isFile() ||
                !asset(content, "CFG/Main.dat").isFile() ||
                !asset(content, "DATA/common.pkg").isFile())
                throw new IOException("This is not the Space Rangers resource archive");
            File game = new File(root(), "game");
            if (game.exists())
                throw new IOException("Resources already installed");
            if (!content.renameTo(game))
                throw new IOException("Cannot finish resource import");
            if (!content.equals(stage))
                deleteTree(stage);
        } catch (Exception e) {
            deleteTree(stage);
            error(e);
        } finally {
            importing = false;
            runOnUiThread(this::refresh);
        }
    }
    private static File asset(File directory, String path) {
        File result = directory;
        for (String part : path.split("/")) {
            File[] children = result.listFiles();
            File match = null;
            if (children != null)
                for (File child : children)
                    if (child.getName().equalsIgnoreCase(part)) {
                        match = child;
                        break;
                    }
            result = match != null ? match : new File(result, part);
        }
        return result;
    }
    private void error(Exception e) {
        runOnUiThread(()
                          -> new AlertDialog.Builder(this)
                                 .setMessage(e.toString())
                                 .setPositiveButton("OK", null)
                                 .show());
    }
    private static void deleteTree(File f) {
        File[] files = f.listFiles();
        if (files != null)
            for (File child : files)
                deleteTree(child);
        f.delete();
    }
    private static void zipDirectory(File directory, String path, ZipOutputStream zip)
        throws IOException {
        File[] files = directory.listFiles();
        if (files == null)
            return;
        byte[] buffer = new byte[65536];
        for (File file : files) {
            if (file.isDirectory()) {
                if (!file.getName().equals("Cache"))
                    zipDirectory(file, path + file.getName() + "/", zip);
                continue;
            }
            zip.putNextEntry(new ZipEntry(path + file.getName()));
            try (InputStream in = new FileInputStream(file)) {
                int n;
                while ((n = in.read(buffer)) != -1)
                    zip.write(buffer, 0, n);
            }
            zip.closeEntry();
        }
    }
}
