package com.abhishek.chat_app_backend_media.dto

import jakarta.validation.constraints.NotBlank
import jakarta.validation.constraints.NotNull
import jakarta.validation.constraints.Positive

// Request DTOs
data class UploadUrlRequest(
    @field:NotBlank(message = "Object key is required")
    val objectKey: String,
    
    @field:NotBlank(message = "MIME type is required")
    val mimeType: String,
    
    @field:NotNull(message = "File size is required")
    @field:Positive(message = "File size must be positive")
    val sizeBytes: Long,
    
    val fileName: String? = null,
    val width: Int? = null,
    val height: Int? = null
)

data class VerifyUploadRequest(
    @field:NotBlank(message = "Object key is required")
    val objectKey: String,
    
    @field:NotNull(message = "Expected size is required")
    @field:Positive(message = "Expected size must be positive")
    val expectedSize: Long
)

// Response DTOs
data class UploadUrlResponse(
    val uploadUrl: String,
    val objectKey: String,
    val publicUrl: String,
    val expiresIn: Int
)

data class DownloadUrlResponse(
    val downloadUrl: String,
    val expiresIn: Int
)

data class VerifyUploadResponse(
    val verified: Boolean,
    val actualSize: Long,
    val publicUrl: String
)

// API Response wrapper
data class ApiResponse<T>(
    val success: Boolean,
    val message: String,
    val data: T? = null
)
