package com.abhishek.chat_app_backend_media.service

import com.abhishek.chat_app_backend_media.dto.*
import io.minio.GetPresignedObjectUrlArgs
import io.minio.MinioClient
import io.minio.RemoveObjectArgs
import io.minio.StatObjectArgs
import io.minio.http.Method
import org.slf4j.LoggerFactory
import org.springframework.beans.factory.annotation.Value
import org.springframework.stereotype.Service
import java.util.concurrent.TimeUnit
import kotlin.math.abs

@Service
class MediaService(
    private val minioClient: MinioClient
) {

    private val logger = LoggerFactory.getLogger(MediaService::class.java)

    @Value("\${minio.bucket}")
    private lateinit var bucket: String

    @Value("\${minio.presigned-upload-expiry-seconds}")
    private var uploadExpirySeconds: Int = 600

    @Value("\${minio.presigned-download-expiry-seconds}")
    private var downloadExpirySeconds: Int = 1800

    // Ensure this is set to "http://localhost/minio" in your docker-compose/env
    // AND we need the internal endpoint to replace it
    @Value("\${minio.public-url}")
    private lateinit var publicUrl: String

    // We need the internal endpoint to know what string to replace
    @Value("\${minio.endpoint}")
    private lateinit var internalEndpoint: String

    @Value("\${media.max-file-size}")
    private var maxFileSize: Long = 10485760

    @Value("\${media.allowed-mime-types}")
    private lateinit var allowedMimeTypes: String
    private val allowedMimeTypeSet: Set<String> by lazy {
        allowedMimeTypes.split(",")
            .map { it.trim().lowercase() }
            .filter { it.isNotEmpty() }
            .toSet()
    }

    fun generateUploadUrl(request: UploadUrlRequest): UploadUrlResponse {
        logger.info("Generating upload URL for object key ${request.objectKey}")

        validateUploadRequest(request)

        // 1. Generate URL (returns http://minio:9000/bucket/key...)
        val internalUploadUrl = minioClient.getPresignedObjectUrl(
            GetPresignedObjectUrlArgs.builder()
                .method(Method.PUT)
                .bucket(bucket)
                .`object`(request.objectKey)
                .expiry(uploadExpirySeconds, TimeUnit.SECONDS)
                .build()
        )

        // 2. Swap Internal Host with Public Proxy Host
        // "http://minio:9000/..." -> "http://localhost/minio/..."
        val publicUploadUrl = internalUploadUrl.replace(internalEndpoint, publicUrl)

        return UploadUrlResponse(
            uploadUrl = publicUploadUrl, // Send the browser-accessible URL
            objectKey = request.objectKey,
            publicUrl = buildPublicUrl(request.objectKey), // This is just the static GET url
            expiresIn = uploadExpirySeconds
        )
    }

    fun verifyUpload(request: VerifyUploadRequest): VerifyUploadResponse {
        logger.info("Verifying upload for object key ${request.objectKey}")

        return try {
            val stat = minioClient.statObject(
                StatObjectArgs.builder()
                    .bucket(bucket)
                    .`object`(request.objectKey)
                    .build()
            )

            val actualSize = stat.size()
            if (abs(actualSize - request.expectedSize) > 1024) {
                logger.warn(
                    "Size mismatch for ${request.objectKey}: expected=${request.expectedSize}, actual=$actualSize"
                )
            }

            VerifyUploadResponse(
                verified = true,
                actualSize = actualSize,
                publicUrl = buildPublicUrl(request.objectKey)
            )
        } catch (ex: Exception) {
            logger.error("Failed to verify object in MinIO: ${ex.message}", ex)
            VerifyUploadResponse(
                verified = false,
                actualSize = 0,
                publicUrl = ""
            )
        }
    }

    fun generateDownloadUrl(objectKey: String): DownloadUrlResponse {
        logger.info("Generating download URL for object key $objectKey")

        // 1. Generate URL
        val internalDownloadUrl = minioClient.getPresignedObjectUrl(
            GetPresignedObjectUrlArgs.builder()
                .method(Method.GET)
                .bucket(bucket)
                .`object`(objectKey)
                .expiry(downloadExpirySeconds, TimeUnit.SECONDS)
                .build()
        )

        // 2. Swap Internal Host with Public Proxy Host
        val publicDownloadUrl = internalDownloadUrl.replace(internalEndpoint, publicUrl)

        return DownloadUrlResponse(
            downloadUrl = publicDownloadUrl,
            expiresIn = downloadExpirySeconds
        )
    }

    fun deleteMedia(objectKey: String) {
        logger.info("Deleting media with object key $objectKey")

        try {
            minioClient.removeObject(
                RemoveObjectArgs.builder()
                    .bucket(bucket)
                    .`object`(objectKey)
                    .build()
            )
        } catch (ex: Exception) {
            logger.error("Failed to delete object from MinIO: ${ex.message}", ex)
            throw IllegalStateException("Failed to delete media: ${ex.message}")
        }
    }

    private fun validateUploadRequest(request: UploadUrlRequest) {
        val normalizedMime = request.mimeType.lowercase()

        if (allowedMimeTypeSet.isNotEmpty() && normalizedMime !in allowedMimeTypeSet) {
            throw IllegalArgumentException(
                "MIME type ${request.mimeType} is not allowed. Allowed types: $allowedMimeTypes"
            )
        }

        if (maxFileSize > 0 && request.sizeBytes > maxFileSize) {
            throw IllegalArgumentException(
                "File size ${request.sizeBytes} exceeds maximum allowed size $maxFileSize"
            )
        }
    }

    private fun buildPublicUrl(objectKey: String): String {
        // CAREFUL: Your NGINX rewrites /minio/bucket/key -> /bucket/key
        // So if publicUrl is "http://localhost/minio", this becomes "http://localhost/minio/bucket/key"
        // Which NGINX rewrites to http://minio:9000/bucket/key (Correct)
        return "$publicUrl/$bucket/$objectKey"
    }
}
