package com.abhishek.chat_app_backend.service

import com.abhishek.chat_app_backend.dto.ChatMessageResponse
import com.abhishek.chat_app_backend.dto.RoomUpdateEvent
import com.fasterxml.jackson.databind.ObjectMapper
import jakarta.annotation.PostConstruct
import org.slf4j.LoggerFactory
import org.springframework.data.redis.connection.MessageListener
import org.springframework.data.redis.core.RedisTemplate
import org.springframework.data.redis.listener.ChannelTopic
import org.springframework.data.redis.listener.PatternTopic
import org.springframework.data.redis.listener.RedisMessageListenerContainer
import org.springframework.messaging.simp.SimpMessagingTemplate
import org.springframework.stereotype.Service

@Service
class RedisMessageService(
    private val redisTemplate: RedisTemplate<String, Any>,
    private val messagingTemplate: SimpMessagingTemplate,
    private val redisMessageListenerContainer: RedisMessageListenerContainer,
    private val objectMapper: ObjectMapper
) {
    
    private val logger = LoggerFactory.getLogger(RedisMessageService::class.java)
    
    @PostConstruct
    fun initializeListener() {
        // Chat message listener for room topics
        val messageListener = MessageListener { message, pattern ->
            try {
                val messageBody = String(message.body)
                val chatMessage = objectMapper.readValue(messageBody, ChatMessageResponse::class.java)
                
                // Broadcast to WebSocket clients
                val destination = "/topic/room.${chatMessage.roomId}"
                messagingTemplate.convertAndSend(destination, chatMessage)
                
                logger.debug("Message forwarded from Redis to WebSocket: ${chatMessage.id}")
            } catch (e: Exception) {
                logger.error("Error processing Redis message: ${e.message}", e)
            }
        }
        
        // Room update listener for user-specific notifications
        val roomUpdateListener = MessageListener { message, pattern ->
            try {
                val messageBody = String(message.body)
                val updateEvent = objectMapper.readValue(messageBody, RoomUpdateEvent::class.java)
                
                // Forward to user's WebSocket queue
                val destination = "/user/${updateEvent.userId}/queue/roomUpdates"
                messagingTemplate.convertAndSendToUser(
                    updateEvent.userId.toString(),
                    "/queue/roomUpdates",
                    updateEvent,
                )
                
                logger.debug("Room update forwarded to user ${updateEvent.userId}: type=${updateEvent.type}, roomId=${updateEvent.roomId}")
            } catch (e: Exception) {
                logger.error("Error processing room update from Redis: ${e.message}", e)
            }
        }
        
        // Subscribe to all chat room channels for messages
        val chatTopic = PatternTopic("chat.room.*")
        redisMessageListenerContainer.addMessageListener(messageListener, chatTopic)
        
        // Subscribe to all user channels for room updates
        val userTopic = PatternTopic("chat.user.*")
        redisMessageListenerContainer.addMessageListener(roomUpdateListener, userTopic)
        
        logger.info("Redis message listeners initialized for chat and room update channels")
    }
    
    fun publishMessage(message: ChatMessageResponse) {
        try {
            val channel = "chat.room.${message.roomId}"
            redisTemplate.convertAndSend(channel, message)
            logger.debug("Message published to Redis channel: $channel")
        } catch (e: Exception) {
            logger.error("Failed to publish message to Redis: ${e.message}", e)
        }
    }
}

