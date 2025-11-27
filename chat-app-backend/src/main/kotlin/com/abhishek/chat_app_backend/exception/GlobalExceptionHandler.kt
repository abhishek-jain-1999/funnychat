package com.abhishek.chat_app_backend.exception

import com.abhishek.chat_app_backend.dto.ApiResponse
import org.slf4j.LoggerFactory
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.security.authentication.BadCredentialsException
import org.springframework.security.core.userdetails.UsernameNotFoundException
import org.springframework.validation.BindException
import org.springframework.web.bind.MethodArgumentNotValidException
import org.springframework.web.bind.annotation.ExceptionHandler
import org.springframework.web.bind.annotation.RestControllerAdvice

@RestControllerAdvice
class GlobalExceptionHandler {
    
    private val logger = LoggerFactory.getLogger(GlobalExceptionHandler::class.java)
    
    @ExceptionHandler(MethodArgumentNotValidException::class)
    fun handleValidationExceptions(
        ex: MethodArgumentNotValidException
    ): ResponseEntity<ApiResponse<Nothing>> {
        val errors = ex.bindingResult.fieldErrors
            .map { "${it.field}: ${it.defaultMessage}" }
            .joinToString(", ")
        
        logger.warn("Validation error: $errors")
        
        return ResponseEntity.badRequest().body(
            ApiResponse(
                success = false,
                message = "Validation failed: $errors"
            )
        )
    }
    
    @ExceptionHandler(BindException::class)
    fun handleBindException(ex: BindException): ResponseEntity<ApiResponse<Nothing>> {
        val errors = ex.fieldErrors
            .map { "${it.field}: ${it.defaultMessage}" }
            .joinToString(", ")
        
        logger.warn("Bind error: $errors")
        
        return ResponseEntity.badRequest().body(
            ApiResponse(
                success = false,
                message = "Invalid request: $errors"
            )
        )
    }

    @ExceptionHandler(ResourceNotFoundException::class)
    fun handleResourceNotFoundException(
        ex: ResourceNotFoundException
    ): ResponseEntity<ApiResponse<Nothing>> {
        logger.warn("Resource not found: ${ex.message}")

        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(
            ApiResponse(
                success = false,
                message = ex.message ?: "Resource not found"
            )
        )
    }
    
    @ExceptionHandler(IllegalArgumentException::class)
    fun handleIllegalArgumentException(
        ex: IllegalArgumentException
    ): ResponseEntity<ApiResponse<Nothing>> {
        logger.warn("Illegal argument: ${ex.message}")
        
        return ResponseEntity.badRequest().body(
            ApiResponse(
                success = false,
                message = ex.message ?: "Invalid request"
            )
        )
    }
    
    @ExceptionHandler(UsernameNotFoundException::class, BadCredentialsException::class)
    fun handleAuthenticationException(
        ex: Exception
    ): ResponseEntity<ApiResponse<Nothing>> {
        logger.warn("Authentication error: ${ex.message}")
        
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(
            ApiResponse(
                success = false,
                message = "Authentication failed"
            )
        )
    }

    @ExceptionHandler(org.springframework.security.access.AccessDeniedException::class)
    fun handleAccessDeniedException(
        ex: org.springframework.security.access.AccessDeniedException
    ): ResponseEntity<ApiResponse<Nothing>> {
        logger.warn("Access denied: ${ex.message}")

        return ResponseEntity.status(HttpStatus.FORBIDDEN).body(
            ApiResponse(
                success = false,
                message = "Access denied"
            )
        )
    }
    
    @ExceptionHandler(Exception::class)
    fun handleGenericException(ex: Exception): ResponseEntity<ApiResponse<Nothing>> {
        logger.error("Unexpected error: ${ex.message}", ex)
        
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(
            ApiResponse(
                success = false,
                message = "Internal server error"
            )
        )
    }
}
