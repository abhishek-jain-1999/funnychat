package com.abhishek.chat_app_backend_media.config

import jakarta.servlet.FilterChain
import jakarta.servlet.http.HttpServletRequest
import jakarta.servlet.http.HttpServletResponse
import org.springframework.beans.factory.annotation.Value
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken
import org.springframework.security.core.authority.SimpleGrantedAuthority
import org.springframework.security.core.context.SecurityContextHolder
import org.springframework.stereotype.Component
import org.springframework.web.filter.OncePerRequestFilter

@Component
class InternalTokenFilter : OncePerRequestFilter() {
    
    @Value("\${media.service.token:}")
    private lateinit var internalToken: String
    
    override fun doFilterInternal(
        request: HttpServletRequest,
        response: HttpServletResponse,
        filterChain: FilterChain
    ) {
        // Only apply token validation to internal endpoints
        if (request.requestURI.startsWith("/internal/")) {
            // If no token is configured, allow the request (backward compatibility)
            if (internalToken.isEmpty()) {
                // Create a simple authentication for internal requests
                val authToken = UsernamePasswordAuthenticationToken(
                    "internal-service",
                    null,
                    listOf(SimpleGrantedAuthority("INTERNAL_SERVICE"))
                )
                SecurityContextHolder.getContext().authentication = authToken
                filterChain.doFilter(request, response)
                return
            }
            
            // Check for the X-Internal-Token header
            val requestToken = request.getHeader("X-Internal-Token")
            if (requestToken != null && requestToken == internalToken) {
                // Create authentication for valid internal requests
                val authToken = UsernamePasswordAuthenticationToken(
                    "internal-service",
                    null,
                    listOf(SimpleGrantedAuthority("INTERNAL_SERVICE"))
                )
                SecurityContextHolder.getContext().authentication = authToken
            } else {
                response.status = HttpServletResponse.SC_UNAUTHORIZED
                response.contentType = "application/json"
                response.writer.write(
                    """{"success": false, "message": "Invalid or missing internal token"}"""
                )
                return
            }
        }
        
        filterChain.doFilter(request, response)
    }
}