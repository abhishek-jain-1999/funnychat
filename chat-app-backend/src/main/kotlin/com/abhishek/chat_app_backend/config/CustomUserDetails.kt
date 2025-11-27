package com.abhishek.chat_app_backend.config

import org.springframework.security.core.GrantedAuthority
import org.springframework.security.core.userdetails.UserDetails

class CustomUserDetails(
    val userId: Long,
    val userEmail: String,
    private val password: String,
    private val authorities: Collection<GrantedAuthority> = emptyList()
) : UserDetails {
    
    override fun getUsername(): String = userId.toString()
    
    override fun getPassword(): String = password
    
    override fun getAuthorities(): Collection<GrantedAuthority> = authorities
    
    override fun isAccountNonExpired(): Boolean = true
    
    override fun isAccountNonLocked(): Boolean = true
    
    override fun isCredentialsNonExpired(): Boolean = true
    
    override fun isEnabled(): Boolean = true
}
