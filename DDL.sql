-- ContentVault Database Schema (DDL)
-- Drift ORM을 통해 자동 생성되는 테이블들의 참조용 DDL

-- 콘텐츠 메인 테이블
CREATE TABLE IF NOT EXISTS contents (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    url TEXT NOT NULL UNIQUE,
    description TEXT,
    thumbnail_url TEXT,
    content_type TEXT NOT NULL, -- 'youtube', 'twitter', 'web', 'article'
    source_platform TEXT NOT NULL,
    author TEXT,
    published_at INTEGER, -- Unix timestamp
    content_text TEXT, -- 추출된 텍스트 콘텐츠
    metadata TEXT, -- JSON 형태의 추가 메타데이터
    is_favorite INTEGER NOT NULL DEFAULT 0,
    is_archived INTEGER NOT NULL DEFAULT 0,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
);

-- 태그 테이블
CREATE TABLE IF NOT EXISTS tags (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    color TEXT, -- 태그 색상 (hex code)
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
);

-- 콘텐츠-태그 연결 테이블 (다대다 관계)
CREATE TABLE IF NOT EXISTS content_tags (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    content_id TEXT NOT NULL,
    tag_id INTEGER NOT NULL,
    created_at INTEGER NOT NULL,
    FOREIGN KEY (content_id) REFERENCES contents (id) ON DELETE CASCADE,
    FOREIGN KEY (tag_id) REFERENCES tags (id) ON DELETE CASCADE,
    UNIQUE(content_id, tag_id)
);

-- 폴더/카테고리 테이블
CREATE TABLE IF NOT EXISTS folders (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    parent_id INTEGER, -- 하위 폴더 지원
    icon TEXT, -- 아이콘 이름
    color TEXT, -- 폴더 색상
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    FOREIGN KEY (parent_id) REFERENCES folders (id) ON DELETE CASCADE
);

-- 콘텐츠-폴더 연결 테이블
CREATE TABLE IF NOT EXISTS content_folders (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    content_id TEXT NOT NULL,
    folder_id INTEGER NOT NULL,
    created_at INTEGER NOT NULL,
    FOREIGN KEY (content_id) REFERENCES contents (id) ON DELETE CASCADE,
    FOREIGN KEY (folder_id) REFERENCES folders (id) ON DELETE CASCADE,
    UNIQUE(content_id, folder_id)
);

-- AI 분석 결과 테이블
CREATE TABLE IF NOT EXISTS ai_analysis (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    content_id TEXT NOT NULL,
    summary TEXT, -- AI 생성 요약
    keywords TEXT, -- JSON 배열 형태의 키워드
    sentiment TEXT, -- 감정 분석 결과
    category TEXT, -- AI 추천 카테고리
    relevance_score REAL, -- 관련성 점수
    analyzed_at INTEGER NOT NULL,
    FOREIGN KEY (content_id) REFERENCES contents (id) ON DELETE CASCADE
);

-- 검색 기록 테이블
CREATE TABLE IF NOT EXISTS search_history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    query TEXT NOT NULL,
    result_count INTEGER NOT NULL DEFAULT 0,
    searched_at INTEGER NOT NULL
);

-- 사용자 설정 테이블
CREATE TABLE IF NOT EXISTS user_settings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    key TEXT NOT NULL UNIQUE,
    value TEXT NOT NULL,
    updated_at INTEGER NOT NULL
);

-- 백업 메타데이터 테이블
CREATE TABLE IF NOT EXISTS backup_metadata (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    backup_name TEXT NOT NULL,
    backup_path TEXT,
    content_count INTEGER NOT NULL DEFAULT 0,
    file_size INTEGER NOT NULL DEFAULT 0,
    created_at INTEGER NOT NULL
);

-- 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_contents_created_at ON contents (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_contents_content_type ON contents (content_type);
CREATE INDEX IF NOT EXISTS idx_contents_is_favorite ON contents (is_favorite);
CREATE INDEX IF NOT EXISTS idx_contents_is_archived ON contents (is_archived);
CREATE INDEX IF NOT EXISTS idx_contents_title ON contents (title);
CREATE INDEX IF NOT EXISTS idx_content_tags_content_id ON content_tags (content_id);
CREATE INDEX IF NOT EXISTS idx_content_tags_tag_id ON content_tags (tag_id);
CREATE INDEX IF NOT EXISTS idx_content_folders_content_id ON content_folders (content_id);
CREATE INDEX IF NOT EXISTS idx_content_folders_folder_id ON content_folders (folder_id);
CREATE INDEX IF NOT EXISTS idx_ai_analysis_content_id ON ai_analysis (content_id);
CREATE INDEX IF NOT EXISTS idx_search_history_searched_at ON search_history (searched_at DESC);

-- 기본 데이터 삽입
INSERT OR IGNORE INTO folders (id, name, icon, color, created_at, updated_at) VALUES 
(1, '일반', 'folder', '#2196F3', strftime('%s', 'now'), strftime('%s', 'now')),
(2, '즐겨찾기', 'star', '#FF9800', strftime('%s', 'now'), strftime('%s', 'now')),
(3, '나중에 읽기', 'schedule', '#4CAF50', strftime('%s', 'now'), strftime('%s', 'now'));

INSERT OR IGNORE INTO tags (id, name, color, created_at, updated_at) VALUES 
(1, '기술', '#2196F3', strftime('%s', 'now'), strftime('%s', 'now')),
(2, '뉴스', '#F44336', strftime('%s', 'now'), strftime('%s', 'now')),
(3, '교육', '#4CAF50', strftime('%s', 'now'), strftime('%s', 'now')),
(4, '엔터테인먼트', '#9C27B0', strftime('%s', 'now'), strftime('%s', 'now'));

-- 버전 정보
INSERT OR IGNORE INTO user_settings (key, value, updated_at) VALUES 
('db_version', '1.0.0', strftime('%s', 'now')),
('app_theme', 'system', strftime('%s', 'now')),
('auto_backup', 'true', strftime('%s', 'now'));

-- DDL 히스토리
-- v1.0.0 (2024-01-XX): 초기 스키마 생성 