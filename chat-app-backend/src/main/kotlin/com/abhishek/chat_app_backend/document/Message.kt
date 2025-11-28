package com.abhishek.chat_app_backend.document

import org.springframework.data.annotation.CreatedDate
import org.springframework.data.annotation.Id
import org.springframework.data.mongodb.core.index.Indexed
import org.springframework.data.mongodb.core.mapping.Document
import java.time.LocalDateTime

@Document(collection = "messages")
data class Message(
    @Id
    val id: String? = null,
    
    @Indexed
    val roomId: String,
    
    @Indexed
    val senderId: Long,
    
    val content: String,
    
    val messageType: MessageType = MessageType.TEXT,
    
    val attachments: List<Attachment> = emptyList(),
    
    @CreatedDate
    @Indexed
    val createdAt: LocalDateTime = LocalDateTime.now(),
    
    val readBy: Map<Long, LocalDateTime> = emptyMap(),
    
    val edited: Boolean = false,
    
    val editedAt: LocalDateTime? = null
)



enum class MessageType {
    TEXT,
    IMAGE,
    FILE,
    SYSTEM
}

data class Attachment(
    val fileName: String,
    val fileUrl: String,
    val fileSize: Long,
    val mimeType: String,
    val objectKey: String? = null,
    val mediaId: String? = null,
    val width: Int? = null,
    val height: Int? = null
)
