package com.abhishek.chat_app_backend.dto

import jakarta.validation.constraints.Email
import jakarta.validation.constraints.NotBlank
import jakarta.validation.constraints.Size
import java.time.LocalDateTime

// Auth DTOs
data class SignupRequest(
    @field:Email(message = "Invalid email format")
    @field:NotBlank(message = "Email is required")
    val email: String,
    
    @field:NotBlank(message = "Password is required")
    @field:Size(min = 6, message = "Password must be at least 6 characters")
    val password: String,
    
    @field:NotBlank(message = "First name is required")
    val firstName: String,
    
    @field:NotBlank(message = "Last name is required")
    val lastName: String
)

data class LoginRequest(
    @field:Email(message = "Invalid email format")
    @field:NotBlank(message = "Email is required")
    val email: String,
    
    @field:NotBlank(message = "Password is required")
    val password: String
)

data class AuthResponse(
    val token: String,
    val user: UserDto
)

data class UserDto(
    val id: Long,
    val email: String,
    val firstName: String,
    val lastName: String,
    val createdAt: LocalDateTime
)

// Room DTOs
data class CreateRoomRequest(
    @field:NotBlank(message = "Room name is required")
    val name: String,
    
    val description: String = "",
    
    // Emails of the other participants (excluding the current user)
    val participantEmails: Set<@Email String> = emptySet()
)

data class RoomDto(
    val id: String,
    val name: String,
    val description: String,
    val type: String,
    val participants: Set<Long>,
    val createdBy: Long,
    val lastMessage: String? = null,
    val lastMessageTime: LocalDateTime? = null,
    val createdAt: LocalDateTime
)

// Message DTOs
data class SendMessageRequest(
    @field:NotBlank(message = "Content is required")
    val content: String,
    
    val messageType: String = "TEXT"
)

data class MessageDto(
    val id: String,
    val roomId: String,
    val senderId: Long,
    val content: String,
    val messageType: String,
    val createdAt: LocalDateTime,
    val edited: Boolean = false,
    val isUserSelf: Boolean = false
)

// WebSocket DTOs
data class ChatMessagePayload(
    val roomId: String,
    val content: String,
    val messageType: String = "TEXT"
)

data class ChatMessageResponse(
    val id: String,
    val roomId: String,
    val senderId: Long,
    val senderName: String,
    val content: String,
    val messageType: String,
    val createdAt: LocalDateTime
)

data class RoomUpdatePayload(
    val type: String,
    val roomId: String,
    val lastMessage: String?,
    val lastMessageTime: LocalDateTime?,
    val senderName: String
)

data class RoomUpdateEvent(
    val type: String,  // ROOM_CREATED, MESSAGE_SENT, UNREAD_UPDATE
    val roomId: String,
    val userId: Long,  // Target user ID for this notification
    val room: RoomDto? = null,  // Full room data for new rooms
    val lastMessage: String? = null,
    val lastMessageTime: LocalDateTime? = null,
    val senderName: String? = null,
    val timestamp: LocalDateTime = LocalDateTime.now()
)

// API Response wrapper
data class ApiResponse<T>(
    val success: Boolean,
    val message: String,
    val data: T? = null
)

data class PagedResponse<T>(
    val content: List<T>,
    val page: Int,
    val size: Int,
    val totalElements: Long,
    val totalPages: Int,
    val last: Boolean
)
