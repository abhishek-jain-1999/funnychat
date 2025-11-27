package com.abhishek.chat_app_backend

import org.springframework.boot.autoconfigure.SpringBootApplication
import org.springframework.boot.runApplication
import org.springframework.context.annotation.Bean
import org.springframework.data.jpa.repository.config.EnableJpaAuditing
import org.springframework.data.mongodb.config.EnableMongoAuditing
import org.springframework.scheduling.annotation.EnableAsync
import org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor
import java.util.concurrent.Executor

@SpringBootApplication
@EnableJpaAuditing
@EnableMongoAuditing
@EnableAsync
class ChatAppBackendApplication {
    @Bean(name = ["taskExecutor"])
    fun taskExecutor(): Executor {
        val executor = ThreadPoolTaskExecutor()
        executor.corePoolSize = 5
        executor.maxPoolSize = 10
        executor.queueCapacity = 100
//        executor.threadNamePrefix = "async-task-"
        executor.setThreadNamePrefix("async-task-")
        executor.initialize()
        return executor
    }
}

fun main(args: Array<String>) {
	runApplication<ChatAppBackendApplication>(*args)
}
