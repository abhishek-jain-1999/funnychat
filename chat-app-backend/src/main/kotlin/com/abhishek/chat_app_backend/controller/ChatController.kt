package com.abhishek.chat_app_backend.controller

import com.abhishek.chat_app_backend.config.CustomUserDetails
import com.abhishek.chat_app_backend.dto.ChatMessagePayload
import com.abhishek.chat_app_backend.service.MessageService
import org.slf4j.LoggerFactory
import org.springframework.messaging.handler.annotation.MessageMapping
import org.springframework.messaging.handler.annotation.Payload
import org.springframework.messaging.simp.annotation.SendToUser
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken
import org.springframework.stereotype.Controller
import java.security.Principal

@Controller
class ChatController(
    private val messageService: MessageService
) {
    
    private val logger = LoggerFactory.getLogger(ChatController::class.java)
    
    @MessageMapping("/chat.sendMessage")
    fun sendMessage(
        @Payload payload: ChatMessagePayload,
        principal: Principal,
    ) {
        try {
            val authentication = principal as? UsernamePasswordAuthenticationToken
            val userDetails = authentication?.principal as? CustomUserDetails
            val userId = userDetails!!.userId
            messageService.sendMessage(payload, userId)
            
            logger.info("Message sent successfully from user $userId to room ${payload.roomId}")
        } catch (e: IllegalArgumentException) {
            logger.error("Validation error: ${e.message}")
            throw e
        } catch (e: Exception) {
            logger.error("Failed to send message: ${e.message}", e)
            throw e
        }
    }
    
    @MessageMapping("/chat.addUser")
    @SendToUser("/queue/reply")
    fun addUser(
        principal: Principal,
//        @AuthenticationPrincipal userDetails: UserDetails
    ): Map<String, String> {
        val authentication = principal as? UsernamePasswordAuthenticationToken
        val userDetails = authentication?.principal as? CustomUserDetails
        logger.info("User ${userDetails!!.userId} connected to chat")
        return mapOf(
            "type" to "USER_CONNECTED",
            "message" to "Successfully connected to chat"
        )
    }
}
