package deckers.thibault.aves.decoder;

import android.graphics.Bitmap;
import android.media.MediaMetadataRetriever;

import androidx.annotation.NonNull;

import com.bumptech.glide.Priority;
import com.bumptech.glide.load.DataSource;
import com.bumptech.glide.load.data.DataFetcher;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.InputStream;

class VideoThumbnailFetcher implements DataFetcher<InputStream> {
    private final VideoThumbnail model;

    VideoThumbnailFetcher(VideoThumbnail model) {
        this.model = model;
    }

    @Override
    public void loadData(@NonNull Priority priority, @NonNull DataCallback<? super InputStream> callback) {
        MediaMetadataRetriever retriever = new MediaMetadataRetriever();
        try {
            retriever.setDataSource(model.getContext(), model.getUri());
            byte[] picture = retriever.getEmbeddedPicture();
            if (picture != null) {
                callback.onDataReady(new ByteArrayInputStream(picture));
            } else {
                // not ideal: bitmap -> byte[] -> bitmap
                // but simple fallback and we cache result
                Bitmap bitmap = retriever.getFrameAtTime();
                ByteArrayOutputStream bos = new ByteArrayOutputStream();
                bitmap.compress(Bitmap.CompressFormat.PNG, 0, bos);
                callback.onDataReady(new ByteArrayInputStream(bos.toByteArray()));
            }
        } catch (Exception ex) {
            callback.onLoadFailed(ex);
        } finally {
            retriever.release();
        }
    }

    @Override
    public void cleanup() {
        // already cleaned up in loadData and ByteArrayInputStream will be GC'd
    }

    @Override
    public void cancel() {
        // cannot cancel
    }

    @NonNull
    @Override
    public Class<InputStream> getDataClass() {
        return InputStream.class;
    }

    @NonNull
    @Override
    public DataSource getDataSource() {
        return DataSource.LOCAL;
    }
}