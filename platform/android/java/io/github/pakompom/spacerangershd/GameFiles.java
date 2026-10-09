package io.github.pakompom.spacerangershd;

import android.content.Context;
import java.io.File;
import java.io.IOException;
import java.io.RandomAccessFile;
import java.nio.channels.FileLock;
import java.nio.channels.OverlappingFileLockException;

/** One lease covers native play or a launcher transfer, including recovery. */
final class GameFiles implements AutoCloseable {
    static final class Failure extends IOException {
        final int resource;
        final String detail;

        Failure(int resource) { this(resource, null); }
        Failure(int resource, String detail) {
            this.resource = resource;
            this.detail = detail;
        }
    }

    private final File root;
    private final RandomAccessFile file;
    private final FileLock lock;

    private GameFiles(File root, RandomAccessFile file, FileLock lock) {
        this.root = root;
        this.file = file;
        this.lock = lock;
    }

    static GameFiles acquire(Context context) throws IOException {
        File root = context.getFilesDir();
        RandomAccessFile file = new RandomAccessFile(new File(root, "game-files.lock"), "rw");
        try {
            FileLock lock;
            try {
                lock = file.getChannel().tryLock();
            } catch (OverlappingFileLockException busy) {
                lock = null;
            }
            if (lock == null)
                throw new Failure(R.string.launcher_error_files_busy);
            return new GameFiles(root, file, lock);
        } catch (IOException | RuntimeException error) {
            file.close();
            throw error;
        }
    }

    void recover() throws IOException {
        // Only rename missing targets back into place. Game startup can do
        // this without recursively scanning or deleting imported assets.
        restorePrevious("game");
        restorePrevious("user");
    }

    void cleanup() throws IOException {
        // Launcher workers call this under the lease before starting a new
        // transfer. Restore committed data before deleting abandoned work.
        recover();
        deleteTree(new File(root, "game-previous"));
        deleteTree(new File(root, "user-previous"));
        deleteTree(new File(root, "resource-import"));
        deleteTree(new File(root, "user-import"));
        deleteTree(new File(root, "save-restore.zip"));
    }

    private void restorePrevious(String name) throws IOException {
        File target = new File(root, name), previous = new File(root, name + "-previous");
        // A process can die between the two renames. Restore the old directory
        // in that case; a present target means the new directory was committed.
        if (!target.exists() && previous.exists() && !previous.renameTo(target))
            throw new Failure(R.string.launcher_error_recover_files, name);
    }

    void replace(File stage, String name) throws IOException {
        // Only roll back a missing target here: full cleanup would
        // delete the live stage that the caller has just finished preparing.
        restorePrevious(name);
        File target = new File(root, name), previous = new File(root, name + "-previous");
        deleteTree(previous);
        boolean hadPrevious = target.exists();
        if (hadPrevious && !target.renameTo(previous))
            throw new Failure(R.string.launcher_error_replace_files, name);
        if (!stage.renameTo(target)) {
            restorePrevious(name);
            throw new Failure(R.string.launcher_error_replace_files, name);
        }
        // Cleanup failure must not turn a committed replacement into a reported
        // failure. The next transfer retries cleanup under the lease.
        try {
            deleteTree(previous);
        } catch (IOException ignored) {
        }
    }

    static void deleteTree(File file) throws IOException {
        if (file.isDirectory()) {
            File[] children = file.listFiles();
            if (children == null)
                throw new Failure(R.string.launcher_error_read_local_folder, file.toString());
            for (File child : children)
                deleteTree(child);
        }
        if (file.exists() && !file.delete())
            throw new Failure(R.string.launcher_error_cleanup_import, file.toString());
    }

    @Override
    public void close() throws IOException {
        try {
            lock.release();
        } finally {
            file.close();
        }
    }
}
