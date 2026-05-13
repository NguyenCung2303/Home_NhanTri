import json
import os
import shutil
from collections import Counter, defaultdict
from typing import Any, Dict, List, Optional, Tuple

import chess
import chess.engine
import requests
from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel


app = FastAPI(title="Home NhanTri Stockfish Analyzer", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

LICHESS_BASE = "https://lichess.org"
USER_AGENT = "HomeNhanTriChessCenter/1.0"


def normalize_username(value: str) -> str:
    value = (value or "").strip()
    value = value.replace("https://lichess.org/@/", "")
    value = value.replace("http://lichess.org/@/", "")
    value = value.replace("lichess.org/@/", "")
    value = value.replace("@/", "")
    value = value.replace("@", "")
    return value.split("/")[0].strip()


def stockfish_path() -> Optional[str]:
    configured = os.getenv("STOCKFISH_PATH")
    if configured and os.path.exists(configured):
        return configured
    found = shutil.which("stockfish")
    return found


class BestMoveRequest(BaseModel):
    fen: str
    depth: int = 12


class CheckMoveRequest(BaseModel):
    fen: str
    player_move: str
    depth: int = 12


def _open_engine() -> chess.engine.SimpleEngine:
    path = stockfish_path()
    if not path:
        raise HTTPException(
            status_code=500,
            detail="Không tìm thấy Stockfish trên server. Kiểm tra Dockerfile hoặc biến STOCKFISH_PATH."
        )
    try:
        return chess.engine.SimpleEngine.popen_uci(path)
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Không mở được Stockfish: {exc}")


@app.post("/best-move")
def best_move(req: BestMoveRequest) -> Dict[str, Any]:
    try:
        board = chess.Board(req.fen)
    except ValueError:
        raise HTTPException(status_code=400, detail="FEN không hợp lệ")

    if board.is_game_over():
        return {
            "best_move": None,
            "game_over": True,
            "fen": req.fen,
        }

    with _open_engine() as engine:
        result = engine.play(board, chess.engine.Limit(depth=req.depth))

    return {
        "best_move": result.move.uci() if result.move else None,
        "fen": req.fen,
        "depth": req.depth,
    }


@app.post("/check-move")
def check_move(req: CheckMoveRequest) -> Dict[str, Any]:
    try:
        board = chess.Board(req.fen)
    except ValueError:
        raise HTTPException(status_code=400, detail="FEN không hợp lệ")

    try:
        player_move = chess.Move.from_uci(req.player_move)
    except ValueError:
        raise HTTPException(status_code=400, detail="player_move phải ở dạng UCI, ví dụ e2e4 hoặc e7e8q")

    if player_move not in board.legal_moves:
        return {
            "correct": False,
            "legal": False,
            "player_move": req.player_move,
            "best_move": None,
            "reason": "Nước đi không hợp lệ trong thế cờ hiện tại",
        }

    with _open_engine() as engine:
        result = engine.play(board, chess.engine.Limit(depth=req.depth))

    best = result.move.uci() if result.move else None

    return {
        "correct": req.player_move == best,
        "legal": True,
        "player_move": req.player_move,
        "best_move": best,
        "depth": req.depth,
    }


def fetch_lichess_games(username: str, max_games: int) -> List[Dict[str, Any]]:
    url = f"{LICHESS_BASE}/api/games/user/{username}"
    params = {
        "max": max_games,
        "moves": "true",
        "opening": "true",
        "clocks": "true",
        "analysed": "false",
    }
    headers = {
        "Accept": "application/x-ndjson",
        "User-Agent": USER_AGENT,
    }
    resp = requests.get(url, params=params, headers=headers, timeout=30)
    if resp.status_code == 404:
        raise HTTPException(status_code=404, detail=f"Không tìm thấy tài khoản Lichess: {username}")
    if resp.status_code == 429:
        raise HTTPException(status_code=429, detail="Lichess đang giới hạn tần suất gọi API. Thử lại sau ít phút.")
    if not 200 <= resp.status_code < 300:
        raise HTTPException(status_code=resp.status_code, detail=f"Lichess trả lỗi {resp.status_code}")

    games: List[Dict[str, Any]] = []
    for line in resp.text.splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            games.append(json.loads(line))
        except json.JSONDecodeError:
            continue
    return games


def player_color(game: Dict[str, Any], username: str) -> Optional[chess.Color]:
    target = username.lower()
    players = game.get("players") or {}
    for color_name, color_value in (("white", chess.WHITE), ("black", chess.BLACK)):
        user = (players.get(color_name) or {}).get("user") or {}
        name = (user.get("name") or user.get("id") or "").lower()
        if name == target:
            return color_value
    return None


def outcome_for_student(game: Dict[str, Any], color: chess.Color) -> str:
    winner = game.get("winner")
    if not winner:
        return "draw"
    if winner == "white" and color == chess.WHITE:
        return "win"
    if winner == "black" and color == chess.BLACK:
        return "win"
    return "loss"


def phase_from_fullmove(fullmove_number: int) -> str:
    if fullmove_number <= 10:
        return "opening"
    if fullmove_number <= 30:
        return "middlegame"
    return "endgame"


def score_cp(info: Dict[str, Any], color: chess.Color) -> float:
    score = info["score"].pov(color)
    cp = score.score(mate_score=10000)
    if cp is None:
        return 0.0
    return max(min(cp / 100.0, 100.0), -100.0)


def classify_drop(drop: float) -> Optional[str]:
    if drop >= 3.0:
        return "blunder"
    if drop >= 1.5:
        return "mistake"
    if drop >= 0.6:
        return "inaccuracy"
    return None


def parse_moves_san(board: chess.Board, moves_text: str) -> List[chess.Move]:
    moves: List[chess.Move] = []
    for token in (moves_text or "").split():
        token = token.strip()
        if not token:
            continue
        try:
            move = board.parse_san(token)
        except ValueError:
            try:
                move = chess.Move.from_uci(token)
                if move not in board.legal_moves:
                    break
            except ValueError:
                break
        moves.append(move)
        board.push(move)
    return moves


def analyze_game_with_engine(
    engine: chess.engine.SimpleEngine,
    game: Dict[str, Any],
    username: str,
    depth: int,
) -> Dict[str, Any]:
    color = player_color(game, username)
    if color is None:
        return {"skipped": True, "reason": "Không xác định được màu quân của học sinh"}

    moves_text = game.get("moves") or ""
    if not moves_text.strip():
        return {"skipped": True, "reason": "Ván không có dữ liệu nước đi"}

    parse_board = chess.Board()
    moves = parse_moves_san(parse_board, moves_text)
    board = chess.Board()
    issues: List[Dict[str, Any]] = []
    limit = chess.engine.Limit(depth=depth)

    for ply_index, move in enumerate(moves):
        is_student_move = board.turn == color
        fullmove = board.fullmove_number
        phase = phase_from_fullmove(fullmove)

        if is_student_move:
            try:
                before = engine.analyse(board, limit)
                before_score = score_cp(before, color)
            except Exception:
                before_score = 0.0

        try:
            san = board.san(move)
            board.push(move)
        except Exception:
            break

        if is_student_move:
            try:
                after = engine.analyse(board, limit)
                after_score = score_cp(after, color)
            except Exception:
                after_score = before_score

            drop = before_score - after_score
            issue_type = classify_drop(drop)
            if issue_type:
                issues.append({
                    "gameId": game.get("id"),
                    "moveNumber": fullmove,
                    "ply": ply_index + 1,
                    "playedMove": san,
                    "type": issue_type,
                    "phase": phase,
                    "evalBefore": round(before_score, 2),
                    "evalAfter": round(after_score, 2),
                    "drop": round(drop, 2),
                })

    opening = game.get("opening") or {}
    return {
        "id": game.get("id"),
        "url": f"https://lichess.org/{game.get('id')}" if game.get("id") else None,
        "perf": game.get("perf"),
        "rated": game.get("rated", False),
        "status": game.get("status"),
        "result": outcome_for_student(game, color),
        "studentColor": "white" if color == chess.WHITE else "black",
        "opening": opening.get("name"),
        "movesCount": len(moves),
        "issues": issues,
    }


def basic_game_summary(game: Dict[str, Any], username: str) -> Dict[str, Any]:
    color = player_color(game, username)
    opening = game.get("opening") or {}
    moves = (game.get("moves") or "").split()
    return {
        "id": game.get("id"),
        "url": f"https://lichess.org/{game.get('id')}" if game.get("id") else None,
        "perf": game.get("perf"),
        "rated": game.get("rated", False),
        "status": game.get("status"),
        "result": outcome_for_student(game, color) if color is not None else "unknown",
        "studentColor": "white" if color == chess.WHITE else "black" if color == chess.BLACK else "unknown",
        "opening": opening.get("name"),
        "movesCount": len(moves),
        "issues": [],
    }


def build_suggestion(engine_available: bool, summaries: List[Dict[str, Any]]) -> Tuple[str, Dict[str, Any]]:
    result_counter = Counter(s.get("result") for s in summaries)
    perf_counter = Counter(s.get("perf") for s in summaries if s.get("perf"))
    opening_losses = Counter(s.get("opening") for s in summaries if s.get("result") == "loss" and s.get("opening"))

    all_issues: List[Dict[str, Any]] = []
    for s in summaries:
        all_issues.extend(s.get("issues") or [])

    type_counter = Counter(i.get("type") for i in all_issues)
    phase_counter = Counter(i.get("phase") for i in all_issues)
    issue_by_phase_type: Dict[str, Counter] = defaultdict(Counter)
    for issue in all_issues:
        issue_by_phase_type[issue.get("phase")][issue.get("type")] += 1

    games_count = len(summaries)
    wins = result_counter.get("win", 0)
    losses = result_counter.get("loss", 0)
    draws = result_counter.get("draw", 0)
    win_rate = (wins / games_count * 100) if games_count else 0

    strengths: List[str] = []
    weaknesses: List[str] = []
    recommendations: List[str] = []

    if games_count == 0:
        return "Chưa có đủ dữ liệu ván đấu để phân tích.", {"games": 0}

    if win_rate >= 65:
        strengths.append("tỉ lệ thắng trong nhóm ván gần đây khá tốt")
    elif win_rate < 45:
        weaknesses.append("tỉ lệ thắng trong nhóm ván gần đây còn thấp")
        recommendations.append("giáo viên nên chọn 2-3 ván thua để học sinh tự phân tích lại nguyên nhân")

    if engine_available:
        blunders = type_counter.get("blunder", 0)
        mistakes = type_counter.get("mistake", 0)
        inaccuracies = type_counter.get("inaccuracy", 0)
        if blunders == 0 and mistakes <= 1:
            strengths.append("số lỗi nghiêm trọng theo Stockfish không nhiều")
        if blunders >= 2:
            weaknesses.append(f"có {blunders} blunder trong các ván được phân tích")
            recommendations.append("giảm tốc độ ra quyết định ở các vị trí phức tạp và luyện tính biến trước khi đi")
        if mistakes >= 3:
            weaknesses.append(f"có {mistakes} mistake, cho thấy cần củng cố khả năng đánh giá thế trận")
        if phase_counter.get("opening", 0) >= 2:
            weaknesses.append("lỗi xuất hiện khá sớm ở khai cuộc")
            recommendations.append("ôn lại nguyên tắc khai cuộc: phát triển quân, nhập thành, không đi một quân quá nhiều lần")
        if phase_counter.get("middlegame", 0) >= 2:
            weaknesses.append("nhiều lỗi rơi vào trung cuộc")
            recommendations.append("tăng bài tập chiến thuật về ghim quân, đòn đôi, quá tải quân phòng thủ và an toàn vua")
        if phase_counter.get("endgame", 0) >= 2:
            weaknesses.append("cần chú ý hơn ở giai đoạn tàn cuộc")
            recommendations.append("luyện các thế tàn cơ bản: vua tốt, xe tốt, chuyển hóa ưu thế")
        if inaccuracies >= 4:
            recommendations.append("duy trì thói quen kiểm tra nước ứng viên trước khi đi")
    else:
        weaknesses.append("backend chưa kết nối được Stockfish nên mới phân tích xu hướng kết quả, chưa chỉ ra lỗi nước đi cụ thể")
        recommendations.append("cấu hình STOCKFISH_PATH để bật phân tích nước đi chi tiết")

    if opening_losses:
        opening_name, count = opening_losses.most_common(1)[0]
        if count >= 2:
            weaknesses.append(f"thua lặp lại trong khai cuộc {opening_name}")
            recommendations.append(f"giáo viên nên ôn riêng biến khai cuộc {opening_name}")

    dominant_perf = perf_counter.most_common(1)[0][0] if perf_counter else None
    if dominant_perf in {"bullet", "blitz"}:
        recommendations.append("nên bổ sung thêm ván Rapid để rèn tư duy tính toán sâu thay vì chỉ chơi nhanh")

    if not strengths:
        strengths.append("học sinh đã có dữ liệu ván đấu đủ để giáo viên bắt đầu cá nhân hóa bài luyện")
    if not weaknesses:
        weaknesses.append("chưa thấy lỗi lặp lại quá rõ trong nhóm ván gần đây")
    if not recommendations:
        recommendations.append("tiếp tục duy trì luyện tập đều, kết hợp chơi ván có kiểm soát và phân tích sau ván")

    suggestion = (
        f"Dựa trên {games_count} ván gần nhất từ Lichess, học sinh thắng {wins}, thua {losses}, hòa {draws}, "
        f"tỉ lệ thắng khoảng {win_rate:.1f}%.\n\n"
        f"Điểm mạnh: {'; '.join(strengths)}.\n\n"
        f"Điểm cần lưu ý: {'; '.join(weaknesses)}.\n\n"
        f"Định hướng đề xuất: {'; '.join(recommendations)}."
    )

    stats = {
        "games": games_count,
        "wins": wins,
        "losses": losses,
        "draws": draws,
        "winRate": round(win_rate, 1),
        "issueTypes": dict(type_counter),
        "issuePhases": dict(phase_counter),
        "perfTypes": dict(perf_counter),
        "topLosingOpenings": dict(opening_losses.most_common(3)),
    }
    return suggestion, stats


@app.get("/health")
def health() -> Dict[str, Any]:
    path = stockfish_path()
    return {
        "status": "ok",
        "engineAvailable": path is not None,
        "stockfishPath": path,
    }


@app.get("/analyze/{username}")
def analyze_user(
    username: str,
    max_games: int = Query(default=5, ge=1, le=20),
    depth: int = Query(default=8, ge=4, le=15),
) -> Dict[str, Any]:
    clean_username = normalize_username(username)
    if not clean_username:
        raise HTTPException(status_code=400, detail="Username Lichess rỗng")

    games = fetch_lichess_games(clean_username, max_games=max_games)
    path = stockfish_path()
    engine_available = path is not None
    summaries: List[Dict[str, Any]] = []

    if engine_available:
        try:
            with chess.engine.SimpleEngine.popen_uci(path) as engine:
                for game in games:
                    try:
                        summary = analyze_game_with_engine(engine, game, clean_username, depth)
                        if not summary.get("skipped"):
                            summaries.append(summary)
                    except Exception as exc:
                        fallback = basic_game_summary(game, clean_username)
                        fallback["analysisError"] = str(exc)
                        summaries.append(fallback)
        except Exception as exc:
            engine_available = False
            summaries = [basic_game_summary(g, clean_username) for g in games]
            engine_error = str(exc)
        else:
            engine_error = None
    else:
        engine_error = "Không tìm thấy Stockfish. Cấu hình biến môi trường STOCKFISH_PATH hoặc thêm stockfish vào PATH."
        summaries = [basic_game_summary(g, clean_username) for g in games]

    suggestion, stats = build_suggestion(engine_available, summaries)
    issues = []
    for s in summaries:
        for issue in s.get("issues") or []:
            issue = dict(issue)
            issue["gameUrl"] = s.get("url")
            issue["opening"] = s.get("opening")
            issues.append(issue)

    issues.sort(key=lambda i: i.get("drop", 0), reverse=True)

    return {
        "username": clean_username,
        "engineAvailable": engine_available,
        "engineError": engine_error,
        "depth": depth,
        "gamesRequested": max_games,
        "gamesFetched": len(games),
        "gamesAnalyzed": len(summaries),
        "stats": stats,
        "suggestion": suggestion,
        "topIssues": issues[:10],
        "games": summaries,
    }
