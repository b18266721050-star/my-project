@echo off
rem ============================================================
rem  codex-commit.cmd - Commit with Codex-generated summary
rem  Workflow: stage all changes -> codex summarizes the diff
rem  -> commit using the summary as the commit message.
rem  Just run this script inside the repository.
rem ============================================================
setlocal
set "PATH=D:\agent\git\cmd;D:\agent\codex\bin;%PATH%"
set "CODEX_HOME=D:\agent\codex\home"
set "TMPD=D:\agent\tmp"

rem --- repo dir = location of this script, without trailing backslash ---
set "REPO=%~dp0"
if "%REPO:~-1%"=="\" set "REPO=%REPO:~0,-1%"

if not exist "%TMPD%" mkdir "%TMPD%"

rem --- stage all changes, then check if there is anything to commit ---
git -C "%REPO%" add -A
git -C "%REPO%" diff --cached --quiet
if %ERRORLEVEL% EQU 0 (
  echo [codex-commit] nothing to commit, working tree clean
  exit /b 0
)

rem --- ask codex to summarize the staged diff ---
if exist "%TMPD%\commit_msg.txt" del "%TMPD%\commit_msg.txt"
cd /d "%TMPD%"
git -C "%REPO%" diff --cached | codex exec --skip-git-repo-check -o "%TMPD%\commit_msg.txt" "The stdin contains the git diff of the changes to be committed. Write a concise commit message in Simplified Chinese, one or two sentences, in the format 'type: short description' (for example: fix: ..., docs: ..., feat: ...). Output ONLY the commit message itself. No explanations, no code fences."
if not exist "%TMPD%\commit_msg.txt" (
  echo [codex-commit] ERROR: codex summary failed, nothing committed
  cd /d "%REPO%"
  exit /b 1
)

echo [codex-commit] Codex summary of the diff:
type "%TMPD%\commit_msg.txt"
echo.

rem --- commit with the summary as message ---
cd /d "%REPO%"
git commit -F "%TMPD%\commit_msg.txt"
endlocal
