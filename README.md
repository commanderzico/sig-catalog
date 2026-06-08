# 시그 통합 카탈로그 (Sig Unified Catalog)

**커맨더지코 방송국 시그니처 통합 카탈로그**  
라이브: https://commanderzico.github.io/sig-catalog/

---

## 프로젝트 개요

- **목적**: 시그(시그니처) 음원과 시그 이미지를 하나의 웹 페이지에서 쉽게 검색·확인·재생할 수 있도록 통합한 카탈로그.
- **데이터 소스**: 
  - 원본 `시그음원(26.06.02)_정리목록.xlsx`
  - 원본 `시그이미지(26.06.02)_정리목록.xlsx`
  - 실제 이미지 파일: `이미지파일/` 폴더 (359개)
  - 실제 음원 파일: `1000~9999/`, `10000~50000/`, `5.xx/6.xx 뉴시그 음원/` 하위 폴더들
- **기준**: 시그 단가 (ID)로 매칭하여 중복 제거 및 통합 (총 371개 고유 단가)
- **배포**: GitHub Pages (정적 사이트, 별도 빌드 없음)

---

## 주요 기능

- **뷰 모드 전환** (검색창 바로 왼쪽)
  - **갤러리**: 카드 그리드 (시그이미지 썸네일 중심, 원본 비율 유지)
  - **테이블**: 한 줄씩 깔끔한 목록 뷰
- **검색 + 필터**
  - 시그 단가 / 제목 실시간 검색
  - 시기 필터 (기존 / 5~6월 뉴시그)
- **시그이미지**
  - 카드/테이블에서 바로 미리보기
  - 클릭 → 모달 팝업 (큰 이미지 + 다운로드 버튼)
- **시그음원**
  - 재생 버튼 (즉시 재생, 플로팅 플레이어)
  - 다운로드 아이콘 (직접 다운로드)
- **기타**
  - 엑셀 다운로드 (현재 필터링된 데이터만)
  - 단가 내림차순 기본 정렬 (높은 번호 위)
  - 반응형 디자인 (모바일/데스크톱)

---

## 프로젝트 구조 (repo root)

```
sig-catalog/
├── index.html                 # 메인 정적 페이지 (Tailwind CDN + Vanilla JS)
├── data/
│   └── sigs.json              # 핵심 데이터 (370+ entries)
├── images/                    # 시그 이미지 원본 (359 files)
├── 1000~9999/                 # 음원 (187 files)
├── 10000~50000/               # 음원 (161 files)
├── 5.7 뉴시그/ ... 6.4 뉴시그/ # 뉴시그 음원 폴더들
└── README.md
```

---

## 데이터 업데이트 방법 (로컬에서)

1. 원본 엑셀 파일 편집 (`시그_통합_정리목록(26.06.02).xlsx` 등)
2. Python으로 `sigs.json` 재생성 (이전 세션에서 사용한 스크립트 참고)
   - 시그 단가 기준 그룹핑
   - audio_path, image_name 등 상대 경로 포함
   - NFC 정규화 (한글 파일명 호환성)
3. `data/sigs.json` 교체
4. `index.html` 필요 시 수정
5. `git add data/sigs.json index.html && git commit && git push`
6. GitHub Pages 자동 배포 대기 (보통 30초~2분)

**참고**: 음원/이미지 파일은 별도로 `audio/`나 `images/`에 추가/삭제 후 동일하게 커밋.

---

## 로컬 개발 / 테스트

```bash
# 저장소 클론
git clone https://github.com/commanderzico/sig-catalog.git
cd sig-catalog

# 간단 서버 (Python)
python -m http.server 8000

# 브라우저에서 http://localhost:8000 접속
```

- `data/sigs.json`만 수정해도 대부분 기능 동작
- 이미지/오디오 파일은 `images/`, `1000~9999/` 등 상대 경로로 참조

---

## 기술 스택

- 순수 HTML + Vanilla JavaScript (no build step)
- Tailwind CSS (CDN)
- SheetJS (xlsx.full.min.js) – 클라이언트 측 엑셀 생성
- GitHub Pages (static hosting)
- 상대 경로 + encodeURI로 오디오/이미지 서빙

---

## 알려진 이슈 / 팁

- **오디오 재생 실패**: 가끔 발생 (raw vs Pages 서빙, 한글 파일명 인코딩, 브라우저 정책). 하드 리프레시 후 재시도. 콘솔 로그 확인 추천.
- **한글 파일명**: macOS NFD ↔ GitHub NFC 정규화 차이로 인해 URL 매칭이 민감함. (이미 NFC 정규화 스크립트 적용 완료)
- **대용량**: 음원 파일이 많아 repo 크기가 큼. Git LFS 도입 고려 가능.
- **엑셀 다운로드**: 현재 필터링된 결과만 export (검색+시기 필터 적용 상태)

---

## 원본 데이터

- `/Users/kim/Desktop/음원전체/시그_통합_정리목록(26.06.02).xlsx` (메인 데이터 소스)
- `시그음원(26.06.02)_정리목록.xlsx` (원본 음원 목록)
- `시그이미지(26.06.02)_정리목록.xlsx` (원본 이미지 목록)
- `이미지파일/` 폴더 (시그 이미지 원본)
- 각종 음원 하위 폴더 (1000~9999 등)

---

**마지막 업데이트**: 2026-06-08  
**저장소**: https://github.com/commanderzico/sig-catalog  
**라이브**: https://commanderzico.github.io/sig-catalog/

이 README는 세션 종료 전 현재 프로젝트 상태를 문서화하기 위해 생성되었습니다.
