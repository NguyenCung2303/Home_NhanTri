# Stockfish Backend cho Home NhanTri

Backend nhỏ này làm 3 việc:

1. Kéo ván gần nhất từ Lichess theo username học sinh.
2. Nếu có Stockfish, phân tích từng nước và phát hiện inaccuracy/mistake/blunder.
3. Trả về gợi ý định hướng học tập để Flutter tự điền vào form giáo viên.

## Cài đặt

### 1. Cài Python package

```bash
cd stockfish_backend
python -m venv .venv

# Windows
.venv\Scripts\activate

# macOS/Linux
source .venv/bin/activate

pip install -r requirements.txt
```

### 2. Cài Stockfish

#### Windows
Tải Stockfish, giải nén, lấy đường dẫn tới file `.exe`, ví dụ:

```text
C:\stockfish\stockfish-windows-x86-64-avx2.exe
```

Chạy backend với biến môi trường:

```bash
set STOCKFISH_PATH=C:\stockfish\stockfish-windows-x86-64-avx2.exe
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

#### macOS
Nếu cài bằng Homebrew:

```bash
brew install stockfish
which stockfish
export STOCKFISH_PATH=$(which stockfish)
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

#### Linux

```bash
sudo apt install stockfish
export STOCKFISH_PATH=/usr/games/stockfish
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

## Test nhanh

Mở trình duyệt:

```text
http://localhost:8000/health
http://localhost:8000/analyze/NguyenCung?max_games=3&depth=8
```

Nếu `engineAvailable = false`, nghĩa là backend vẫn kéo được Lichess nhưng chưa thấy Stockfish. Lúc đó Flutter vẫn có gợi ý thống kê cơ bản, nhưng chưa có lỗi nước đi cụ thể.

## Flutter gọi backend

- Android Emulator dùng: `http://10.0.2.2:8000`
- iOS Simulator/macOS/Windows/Web local dùng: `http://localhost:8000`
- Điện thoại thật dùng IP LAN của máy chạy backend, ví dụ: `http://192.168.1.5:8000`

Trong file Flutter `lib/data/services/stockfish_analysis_service.dart`, sửa `baseUrl` nếu cần.
