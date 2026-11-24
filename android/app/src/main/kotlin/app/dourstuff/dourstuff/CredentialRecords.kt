package app.dourstuff.dourstuff

import android.app.KeyguardManager
import android.content.Context
import android.os.Build
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

internal class CredentialRecords(context: Context) {
    private val keyguard = context.getSystemService(KeyguardManager::class.java)

    private fun requireUnlocked() {
        check(Build.VERSION.SDK_INT >= 28 && keyguard.isDeviceSecure && !keyguard.isDeviceLocked)
    }

    fun transform(seal: Boolean, context: ByteArray, data: ByteArray): ByteArray {
        requireUnlocked()
        require(context.isNotEmpty() && data.isNotEmpty())
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        val key = loadKey(create = seal)
        val result = if (seal) {
            cipher.init(Cipher.ENCRYPT_MODE, key)
            cipher.updateAAD(context)
            check(cipher.iv.size == IV_SIZE)
            cipher.iv + cipher.doFinal(data)
        } else {
            require(data.size > IV_SIZE + 16)
            cipher.init(Cipher.DECRYPT_MODE, key, GCMParameterSpec(128, data, 0, IV_SIZE))
            cipher.updateAAD(context)
            cipher.doFinal(data, IV_SIZE, data.size - IV_SIZE)
        }
        requireUnlocked()
        return result
    }

    companion object {
        private const val ALIAS = "app.dourstuff.credential-record.v1"
        private const val PROVIDER = "AndroidKeyStore"
        private const val IV_SIZE = 12

        // Flutter engines in this application's single Android process share
        // key creation. Open never provisions, replaces or deletes a lost key.
        @Synchronized
        private fun loadKey(create: Boolean): SecretKey {
            val store = KeyStore.getInstance(PROVIDER).apply { load(null) }
            if (store.containsAlias(ALIAS)) return store.getKey(ALIAS, null) as SecretKey
            check(create && Build.VERSION.SDK_INT >= 28)
            val spec = KeyGenParameterSpec.Builder(ALIAS,
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
                .setKeySize(256)
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setUnlockedDeviceRequired(true)
                .build()
            return KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, PROVIDER)
                .apply { init(spec) }.generateKey()
        }
    }
}
