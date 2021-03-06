package com.invertedx.sentinelx.api

import android.content.Context
import android.util.Log
import com.invertedx.sentinelx.BuildConfig
import com.invertedx.sentinelx.SentinelxApp
import com.invertedx.sentinelx.tor.TorManager
import com.invertedx.sentinelx.utils.LoggingInterceptor
import com.invertedx.sentinelx.utils.SentinalPrefs
import io.reactivex.Observable
import io.reactivex.Single
import okhttp3.*
import org.json.JSONObject
import java.io.IOException
import java.util.concurrent.TimeUnit
import javax.net.ssl.HostnameVerifier
import javax.net.ssl.SSLContext
import javax.net.ssl.TrustManager
import javax.net.ssl.X509TrustManager


class ApiService(private val applicationContext: Context) {

    val SAMOURAI_API = "https://api.samouraiwallet.com/v2/"
    val SAMOURAI_API_TESTNET = "https://api.samouraiwallet.com/test/v2/"

    val SAMOURAI_API2_TOR_DIST = "http://d2oagweysnavqgcfsfawqwql2rwxend7xxpriq676lzsmtfwbt75qbqd.onion/v2/"
    val SAMOURAI_API2_TESTNET_TOR_DIST = "http://d2oagweysnavqgcfsfawqwql2rwxend7xxpriq676lzsmtfwbt75qbqd.onion/test/v2/"

    lateinit var client: OkHttpClient

    init {
        makeClient()
    }


    fun getTxAndXPUBData(XpubOrAddress: String): Observable<String> {
        val baseAddress = getBaseUrl()
        val url = if (SentinelxApp.accessToken.isNotEmpty()) "${baseAddress}multiaddr?active=$XpubOrAddress&at=${SentinelxApp.accessToken}" else "${baseAddress}multiaddr?active=$XpubOrAddress"

        Log.i("API", "CALL url -> $url")
        return Observable.fromCallable {
            val request = Request.Builder()
                    .url(url)
                    .build()
            val response = client.newCall(request).execute()
            try {
                val content = response.body!!.string()
                Log.i("API", "response -> $content")
                return@fromCallable content
            } catch (ex: Exception) {
                return@fromCallable "{}"
            }

        }
    }

    private fun getBaseUrl(): String {
        /**
         * rebuilds the client with current state (TOR state)
         * getBaseUrl methods used on all api calls, so rebuilding call for client seems to fit here
         */
        makeClient()

        if (SentinelxApp.dojoUrl.isNotBlank()) {
            return SentinelxApp.dojoUrl
        }

        return if (TorManager.getInstance(this.applicationContext)?.isConnected!!) {
            if (SentinelxApp.isTestNet()) SAMOURAI_API2_TESTNET_TOR_DIST else SAMOURAI_API2_TOR_DIST
        } else {
            if (SentinelxApp.isTestNet()) SAMOURAI_API_TESTNET else SAMOURAI_API
        }
    }

    fun getTx(txid: String): Observable<String> {
        val baseAddress = getBaseUrl()
        val baseUrl = if (SentinelxApp.accessToken.isNotEmpty()) "${baseAddress}tx/$txid/?fees=trues&at=${SentinelxApp.accessToken}" else "${baseAddress}tx/$txid/?fees=trues"

        return Observable.fromCallable {

            val request = Request.Builder()
                    .url(baseUrl)
                    .build()

            val response = client.newCall(request).execute()
            try {
                val content = response.body!!.string()
                Log.i("API", "response -> $content")
                return@fromCallable content
            } catch (ex: Exception) {
                throw  ex
            }

        }
    }


    fun authenticate(url: String, key: String): Observable<String> {
        val targetUrl = "$url/auth/login?apikey=$key"
        return Observable.fromCallable {

            val request = Request.Builder()
                    .url(targetUrl)
                    .post(RequestBody.create(null, ByteArray(0)))
                    .build()

            val response = client.newCall(request).execute()
            try {
                return@fromCallable response.body!!.string()
            } catch (ex: Exception) {
                throw  ex
            }

        }
    }


    fun getUnspent(xpubOrAddress: String): Observable<String> {
        makeClient()

        val baseAddress = getBaseUrl()
        val baseUrl = if (SentinelxApp.accessToken.isNotEmpty()) "${baseAddress}unspent?active=$xpubOrAddress&at=${SentinelxApp.accessToken}" else "${baseAddress}unspent?active=$xpubOrAddress";

        return Observable.fromCallable {

            val request = Request.Builder()
                    .url(baseUrl)
                    .build()

            val response = client.newCall(request).execute()
            try {
                val content = response.body!!.string()
                return@fromCallable content
            } catch (ex: Exception) {
                throw  ex;
            }

        }
    }


    fun pushTx(hex: String): Observable<String> {
        makeClient()

        val baseAddress = getBaseUrl()
        val baseUrl = if (SentinelxApp.accessToken.isNotEmpty()) "${baseAddress}pushtx/?at=${SentinelxApp.accessToken}" else "${baseAddress}pushtx";

        return Observable.fromCallable {

            val request = Request.Builder()
                    .url(baseUrl)
                    .method("POST",FormBody.Builder()
                            .add("tx",hex)
                            .build())
                    .build()

            val response = client.newCall(request).execute()
            try {
                val content = response.body!!.string()
                return@fromCallable content
            } catch (ex: Exception) {
                throw  ex;
            }

        }
    }


    fun addHDAccount(xpub: String, bip: String): Observable<String> {

        makeClient()

        val baseAddress = getBaseUrl()
        val baseUrl = if (SentinelxApp.accessToken.isNotEmpty()) "${baseAddress}xpub?at=${SentinelxApp.accessToken.trim()}" else "${baseAddress}xpub";

        val requestBody = FormBody.Builder()
                .add("xpub", xpub)
                .add("type", "restore")
                .add("segwit", bip)
                .build()

        Log.i("url", baseUrl.toString())
        Log.i("requestBody", requestBody.toString())
        return Observable.fromCallable {

            val request = Request.Builder()
                    .url(baseUrl)
                    .method("POST", requestBody)
                    .build()

            client.connectTimeoutMillis
            val response = client.newCall(request).execute()
            val content = response.body!!.string()
            Log.i("API", "response -> $content")
            return@fromCallable content

        }
    }


    fun makeClient() {
        val builder = OkHttpClient.Builder()
        if (BuildConfig.DEBUG) {
            builder.addInterceptor(LoggingInterceptor())
        }
        if ((TorManager.getInstance(this.applicationContext)?.isConnected!!)) {
            getHostNameVerifier(builder)
            builder.proxy(TorManager.getInstance(this.applicationContext)?.getProxy())
        }
        builder.addInterceptor(LogEntry(this))
        val prefs = SentinalPrefs(applicationContext)

        var timeout = 90L;
        if (prefs.timeout != null) {
            timeout = prefs.timeout!!.toLong();
        }
        builder.connectTimeout(timeout, TimeUnit.SECONDS) // connect timeout
        builder.readTimeout(timeout, TimeUnit.SECONDS)
        client = builder.build()
    }


    @Throws(Exception::class)
    private fun getHostNameVerifier(clientBuilder: OkHttpClient.Builder) {

        // Create a trust manager that does not validate certificate chains
        val trustAllCerts = arrayOf<TrustManager>(object : X509TrustManager {
            override fun checkClientTrusted(chain: Array<java.security.cert.X509Certificate>, authType: String) {}

            override fun checkServerTrusted(chain: Array<java.security.cert.X509Certificate>, authType: String) {}

            override fun getAcceptedIssuers(): Array<java.security.cert.X509Certificate> {
                return arrayOf()
            }
        })

        // Install the all-trusting trust manager
        val sslContext = SSLContext.getInstance("SSL")
        sslContext.init(null, trustAllCerts, java.security.SecureRandom())

        // Create an ssl socket factory with our all-trusting manager
        val sslSocketFactory = sslContext.socketFactory


        clientBuilder.sslSocketFactory(sslSocketFactory, trustAllCerts[0] as X509TrustManager)
        clientBuilder.hostnameVerifier(HostnameVerifier { _, _ -> true })

    }

    //Generic post request handler
    fun postRequest(url: String, requestBody: RequestBody): Single<String> {
        return Single.fromCallable {
            val request = Request.Builder()
                    .url(url)
                    .method("POST", requestBody)
                    .build()
            val response = client.newCall(request).execute()

            try {
                val content = response.body!!.string()
                return@fromCallable content
            } catch (ex: Exception) {
                throw  ex
            }
        }

    }

    //Generic get request handler
    fun getRequest(url: String): Single<String> {
        return Single.fromCallable {
            val request = Request.Builder()
                    .url(url)
                    .build()
            val response = client.newCall(request).execute()

            try {
                val content = response.body!!.string()
                return@fromCallable content
            } catch (ex: Exception) {
                throw  ex
            }
        }

    }


    internal class LogEntry(val apiService: ApiService) : Interceptor {

        @Throws(IOException::class)
        override fun intercept(chain: Interceptor.Chain): Response {
            val obj = JSONObject();
            val request = chain.request()
            val t1 = System.nanoTime()
            obj.put("url", request.url.toString());
            obj.put("method", request.method);
            obj.put("init_time", System.currentTimeMillis());
            val response = chain.proceed(request)
            val t2 = System.nanoTime()
            obj.put("time", (t2 - t1) / 1e6);
            obj.put("status", response.code);
            obj.put("network", "");
            if (SentinelxApp.dojoUrl.isNotBlank()) {
                Log.i("UR", request.url.toUri().host)
                Log.i("URS", SentinelxApp.dojoUrl)
                if (SentinelxApp.dojoUrl.contains(request.url.toUri().host) ) {
                    obj.put("network", "DOJO");
                }
            }

            SentinelxApp.netWorkLog.put(obj);
            return response
        }
    }


}

