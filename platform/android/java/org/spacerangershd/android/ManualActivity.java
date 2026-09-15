package org.spacerangershd.android;

import android.app.Activity;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.webkit.*;
import android.widget.*;
import java.io.*;
import java.util.Locale;

/** Local manuals need their sibling HTML, CSS and images, all in private game storage. */
public final class ManualActivity extends Activity {
    private static final String HOST = "manual.invalid";
    private WebView page;

    @Override
    public void onCreate(Bundle state) {
        super.onCreate(state);
        File document;
        try {
            document = new File(getIntent().getStringExtra("path")).getCanonicalFile();
        } catch (IOException e) {
            finish();
            return;
        }
        File root = document.getParentFile();
        LinearLayout layout = new LinearLayout(this);
        layout.setOrientation(LinearLayout.VERTICAL);
        Button close = new Button(this);
        close.setText("Back to game");
        close.setOnClickListener(v -> finish());
        layout.addView(close);
        page = new WebView(this);
        layout.addView(page, new LinearLayout.LayoutParams(-1, 0, 1));
        setContentView(layout);
        // The original manual uses scripts to navigate its two cooperating frames.
        page.getSettings().setJavaScriptEnabled(true);
        page.getSettings().setBuiltInZoomControls(true);
        page.getSettings().setDisplayZoomControls(false);
        page.getSettings().setUseWideViewPort(true);
        page.getSettings().setLoadWithOverviewMode(true);
        page.getSettings().setAllowFileAccess(false);
        page.getSettings().setAllowContentAccess(false);
        // A single local origin lets the frames cooperate without exposing other
        // private app files to file:// JavaScript or changing Android permissions.
        page.setWebViewClient(new WebViewClient() {
            @Override
            public WebResourceResponse shouldInterceptRequest(WebView view,
                                                              WebResourceRequest request) {
                Uri uri = request.getUrl();
                try {
                    if ("https".equals(uri.getScheme()) && HOST.equals(uri.getHost()) &&
                        uri.getPath() != null && uri.getPath().startsWith("/")) {
                        File file = new File(root, uri.getPath().substring(1)).getCanonicalFile();
                        if (file.getPath().startsWith(root.getPath() + File.separator) &&
                            file.isFile()) {
                            String name = file.getName();
                            String extension =
                                name.substring(name.lastIndexOf('.') + 1).toLowerCase(Locale.ROOT);
                            String mime =
                                MimeTypeMap.getSingleton().getMimeTypeFromExtension(extension);
                            // No forced charset: legacy manuals declare Windows-1251 in their HTML.
                            return new WebResourceResponse(mime, null, new FileInputStream(file));
                        }
                    }
                } catch (IOException e) {
                    // Missing or out-of-directory resources remain unavailable to the page.
                }
                return new WebResourceResponse("text/plain", "UTF-8", 404, "Not Found", null,
                                               new ByteArrayInputStream(new byte[0]));
            }
            @Override
            public boolean shouldOverrideUrlLoading(WebView view, WebResourceRequest request) {
                Uri uri = request.getUrl();
                if ("https".equals(uri.getScheme()) && HOST.equals(uri.getHost()))
                    return false;
                if ("http".equals(uri.getScheme()) || "https".equals(uri.getScheme()) ||
                    "mailto".equals(uri.getScheme())) {
                    try {
                        startActivity(new Intent(Intent.ACTION_VIEW, uri));
                    } catch (android.content.ActivityNotFoundException e) {
                        Toast
                            .makeText(ManualActivity.this, "No app can open this link",
                                      Toast.LENGTH_SHORT)
                            .show();
                    }
                }
                return true;
            }
        });
        page.loadUrl(new Uri.Builder()
                         .scheme("https")
                         .authority(HOST)
                         .appendPath(document.getName())
                         .build()
                         .toString());
    }

    @Override
    public void onBackPressed() {
        if (page != null && page.canGoBack())
            page.goBack();
        else
            super.onBackPressed();
    }

    @Override
    public void onDestroy() {
        if (page != null)
            page.destroy();
        super.onDestroy();
    }
}
