package com.abhishek.chat_app_backend.repository

import com.abhishek.chat_app_backend.document.Message
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.mongodb.repository.MongoRepository
import org.springframework.stereotype.Repository
import java.time.LocalDateTime

@Repository
interface MessageRepository : MongoRepository<Message, String> {
    
    
    
    fun findByRoomIdOrderByCreatedAtDesc(roomId: String, pageable: Pageable): Page<Message>
    fun findByRoomIdAndCreatedAtAfterOrderByCreatedAtDesc(
        roomId: String,
        after: LocalDateTime,
        pageable: Pageable
    ): Page<Message>
    fun findByRoomIdAndCreatedAtBeforeOrderByCreatedAtDesc(
        roomId: String,
        before: LocalDateTime,
        pageable: Pageable
    ): Page<Message>
}
