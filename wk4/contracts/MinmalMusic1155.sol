// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24; // ✅ OZ v5 스타일과 호환

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title 최소 버전: ETH 분배형 ERC-1155 음악 NFT (OpenZeppelin v5 호환)
/// @notice create → ownerMint → depositRevenue(ETH) → claim 흐름만 제공
contract MinimalMusic1155 is ERC1155, ERC1155Supply, Ownable, ReentrancyGuard {
    struct Song {
        string uriOverride;
        uint256 maxSupply;
        bool exists;
    }

    uint256 public constant ACC_PRECISION = 1e18;

    uint256 public nextSongId;
    mapping(uint256 => Song) public songs;

    // 분배 회계
    mapping(uint256 => uint256) public accPerUnit;                 // 누적 포인트(wei * 1e18 / supply)
    mapping(uint256 => mapping(address => int256)) public userDebt; // 각 유저 기준점

    event SongCreated(uint256 indexed songId, string uri, uint256 maxSupply);
    event Minted(address indexed to, uint256 indexed songId, uint256 amount);
    event RevenueDeposited(uint256 indexed songId, uint256 weiAmount);
    event Claimed(address indexed user, uint256 indexed songId, uint256 weiAmount);

    constructor(address initialOwner)
        ERC1155("") // baseURI 미사용
        Ownable(initialOwner)
    {}

    // 곡 생성
    function createSong(string calldata songURI, uint256 maxSupply)
        external onlyOwner returns (uint256 songId)
    {
        require(maxSupply > 0, "maxSupply=0");
        songId = ++nextSongId;
        songs[songId] = Song({ uriOverride: songURI, maxSupply: maxSupply, exists: true });
        emit SongCreated(songId, songURI, maxSupply);
    }

    // 메타데이터 URI
    function uri(uint256 id) public view override returns (string memory) {
        Song memory s = songs[id];
        require(s.exists, "song not found");
        return s.uriOverride; // ipfs://... / https://... / 텍스트 모두 가능
    }

    // 운영자 민팅
    function ownerMint(address to, uint256 songId, uint256 amount) external onlyOwner {
        Song memory s = songs[songId];
        require(s.exists, "song not found");
        require(totalSupply(songId) + amount <= s.maxSupply, "exceeds max");
        _mint(to, songId, amount, "");
        emit Minted(to, songId, amount);
        // 부채 보정은 _update에서 처리 (v5 훅)
    }

    // 수익 입금(ETH)
    function depositRevenue(uint256 songId) external payable nonReentrant {
        require(songs[songId].exists, "song not found");
        require(msg.value > 0, "no eth");
        uint256 supply = totalSupply(songId);
        require(supply > 0, "no holders");
        accPerUnit[songId] += (msg.value * ACC_PRECISION) / supply;
        emit RevenueDeposited(songId, msg.value);
    }

    // 청구 가능액 조회
    function claimable(uint256 songId, address user) public view returns (uint256) {
        uint256 bal = balanceOf(user, songId);
        if (bal == 0) return 0;
        uint256 entitled = bal * accPerUnit[songId];
        int256  debt     = userDebt[songId][user];
        if (int256(entitled) <= debt) return 0;
        return uint256(int256(entitled) - debt) / ACC_PRECISION; // wei
    }

    // 청구(ETH 수령)
    function claim(uint256 songId) external nonReentrant returns (uint256 amt) {
        amt = claimable(songId, msg.sender);
        if (amt > 0) {
            userDebt[songId][msg.sender] = int256(balanceOf(msg.sender, songId) * accPerUnit[songId]);
            (bool ok, ) = msg.sender.call{value: amt}("");
            require(ok, "transfer failed");
            emit Claimed(msg.sender, songId, amt);
        }
    }

    // ✅ v5 훅: 전송/민팅/소각 시 부채 보정은 _update에서
    function _update(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal override(ERC1155, ERC1155Supply) {
        super._update(from, to, ids, amounts);
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 a  = amounts[i];
            if (from != address(0)) {
                userDebt[id][from] -= int256(a * accPerUnit[id]);
            }
            if (to != address(0)) {
                userDebt[id][to]   += int256(a * accPerUnit[id]);
            }
        }
    }
}
