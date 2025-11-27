package com.abhishek.chat_app_backend.repository

import com.abhishek.chat_app_backend.document.Room
import com.abhishek.chat_app_backend.document.RoomType
import org.springframework.data.mongodb.repository.MongoRepository
import org.springframework.data.mongodb.repository.Query
import org.springframework.stereotype.Repository

@Repository
interface RoomRepository : MongoRepository<Room, String> {
    fun findByParticipantsContaining(userId: Long): List<Room>
    
    @Query(value = "{ 'type': ?0, 'participants': { \$all: ?1, \$size: ?2 } }")
//    @Query("""{ "type": ?0, "participants": { "\$all": ?1, "\$size": ?2 }}""")
    fun findByTypeAndParticipantsContainingAndParticipantsSize(
        type: RoomType,
        participantIds: Set<Long>,
        size: Int
    ): List<Room>
}
