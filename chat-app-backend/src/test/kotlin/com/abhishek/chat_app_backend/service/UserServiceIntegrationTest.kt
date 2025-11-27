package com.abhishek.chat_app_backend.service

import com.abhishek.chat_app_backend.dto.LoginRequest
import com.abhishek.chat_app_backend.dto.SignupRequest
import com.abhishek.chat_app_backend.repository.UserRepository
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.assertThrows
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.test.context.ActiveProfiles
import org.springframework.transaction.annotation.Transactional
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

@SpringBootTest
@ActiveProfiles("test")
@Transactional
class UserServiceIntegrationTest {
    
    @Autowired
    private lateinit var userService: UserService
    
    @Autowired
    private lateinit var userRepository: UserRepository
    
    @Test
    fun `should register user successfully`() {
        val request = SignupRequest(
            email = "test@example.com",
            password = "password123",
            firstName = "John",
            lastName = "Doe"
        )
        
        val result = userService.signup(request)
        
        assertNotNull(result.token)
        assertEquals("test@example.com", result.user.email)
        assertEquals("John", result.user.firstName)
        assertEquals("Doe", result.user.lastName)
        assertTrue(userRepository.existsByEmail("test@example.com"))
    }
    
    @Test
    fun `should not register user with duplicate email`() {
        val request = SignupRequest(
            email = "duplicate@example.com",
            password = "password123",
            firstName = "John",
            lastName = "Doe"
        )
        
        userService.signup(request)
        
        assertThrows<IllegalArgumentException> {
            userService.signup(request)
        }
    }
    
    @Test
    fun `should login user successfully`() {
        val signupRequest = SignupRequest(
            email = "login@example.com",
            password = "password123",
            firstName = "Jane",
            lastName = "Smith"
        )
        
        userService.signup(signupRequest)
        
        val loginRequest = LoginRequest(
            email = "login@example.com",
            password = "password123"
        )
        
        val result = userService.login(loginRequest)
        
        assertNotNull(result.token)
        assertEquals("login@example.com", result.user.email)
    }
}
