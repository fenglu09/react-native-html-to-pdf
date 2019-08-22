package com.christopherdro.htmltopdf;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Rect;
import android.graphics.pdf.PdfRenderer;
import android.os.Build;
import android.os.Environment;
import android.os.ParcelFileDescriptor;
import android.util.Log;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.ArrayList;

public class Utils {

    public static ArrayList<Bitmap> pdfToBitmap(File pdfFile, Context context) {
        ArrayList<Bitmap> bitmaps = new ArrayList<>();
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                PdfRenderer renderer = new PdfRenderer(ParcelFileDescriptor.open(pdfFile, ParcelFileDescriptor.MODE_READ_ONLY));
                Bitmap bitmap;
                final int pageCount = renderer.getPageCount();
                Log.e("test_sign", "图片de 张数： " + pageCount);
                for (int i = 0; i < pageCount; i++) {
                    PdfRenderer.Page page = renderer.openPage(i);
                    int width = context.getResources().getDisplayMetrics().densityDpi / 72 * page.getWidth();
                    int height = context.getResources().getDisplayMetrics().densityDpi / 72 * page.getHeight();
                    bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888);
                    //todo 以下三行处理图片存储到本地出现黑屏的问题，这个涉及到背景问题
                    Canvas canvas = new Canvas(bitmap);
                    canvas.drawColor(Color.WHITE);
                    canvas.drawBitmap(bitmap, 0, 0, null);
                    Rect r = new Rect(0, 0, width, height);
                    page.render(bitmap, r, null, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY);
                    bitmaps.add(bitmap);
                    // close the page
                    page.close();
                }
                // close the renderer
                renderer.close();
            }

        } catch (Exception ex) {
            ex.printStackTrace();
        }

        return bitmaps;

    }

    public static String saveImageToGallery(Context context, ArrayList<Bitmap> bitmaps) {
        // 首先保存图片
        File appDir = new File(Environment.getExternalStorageDirectory().getAbsolutePath() + File.separator + "share");
        for (int i = 0; i < bitmaps.size(); i++) {
            if (!appDir.exists()) {
                appDir.mkdir();
            }
            String fileName = "shareImg.jpg";
            File file = new File(appDir, fileName);
            Log.e("test_sign", "图片全路径localFile = " + appDir.getAbsolutePath() + fileName);
            FileOutputStream fos = null;
            try {
                fos = new FileOutputStream(file);
                bitmaps.get(i).compress(Bitmap.CompressFormat.JPEG, 100, fos);
                fos.flush();
                fos.close();
            } catch (FileNotFoundException e) {
                e.printStackTrace();
            } catch (IOException e) {
                e.printStackTrace();
            } finally {
                if (fos != null) {
                    try {
                        fos.close();
                        //回收
                        bitmaps.get(i).recycle();
                    } catch (IOException e) {
                        e.printStackTrace();
                    }
                }
                return appDir.getAbsolutePath() + "/" + fileName;
            }

        }
        return null;

    }


}
