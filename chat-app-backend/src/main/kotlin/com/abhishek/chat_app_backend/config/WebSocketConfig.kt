package com.abhishek.chat_app_backend.config

import com.abhishek.chat_app_backend.service.JwtService
import org.slf4j.LoggerFactory
import org.springframework.context.annotation.Configuration
import org.springframework.messaging.Message
import org.springframework.messaging.MessageChannel
import org.springframework.messaging.simp.config.ChannelRegistration
import org.springframework.messaging.simp.config.MessageBrokerRegistry
import org.springframework.messaging.simp.stomp.StompCommand
import org.springframework.messaging.simp.stomp.StompHeaderAccessor
import org.springframework.messaging.support.ChannelInterceptor
import org.springframework.messaging.support.MessageHeaderAccessor
import org.springframework.security.core.context.SecurityContextHolder
import org.springframework.security.core.userdetails.UserDetailsService
import org.springframework.stereotype.Component
import org.springframework.web.socket.config.annotation.EnableWebSocketMessageBroker
import org.springframework.web.socket.config.annotation.StompEndpointRegistry
import org.springframework.web.socket.config.annotation.WebSocketMessageBrokerConfigurer

@Configuration
@EnableWebSocketMessageBroker
class WebSocketConfig(
    private val jwtAuthenticationInterceptor: JwtAuthenticationInterceptor
) : WebSocketMessageBrokerConfigurer {
    
    override fun configureMessageBroker(config: MessageBrokerRegistry) {
        config.enableSimpleBroker("/topic", "/queue")
        config.setApplicationDestinationPrefixes("/app")
    }
    
    override fun registerStompEndpoints(registry: StompEndpointRegistry) {
        registry.addEndpoint("/ws/chat")
            .setAllowedOriginPatterns("*")
            .withSockJS()
    }
    
    override fun configureClientInboundChannel(registration: ChannelRegistration) {
        registration.interceptors(jwtAuthenticationInterceptor)
    }
}

@Component
class JwtAuthenticationInterceptor(
    private val jwtService: JwtService,
    private val userDetailsService: UserDetailsService
) : ChannelInterceptor {
    
    private val logger = LoggerFactory.getLogger(JwtAuthenticationInterceptor::class.java)
    
    override fun preSend(message: Message<*>, channel: MessageChannel): Message<*>? {
        val accessor = MessageHeaderAccessor.getAccessor(message, StompHeaderAccessor::class.java)
        
        if (accessor != null && StompCommand.CONNECT == accessor.command) {
            val authHeader = accessor.getNativeHeader("Authorization")?.firstOrNull()
            
            if (authHeader?.startsWith("Bearer ") == true) {
                val token = authHeader.substring(7)
                try {
                    val userId = jwtService.fetchUserIdIfValid(token)
                    if (userId != null) {
                        val userDetails: CustomUserDetails? = (userDetailsService.loadUserByUsername(userId) as? CustomUserDetails)
                        if (userDetails != null) {
                            
                            val authentication = org.springframework.security.authentication.UsernamePasswordAuthenticationToken(
                                userDetails,
                                null,
                                userDetails.authorities
                            )
                            accessor.user = authentication
                            SecurityContextHolder.getContext().authentication = authentication
                            logger.info("WebSocket connection authenticated for user: $userId")
                        }
                        
                    }
                } catch (e: Exception) {
                    logger.error("WebSocket authentication failed: ${e.message}")
                    return null
                }
            } else {
                logger.warn("WebSocket connection attempted without valid Authorization header")
                return null
            }
        }
        
        return message
    }
}
