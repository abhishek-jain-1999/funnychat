package com.abhishek.chat_app_backend.service

import com.abhishek.chat_app_backend.config.CustomUserDetails
import io.jsonwebtoken.*
import io.jsonwebtoken.security.Keys
import org.slf4j.LoggerFactory
import org.springframework.beans.factory.annotation.Value
import org.springframework.stereotype.Service
import java.security.Key
import java.util.*

@Service
class JwtService {
    
    private val logger = LoggerFactory.getLogger(JwtService::class.java)
    
    val EMAIL_ID = "emailId"
    
    
    @Value("\${jwt.secret}")
    private lateinit var jwtSecret: String
    
    @Value("\${jwt.expiration}")
    private var jwtExpiration: Int = 86400
    
    private fun getSigningKey(): Key {
        val keyBytes = jwtSecret.toByteArray()
        return Keys.hmacShaKeyFor(keyBytes)
    }
    
    
    fun generateToken(extraClaims: MutableMap<String, Any> = mutableMapOf(), userDetails: CustomUserDetails): String {
        return buildToken(extraClaims, userDetails, jwtExpiration.toLong())
    }
    
    private fun buildToken(
        extraClaims: MutableMap<String, Any>,
        userDetails: CustomUserDetails,
        expiration: Long
    ): String {
        val now = Date()
        val expiryDate = Date(now.time + expiration * 1000)
        extraClaims[EMAIL_ID] = userDetails.userEmail
        return Jwts.builder()
            .setClaims(extraClaims)
            .setSubject(userDetails.username)
            .setIssuedAt(now)
            .setExpiration(expiryDate)
            .signWith(getSigningKey(), SignatureAlgorithm.HS256)
            .compact()
    }
    
    
    fun fetchUserIdIfValid(token: String): String? {
        return try {
            val claims = extractAllClaims(token)
            if (claims == null || isTokenExpired(claims) || isUserIdInvalid(claims) || isUserEmailInvalid(claims)) {
                return null
            }
            
            extractClaim<String>(claims, Claims::getSubject)
            
        } catch (e: Exception) {
            logger.error("Error fetching user from token: ${e.message}")
            null
        }
    }
    
    private fun extractAllClaims(token: String): Claims? {
        try {
            return Jwts.parserBuilder()
                .setSigningKey(getSigningKey())
                .build()
                .parseClaimsJws(token)
                .body
        } catch (e: JwtException) {
            logger.error("JWT validation error: ${e.message}")
        } catch (e: IllegalArgumentException) {
            logger.error("JWT claims string is empty: ${e.message}")
        }
        return null
    }
    
    
    private fun isTokenExpired(claims: Claims): Boolean {
        return extractClaim(claims, Claims::getExpiration).before(Date())
    }
    
    private fun isUserIdInvalid(claims: Claims): Boolean {
        return extractClaim<String?>(claims, Claims::getSubject) == null
    }

    private fun isUserEmailInvalid(claims: Claims): Boolean {
        return  claims[EMAIL_ID] == null
    }
    
    fun <T> extractClaim(claims: Claims, claimsResolver: (Claims) -> T): T {
        return claimsResolver(claims)
    }
    


    
//    fun validateToken(token: String): Boolean {
//        try {
//            Jwts.parserBuilder()
//                .setSigningKey(getSigningKey())
//                .build()
//                .parseClaimsJws(token)
//            return true
//        } catch (e: JwtException) {
//            logger.error("JWT validation error: ${e.message}")
//        } catch (e: IllegalArgumentException) {
//            logger.error("JWT claims string is empty: ${e.message}")
//        }
//        return false
//    }
}
