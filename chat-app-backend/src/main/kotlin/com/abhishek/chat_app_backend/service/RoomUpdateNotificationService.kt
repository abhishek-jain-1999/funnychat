package com.abhishek.chat_app_backend.service

import com.abhishek.chat_app_backend.dto.RoomUpdateEvent
import com.fasterxml.jackson.databind.ObjectMapper
import org.slf4j.LoggerFactory
import org.springframework.data.redis.core.RedisTemplate
import org.springframework.scheduling.annotation.Async
import org.springframework.stereotype.Service
import java.time.LocalDateTime

@Service
class RoomUpdateNotificationService(
    private val redisTemplate: RedisTemplate<String, Any>,
    private val objectMapper: ObjectMapper
) {
    
    private val logger = LoggerFactory.getLogger(RoomUpdateNotificationService::class.java)
    
    @Async
    fun notifyNewMessage(
        roomId: String,
        participants: Set<Long>,
        senderId: Long,
        senderName: String,
        lastMessage: String,
        lastMessageTime: LocalDateTime
    ) {
        try {
            participants.forEach { userId ->
                val event = RoomUpdateEvent(
                    type = "MESSAGE_SENT",
                    roomId = roomId,
                    userId = userId,
                    lastMessage = lastMessage,
                    lastMessageTime = lastMessageTime,
                    senderName = senderName,
                    timestamp = LocalDateTime.now()
                )
                publishToUserChannel(userId, event)
            }
            logger.debug("Room update notifications published for room: $roomId to ${participants.size} participants")
        } catch (e: Exception) {
            logger.error("Failed to notify room updates for room $roomId: ${e.message}", e)
        }
    }
    
    @Async
    fun notifyNewRoom(
        roomId: String,
        participants: Set<Long>,
        roomDto: com.abhishek.chat_app_backend.dto.RoomDto
    ) {
        try {
            participants.forEach { userId ->
                val event = RoomUpdateEvent(
                    type = "ROOM_CREATED",
                    roomId = roomId,
                    userId = userId,
                    room = roomDto,
                    timestamp = LocalDateTime.now()
                )
                publishToUserChannel(userId, event)
            }
            logger.debug("New room notifications published for room: $roomId to ${participants.size} participants")
        } catch (e: Exception) {
            logger.error("Failed to notify new room $roomId: ${e.message}", e)
        }
    }
    
    private fun publishToUserChannel(userId: Long, event: RoomUpdateEvent) {
        try {
            val channel = "chat.user.$userId"
            redisTemplate.convertAndSend(channel, event)
            logger.debug("Room update event published to Redis channel: $channel, type: ${event.type}")
        } catch (e: Exception) {
            logger.error("Failed to publish to user channel $userId: ${e.message}", e)
        }
    }
}
