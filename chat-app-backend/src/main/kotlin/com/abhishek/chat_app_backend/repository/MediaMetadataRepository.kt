package com.abhishek.chat_app_backend.repository

import com.abhishek.chat_app_backend.entity.MediaMetadata
import com.abhishek.chat_app_backend.entity.MediaStatus
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository
import java.util.*

@Repository
interface MediaMetadataRepository : JpaRepository<MediaMetadata, String> {
    
    fun findByObjectKey(objectKey: String): Optional<MediaMetadata>
    
    fun findByRoomIdAndStatus(roomId: String, status: MediaStatus): List<MediaMetadata>
    
    fun findByUserIdAndStatus(userId: Long, status: MediaStatus): List<MediaMetadata>
}
