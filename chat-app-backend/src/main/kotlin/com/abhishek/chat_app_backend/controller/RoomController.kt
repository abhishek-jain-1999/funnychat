package com.abhishek.chat_app_backend.controller

import com.abhishek.chat_app_backend.config.CustomUserDetails
import com.abhishek.chat_app_backend.dto.ApiResponse
import com.abhishek.chat_app_backend.dto.CreateRoomRequest
import com.abhishek.chat_app_backend.dto.MessageDto
import com.abhishek.chat_app_backend.dto.PagedResponse
import com.abhishek.chat_app_backend.dto.RoomDto
import com.abhishek.chat_app_backend.service.MessageService
import com.abhishek.chat_app_backend.service.RoomService
import com.abhishek.chat_app_backend.utils.errorResponse
import com.abhishek.chat_app_backend.utils.successResponse
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.Parameter
import io.swagger.v3.oas.annotations.tags.Tag
import jakarta.validation.Valid
import org.springframework.format.annotation.DateTimeFormat
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.security.core.annotation.AuthenticationPrincipal
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RequestParam
import org.springframework.web.bind.annotation.RestController
import java.time.LocalDateTime

@RestController
@RequestMapping("/api/rooms")
@Tag(name = "Rooms", description = "Chat room management")
class RoomController(
    private val roomService: RoomService,
    private val messageService: MessageService,
) {
    
    @PostMapping
    @Operation(summary = "Create a new chat room")
    fun createRoom(
        @Valid @RequestBody request: CreateRoomRequest,
        @AuthenticationPrincipal userDetails: CustomUserDetails
    ): ResponseEntity<ApiResponse<RoomDto>> {
        val room = roomService.createRoom(request, userDetails.userId)
        return room.successResponse(
            message = "Room created successfully",
            status = HttpStatus.CREATED
        )
    }
    
    @GetMapping
    @Operation(summary = "Get user's rooms")
    fun getUserRooms(
        @AuthenticationPrincipal userDetails: CustomUserDetails
    ): ResponseEntity<ApiResponse<List<RoomDto>>> {
        val rooms = roomService.getUserRooms(userDetails.userId)
        return rooms.successResponse(
            message = "Rooms retrieved successfully"
        )
    }
    
    @GetMapping("/{roomId}/messages")
    @Operation(summary = "Get messages for a room")
    fun getRoomMessages(
        @PathVariable roomId: String,
        @RequestParam(defaultValue = "0")
        @Parameter(description = "Page number") page: Int,
        @RequestParam(defaultValue = "20")
        @Parameter(description = "Page size") size: Int,
        @RequestParam(required = false)
        @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME)
        @Parameter(description = "Get messages before this timestamp") before: LocalDateTime?,
        @RequestParam(required = false)
        @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME)
        @Parameter(description = "Get messages after this timestamp") after: LocalDateTime?,
        @AuthenticationPrincipal userDetails: CustomUserDetails
    ): ResponseEntity<ApiResponse<PagedResponse<MessageDto>>> {
        val messages = messageService.getRoomMessages(
            roomId = roomId,
            userId = userDetails.userId,
            page = page,
            size = size,
            before = before,
            after = after
        )
        return messages.successResponse(
            message = "Messages retrieved successfully"
        )
    }
}
