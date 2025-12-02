package com.abhishek.chat_app_backend_media.controller

import com.abhishek.chat_app_backend_media.dto.*
import com.abhishek.chat_app_backend_media.service.MediaService
import jakarta.servlet.http.HttpServletRequest
import jakarta.validation.Valid
import org.slf4j.LoggerFactory
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*

@RestController
@RequestMapping("/internal/media")
class MediaController(
    private val mediaService: MediaService
) {
    
    private val logger = LoggerFactory.getLogger(MediaController::class.java)
    
    @PostMapping("/upload-url")
    fun generateUploadUrl(
        @Valid @RequestBody request: UploadUrlRequest,
        httpRequest: HttpServletRequest
    ): ResponseEntity<ApiResponse<UploadUrlResponse>> {
        return try {
            val response = mediaService.generateUploadUrl(request)
            ResponseEntity.ok(
                ApiResponse(
                    success = true,
                    message = "Upload URL generated successfully",
                    data = response
                )
            )
        } catch (e: IllegalArgumentException) {
            logger.error("Validation error: ${e.message}")
            ResponseEntity.badRequest().body(
                ApiResponse(
                    success = false,
                    message = e.message ?: "Invalid request",
                    data = null
                )
            )
        } catch (e: Exception) {
            logger.error("Failed to generate upload URL: ${e.message}", e)
            ResponseEntity.status(org.springframework.http.HttpStatus.INTERNAL_SERVER_ERROR).body(
                ApiResponse(
                    success = false,
                    message = "Failed to generate upload URL",
                    data = null
                )
            )
        }
    }
    
    @PostMapping("/verify")
    fun verifyUpload(
        @Valid @RequestBody request: VerifyUploadRequest,
        httpRequest: HttpServletRequest
    ): ResponseEntity<ApiResponse<VerifyUploadResponse>> {
        return try {
            val response = mediaService.verifyUpload(request)
            ResponseEntity.ok(
                ApiResponse(
                    success = true,
                    message = "Upload verified successfully",
                    data = response
                )
            )
        } catch (e: IllegalArgumentException) {
            logger.error("Validation error: ${e.message}")
            ResponseEntity.badRequest().body(
                ApiResponse(
                    success = false,
                    message = e.message ?: "Invalid request",
                    data = null
                )
            )
        } catch (e: Exception) {
            logger.error("Failed to verify upload: ${e.message}", e)
            ResponseEntity.status(org.springframework.http.HttpStatus.INTERNAL_SERVER_ERROR).body(
                ApiResponse(
                    success = false,
                    message = "Failed to verify upload",
                    data = null
                )
            )
        }
    }
    
    @GetMapping("/download-url")
    fun generateDownloadUrl(
        @RequestParam objectKey: String,
        httpRequest: HttpServletRequest
    ): ResponseEntity<ApiResponse<DownloadUrlResponse>> {
        return try {
            val response = mediaService.generateDownloadUrl(objectKey)
            ResponseEntity.ok(
                ApiResponse(
                    success = true,
                    message = "Download URL generated successfully",
                    data = response
                )
            )
        } catch (e: IllegalArgumentException) {
            logger.error("Validation error: ${e.message}")
            ResponseEntity.badRequest().body(
                ApiResponse(
                    success = false,
                    message = e.message ?: "Invalid request",
                    data = null
                )
            )
        } catch (e: Exception) {
            logger.error("Failed to generate download URL: ${e.message}", e)
            ResponseEntity.status(org.springframework.http.HttpStatus.INTERNAL_SERVER_ERROR).body(
                ApiResponse(
                    success = false,
                    message = "Failed to generate download URL",
                    data = null
                )
            )
        }
    }
    
    @DeleteMapping("")
    fun deleteMedia(
        @RequestParam objectKey: String,
        httpRequest: HttpServletRequest
    ): ResponseEntity<ApiResponse<Void>> {
        return try {
            mediaService.deleteMedia(objectKey)
            ResponseEntity.ok(
                ApiResponse(
                    success = true,
                    message = "Media deleted successfully",
                    data = null
                )
            )
        } catch (e: IllegalArgumentException) {
            logger.error("Validation error: ${e.message}")
            ResponseEntity.badRequest().body(
                ApiResponse(
                    success = false,
                    message = e.message ?: "Invalid request",
                    data = null
                )
            )
        } catch (e: Exception) {
            logger.error("Failed to delete media: ${e.message}", e)
            ResponseEntity.status(org.springframework.http.HttpStatus.INTERNAL_SERVER_ERROR).body(
                ApiResponse(
                    success = false,
                    message = "Failed to delete media",
                    data = null
                )
            )
        }
    }
}