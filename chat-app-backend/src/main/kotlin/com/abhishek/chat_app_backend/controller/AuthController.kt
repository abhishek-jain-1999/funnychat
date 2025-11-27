package com.abhishek.chat_app_backend.controller

import com.abhishek.chat_app_backend.config.CustomUserDetails
import com.abhishek.chat_app_backend.dto.*
import com.abhishek.chat_app_backend.service.UserService
import com.abhishek.chat_app_backend.utils.errorResponse
import com.abhishek.chat_app_backend.utils.successResponse
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.tags.Tag
import jakarta.validation.Valid
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.security.core.annotation.AuthenticationPrincipal
import org.springframework.security.core.userdetails.UserDetails
import org.springframework.web.bind.annotation.*

@RestController
@RequestMapping("/api/auth")
@Tag(name = "Authentication", description = "User authentication and registration")
class AuthController(
    private val userService: UserService
) {
    
    @PostMapping("/signup")
    @Operation(summary = "Register a new user")
    fun signup(@Valid @RequestBody request: SignupRequest): ResponseEntity<ApiResponse<AuthResponse>> = try {
        val authResponse = userService.signup(request)
        authResponse.successResponse(
            message = "User registered successfully"
        )
    } catch (e: IllegalArgumentException) {
        (e.message ?: "Registration failed").errorResponse(
            status = HttpStatus.BAD_REQUEST
        )
    }
    
    @PostMapping("/login")
    @Operation(summary = "Login user")
    fun login(@Valid @RequestBody request: LoginRequest): ResponseEntity<ApiResponse<AuthResponse>> = try {
        val authResponse = userService.login(request)
        authResponse.successResponse(
            message = "Login successful"
        )
    } catch (e: Exception) {
        "Invalid credentials".errorResponse(
            status = HttpStatus.UNAUTHORIZED
        )
    }
    
    @GetMapping("/me")
    @Operation(summary = "Get current user information")
    fun getCurrentUser(
        @AuthenticationPrincipal userDetails: CustomUserDetails
    ): ResponseEntity<ApiResponse<UserDto>> {
        val user = userService.findUserDtoById(userDetails.userId)
        return user.successResponse(
            message = "User information retrieved"
        )
    }
}
