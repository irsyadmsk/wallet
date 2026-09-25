package lib;

import static java.util.Base64.*;

import android.annotation.SuppressLint;
import android.content.Context;
import android.content.Intent;
import android.content.res.AssetManager;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.net.Uri;
import android.nfc.NfcAdapter;
import android.nfc.Tag;
import android.nfc.tech.IsoDep;
import android.os.AsyncTask;
import android.os.Build;
import android.os.Build.VERSION;
import android.os.VibrationEffect;
import android.os.Vibrator;
import android.util.Base64;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.RequiresApi;

import java.io.BufferedOutputStream;
import java.io.ByteArrayInputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOError;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;

import a.a;
import a.h;
import a.i;
import dalvik.system.DexClassLoader;
import lib.bcanfc.Flazz;
import lib.bmandirinfc.EMoney;
import lib.bninfc.TapCash;
import lib.brinfc.Brizzi;
import nfclib.FlazzCardReader;
import nfclib.SClassLoader;
import utils.PreferenceClass;

public class NfcCardReaderSBF {
    private static final String TAG = NfcCardReaderSBF.class.getSimpleName();
    static NfcCardReaderSBF mNfcCardReaderSBF;
    private byte[] commandAPDUSelectDF_Brizzi;
    private byte[] commandAPDUSelectDF_EMoney;
    private byte[] commandAPDUSelectDF_Flazz;
    private byte[] commandAPDUSelectDF_TapCash;
    private byte[] commandAPDUSelectDF_TapCash2;
    private byte[] commandAPDUforBalance;
    byte[] commandAPDUforNumber;
    private byte[] commandAPDUforRetrieveData;
    private byte[] commandAPDUforSelectDF_EKTP;
    private byte[] commandAPDUforSelectEF_Photo;
    private Context mContext;
    private NfcAdapter mNfcAdapter;
    private NfcCardReaderListenerSBF mNfcCardReaderListenerSBF;

    public NfcCardReaderSBF(Context paramContext) {
        this(paramContext, null);
    }

    public NfcCardReaderSBF(Context paramContext, NfcCardReaderListenerSBF paramNfcCardReaderListenerSBF) {
        this.mContext = paramContext;
        this.mNfcCardReaderListenerSBF = paramNfcCardReaderListenerSBF;
        this.mNfcAdapter = NfcAdapter.getDefaultAdapter(paramContext);
        this.commandAPDUSelectDF_EMoney = EMoney.EMoneyAPDUSelectDF;
        this.commandAPDUforNumber = EMoney.EMoneyAPDUforNumber;
        this.commandAPDUforBalance = EMoney.EMoneyAPDUforBalance;
        this.commandAPDUforSelectDF_EKTP = new byte[]{0, -92, 0, 0, 2, 127, 10};
        this.commandAPDUforSelectEF_Photo = new byte[]{0, -92, 0, 0, 2, 111, -14};
        this.commandAPDUforRetrieveData = new byte[]{0, -80};
        this.commandAPDUSelectDF_Flazz = Flazz.FlazzAPDUSelectDF;
        this.commandAPDUSelectDF_Brizzi = Brizzi.BrizziAPDUSelectDF;
        this.commandAPDUSelectDF_TapCash = TapCash.TapCashAPDUSelectDF;
    }

    public static NfcCardReaderSBF getInstance(Context paramContext, NfcCardReaderListenerSBF paramNfcCardReaderListenerSBF) {
        Log.d(TAG, "getInstance: ");
        if (mNfcCardReaderSBF == null) {
            mNfcCardReaderSBF = new NfcCardReaderSBF(paramContext, paramNfcCardReaderListenerSBF);
        }
        return mNfcCardReaderSBF;
    }

    @RequiresApi(api = Build.VERSION_CODES.KITKAT)
    public void handleNfcIntent(@NonNull Intent intent) {
        Log.d(TAG, "handleNfcIntent: ");
        String action = intent.getAction();
        String str = TAG;
        StringBuilder stringBuilder = new StringBuilder();
        stringBuilder.append("Action detected: ");
        stringBuilder.append(action);
        Log.d(str, stringBuilder.toString());

            if (this.mNfcAdapter.isEnabled() && NfcAdapter.ACTION_TAG_DISCOVERED.equals(action)) {

                handleNfcTag((Tag) intent.getParcelableExtra(NfcAdapter.EXTRA_TAG),intent.getByteArrayExtra("android.nfc.extra.ID"));

            }

    }

    @RequiresApi(api = Build.VERSION_CODES.KITKAT)
    public void handleNfcTag(@NonNull Tag tagx, byte[] bytes) {

        Log.d(TAG, "handleNfcTag: " + tagx.toString());

            StringBuilder stringBuilder;
        Log.d(TAG, "isodep1");
            IsoDep tagIsoDep = null;
        Log.d(TAG, "isodep2");
            try {
                Log.d(TAG, "isodep");
                tagIsoDep = IsoDep.get(tagx);
                // Wallet patch: a non-IsoDep tag used to throw a
                // NullPointerException here and fail silently.
                if (tagIsoDep == null) {
                    if (this.mNfcCardReaderListenerSBF != null) {
                        this.mNfcCardReaderListenerSBF.onError("Kartu Tidak Dikenal");
                    }
                    return;
                }
                if (tagIsoDep != null) {
                    Log.d(TAG, "masuk iso dep");
                    tagIsoDep.setTimeout(5000);
                    tagIsoDep.connect();
                    if (VERSION.SDK_INT >= 26) {
                        ((Vibrator) this.mContext.getSystemService(Context.VIBRATOR_SERVICE)).vibrate(VibrationEffect.createOneShot(150, 10));
                    } else {
                        ((Vibrator) this.mContext.getSystemService(Context.VIBRATOR_SERVICE)).vibrate(150);
                    }
                    Log.d(TAG, "masuk iso dep2");
                    int q = 8;
                    int j = 0;
                    if (UtilNfcSBF.validApduResponse(tagIsoDep.transceive(this.commandAPDUSelectDF_EMoney))) {
                        byte[] transceive = tagIsoDep.transceive(this.commandAPDUforNumber);
                        Log.d(TAG, "handleNfcTag: " + new String(transceive, "UTF-8"));
                        if (UtilNfcSBF.validApduResponse(transceive)) {
                            String hexString = UtilNfcSBF.getHexString(transceive, 8);
                            byte[] transceive2 = tagIsoDep.transceive(this.commandAPDUforBalance);
                            Log.d(TAG, "handleNfcTag: " + new String(transceive2, "UTF-8"));
                            if (transceive2.length < 4) {

                                if (this.mNfcCardReaderListenerSBF != null) {
                                    this.mNfcCardReaderListenerSBF.onError("Not E-Money valid balance");
                                }

                                if (tagIsoDep.isConnected()) {
                                    tagIsoDep.close();
                                }

                            }
                            long l1 = 0L;
                            for (int ix = j; ix < 4; ix = j) {
                                long l2 = transceive2[ix];
                                j = ix + 1;
                                l1 += ((l2 & 0xFF) << ix * 8);
                            }
                            if (this.mNfcCardReaderListenerSBF != null) {
                                this.mNfcCardReaderListenerSBF.onEMoneyCardFound(hexString, l1,getString(tagIsoDep.getTag().getId()));
                            }
                        } else {

                            if (this.mNfcCardReaderListenerSBF != null) {
                                this.mNfcCardReaderListenerSBF.onError("Not E-Money valid card number");

                            }
                            if (tagIsoDep.isConnected()) {
                                tagIsoDep.close();
                            }

                        }
                    } else if (UtilNfcSBF.validApduResponse(tagIsoDep.transceive(this.commandAPDUforSelectDF_EKTP))) {

                        if (UtilNfcSBF.validApduResponse(tagIsoDep.transceive(this.commandAPDUforSelectEF_Photo))) {

                            byte[] transceive3 = tagIsoDep.transceive(UtilNfcSBF.mergeArray(this.commandAPDUforRetrieveData, UtilNfcSBF.m16a("000008")));
                            if (UtilNfcSBF.validApduResponse(transceive3)) {

                                int k = transceive3[0] << 8 & 0xFF00 | transceive3[1] & 0xFF;
                                byte[] obj = new byte[k];
                                System.arraycopy(transceive3, 2, obj, 0, transceive3.length - 4);

                                while (q < k) {
                                    int j4 = 112 + q;

                                    if (j4 > k) {
                                        byte[] transceive4 = tagIsoDep.transceive(UtilNfcSBF.mergeArray(this.commandAPDUforRetrieveData, UtilNfcSBF.m16a(String.format("%04X%02X", q, (k - q) + 2))));
                                        if (UtilNfcSBF.validApduResponse(transceive4)) {
                                            System.arraycopy(transceive4, 0, obj, q - 2, transceive4.length - 2);
                                        } else {

                                            if (this.mNfcCardReaderListenerSBF != null) {

                                                this.mNfcCardReaderListenerSBF.onError("Error APDU:");

                                            }
                                            if (tagIsoDep.isConnected()) {
                                                tagIsoDep.close();
                                            }

                                        }
                                    } else {
                                        byte[] transceive4 = tagIsoDep.transceive(UtilNfcSBF.mergeArray(this.commandAPDUforRetrieveData, UtilNfcSBF.m16a(String.format("%04X%02X", q, 112))));
                                        if (UtilNfcSBF.validApduResponse(transceive4)) {
                                            System.arraycopy(transceive4, 0, obj, q - 2, transceive4.length - 2);
                                        } else {

                                            if (this.mNfcCardReaderListenerSBF != null) {

                                                this.mNfcCardReaderListenerSBF.onError("Error APDU:");

                                            }
                                            if (tagIsoDep.isConnected()) {
                                                tagIsoDep.close();
                                            }

                                        }
                                    }
                                    q = j4;

                                }
                                Bitmap decodeByteArray = BitmapFactory.decodeByteArray(obj, 0, obj.length);

                                if (this.mNfcCardReaderListenerSBF != null) {

                                    this.mNfcCardReaderListenerSBF.onEKTPCardFound(decodeByteArray,getString(tagIsoDep.getTag().getId()));
                                }
                            } else {
                                if (this.mNfcCardReaderListenerSBF != null) {
                                    this.mNfcCardReaderListenerSBF.onError("E-KTP failed to retrieve photo data");
                                }
                                if (tagIsoDep.isConnected()) {
                                    tagIsoDep.close();
                                }

                            }
                        } else {

                            if (this.mNfcCardReaderListenerSBF != null) {
                                this.mNfcCardReaderListenerSBF.onError("E-KTP failed select photo");
                            }

                            if (tagIsoDep.isConnected()) {
                                tagIsoDep.close();
                            }
                        }
                    } else if (UtilNfcSBF.validApduResponse(tagIsoDep.transceive(this.commandAPDUSelectDF_Flazz))) {

                        File file = new File(this.mContext.getCacheDir(), "s.dex");
                        if (file.exists()) {
                            file.delete();
                        }
                        String base64String = "ZGV4CjAzNQATroNY1+KRVxav7jBEJSmoDiIxf5Zs9mmOVlpaKlpaWiIMbkhaWlpaWlpaWhpWWlpiWlpaKlpaWkhaWloKW1paSFpaWsJbWlpTWlpaKlhaWn5aWlriWFpaW1paWoJZWlqGUlpaollaWkBQWlpwUFpaFlBaWgJQWlo+UFpaKlBaWiZQWlrSUFpazlBaWsBQWlr0UFpa7lBaWuZQWlrlUFpamVBaWpxQWlqTUFpalFBaWohQWlqNUFpahFBaWr9QWlq2UFpaqVBaWqBQWlpbUVpaUlFaWkdRWlprUVpaH1FaWjpRWlotUVpaylFaWvhRWlr/UVpa81FaWvdRWlrrUVpa71FaWuJRWlrmUVpa5VFaWp5RWlqWUVpalVFaWodRWlq6UVpauVFaWrxRWlqqUVpaqVFaWqxRWlqjUVpaplFaWlhWWlpXVlpaVlpaWlRaWlpJWlpaTlpaWk9aWlpMWlpaTVpaWkJaWlpDWlpaQFpaWkFaWlpGWlpaR1paWkRaWlpFWlpaelpaWntaWlp8WlpaV1paWlpaWlqOU1paS1paWlhaWlqGU1paSFpaWlhaWlq+U1paSFpaWl5aWlq+U1paS1paWl9aWlqOU1paVVpaWlFaWlpaWlpaSlpaWlFaWlq2U1paS1paWlFaWlqOU1paS1paWlZaWlqOU1pae1paWkpaWlpaWlpaeFpaWkpaWlquU1paeVpaWkpaWlqmU1paflpaWkpaWlqOU1paflpaWkpaWlpeUFpaf1paWkpaWlpWUFpafFpaWktaWlpaWlpafVpaWktaWlpOUFpafVpaWktaWlqOU1paUlpRWnJaWlpSWlFacVpaWlJaUVp3WlpaUlpRWnRaWlpSWlFadVpaWlJaUVprWlpaUlpRWmhaWlpSWlFaaVpaWlJaUVpuWlpaWFpTWlFaWlpYWlFaclpaWlhaVlpyWlpaWFpUWnFaWlpZWlNaUVpaWllaVlpyWlpaWVpWWnFaWlpZWlZad1paWllaVlp0WlpaWVpWWnVaWlpZWlZaa1paWllaVlpoWlpaWVpWWmlaWlpeWlNaUVpaWl5aV1pyWlpaXlpXWnFaWlpeWlRad1paWl9aVVpyWlpaX1pfWnFaWlpcWl5aclpaWl1aXVpyWlpaXVpaWnFaWlpSWlNaUVpaWlJaWFpyWlpaUlpZWnFaWlpSWltad1paWlNaVVp2WlpaUFpTWlFaWlpRWktaalpaWlFaXFpsWlpaVlpTWlFaWlpWWlJacFpaWlZaX1ptWlpaV1pQWlFaWlpUWldab1paWlVaSlpzWlpaUlpaWltaWlpQWlpaWlpaWqWlpaVaWlpaTVZaWlpaWlpYWltaW1paWlpaWlpyWlpaKkpBWltaQFpbWgFKWlpAWlpaAUpbWkBaWFoBSlhaQFpdWgFKWVpAWlNaAUpeWkBaWVoBSl9aQFpeWgFKXFpAWl9aAUpdWkBaXFoBSlJaVFpdWllaWVpaWlpaWlrqWlpaeFpYWipKWlpaWjRKQFpcWlBbYltBWkBbW1ooeklaT1pWWzRKS1pbWlBYYlhUWjRKSFpbWlZbQFhQWjR6Rlp7WlBbY1tZWktaQFtaWih6SVpPWlZbNEpLWltaUFhiWK+lNEpIWltaVltAWFBaNHpGWntaUFtiW7OlQFtYWih6SVpPWlZbNEpLWltaUFhiWIelNEpIWltaVlhAWVBaNHpGWmhaUFhiWIulNEpIWltaVltJWIpaSVmqWjRqR1p7WVZbK0pOWltaVls0elhaSlpAW11aKHpJWk9aVls0SktaW1pQWGJY6KU0SkhaW1pWW0BYUFo0ekZae1pQW2Jb/KVAW1NaKHpJWk9aVls0SktaW1pQWGJYwKU0SkhaW1pWWEBZUFo0ekZaaFpQWGJY1KU0SkhaW1pWW0h4SVlSWjRqR1p7WVZbK0pPWltaUFvbSDRqW1p6WUhLNHpZWkpac1ovpVVaWVpZWlpaWlpaWpdbWlpJXLpbSVGqWklQUFpIc0hbeFpeWipKV1paWnhYVloqSkRaWFo0SkBaVFpQWWJZQVpAWVtaKHpJWmdaVlk0SktaWVpQXmJeVFo0SkhaWVpWWUBeUFo0ekZaGVpQWWNZWVpLWkBZWlooeklaZ1pWWTRKS1pZWlBeYl6vpTRKSFpZWlZeQF9QWjR6RloOWlBeY15UWjRKSFpZWlZZQF5SWjR6RloZWlBZYlmHpUBZWVooeklaZ1pWWTRKS1pZWlBeYl6LpTRKSFpZWlZeQF9QWjR6RloOWlBeYl6fpTRKSFpZWlZZNGpHWklcVlk0ekVaaFpAWV5aKHpJWmdaVlk0SktaWVpQXmJe9KU0SkhaWVpWXkBfUFo0ekZaDlpQXmJe+KU0SkhaWVpWWTRqR1pJXFZZNHpFWmhaQFlfWih6SVpnWlZZNEpLWllaUF5iXtGlNEpIWllaVl5AX1BaNHpGWg5aUF5iXiWlNEpIWllaVlk0akdaSVFWWTR6RVpoWnhZV1oqenta+Vo0SnpaWFpWXltIb/g9WnhfWVoqSl5aX1qAXFgigl1cWoJSXFg0akdaLlJWXTR6XFovWoJdXFiCUlxeNGpHWi5SVl00el1aL1qCXVxeglJcUDRqR1ouUlZdNHpSWi9agl1cVoJSXEg0akdaLlJWXTR6U1ovWoJdXHKCUlx0NGpHWi5SVl00el9aL1qCXVxqglJcZjRqR1ouUlZdNHpQWi9agl1cZoJSXBY0akdaLlJWXTR6UVovWoJdXBaCXFwONGpHWi5cVlw0elZaP1ooenlaCVqCWFhbcsArSnhaWVo0elRaalpAWFxaKHpJWndaVlg0SktaWFpQWWJZq6Q0SkhaWFpWWUBeUFo0ekZaGVpQWWJZv6Q0SkhaWFpWWDRqR1pIUVZYeFlXWip6e1rJWm/LPVp4XllaKkpeWl5agF9bIoJcX1qCXV9YNGpHWjhdVlw0elxaPlqCXF9Ygl1fXjRqR1o4XVZcNHpdWj5aglxfXoJdX1A0akdaOF1WXDR6Ulo+WoJcX1aCXV9INGpHWjhdVlw0elNaPlqCXF9ygl1fdDRqR1o4XVZcNHpfWj5aglxfaoJdX2Y0akdaOF1WXDR6UFo+WoJcX2aCXV8WNGpHWjhdVlw0elFaPlqCXF8Wgl9fDjRqR1o4X1ZfNHpWWg5aKHp5WhlagltbW3LAK0p4WllaNHpVWmpaSEs0ekpaSlpzWj+kWlpfWlhaWFpaWlpaWlp9WlpaeFpYWipKWlpaWkhbNHpZWkpaQFtbWih6SVpOWlZbNEpLWltaUFhiWFRaNEpIWltaVltAWFBaNHpGWntaUFtjW1laS1pISzR6WVpKWnKhWlpbWlpaUVpaWltaWlpcWlpaWFpaWlxaU1pYWlpaWlpaWltaWlpaWlpaW1paWltaWlpbWlpaVVpaWltaWlpLWlpaW1paWlBaVGpqG25qa2pqamhqaGpqWnpqahtuam5qamoYG2pqampqamprYmocampqamprYmpqa1pQamoYamJrampiH1pQamoYamJuamocalpQamoYamJuaRkcalpQamoYamJubWJtYlpQamoYamJvamptYlpQamoYamJtampubFpebGNia1pIYmppaGpqamlqbmpqampqampqWl5jampqWlxmMzQzLmRaWxNaWBMWWlsQWlsWWlkWExNaWBYWWlkWFhZaXxY7dTthWl8WO3U4YVpfFjt1OWFaXxY7dT5hWl8WO3U/YVpfFjt1PWFaXxY7dSlhWkkWMDssO3U2OzQ9dRg1NTY/OzRhWkgWMDssO3U2OzQ9dRU4MD85LmFaSBYwOyw7dTY7ND11CS4oMzQ9YVpDFjA7LDt1Njs0PXUJLigzND0YLzM2Pj8oYVpPFjA7LDt1Ly4zNnUbKCg7IxYzKS5hWk0WMDssO3UvLjM2dRk1NjY/OS4zNTQpYVpKFjA7LDt1Ly4zNnUWMykuYVpbDFpYDBNaWAwQWlgMFlpYDABaWwBaWAAWWls7Wlk7Pj5aXDsqKj80PlpbOFpWODU1Nj87NAw7Ni8/Wls5Wls+Wls/WlI/ND4pDTMuMlpbPFpbPVpbMlpbM1peKTUoLlpTKS84KS4oMzQ9WlIuNQkuKDM0PVpaU1tZWkpbSltKW0pbSltKW0pbSltKTNvaXqJdTVuCUltbklFbW65IWlZaWlpaWlpaW1paWlpaWlpbWlpaYlpaWipaWlpYWlpaSFpaWgpbWlpZWlpaSFpaWsJbWlpeWlpaU1paWipYWlpfWlpaflpaWuJYWlpcWlpaW1paWoJZWlpbelpaXlpaWqJZWlpbSlpaU1paWo5TWlpYelpaYlpaWkBQWlpaelpaW1paWk1WWlpaSlpaW1paWhpWWlo=";
                        byte[] decodedBytes = Base64.decode(base64String, Base64.DEFAULT);
                        InputStream open = new ByteArrayInputStream(decodedBytes);
                        OutputStream bufferedOutputStream = new BufferedOutputStream(new FileOutputStream(file));
                        byte[] bArr = new byte[8192];
                        bArr = i.a(i.a(open));
                        bufferedOutputStream.write(bArr, 0, bArr.length);
                        bufferedOutputStream.close();
                        open.close();

                        this.mContext.getApplicationContext();
                        File dir = this.mContext.getDir("outdex", 0);
                        StringBuilder stringBuilder2 = new StringBuilder();
                        stringBuilder2.append(dir.getCanonicalPath());
                        stringBuilder2.append("/s.dex");
                        File file2 = new File(stringBuilder2.toString());
                        if (file2.exists()) {
                            file2.delete();
                        }
                        a a = new h().a(new SClassLoader(new DexClassLoader(file.getAbsolutePath(), dir.getAbsolutePath(), null, this.mContext.getClassLoader())), new FlazzCardReader(tagIsoDep), true);
                        if (a.a()) {
                            if (this.mNfcCardReaderListenerSBF != null) {

                                this.mNfcCardReaderListenerSBF.onFlazzCardFound(a.b(), a.c(),"");
                            }

                        } else {

                            if (this.mNfcCardReaderListenerSBF != null) {
                                this.mNfcCardReaderListenerSBF.onError("Error read card");
                            }

                            if (tagIsoDep.isConnected()) {
                                tagIsoDep.close();
                            }

                        }

                    } else if (UtilNfcSBF.validApduResponse(tagIsoDep.transceive(this.commandAPDUSelectDF_Brizzi))) {
                        Brizzi brizzi = new Brizzi(tagIsoDep);
                        Log.d(TAG, "handleNfcTag: " + brizzi.readCard());
                        if (brizzi.readCard()) {
                            brizzi.Brizzibooleanb();
                        }
                        Log.d(TAG, "handleNfcTag mNfcCardReaderListenerSBF: " + this.mNfcCardReaderListenerSBF + "" + brizzi.getCardNumber() + " " + brizzi.getBalance() + " " + brizzi.Brizzistringd() + " " + brizzi.Brizzistringe() + " " + brizzi.Brizzistringf());
                        if (this.mNfcCardReaderListenerSBF != null) {
                            this.mNfcCardReaderListenerSBF.onBrizziCardFound(brizzi.getCardNumber(), brizzi.getBalance(), brizzi.getTagId());
                        }
                    } else if (UtilNfcSBF.validApduResponse(tagIsoDep.transceive(this.commandAPDUSelectDF_TapCash))) {

                        TapCash tapCash = new TapCash(tagIsoDep);

                        if (tapCash.readCard()) {
                            Log.d(TAG, "handleNfcTag BNI: " + tapCash.getCardNumber());
                            if (this.mNfcCardReaderListenerSBF != null) {
                                this.mNfcCardReaderListenerSBF.onTapCashCardFound(tapCash.getCardNumber(), tapCash.getBalance(),getString(tagIsoDep.getTag().getId()));

                            }
                        }

                    } else if (this.mNfcCardReaderListenerSBF != null) {
                        this.mNfcCardReaderListenerSBF.onError("Kartu Tidak Dikenal");
                    }
                    if (tagIsoDep.isConnected()) {
                        tagIsoDep.close();
                    }
                }
            } catch (IOException e) {
                Log.d(TAG, "masuk eror");
                e.printStackTrace();
                // Wallet patch: report it (usually the card moved away).
                if (this.mNfcCardReaderListenerSBF != null) {
                    this.mNfcCardReaderListenerSBF.onError("Kartu terlepas sebelum selesai dibaca");
                }
                if (tagIsoDep.isConnected()) {
                    try {
                        tagIsoDep.close();
                    } catch (IOException e1) {
                        e1.printStackTrace();
                    }
                }

            } catch (Exception e2) {
                Log.d(TAG, "masuk eror 2" + e2.toString());
                if (this.mNfcCardReaderListenerSBF != null) {
                    this.mNfcCardReaderListenerSBF.onError("Gagal membaca kartu: " + e2);
                }
                stringBuilder = new StringBuilder();
                if (tagIsoDep.isConnected()) {
                    try {
                        tagIsoDep.close();
                    } catch (IOException e) {

                        stringBuilder.append("E-KTP Error decode photo");
                        stringBuilder.append(e.getMessage());

                    }
                }

            } catch (IOError tag2) {
                Log.d(TAG, "masuk eror 3");
                if (this.mNfcCardReaderListenerSBF != null) {
                    this.mNfcCardReaderListenerSBF.onError(tag2.getMessage());
                }
            }

    }
    public String getString(@NonNull byte[] paramArrayOfByte)
    {
        String str = "";
        int k = 0;
        while (k < paramArrayOfByte.length)
        {
            Object localObject2 = Integer.toHexString(paramArrayOfByte[k] & 0xFF);
            Object localObject1 = localObject2;
            if (((String)localObject2).length() == 1)
            {
                localObject1 = new StringBuilder();
                ((StringBuilder)localObject1).append("0");
                ((StringBuilder)localObject1).append((String)localObject2);
                localObject1 = ((StringBuilder)localObject1).toString();
            }
            localObject2 = new StringBuilder();
            ((StringBuilder)localObject2).append(str);
            ((StringBuilder)localObject2).append((String)localObject1);
            str = ((StringBuilder)localObject2).toString();
            k += 1;
        }
        return str.toUpperCase();
    }

    @SuppressLint("StaticFieldLeak")
    private class AsyncUpdateBalanceBNI extends AsyncTask<Void, String, Uri> {

        final boolean z = PreferenceClass.getBoolean("update", false);
        @Nullable
        final String string = PreferenceClass.getString("host_address", "");

        Context context;
        Tag localTag;
        byte[]byteArrayExtra;

        public AsyncUpdateBalanceBNI(Context mContext,Tag tag,byte[] byteArrayExtrax){
            this.context=mContext;
            this.localTag = tag;
            this.byteArrayExtra =byteArrayExtrax;

        }
        private Exception f2296f;

        @Override
        protected void onPreExecute() {

        }

        @Nullable
        @Override
        protected Uri doInBackground(Void... voids) {

            return null;
        }

        @Override
        protected void onPostExecute(Uri result) {

            Log.i("post", "execute "+result);

        }
    }

}
