// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; 

contract diary {
    enum Mood { Good, Normal, Bad, Sad }

    struct Entry { 
        string title; 
        string content; 
        Mood mood; 
        uint timestamp; 
    }

    mapping(address => Entry[]) private diaries;    event DiaryWritten(address indexed user, string title, Mood mood, uint timestamp); 

    function writeDiary(string calldata _title, string calldata _content, Mood _mood) external {
    Entry memory newEntry = Entry({
        title: _title,
        content: _content,
        mood: _mood,
        timestamp: block.timestamp
    });

    diaries[msg.sender].push(newEntry); // ✅ 저장!
    emit DiaryWritten(msg.sender, _title, _mood, block.timestamp); // ✅ 로그 기록
}


    function getDiaryCount() external view returns (uint) {
        return diaries[msg.sender].length; 
    }

    function getDiaryByIndex(uint index) external view returns (string memory, string memory, Mood, uint) {
        require(index < diaries[msg.sender].length, "Invalid"); 
        Entry memory entry =  diaries[msg.sender][index]; 
        return (entry.title, entry.content, entry.mood, entry.timestamp); 
    }

    function getDiariesByMood(Mood _mood) external view returns (Entry[] memory) {
        uint  count  = 0; 
        for (uint i = 0; i < diaries[msg.sender].length; i++) {
            if (diaries[msg.sender][i].mood == _mood) {
                count++; 
            }
        }

        Entry[] memory result = new Entry[](count); 
        uint j = 0; 
        for (uint i = 0; i < diaries[msg.sender].length; i++) {
            if (diaries[msg.sender][i].mood == _mood) {
                result[j] = diaries[msg.sender][i]; 
                j++; 
            }
        }
        return result; 
    }
}