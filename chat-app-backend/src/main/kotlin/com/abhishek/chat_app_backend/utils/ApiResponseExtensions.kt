package com.abhishek.chat_app_backend.utils

import com.abhishek.chat_app_backend.dto.ApiResponse
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity

fun <T> T.successResponse(
    message: String = "Success",
    status: HttpStatus = HttpStatus.OK
): ResponseEntity<ApiResponse<T>> {
    return  ResponseEntity.status(status).body(
        ApiResponse(
            success = true,
            message = message,
            data = this
        )
    )
}


fun <T> String.errorResponse(
    status: HttpStatus
): ResponseEntity<ApiResponse<T>> =
    ResponseEntity.status(status).body(
        ApiResponse<T>(
            success = false,
            message = this,
            data = null
        )
    )

