package io.github.pakompom.spacerangershd;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.Context;
import android.content.Intent;
import android.content.res.Configuration;
import android.database.Cursor;
import android.net.Uri;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.provider.DocumentsContract;
import android.provider.DocumentsContract.Document;
import android.view.View;
import android.view.WindowManager;
import android.widget.*;
import java.io.*;
import java.nio.file.Files;
import java.nio.file.StandardCopyOption;
import java.nio.file.attribute.FileTime;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Collections;
import java.util.Enumeration;
import java.util.TreeMap;
import java.util.TreeSet;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.WeakHashMap;
import java.util.zip.*;

/** Game assets and user files are separate and survive signed APK updates. */
public final class LauncherActivity extends Activity {
    private static final int IMPORT_GAME = 1, EXPORT_SAVES = 2, RESTORE_SAVES = 3;
    private TextView title, status, help;
    private Button play, importer, exporter, restorer;
    private RadioButton english, russian;
    private Context textContext;
    private Uri pendingUri;
    private int pendingRequest;
    private boolean resumed;
    private AlertDialog confirmation;
    private static final Transfers transfers = new Transfers();

    /** Owns the worker across Activity recreation. State and observers use the main thread. */
    private static final class Transfers {
        private final Handler main = new Handler(Looper.getMainLooper());
        private final Set<LauncherActivity> observers =
            Collections.newSetFromMap(new WeakHashMap<LauncherActivity, Boolean>());
        private boolean busy;
        private int request;
        private int message, error;
        private String detail;
        private long megabytes;

        void attach(LauncherActivity activity) {
            observers.add(activity);
            activity.refresh();
        }

        void detach(LauncherActivity activity) { observers.remove(activity); }

        private void notifyActivities() {
            for (LauncherActivity activity : observers)
                if (!activity.isFinishing() && !activity.isDestroyed())
                    activity.refresh();
        }

        void restore(Bundle state) {
            if (state == null || message != 0 || busy)
                return;
            int interrupted = state.getInt("transferRequest");
            if (interrupted == IMPORT_GAME)
                message = R.string.launcher_import_interrupted;
            else if (interrupted == EXPORT_SAVES)
                message = R.string.launcher_export_unconfirmed;
            else if (interrupted == RESTORE_SAVES)
                message = R.string.launcher_restore_interrupted;
            else {
                message = state.getInt("transferMessageId");
                error = state.getInt("transferErrorId");
                detail = state.getString("transferDetail");
                megabytes = state.getLong("transferMegabytes");
            }
        }

        void save(Bundle state) {
            state.putInt("transferRequest", busy ? request : 0);
            state.putInt("transferMessageId", message);
            state.putInt("transferErrorId", error);
            state.putString("transferDetail", detail);
            state.putLong("transferMegabytes", megabytes);
        }

        String text(Context context, boolean ready) {
            int resource = message != 0 ? message
                           : ready      ? R.string.launcher_ready
                                        : R.string.launcher_select_folder;
            if (resource == R.string.launcher_import_progress)
                return context.getString(resource, megabytes);
            if (resource == R.string.launcher_import_failed ||
                resource == R.string.launcher_export_failed ||
                resource == R.string.launcher_restore_failed) {
                String explanation = error == 0       ? detail
                                     : detail == null ? context.getString(error)
                                                      : context.getString(error, detail);
                return context.getString(resource, explanation);
            }
            return context.getString(resource);
        }

        private void progress(long copied) {
            main.post(() -> {
                message = R.string.launcher_import_progress;
                megabytes = copied;
                notifyActivities();
            });
        }

        private static int failureMessage(int operation) {
            return operation == IMPORT_GAME ? R.string.launcher_import_failed
            : operation == EXPORT_SAVES     ? R.string.launcher_export_failed
                                            : R.string.launcher_restore_failed;
        }

        void start(Context application, int operation, Uri uri) {
            // Activity results run on the main thread. The file lease below
            // also excludes the separate :game process for the whole transfer.
            if (busy)
                return;
            busy = true;
            request = operation;
            message = operation == IMPORT_GAME    ? R.string.launcher_importing
                      : operation == EXPORT_SAVES ? R.string.launcher_exporting
                                                  : R.string.launcher_restoring;
            error = 0;
            detail = null;
            megabytes = 0;
            notifyActivities();
            Context context = application.getApplicationContext();
            new Thread(() -> {
                int result, failure = 0;
                String diagnostic = null;
                boolean exported = false;
                try (GameFiles files = GameFiles.acquire(context)) {
                    files.cleanup();
                    if (operation == EXPORT_SAVES) {
                        File user = new File(context.getFilesDir(), "user");
                        if (!user.isDirectory())
                            throw new GameFiles.Failure(R.string.launcher_error_no_user_files);
                        try (OutputStream output =
                                 context.getContentResolver().openOutputStream(uri, "wt")) {
                            if (output == null)
                                throw new GameFiles.Failure(
                                    R.string.launcher_error_export_document);
                            try (ZipOutputStream zip = new ZipOutputStream(output)) {
                                if (zipDirectory(user, "user/", zip) == 0)
                                    throw new GameFiles.Failure(
                                        R.string.launcher_error_no_user_files);
                            }
                        }
                        exported = true;
                        result = R.string.launcher_exported;
                    } else {
                        // Keep access if the picker-owning Activity is recreated.
                        context.getContentResolver().takePersistableUriPermission(
                            uri, Intent.FLAG_GRANT_READ_URI_PERMISSION);
                        try {
                            if (operation == IMPORT_GAME)
                                new FolderImport(context, this).run(uri, files);
                            else
                                restoreUser(context, uri, files);
                        } finally {
                            try {
                                context.getContentResolver().releasePersistableUriPermission(
                                    uri, Intent.FLAG_GRANT_READ_URI_PERMISSION);
                            } catch (SecurityException ignored) {
                            }
                        }
                        result = operation == IMPORT_GAME ? R.string.launcher_ready
                                                          : R.string.launcher_restored;
                    }
                } catch (GameFiles.Failure error) {
                    result = failureMessage(operation);
                    failure = error.resource;
                    diagnostic = error.detail;
                } catch (Exception error) {
                    result = failureMessage(operation);
                    diagnostic = error.toString();
                } finally {
                    if (operation == EXPORT_SAVES && !exported) {
                        // ACTION_CREATE_DOCUMENT creates a new document. A failed
                        // ZIP must not remain looking like a usable backup.
                        try {
                            DocumentsContract.deleteDocument(context.getContentResolver(), uri);
                        } catch (Exception ignored) {
                            // Some providers do not support deletion.
                        }
                    }
                }
                final int completed = result, completedError = failure;
                final String completedDetail = diagnostic;
                main.post(() -> {
                    busy = false;
                    message = completed;
                    error = completedError;
                    detail = completedDetail;
                    notifyActivities();
                });
            }, "game-file-transfer").start();
        }
    }

    private boolean ready() {
        return new File(getFilesDir(), "game/INSTALL.TXT").isFile() ||
            new File(getFilesDir(), "game-previous/INSTALL.TXT").isFile();
    }

    @Override
    public void onCreate(Bundle state) {
        super.onCreate(state);
        LinearLayout layout = new LinearLayout(this);
        layout.setOrientation(LinearLayout.VERTICAL);
        int padding = Math.round(20 * getResources().getDisplayMetrics().density);
        layout.setPadding(padding, padding, padding, padding);
        title = new TextView(this);
        title.setTextSize(28);
        layout.addView(title);
        status = new TextView(this);
        status.setPadding(0, padding, 0, padding);
        layout.addView(status);
        RadioGroup languages = new RadioGroup(this);
        english = new RadioButton(this);
        english.setId(1);
        russian = new RadioButton(this);
        russian.setId(2);
        languages.addView(english);
        languages.addView(russian);
        languages.check(getPreferences(0).getBoolean("english", false) ? 1 : 2);
        languages.setOnCheckedChangeListener((group, id) -> {
            getPreferences(0).edit().putBoolean("english", id == 1).apply();
            selectLanguage(id == 1);
        });
        layout.addView(languages);
        play = new Button(this);
        play.setOnClickListener(view -> {
            Intent intent = new Intent(this, GameActivity.class);
            intent.putExtra("language",
                            languages.getCheckedRadioButtonId() == 1 ? "english" : "russian");
            startActivity(intent);
        });
        layout.addView(play);
        importer = new Button(this);
        importer.setOnClickListener(view -> {
            startActivityForResult(new Intent(Intent.ACTION_OPEN_DOCUMENT_TREE), IMPORT_GAME);
        });
        layout.addView(importer);
        exporter = new Button(this);
        exporter.setOnClickListener(view -> {
            Intent intent = new Intent(Intent.ACTION_CREATE_DOCUMENT);
            intent.setType("application/zip");
            intent.addCategory(Intent.CATEGORY_OPENABLE);
            String timestamp = LocalDateTime.now().format(
                DateTimeFormatter.ofPattern("yyyy-MM-dd_HH-mm-ss", Locale.ROOT));
            intent.putExtra(Intent.EXTRA_TITLE,
                            textContext.getString(R.string.launcher_export_filename, timestamp));
            startActivityForResult(intent, EXPORT_SAVES);
        });
        layout.addView(exporter);
        restorer = new Button(this);
        restorer.setOnClickListener(view -> {
            Intent intent = new Intent(Intent.ACTION_OPEN_DOCUMENT);
            intent.setType("application/zip");
            intent.addCategory(Intent.CATEGORY_OPENABLE);
            intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION |
                            Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION);
            startActivityForResult(intent, RESTORE_SAVES);
        });
        layout.addView(restorer);
        help = new TextView(this);
        help.setPadding(0, padding, 0, 0);
        layout.addView(help);
        ScrollView scroll = new ScrollView(this);
        scroll.addView(layout);
        scroll.setOnApplyWindowInsetsListener((view, insets) -> {
            view.setPadding(insets.getSystemWindowInsetLeft(), insets.getSystemWindowInsetTop(),
                            insets.getSystemWindowInsetRight(),
                            insets.getSystemWindowInsetBottom());
            return insets;
        });
        setContentView(scroll);
        transfers.restore(state);
        if (state != null) {
            String uri = state.getString("pendingUri");
            pendingUri = uri == null ? null : Uri.parse(uri);
            pendingRequest = state.getInt("pendingRequest");
        }
        selectLanguage(languages.getCheckedRadioButtonId() == 1);
    }

    private void selectLanguage(boolean useEnglish) {
        Configuration configuration = new Configuration(getResources().getConfiguration());
        configuration.setLocale(new Locale(useEnglish ? "en" : "ru"));
        textContext = createConfigurationContext(configuration);
        setTitle(textContext.getString(R.string.app_name));
        title.setText(textContext.getString(R.string.app_name));
        english.setText(textContext.getString(R.string.launcher_english));
        russian.setText(textContext.getString(R.string.launcher_russian));
        play.setText(textContext.getString(R.string.launcher_play));
        exporter.setText(textContext.getString(R.string.launcher_export));
        restorer.setText(textContext.getString(R.string.launcher_restore));
        refresh();
    }

    private void refresh() {
        if (transfers.busy)
            getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        else
            getWindow().clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        boolean installed = ready();
        play.setEnabled(!transfers.busy && installed);
        importer.setEnabled(!transfers.busy);
        importer.setText(textContext.getString(installed ? R.string.launcher_replace_game
                                                         : R.string.launcher_import));
        exporter.setEnabled(!transfers.busy);
        restorer.setEnabled(!transfers.busy);
        status.setText(transfers.text(textContext, installed));
        String instructions = textContext.getString(R.string.launcher_help);
        if (!installed)
            instructions =
                textContext.getString(R.string.launcher_import_help) + "\n\n" + instructions;
        help.setText(instructions);
    }

    @Override
    protected void onResume() {
        super.onResume();
        resumed = true;
        transfers.attach(this);
        confirmPending();
    }

    @Override
    protected void onPause() {
        resumed = false;
        if (confirmation != null) {
            confirmation.dismiss();
            confirmation = null;
        }
        transfers.detach(this);
        super.onPause();
    }

    @Override
    protected void onDestroy() {
        transfers.detach(this);
        super.onDestroy();
    }

    @Override
    protected void onSaveInstanceState(Bundle state) {
        transfers.save(state);
        if (pendingUri != null) {
            state.putString("pendingUri", pendingUri.toString());
            state.putInt("pendingRequest", pendingRequest);
        }
        super.onSaveInstanceState(state);
    }

    @Override
    protected void onActivityResult(int request, int result, Intent data) {
        super.onActivityResult(request, result, data);
        if (result != RESULT_OK || data == null || data.getData() == null || transfers.busy)
            return;
        if (request != IMPORT_GAME && request != EXPORT_SAVES && request != RESTORE_SAVES)
            return;
        if (request == RESTORE_SAVES || (request == IMPORT_GAME && ready())) {
            pendingUri = data.getData();
            pendingRequest = request;
            confirmPending();
        } else {
            transfers.start(getApplicationContext(), request, data.getData());
        }
        refresh();
    }

    private void confirmPending() {
        if (!resumed || pendingUri == null || confirmation != null || transfers.busy)
            return;
        boolean restore = pendingRequest == RESTORE_SAVES;
        confirmation =
            new AlertDialog.Builder(this)
                .setTitle(textContext.getString(restore ? R.string.launcher_restore
                                                        : R.string.launcher_replace_game))
                .setMessage(textContext.getString(restore ? R.string.launcher_confirm_restore
                                                          : R.string.launcher_confirm_replace))
                .setPositiveButton(textContext.getString(restore ? R.string.launcher_restore
                                                                 : R.string.launcher_replace_game),
                                   (dialog, button) -> {
                                       Uri uri = pendingUri;
                                       int request = pendingRequest;
                                       pendingUri = null;
                                       confirmation = null;
                                       transfers.start(getApplicationContext(), request, uri);
                                   })
                .setNegativeButton(textContext.getString(R.string.launcher_cancel),
                                   (dialog, button) -> {
                                       pendingUri = null;
                                       confirmation = null;
                                   })
                .setOnCancelListener(dialog -> {
                    pendingUri = null;
                    confirmation = null;
                })
                .create();
        confirmation.show();
    }

    private static final class Resource {
        final Uri uri;
        final String name, path;
        final boolean directory;
        final long size;

        Resource(Uri parent, String prefix, Cursor row) {
            uri = DocumentsContract.buildDocumentUriUsingTree(parent, row.getString(0));
            name = row.getString(1);
            path = prefix + name;
            directory = Document.MIME_TYPE_DIR.equals(row.getString(2));
            size = row.isNull(3) ? -1 : row.getLong(3);
        }
    }

    private static final class FolderImport {
        private final Context context;
        private final Transfers transfer;
        private final byte[] buffer = new byte[1024 * 1024];
        private long total, lastProgress;

        FolderImport(Context context, Transfers transfer) {
            this.context = context;
            this.transfer = transfer;
        }

        private Map<String, Resource> children(Uri directory, String path) throws IOException {
            Uri uri = DocumentsContract.buildChildDocumentsUriUsingTree(
                directory, DocumentsContract.getDocumentId(directory));
            String[] columns = {Document.COLUMN_DOCUMENT_ID, Document.COLUMN_DISPLAY_NAME,
                                Document.COLUMN_MIME_TYPE, Document.COLUMN_SIZE};
            Map<String, Resource> files = new TreeMap<>(String.CASE_INSENSITIVE_ORDER);
            try (Cursor rows = context.getContentResolver().query(uri, columns, null, null, null)) {
                if (rows == null)
                    throw new GameFiles.Failure(R.string.launcher_error_read_folder);
                while (rows.moveToNext()) {
                    Resource file = new Resource(directory, path, rows);
                    String name = file.name;
                    if (name == null || name.isEmpty() || name.equals(".") || name.equals("..") ||
                        name.indexOf('/') >= 0 || name.indexOf('\\') >= 0 ||
                        name.indexOf('\0') >= 0)
                        throw new GameFiles.Failure(R.string.launcher_error_invalid_resource,
                                                    String.valueOf(name));
                    Resource previous = files.put(name, file);
                    if (previous != null)
                        throw new GameFiles.Failure(R.string.launcher_error_duplicate_resource,
                                                    previous.path + "; " + file.path);
                }
            }
            return files;
        }

        private Resource require(Map<String, Resource> files, String path, boolean directory)
            throws IOException {
            String name = path.substring(path.lastIndexOf('/') + 1);
            Resource file = files.get(name);
            if (file == null)
                throw new GameFiles.Failure(R.string.launcher_error_missing_resource, path);
            if (file.directory != directory)
                throw new GameFiles.Failure(directory ? R.string.launcher_error_expected_directory
                                                      : R.string.launcher_error_expected_file,
                                            path);
            if (!directory && file.size == 0)
                throw new GameFiles.Failure(R.string.launcher_error_empty_file, path);
            return file;
        }

        private boolean isLanguageFile(Resource file) {
            if (file == null)
                return false;
            String name = file.name.toLowerCase(Locale.ROOT);
            return !file.directory && name.startsWith("install_") && name.endsWith(".txt") &&
                name.length() > 12 && file.size != 0;
        }

        private void copy(Resource source, File target) throws IOException {
            if (source.directory) {
                if (!target.mkdir())
                    throw new GameFiles.Failure(R.string.launcher_error_create_directory,
                                                source.path);
                for (Resource child : children(source.uri, source.path + "/").values())
                    copy(child, new File(target, child.name));
                return;
            }
            long copied = 0;
            try (InputStream input = context.getContentResolver().openInputStream(source.uri)) {
                if (input == null)
                    throw new GameFiles.Failure(R.string.launcher_error_read_resource, source.path);
                try (OutputStream output = new BufferedOutputStream(new FileOutputStream(target))) {
                    int count;
                    while ((count = input.read(buffer)) != -1) {
                        output.write(buffer, 0, count);
                        copied += count;
                        total += count;
                        if (total - lastProgress >= 32 * 1024 * 1024) {
                            lastProgress = total;
                            transfer.progress(total / 1048576);
                        }
                    }
                }
            }
            if (source.size >= 0 && copied != source.size)
                throw new GameFiles.Failure(R.string.launcher_error_incomplete_resource,
                                            source.path);
        }

        void run(Uri tree, GameFiles lease) throws IOException {
            Uri root = DocumentsContract.buildDocumentUriUsingTree(
                tree, DocumentsContract.getTreeDocumentId(tree));
            Map<String, Resource> files = children(root, "");
            Resource install = require(files, "INSTALL.TXT", false);
            Resource settings = require(files, "CFG.TXT", false);
            Resource cfg = require(files, "CFG", true);
            Resource data = require(files, "DATA", true);
            require(children(cfg.uri, cfg.path + "/"), "CFG/Main.dat", false);
            require(children(data.uri, data.path + "/"), "DATA/common.pkg", false);
            if (!isLanguageFile(files.get("install_english.txt")) &&
                !isLanguageFile(files.get("install_russian.txt")))
                throw new GameFiles.Failure(R.string.launcher_error_missing_languages);
            Resource mods = files.get("mods");
            if (mods != null)
                require(files, "Mods", true);
            File stage = new File(context.getFilesDir(), "resource-import");
            try {
                if (!stage.mkdir())
                    throw new GameFiles.Failure(R.string.launcher_error_create_resources);
                copy(install, new File(stage, "INSTALL.TXT"));
                copy(settings, new File(stage, "CFG.TXT"));
                for (Resource file : files.values())
                    if (isLanguageFile(file))
                        copy(file, new File(stage, file.name));
                copy(cfg, new File(stage, "CFG"));
                copy(data, new File(stage, "data"));
                if (mods != null)
                    copy(mods, new File(stage, "Mods"));
                // Recheck actual bytes: document providers can report an unknown
                // size, including for an empty required file.
                validateInstalled(stage);
                lease.replace(stage, "game");
            } finally {
                // A successful replacement renames the stage out of the way.
                GameFiles.deleteTree(stage);
            }
        }
    }

    private static long zipDirectory(File directory, String path, ZipOutputStream zip)
        throws IOException {
        File[] files = directory.listFiles();
        if (files == null)
            throw new GameFiles.Failure(R.string.launcher_error_read_local_folder, path);
        long count = 0;
        Set<String> names = new TreeSet<>(String.CASE_INSENSITIVE_ORDER);
        for (File file : files) {
            if (!names.add(file.getName()))
                throw new GameFiles.Failure(R.string.launcher_error_duplicate_resource,
                                            path + file.getName());
            if (excluded(file.getName()))
                continue;
            if (Files.isSymbolicLink(file.toPath()))
                throw new GameFiles.Failure(R.string.launcher_error_invalid_resource,
                                            path + file.getName());
            if (file.isDirectory()) {
                count += zipDirectory(file, path + file.getName() + "/", zip);
                continue;
            }
            if (!file.isFile())
                throw new GameFiles.Failure(R.string.launcher_error_read_resource,
                                            path + file.getName());
            ZipEntry entry = new ZipEntry(path + file.getName());
            // Preserve the save ordering across export/restore. The explicit
            // timestamp extra field avoids DOS ZIP time's timezone ambiguity
            // and two-second rounding for archives produced by this launcher.
            entry.setLastModifiedTime(Files.getLastModifiedTime(file.toPath()));
            zip.putNextEntry(entry);
            Files.copy(file.toPath(), zip);
            zip.closeEntry();
            count++;
        }
        return count;
    }

    private static boolean excluded(String name) {
        return name.equalsIgnoreCase("Cache") || name.equalsIgnoreCase("instance.lock");
    }

    private static File childIgnoringCase(File directory, String name) throws IOException {
        File[] children = directory.listFiles();
        if (children == null)
            throw new GameFiles.Failure(R.string.launcher_error_read_local_folder,
                                        directory.toString());
        File match = null;
        for (File child : children)
            if (child.getName().equalsIgnoreCase(name)) {
                if (match != null)
                    throw new GameFiles.Failure(R.string.launcher_error_duplicate_resource,
                                                match + "; " + child);
                match = child;
            }
        return match == null ? new File(directory, name) : match;
    }

    private static void requireNonempty(File root, String path) throws IOException {
        File file = root;
        for (String part : path.split("/"))
            file = childIgnoringCase(file, part);
        if (!file.isFile() || file.length() == 0)
            throw new GameFiles.Failure(R.string.launcher_error_empty_file, path);
    }

    private static void validateInstalled(File stage) throws IOException {
        requireNonempty(stage, "INSTALL.TXT");
        requireNonempty(stage, "CFG.TXT");
        requireNonempty(stage, "CFG/Main.dat");
        requireNonempty(stage, "data/common.pkg");
        File english = childIgnoringCase(stage, "INSTALL_ENGLISH.TXT");
        File russian = childIgnoringCase(stage, "INSTALL_RUSSIAN.TXT");
        if ((!english.isFile() || english.length() == 0) &&
            (!russian.isFile() || russian.length() == 0))
            throw new GameFiles.Failure(R.string.launcher_error_missing_languages);
    }

    private static void copyUser(File source, File target) throws IOException {
        if (Files.isSymbolicLink(source.toPath()))
            throw new GameFiles.Failure(R.string.launcher_error_invalid_resource,
                                        source.toString());
        if (source.isDirectory()) {
            if (!target.mkdir())
                throw new GameFiles.Failure(R.string.launcher_error_create_directory,
                                            target.toString());
            File[] children = source.listFiles();
            if (children == null)
                throw new GameFiles.Failure(R.string.launcher_error_read_local_folder,
                                            source.toString());
            Set<String> names = new TreeSet<>(String.CASE_INSENSITIVE_ORDER);
            for (File child : children) {
                if (excluded(child.getName()))
                    continue;
                if (!names.add(child.getName()))
                    throw new GameFiles.Failure(R.string.launcher_error_duplicate_resource,
                                                child.toString());
                copyUser(child, new File(target, child.getName()));
            }
            Files.setLastModifiedTime(target.toPath(), Files.getLastModifiedTime(source.toPath()));
        } else if (source.isFile()) {
            Files.copy(source.toPath(), target.toPath(), StandardCopyOption.COPY_ATTRIBUTES);
        } else {
            throw new GameFiles.Failure(R.string.launcher_error_read_resource, source.toString());
        }
    }

    private static void restoreUser(Context context, Uri uri, GameFiles lease) throws IOException {
        File stage = new File(context.getFilesDir(), "user-import");
        File archive = new File(context.getFilesDir(), "save-restore.zip");
        try {
            // ZipFile checks the central directory; reading an arbitrary truncated
            // stream must not masquerade as a complete backup.
            try (InputStream input = context.getContentResolver().openInputStream(uri)) {
                if (input == null)
                    throw new GameFiles.Failure(R.string.launcher_error_read_backup);
                Files.copy(input, archive.toPath());
            }
            File user = new File(context.getFilesDir(), "user");
            if (user.exists())
                copyUser(user, stage);
            else if (!stage.mkdir())
                throw new GameFiles.Failure(R.string.launcher_error_create_directory, "user");
            Map<String, String> names = new TreeMap<>(String.CASE_INSENSITIVE_ORDER);
            Set<String> entries = new TreeSet<>(String.CASE_INSENSITIVE_ORDER);
            long restored = 0;
            try (ZipFile zip = new ZipFile(archive)) {
                Enumeration<? extends ZipEntry> members = zip.entries();
                byte[] buffer = new byte[65536];
                while (members.hasMoreElements()) {
                    ZipEntry entry = members.nextElement();
                    String path = entry.getName();
                    String normalized =
                        entry.isDirectory() ? path.substring(0, path.length() - 1) : path;
                    String[] parts = normalized.split("/", -1);
                    if (parts.length == 0 || !parts[0].equals("user") ||
                        (parts.length == 1 && !entry.isDirectory()) || path.indexOf('\\') >= 0 ||
                        path.indexOf('\0') >= 0 || !entries.add(normalized))
                        throw new GameFiles.Failure(R.string.launcher_error_invalid_backup_path,
                                                    path);
                    File target = stage;
                    String prefix = "user";
                    for (int i = 1; i < parts.length; i++) {
                        String part = parts[i];
                        if (part.isEmpty() || part.equals(".") || part.equals("..") ||
                            part.indexOf(':') >= 0 || excluded(part))
                            throw new GameFiles.Failure(R.string.launcher_error_invalid_backup_path,
                                                        path);
                        prefix += "/" + part;
                        String old = names.putIfAbsent(prefix, prefix);
                        if (old != null && !old.equals(prefix))
                            throw new GameFiles.Failure(R.string.launcher_error_duplicate_resource,
                                                        old + "; " + prefix);
                        target = childIgnoringCase(target, part);
                        boolean directory = i < parts.length - 1 || entry.isDirectory();
                        if (directory) {
                            if (target.exists() && !target.isDirectory())
                                throw new GameFiles.Failure(
                                    R.string.launcher_error_expected_directory, prefix);
                            if (!target.exists() && !target.mkdir())
                                throw new GameFiles.Failure(
                                    R.string.launcher_error_create_directory, prefix);
                        } else if (target.exists() && !target.isFile()) {
                            throw new GameFiles.Failure(R.string.launcher_error_expected_file,
                                                        prefix);
                        }
                    }
                    if (entry.isDirectory())
                        continue;
                    FileTime modified = entry.getLastModifiedTime();
                    // A timestamp-less archive cannot tell us the save date.
                    // Keep an existing file's date; only a newly introduced
                    // file falls back to its extraction time.
                    if (modified == null && target.exists())
                        modified = Files.getLastModifiedTime(target.toPath());
                    CRC32 crc = new CRC32();
                    long size = 0;
                    try (InputStream input = zip.getInputStream(entry);
                         OutputStream output = new FileOutputStream(target)) {
                        int count;
                        while ((count = input.read(buffer)) != -1) {
                            output.write(buffer, 0, count);
                            crc.update(buffer, 0, count);
                            size += count;
                        }
                    }
                    if (size != entry.getSize() || crc.getValue() != entry.getCrc())
                        throw new GameFiles.Failure(R.string.launcher_error_damaged_backup, path);
                    if (modified != null)
                        Files.setLastModifiedTime(target.toPath(), modified);
                    restored++;
                }
            }
            if (restored == 0)
                throw new GameFiles.Failure(R.string.launcher_error_empty_backup);
            lease.replace(stage, "user");
        } catch (ZipException error) {
            throw new GameFiles.Failure(R.string.launcher_error_invalid_backup);
        } finally {
            // The committed directory was renamed away; only temporary files
            // remain here on failure. Existing saves have not been touched.
            try {
                GameFiles.deleteTree(stage);
            } finally {
                archive.delete();
            }
        }
    }
}
