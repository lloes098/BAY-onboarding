# Web3 Music DApp (Minimal Prototype)

ERC-1155 기반 **음악 NFT + 자동 수익 분배 DApp**의 최소 버전입니다.  
Remix에서 스마트컨트랙트를 배포하고, Next.js + wagmi/viem으로 간단한 대시보드를 제공합니다.

##  기능
- **아티스트 / 운영자**
  - `createSong` : 곡 등록 (메타데이터 URI, 공급량)
  - `ownerMint` : 팬에게 NFT 배포
  - `depositRevenue` : ETH 수익 입금
- **팬**
  - `claim` : NFT 보유량 비례로 ETH 수익 청구
- **프론트엔드**
  - 곡별 **IPFS 메타데이터** 표시 (커버 이미지, 오디오 등)
  - 내 **보유 수량** 및 **청구 가능액** 확인
  - Claim 버튼으로 바로 청구 실행

##  Stack
- **Smart Contract**: Solidity (Remix, OpenZeppelin ERC1155)
- **Frontend**: Next.js 14, TypeScript, wagmi, viem
- **Storage**: IPFS (메타데이터/음원/커버)

##  흐름
1. Remix에서 컨트랙트 배포 (`MinimalMusic1155.sol`)
2. 운영자가 곡 생성 → 팬에게 NFT 민팅
3. 운영자가 ETH 수익 입금 (`depositRevenue`)
4. 팬은 프론트 대시보드에서 `claim` 호출 → ETH 수령

---

현재는 **운영자 민팅 & ETH 분배만 지원**하는 MVP 버전입니다.  
추후 **구매 기능**, **USDC/스테이블코인 지원**, **2차 판매 로열티** 등을 확장할 수 있습니다.
