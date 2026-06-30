
## 개요

Raspberry Pi 5 + NVMe SSD를 사용하여 Samba NAS를 구축하고, Tailscale을 통해 어디서든 접속 가능하도록 설정하는 가이드.

## 필요 장비

| 장비 | 용도 |
|------|------|
| Raspberry Pi 5 | NAS 서버 본체 |
| NVMe SSD + SSD 베이스 | 파일 저장소 |
| microSD 카드 (16GB 이상) | OS 설치용 |
| **5V 5A (27W) USB-C 전원 어댑터** | Pi 5 + SSD 전력 공급 (일반 충전기/PC USB 불가!) |
| micro HDMI 케이블 | 초기 화면 확인용 |
| 랜케이블 | 네트워크 연결 |
| 스위칭 허브 (5포트) | 벽면 랜포트 1개를 PC + Pi로 분배 |
| Windows PC | 초기 세팅 + NAS 클라이언트 |

## 네트워크 구성

```
벽면 랜포트 → 스위칭 허브
                ├→ PC (인터넷 + Tailscale)
                └→ Raspberry Pi (인터넷 + Tailscale + Samba)
```

> **주의:** 공유기(라우터)를 벽면 포트에 연결하면 이중 라우터 충돌로 인터넷이 안 될 수 있음. 스위칭 허브 사용 권장.

---

## 1단계: SD카드에 OS 굽기

### 1-1. Raspberry Pi Imager 설치
- https://www.raspberrypi.com/software/ 에서 Windows용 다운로드 및 설치

### 1-2. OS 굽기 설정

| 항목 | 선택값 |
|------|--------|
| 장치 | Raspberry Pi 5 |
| OS | Raspberry Pi OS (other) → **Raspberry Pi OS Lite (64-bit)** |
| 저장소 | microSD 카드 |

### 1-3. OS 설정 편집 (중요!)

OS 선택 후 "다음" → "OS 설정을 편집하시겠습니까?" → **편집** 클릭:

| 항목 | 설정값 |
|------|--------|
| 호스트네임 | `naspi` |
| 사용자 이름 | `pi` |
| 비밀번호 | (원하는 비밀번호) |
| Wi-Fi | 건너뛰기 (유선 사용) |
| 타임존 | Asia/Seoul |
| 키보드 | kr |
| SSH | **활성화** (비밀번호 인증) |
| 라즈베리파이 커넥트 | 비활성화 (불필요) |

### 1-4. 쓰기
"쓰기" 클릭 → 완료 대기 (5~10분)

---

## 2단계: 첫 부팅 + 네트워크 연결

### 2-1. 연결 순서
1. microSD 카드를 라즈베리파이에 삽입
2. 랜케이블로 네트워크에 연결
3. micro HDMI 케이블로 모니터 연결 (**HDMI 0 포트** — USB-C 전원 포트 쪽에 가까운 포트)
4. 전원(USB-C) 연결

> **주의:** HDMI를 먼저 꽂고, 그 다음 전원 연결. 순서 바뀌면 화면 안 나올 수 있음.

### 2-2. 부팅 확인
- 빨간 LED: 전원 들어옴
- 초록 LED 깜빡임: SD카드에서 부팅 중
- 초록 LED 안 깜빡이면: 전원 부족 또는 SD카드 문제

### 2-3. 로그인 및 IP 확인
```bash
# 로그인 후 IP 확인
hostname -I
# 예: 192.168.0.36
```

### 2-4. SSH 활성화 (Imager 설정이 안 먹힌 경우)
```bash
# SSH 상태 확인
sudo systemctl status ssh

# inactive (dead)면 직접 활성화
sudo systemctl enable ssh   # 부팅 시 자동 시작 등록
sudo systemctl start ssh    # 지금 바로 시작
```

### 2-5. Wi-Fi 국가 설정 (Wi-Fi 사용 시 필수)
```bash
sudo raspi-config
# 5 Localisation Options → L4 WLAN Country → KR (Korea) → OK → Finish
sudo reboot
```

### 2-6. Wi-Fi 연결 (핫스팟 등 임시 인터넷용)
```bash
# Wi-Fi 차단 해제
sudo rfkill unblock wifi

# Wi-Fi 장치 켜기
sudo ip link set wlan0 up

# 주변 Wi-Fi 검색
sudo nmcli device wifi list

# Wi-Fi 연결
sudo nmcli device wifi connect "SSID이름" password "비밀번호"

# 인터넷 확인
ping -c 3 google.com
```

---

## 3단계: SSD 마운트 + 포맷

### 3-1. 시스템 업데이트
```bash
sudo apt update && sudo apt upgrade -y
# apt update: 패키지 목록 갱신
# apt upgrade: 설치된 패키지 최신 버전으로 업그레이드
# -y: 확인 질문에 자동 Yes
```

### 3-2. SSD 인식 확인
```bash
lsblk
# 연결된 저장장치 목록 표시
# NVMe SSD는 nvme0n1으로 표시됨
```

### 3-3. SSD 포맷 (데이터 전부 삭제됨!)
```bash
# 기존 파티션 테이블 제거
sudo wipefs -a /dev/nvme0n1

# 새 파티션 생성 (GPT, 디스크 전체를 하나의 파티션으로)
sudo parted /dev/nvme0n1 --script mklabel gpt mkpart primary ext4 0% 100%

# ext4 파일시스템으로 포맷
sudo mkfs.ext4 /dev/nvme0n1p1
```

### 3-4. 마운트
```bash
# 마운트 폴더 생성
sudo mkdir -p /mnt/nas

# SSD 마운트
sudo mount /dev/nvme0n1p1 /mnt/nas

# 소유권 설정 (pi 사용자가 읽고 쓸 수 있도록)
sudo chown -R pi:pi /mnt/nas
```

### 3-5. 자동 마운트 설정 (fstab)
```bash
# UUID 확인
sudo blkid /dev/nvme0n1p1
# 출력 예: UUID="458a0bd0-d5c1-4606-a6a8-0b45fefb2835"

# fstab 편집
sudo nano /etc/fstab
```

맨 아래에 한 줄 추가:
```
UUID=여기에UUID넣기  /mnt/nas  ext4  defaults,noatime  0  2
```
`Ctrl+O` → Enter → `Ctrl+X`로 저장/종료

---

## 4단계: Samba 설치 + 공유 설정

### 4-1. Samba 설치
```bash
sudo apt install samba samba-common-bin -y
# samba: Windows 파일 공유 프로토콜 서버
# samba-common-bin: smbpasswd 등 유틸리티 포함
```

### 4-2. 공유 폴더 설정
```bash
sudo nano /etc/samba/smb.conf
```

파일 맨 아래에 추가:
```ini
[NAS]
   path = /mnt/nas
   browseable = yes
   writable = yes
   only guest = no
   create mask = 0775
   directory mask = 0775
   valid users = pi
```

`Ctrl+O` → Enter → `Ctrl+X`로 저장/종료

### 4-3. Samba 사용자 비밀번호 설정
```bash
sudo smbpasswd -a pi
# Windows에서 NAS 접속할 때 사용할 비밀번호 설정
# 두 번 입력
```

### 4-4. Samba 서비스 시작
```bash
sudo systemctl restart smbd   # Samba 재시작
sudo systemctl enable smbd    # 부팅 시 자동 시작
```

---

## 5단계: Tailscale 설치 (외부 접속)

### 5-1. Tailscale 설치
```bash
# 설치 스크립트 다운로드
curl -fsSL https://tailscale.com/install.sh -o install.sh

# 설치 실행
sudo sh install.sh
```

### 5-2. Tailscale 로그인
```bash
sudo tailscale up
# 화면에 인증 URL이 뜸 → PC 브라우저에서 해당 URL 열고 로그인
```

### 5-3. Tailscale IP 확인
```bash
tailscale ip -4
# 예: 100.83.27.87
```

---

## 6단계: Windows에서 NAS 접속

### 6-1. 접속
1. 파일 탐색기 열기
2. 주소창에 `\\Tailscale_IP` 입력 (예: `\\100.83.27.87`)
3. 사용자 이름: `pi`
4. 비밀번호: smbpasswd로 설정한 비밀번호

### 6-2. 네트워크 드라이브 연결 (선택)
1. NAS 폴더 우클릭 → **네트워크 드라이브 연결**
2. 드라이브 문자 선택 (예: `Z:`)
3. **로그온 시 다시 연결** 체크 → 완료

---

## 접속 조건

Tailscale을 통한 NAS 접속에 필요한 조건:

1. **라즈베리파이**가 인터넷에 연결되어 있을 것
2. **접속하는 PC/노트북/폰**에 Tailscale이 켜져 있을 것 (같은 계정)

이 조건만 충족되면 **사무실, 집, 카페 어디서든** `\\Tailscale_IP`로 NAS 접속 가능.

![[Pasted image 20260629195409.png]]

---

## 트러블슈팅

### 화면이 안 뜸
- micro HDMI → **HDMI 0 포트** (전원 포트 쪽)에 꽂았는지 확인
- HDMI 먼저 꽂고, 전원을 나중에 연결

### 부팅 안 됨 (빨간불만 켜짐)
- **전원 부족**: 5V 5A (27W) 전용 어댑터 사용 필수. PC USB, 핸드폰 충전기 불가
- SD카드 다시 삽입 또는 다시 굽기

### SSH 접속 안 됨
- `sudo systemctl status ssh`로 SSH 상태 확인
- inactive면 `sudo systemctl enable ssh && sudo systemctl start ssh`

### Wi-Fi가 unavailable
- `sudo raspi-config` → WLAN Country → KR 설정 후 재부팅

### 공유기 연결 시 인터넷 안 됨
- 이중 라우터 충돌. **스위칭 허브** 사용 권장