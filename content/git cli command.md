
```
# 이 프로젝트에서만 변경
git config user.name "내 GitHub 이름"
git config user.email "내 GitHub 이메일"

# 또는 모든 프로젝트에 적용 (--global)
git config --global user.name "내 GitHub 이름"
git config --global user.email "내 GitHub 이메일"
```

```
# 1. 파일이 있는 폴더로 이동
cd 파일이있는폴더

# 2. Git 저장소 초기화
git init

# 3. 모든 파일을 스테이징
git add .

# 4. 첫 커밋
git commit -m "first commit"

# 5. GitHub 레포지토리를 원격으로 연결
git remote add origin https://github.com/jiu-0317/새이름.git

# 6. 올리기
git push -u origin main
```

```
git branch -M main          # 브랜치 이름을 main으로 변경
```

```
# 모든 파일 추적 해제 (실제 파일은 안 지워짐)
git rm -r --cached .
```

```
git status          # 뭐가 바뀌었나
git diff            # 어디가 바뀌었나
git log --oneline   # 어떤 커밋이 올라가나
```

```
git restore 파일이름          # 수정한 파일 되돌리기 (커밋 전)
git restore --staged 파일이름  # add 취소 (스테이징 해제)
git revert 커밋해시           # 특정 커밋을 취소하는 새 커밋 생성
```

```
git stash           # 현재 수정사항 임시 저장
git checkout main   # 다른 브랜치로 이동
# (다른 작업)
git checkout RF_reuse
git stash pop       # 임시 저장한 거 다시 꺼내기
```

```
# 1. main에서 공통 부분 수정 & 커밋
git checkout main
# (공통 코드 수정)
git add .
git commit -m "공통 모듈 수정"

# 2. 각 브랜치로 가서 main을 합치기
git checkout RF_reuse
git merge main

git checkout v2
git merge main
```

