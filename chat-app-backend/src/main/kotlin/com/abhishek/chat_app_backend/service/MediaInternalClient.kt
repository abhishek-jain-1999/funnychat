package com.abhishek.chat_app_backend.service

import org.slf4j.LoggerFactory
import org.springframework.beans.factory.annotation.Value
import org.springframework.http.HttpEntity
import org.springframework.http.HttpHeaders
import org.springframework.http.HttpMethod
import org.springframework.http.MediaType
import org.springframework.core.ParameterizedTypeReference
import org.springframework.stereotype.Service
import org.springframework.web.client.RestTemplate

// DTOs for media service communication
data class InternalUploadUrlRequest(
    val objectKey: String,
    val mimeType: String,
    val sizeBytes: Long,
    val fileName: String? = null
)

data class InternalUploadUrlResponse(
    val uploadUrl: String,
    val objectKey: String,
    val publicUrl: String,
    val expiresIn: Int
)

data class InternalVerifyRequest(
    val objectKey: String,
    val expectedSize: Long
)

data class InternalVerifyResponse(
    val verified: Boolean,
    val actualSize: Long,
    val publicUrl: String
)

data class InternalApiResponse<T>(
    val success: Boolean,
    val message: String?,
    val data: T?
)

@Service
class MediaInternalClient(
    private val restTemplate: RestTemplate = RestTemplate()
) {
    
    private val logger = LoggerFactory.getLogger(MediaInternalClient::class.java)
    
    @Value("\${media.service.url:http://backend-media:8081}")
    private lateinit var mediaServiceUrl: String
    
    @Value("\${media.service.token:}")
    private lateinit var internalToken: String
    
    private fun createHeaders(): HttpHeaders {
        val headers = HttpHeaders()
        headers.contentType = MediaType.APPLICATION_JSON
        if (internalToken.isNotEmpty()) {
            headers.set("X-Internal-Token", internalToken)
        }
        return headers
    }
    
    /**
     * Request presigned upload URL from media service
     */
    fun getUploadUrl(
        objectKey: String,
        mimeType: String,
        sizeBytes: Long,
        fileName: String?
    ): InternalUploadUrlResponse {
        return try {
            logger.debug("Requesting upload URL for objectKey: $objectKey")
            
            val url = "$mediaServiceUrl/internal/media/upload-url"
            val request = InternalUploadUrlRequest(objectKey, mimeType, sizeBytes, fileName)
            val headers = createHeaders()
            val entity = HttpEntity(request, headers)
            
            val response = restTemplate.exchange(
                url,
                HttpMethod.POST,
                entity,
                object : ParameterizedTypeReference<InternalApiResponse<InternalUploadUrlResponse>>() {}
            ).body ?: throw IllegalStateException("Media service unavailable")
            
            if (response.success && response.data != null) {
                response.data
            } else {
                throw IllegalStateException("Media service failed: ${response.message}")
            }
        } catch (e: Exception) {
            logger.error("Failed to get upload URL from media service: ${e.message}", e)
            throw RuntimeException("Media service unavailable", e)
        }
    }
    
    /**
     * Verify uploaded object in MinIO
     */
    fun verifyUpload(objectKey: String, expectedSize: Long): InternalVerifyResponse {
        return try {
            logger.debug("Verifying upload for objectKey: $objectKey")
            
            val url = "$mediaServiceUrl/internal/media/verify"
            val request = InternalVerifyRequest(objectKey, expectedSize)
            val headers = createHeaders()
            val entity = HttpEntity(request, headers)
            
            val response = restTemplate.exchange(
                url,
                HttpMethod.POST,
                entity,
                object : ParameterizedTypeReference<InternalApiResponse<InternalVerifyResponse>>() {}
            ).body ?: throw IllegalStateException("Verification failed")
            
            if (response.success && response.data != null) {
                response.data
            } else {
                throw IllegalStateException("Verification failed: ${response.message}")
            }
        } catch (e: Exception) {
            logger.error("Failed to verify upload: ${e.message}", e)
            throw RuntimeException("Verification failed", e)
        }
    }
    
    /**
     * Get presigned download URL (for future private bucket support)
     */
    fun getDownloadUrl(objectKey: String): String {
        return try {
            logger.debug("Requesting download URL for objectKey: $objectKey")
            
            val url = "$mediaServiceUrl/internal/media/download-url?objectKey=$objectKey"
            val headers = createHeaders()
            val entity = HttpEntity<String>(headers)
            
            val response = restTemplate.exchange(
                url,
                HttpMethod.GET,
                entity,
                object : ParameterizedTypeReference<InternalApiResponse<Map<String, String>>>() {}
            ).body ?: throw IllegalStateException("Failed to get download URL")
            
            if (response.success && response.data != null) {
                response.data["downloadUrl"] ?: throw IllegalStateException("downloadUrl missing")
            } else {
                throw IllegalStateException("Failed to get download URL: ${response.message}")
            }
        } catch (e: Exception) {
            logger.error("Failed to get download URL: ${e.message}", e)
            throw RuntimeException("Failed to get download URL", e)
        }
    }
    
    /**
     * Delete object from MinIO
     */
    fun deleteObject(objectKey: String): Boolean {
        return try {
            logger.debug("Deleting objectKey: $objectKey")
            
            val url = "$mediaServiceUrl/internal/media/object?objectKey=$objectKey"
            val headers = createHeaders()
            val entity = HttpEntity<String>(headers)
            
            val response = restTemplate.exchange(
                url,
                HttpMethod.DELETE,
                entity,
                object : ParameterizedTypeReference<InternalApiResponse<Void>>() {}
            ).body ?: return false
            
            response.success
        } catch (e: Exception) {
            logger.error("Failed to delete object: ${e.message}", e)
            false
        }
    }
}
