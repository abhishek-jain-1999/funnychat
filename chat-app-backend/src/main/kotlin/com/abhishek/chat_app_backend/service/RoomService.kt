package com.abhishek.chat_app_backend.service

import com.abhishek.chat_app_backend.document.Room
import com.abhishek.chat_app_backend.document.RoomType
import com.abhishek.chat_app_backend.dto.CreateRoomRequest
import com.abhishek.chat_app_backend.dto.RoomDto
import com.abhishek.chat_app_backend.repository.RoomRepository
import com.abhishek.chat_app_backend.exception.ResourceNotFoundException
import org.slf4j.LoggerFactory
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional

@Service
class RoomService(
    private val roomRepository: RoomRepository,
    private val userService: UserService,
    private val roomUpdateNotificationService: RoomUpdateNotificationService
) {
    
    private val logger = LoggerFactory.getLogger(RoomService::class.java)
    
    @Transactional
    fun createRoom(request: CreateRoomRequest, createdBy: Long): RoomDto {
        logger.info("Creating room: ${request.name} by user: $createdBy")
        
        // Validate creator exists
        val creator = userService.findUserById(createdBy)

        // Resolve participant emails to IDs, ignoring creator email if present
        val participantIds: Set<Long> = request.participantEmails
            .filter { it != creator.email }
            .map { email -> userService.getUserEntityByEmail(email).id }
            .toSet()
        
        val allParticipants: Set<Long> = participantIds + createdBy

        if (allParticipants.isEmpty()) {
            throw IllegalArgumentException("At least one participant is required")
        }
        
        val roomType = if (allParticipants.size == 2) RoomType.DIRECT else RoomType.GROUP
        
        // For direct chats, reuse existing room if exact pair already has one
        if (roomType == RoomType.DIRECT) {
            val existingRoom = roomRepository.findByTypeAndParticipantsContainingAndParticipantsSize(
                RoomType.DIRECT,
                allParticipants,
                2
            ).firstOrNull()
            
            if (existingRoom != null) {
                logger.info("Returning existing direct room: ${existingRoom.id}")
                return existingRoom.toDto()
            }
        }
        
        val room = Room(
            name = request.name,
            description = request.description,
            type = roomType,
            participants = allParticipants,
            createdBy = createdBy
        )
        
        val savedRoom = roomRepository.save(room)
        logger.info("Room created successfully with ID: ${savedRoom.id}")
        
        // Notify all participants asynchronously about the new room
        roomUpdateNotificationService.notifyNewRoom(
            savedRoom.id!!,
            allParticipants,
            savedRoom.toDto()
        )
        
        return savedRoom.toDto()
    }
    
    @Transactional(readOnly = true)
    fun getUserRooms(userId: Long): List<RoomDto> {
        logger.info("Fetching rooms for user: $userId")
        
        return roomRepository.findByParticipantsContaining(userId)
            .map { it.toDto() }
    }
    
    @Transactional(readOnly = true)
    fun getRoomById(roomId: String): Room {
        return roomRepository.findById(roomId)
            .orElseThrow { ResourceNotFoundException("Room not found with id: $roomId") }
    }
    

    private fun Room.toDto(): RoomDto {
        return RoomDto(
            id = this.id!!,
            name = this.name,
            description = this.description,
            type = this.type.name,
            participants = this.participants,
            createdBy = this.createdBy,
            lastMessage = this.lastMessage,
            lastMessageTime = this.lastMessageTime,
            createdAt = this.createdAt
        )
    }
}
