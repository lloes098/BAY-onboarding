// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TimelockedVoting {
    // 후보 5명 고정
    string[5] public candidates = ["A", "B", "C", "D", "E"];

    // 후보별 득표수
    mapping(string => uint256) public votes;

    // 유권자 중복 투표 방지
    mapping(address => bool) public hasVoted;

    // 유권자별 투표 완료 시간 기록
    mapping(address => uint256) public votedAt;

    // 시작 및 종료 시간
    uint256 public startTime;
    uint256 public endTime;

    // 이벤트: 투표 시 발생
    event Voted(address indexed voter, string candidate);

    // 생성자: 시작 및 종료 시간 설정
    constructor(uint256 _startTime, uint256 _durationSeconds) {
        require(_startTime >= block.timestamp, "Start time must be in the future");
        startTime = _startTime;
        endTime = _startTime + _durationSeconds;
    }

    // modifier: 타임락 검사
    modifier withinVotingPeriod() {
        require(block.timestamp >= startTime, "Voting has not started yet");
        require(block.timestamp <= endTime, "Voting period is over");
        _;
    }

    // modifier: 중복 방지
    modifier onlyOnce() {
        require(!hasVoted[msg.sender], "You have already voted");
        _;
    }

    // 유효한 후보인지 확인
    function isValidCandidate(string memory name) internal view returns (bool) {
        for (uint i = 0; i < candidates.length; i++) {
            if (keccak256(bytes(candidates[i])) == keccak256(bytes(name))) {
                return true;
            }
        }
        return false;
    }

    // 투표 함수
    function vote(string memory candidate) external withinVotingPeriod onlyOnce {
        require(isValidCandidate(candidate), "Invalid candidate");

        votes[candidate] += 1;
        hasVoted[msg.sender] = true;
        votedAt[msg.sender] = block.timestamp;

        emit Voted(msg.sender, candidate);
    }

    // 특정 후보 득표 수 반환
    function getVoteCount(string memory candidate) external view returns (uint256) {
        return votes[candidate];
    }

    // 내가 투표했는지 여부
    function hasUserVoted(address user) external view returns (bool) {
        return hasVoted[user];
    }

    // 내가 투표한 시간
    function getUserVotedAt(address user) external view returns (uint256) {
        return votedAt[user];
    }
}
