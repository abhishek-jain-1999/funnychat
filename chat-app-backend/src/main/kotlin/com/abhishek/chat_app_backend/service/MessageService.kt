package com.abhishek.chat_app_backend.service

import com.abhishek.chat_app_backend.document.Message
import com.abhishek.chat_app_backend.document.MessageType
import com.abhishek.chat_app_backend.dto.ChatMessagePayload
import com.abhishek.chat_app_backend.dto.ChatMessageResponse
import com.abhishek.chat_app_backend.dto.MessageDto
import com.abhishek.chat_app_backend.dto.PagedResponse
import com.abhishek.chat_app_backend.repository.MessageRepository
import org.slf4j.LoggerFactory
import org.springframework.data.domain.PageRequest
import org.springframework.data.domain.Sort
import org.springframework.messaging.simp.SimpMessagingTemplate
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.LocalDateTime

@Service
class MessageService(
    private val messageRepository: MessageRepository,
    private val roomService: RoomService,
    private val userService: UserService,
    private val messagingTemplate: SimpMessagingTemplate,
    private val redisMessageService: RedisMessageService,
    private val roomRepository: com.abhishek.chat_app_backend.repository.RoomRepository,
    private val roomUpdateNotificationService: RoomUpdateNotificationService
) {
    
    private val logger = LoggerFactory.getLogger(MessageService::class.java)
    
    @Transactional
    fun sendMessage(payload: ChatMessagePayload, senderId: Long): ChatMessageResponse {
        logger.info("Sending message to room ${payload.roomId} from user $senderId")
        
        // Validate user is in room
        val room = roomService.getRoomById(payload.roomId)
        if (!room.participants.contains(senderId)) {
            throw IllegalArgumentException("User not authorized for this room")
        }
        
        // Get sender details
        val sender = userService.findUserById(senderId)
        
        // Create and save message
        val message = Message(
            roomId = payload.roomId,
            senderId = senderId,
            content = payload.content,
            messageType = MessageType.valueOf(payload.messageType.uppercase())
        )
        
        val savedMessage = messageRepository.save(message)
        
        // Update room's lastMessage and lastMessageTime
        val updatedRoom = room.copy(
            lastMessage = payload.content,
            lastMessageTime = savedMessage.createdAt
        )
        roomRepository.save(updatedRoom)
        
        val response = ChatMessageResponse(
            id = savedMessage.id!!,
            roomId = savedMessage.roomId,
            senderId = savedMessage.senderId,
            senderName = "${sender.firstName} ${sender.lastName}",
            content = savedMessage.content,
            messageType = savedMessage.messageType.name,
            createdAt = savedMessage.createdAt
        )
        
        // Broadcast to WebSocket
//        broadcastMessage(response)
        
//        // Publish to Redis for multi-instance support
        redisMessageService.publishMessage(response)
        
        // Notify room participants about the new message asynchronously
        roomUpdateNotificationService.notifyNewMessage(
            payload.roomId,
            room.participants,
            senderId,
            "${sender.firstName} ${sender.lastName}",
            payload.content,
            savedMessage.createdAt
        )
        
        logger.info("Message sent successfully with ID: ${savedMessage.id}")
        return response
    }
    
    @Transactional(readOnly = true)
    fun getRoomMessages(
        roomId: String,
        userId: Long,
        page: Int = 0,
        size: Int = 20,
        before: LocalDateTime? = null,
        after: LocalDateTime? = null
    ): PagedResponse<MessageDto> {
        logger.info("Fetching messages for room $roomId, page $page, size $size")
        
        // Validate user is in room
        
        val pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"))
        
        val messagesPage = when {
            after != null -> messageRepository.findByRoomIdAndCreatedAtAfterOrderByCreatedAtDesc(
                roomId, after, pageable
            )
            before != null -> messageRepository.findByRoomIdAndCreatedAtBeforeOrderByCreatedAtDesc(
                roomId, before, pageable
            )
            else -> messageRepository.findByRoomIdOrderByCreatedAtDesc(roomId, pageable)
        }
        
        val messages = messagesPage.content.map { it.toDto(userId) }
        
        return PagedResponse(
            content = messages,
            page = messagesPage.number,
            size = messagesPage.size,
            totalElements = messagesPage.totalElements,
            totalPages = messagesPage.totalPages,
            last = messagesPage.isLast
        )
    }
    
//    private fun broadcastMessage(message: ChatMessageResponse) {
//        val destination = "/topic/room.${message.roomId}"
//        messagingTemplate.convertAndSend(destination, message)
//        logger.debug("Message broadcast to WebSocket destination: $destination")
//    }
    
    private fun Message.toDto(userId: Long): MessageDto {
        return MessageDto(
            id = this.id!!,
            roomId = this.roomId,
            senderId = this.senderId,
            content = this.content,
            messageType = this.messageType.name,
            createdAt = this.createdAt,
            edited = this.edited,
            isUserSelf = userId == this.senderId
        )
    }
}

