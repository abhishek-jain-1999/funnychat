package com.abhishek.chat_app_backend_media.config

import io.minio.MinioClient
import org.slf4j.LoggerFactory
import org.springframework.beans.factory.annotation.Value
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration

@Configuration
class MinioConfig {
    
    private val logger = LoggerFactory.getLogger(MinioConfig::class.java)
    
    @Value("\${minio.endpoint}")
    private lateinit var endpoint: String
    
    @Value("\${minio.access-key}")
    private lateinit var accessKey: String
    
    @Value("\${minio.secret-key}")
    private lateinit var secretKey: String
    
    @Bean
    fun minioClient(): MinioClient {
        logger.info("Initializing MinIO client with endpoint: $endpoint")
        return MinioClient.builder()
            .endpoint(endpoint)
            .credentials(accessKey, secretKey)
            .build()
    }
}