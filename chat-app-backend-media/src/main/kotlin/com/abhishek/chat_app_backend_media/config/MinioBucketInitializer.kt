package com.abhishek.chat_app_backend_media.config

import io.minio.BucketExistsArgs
import io.minio.MakeBucketArgs
import io.minio.MinioClient
import io.minio.SetBucketPolicyArgs
import jakarta.annotation.PostConstruct
import org.slf4j.LoggerFactory
import org.springframework.beans.factory.annotation.Value
import org.springframework.stereotype.Component

@Component
class MinioBucketInitializer(
    private val minioClient: MinioClient,
    @Value("\${minio.bucket}") private val bucket: String,
    @Value("\${minio.region:us-east-1}") private val region: String
) {
    
    private val logger = LoggerFactory.getLogger(MinioBucketInitializer::class.java)
    
    @PostConstruct
    fun initializeBucket() {
        try {
            // Check if bucket exists
            val bucketExists = minioClient.bucketExists(
                BucketExistsArgs.builder()
                    .bucket(bucket)
                    .build()
            )
            
            if (!bucketExists) {
                logger.info("Bucket $bucket does not exist, creating...")
                
                // Create bucket
                minioClient.makeBucket(
                    MakeBucketArgs.builder()
                        .bucket(bucket)
                        .region(region)
                        .build()
                )
                
                // Set public read policy for uploaded objects
                val policy = """
                {
                    "Version": "2012-10-17",
                    "Statement": [
                        {
                            "Effect": "Allow",
                            "Principal": {"AWS": "*"},
                            "Action": ["s3:GetObject"],
                            "Resource": ["arn:aws:s3:::$bucket/*"]
                        }
                    ]
                }
                """.trimIndent()
                
                minioClient.setBucketPolicy(
                    SetBucketPolicyArgs.builder()
                        .bucket(bucket)
                        .config(policy)
                        .build()
                )
                
                logger.info("Bucket $bucket created successfully with public read policy")
            } else {
                logger.info("Bucket $bucket already exists")
            }
            
            // Note: CORS configuration should be done via MinIO console or mc command:
            // mc anonymous set-json policy.json myminio/chat-media
            // Or via environment/startup script
            
        } catch (e: Exception) {
            logger.error("Failed to initialize MinIO bucket: ${e.message}", e)
            throw RuntimeException("MinIO initialization failed", e)
        }
    }
}