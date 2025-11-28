package com.abhishek.chat_app_backend.entity

import jakarta.persistence.*
import org.hibernate.annotations.CreationTimestamp
import java.time.LocalDateTime

@Entity
@Table(name = "media_metadata")
data class MediaMetadata(
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    val id: String? = null,
    
    @Column(nullable = false)
    val roomId: String,
    
    @Column(nullable = false)
    val userId: Long,
    
    @Column(nullable = false, unique = true)
    val objectKey: String,
    
    @Column(nullable = false)
    val mimeType: String,
    
    @Column(nullable = false)
    var sizeBytes: Long,
    
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    var status: MediaStatus = MediaStatus.PENDING_UPLOAD,
    
    var mediaUrl: String? = null,
    
    @Column
    val expiresAt: LocalDateTime? = null,
    
    @CreationTimestamp
    @Column(nullable = false, updatable = false)
    val createdAt: LocalDateTime = LocalDateTime.now()
)

enum class MediaStatus {
    PENDING_UPLOAD,
    ACTIVE,
    FAILED,
    DELETED
}
