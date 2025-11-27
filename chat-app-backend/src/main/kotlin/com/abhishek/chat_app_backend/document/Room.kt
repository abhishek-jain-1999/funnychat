package com.abhishek.chat_app_backend.document

import org.springframework.data.annotation.CreatedDate
import org.springframework.data.annotation.Id
import org.springframework.data.annotation.LastModifiedDate
import org.springframework.data.mongodb.core.mapping.Document
import java.time.LocalDateTime

@Document(collection = "rooms")
data class Room(
    @Id
    val id: String? = null,
    
    val name: String,
    
    val description: String = "",
    
    val type: RoomType,
    
    val participants: Set<Long> = setOf(),
    
    val createdBy: Long,
    
    val lastMessage: String? = null,
    
    val lastMessageTime: LocalDateTime? = null,
    
    @CreatedDate
    val createdAt: LocalDateTime = LocalDateTime.now(),
    
    @LastModifiedDate
    val updatedAt: LocalDateTime = LocalDateTime.now(),
    
    val active: Boolean = true
)

enum class RoomType {
    DIRECT,    // One-to-one chat
    GROUP      // Group chat
}
