package com.abhishek.chat_app_backend.service

import com.abhishek.chat_app_backend.entity.MediaMetadata
import com.abhishek.chat_app_backend.entity.MediaStatus
import com.abhishek.chat_app_backend.repository.MediaMetadataRepository
import org.slf4j.LoggerFactory
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional

@Service
class MediaMetadataService(
    private val mediaMetadataRepository: MediaMetadataRepository
) {
    
    private val logger = LoggerFactory.getLogger(MediaMetadataService::class.java)
    
    @Transactional
    fun createPendingMedia(
        roomId: String,
        userId: Long,
        objectKey: String,
        mimeType: String,
        sizeBytes: Long
    ): MediaMetadata {
        logger.info("Creating pending media: room=$roomId, user=$userId, objectKey=$objectKey")
        
        val metadata = MediaMetadata(
            roomId = roomId,
            userId = userId,
            objectKey = objectKey,
            mimeType = mimeType,
            sizeBytes = sizeBytes,
            status = MediaStatus.PENDING_UPLOAD
        )
        
        return mediaMetadataRepository.save(metadata)
    }
    
    @Transactional
    fun markActive(mediaId: String, mediaUrl: String, actualSize: Long): MediaMetadata {
        logger.info("Marking media $mediaId as ACTIVE with URL: $mediaUrl")
        
        val metadata = mediaMetadataRepository.findById(mediaId)
            .orElseThrow { IllegalArgumentException("Media not found: $mediaId") }
        
        metadata.status = MediaStatus.ACTIVE
        metadata.mediaUrl = mediaUrl
        metadata.sizeBytes = actualSize
        
        return mediaMetadataRepository.save(metadata)
    }

    @Transactional
    fun markActive(metadata: MediaMetadata, mediaUrl: String, actualSize: Long): MediaMetadata {
        logger.info("Marking media ${metadata.id} as ACTIVE with URL: $mediaUrl")
        
        metadata.status = MediaStatus.ACTIVE
        metadata.mediaUrl = mediaUrl
        metadata.sizeBytes = actualSize
        
        return mediaMetadataRepository.save(metadata)
    }
    
    @Transactional
    fun markFailed(mediaId: String) {
        logger.warn("Marking media $mediaId as FAILED")
        
        val metadata = mediaMetadataRepository.findById(mediaId)
            .orElseThrow { IllegalArgumentException("Media not found: $mediaId") }
        
        metadata.status = MediaStatus.FAILED
        mediaMetadataRepository.save(metadata)
    }

    @Transactional
    fun markFailed(metadata: MediaMetadata) {
        logger.warn("Marking media ${metadata.id} as FAILED")
        
        metadata.status = MediaStatus.FAILED
        mediaMetadataRepository.save(metadata)
    }
    
    fun getPendingMedia(mediaId: String, userId: Long, roomId: String): MediaMetadata {
        val metadata = mediaMetadataRepository.findById(mediaId)
            .orElseThrow { IllegalArgumentException("Media not found: $mediaId") }
        
        if (metadata.userId != userId) {
            throw IllegalArgumentException("User does not own this media")
        }
        
        if (metadata.roomId != roomId) {
            throw IllegalArgumentException("Media does not belong to this room")
        }
        
        if (metadata.status != MediaStatus.PENDING_UPLOAD) {
            throw IllegalArgumentException("Media is not in PENDING_UPLOAD state")
        }
        
        return metadata
    }
}
