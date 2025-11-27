package com.abhishek.chat_app_backend.service

import com.abhishek.chat_app_backend.config.CustomUserDetails
import com.abhishek.chat_app_backend.dto.AuthResponse
import com.abhishek.chat_app_backend.dto.LoginRequest
import com.abhishek.chat_app_backend.dto.SignupRequest
import com.abhishek.chat_app_backend.dto.UserDto
import com.abhishek.chat_app_backend.entity.User
import com.abhishek.chat_app_backend.repository.UserRepository
import com.abhishek.chat_app_backend.exception.ResourceNotFoundException
import org.slf4j.LoggerFactory
import org.springframework.context.annotation.Lazy
import org.springframework.security.authentication.AuthenticationManager
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken
import org.springframework.security.core.userdetails.UserDetails
import org.springframework.security.core.userdetails.UserDetailsService
import org.springframework.security.core.userdetails.UsernameNotFoundException
import org.springframework.security.crypto.password.PasswordEncoder
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional

@Service
class UserService(
    private val userRepository: UserRepository,
    private val passwordEncoder: PasswordEncoder,
    private val jwtService: JwtService,
    @Lazy private val authenticationManager: AuthenticationManager
) : UserDetailsService {
    
    private val logger = LoggerFactory.getLogger(UserService::class.java)
    
    @Transactional
    fun signup(request: SignupRequest): AuthResponse {
        logger.info("Attempting to register user with email: ${request.email}")
        
        if (userRepository.existsByEmail(request.email)) {
            throw IllegalArgumentException("User with email ${request.email} already exists")
        }
        
        val user = User(
            email = request.email,
            passwordHash = passwordEncoder.encode(request.password),
            firstName = request.firstName,
            lastName = request.lastName
        )
        
        val savedUser = userRepository.save(user)
        logger.info("User registered successfully with ID: ${savedUser.id}")
        
        val userDetails = CustomUserDetails(
            userId = savedUser.id,
            userEmail = savedUser.email,
            password = savedUser.passwordHash
        )

        val token = jwtService.generateToken(userDetails = userDetails)
        
        return AuthResponse(
            token = token,
            user = savedUser.toDto()
        )
    }
    
    @Transactional(readOnly = true)
    fun login(request: LoginRequest): AuthResponse {
        logger.info("Attempting to authenticate user: ${request.email}")
        
        authenticationManager.authenticate(
            UsernamePasswordAuthenticationToken(request.email, request.password)
        )
        
        val userEntity = userRepository.findByEmail(request.email)
            .orElseThrow { UsernameNotFoundException("User not found") }
        
        val userDetails = CustomUserDetails(
            userId = userEntity.id,
            userEmail = userEntity.email,
            password = userEntity.passwordHash
        )

        val token = jwtService.generateToken(userDetails = userDetails)
        
        logger.info("User authenticated successfully: ${userEntity.email}")
        
        return AuthResponse(
            token = token,
            user = userEntity.toDto()
        )
    }
    
    @Transactional(readOnly = true)
    fun findUserDtoById(id: Long): UserDto {
        return findUserById(id).toDto()
    }
    
    @Transactional(readOnly = true)
    fun findUserById(id: Long): User {
        return userRepository.findById(id)
            .orElseThrow { ResourceNotFoundException("User not found with id: $id") }
    }
  
    
    @Transactional(readOnly = true)
    fun getUserEntityByEmail(email: String): User {
        return userRepository.findByEmail(email)
            .orElseThrow { ResourceNotFoundException("User not found with email: $email") }
    }
    

    override fun loadUserByUsername(id: String): UserDetails {
        try {
            val user: User = if ("@" in id) {
                getUserEntityByEmail(id)
            } else {
                findUserById(id.toLong())
            }

            return CustomUserDetails(
                userId = user.id,
                userEmail = user.email,
                password = user.passwordHash
            )
        } catch (e: ResourceNotFoundException) {
            throw UsernameNotFoundException(e.message)
        }
    }
    
    private fun User.toDto(): UserDto {
        return UserDto(
            id = this.id,
            email = this.email,
            firstName = this.firstName,
            lastName = this.lastName,
            createdAt = this.createdAt
        )
    }
}
