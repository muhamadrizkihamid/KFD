# KFD — Kimid Falacy Done
# Panduan Lengkap Framework
# Versi: 1.1 | Tanggal: 2026-04-23

---

## Daftar Isi

1. [Latar Belakang](#1-latar-belakang)
2. [Permasalahan yang Dipecahkan](#2-permasalahan-yang-dipecahkan)
3. [Inspirasi: AWS KIRO dan Adopsi Konsep](#3-inspirasi-aws-kiro-dan-adopsi-konsep)
4. [Filosofi Framework](#4-filosofi-framework)
5. [Arsitektur Agent Squad](#5-arsitektur-agent-squad)
6. [Sprint Auto-Detect Mode](#6-sprint-auto-detect-mode)
7. [Steering Files — Aturan Modular](#7-steering-files--aturan-modular)
8. [Persistent Context — Memori Antar Sesi](#8-persistent-context--memori-antar-sesi)
9. [Alur Sprint Lengkap](#9-alur-sprint-lengkap)
10. [Ketentuan Teknis](#10-ketentuan-teknis)
11. [Instalasi di Laptop Baru](#11-instalasi-di-laptop-baru)
12. [Setup di Project Baru](#12-setup-di-project-baru)
13. [Skalabilitas dan Multi-Project](#13-skalabilitas-dan-multi-project)

---

## 1. Latar Belakang

### Apa itu KFD?

**KFD (Kimid Falacy Done)** adalah framework sprint execution berbasis AI agent yang berjalan di atas Claude Code CLI. Framework ini mensimulasikan tim pengembang perangkat lunak lengkap — 7 agen dengan peran berbeda yang bekerja secara terkoordinasi untuk mengeksekusi sprint dari Jira issue sampai siap review oleh Product Owner.

KFD bisa diinstall sekali di laptop dan digunakan di project manapun, untuk tech stack apapun.

### Hubungan dengan NextTask

**NextTask** adalah repository riset tempat KFD dikembangkan dan diuji. NextTask berisi aplikasi manajemen sprint berbasis Next.js 14 yang digunakan sebagai guinea pig — tempat setiap iterasi framework diuji langsung di dunia nyata.

```
nexttask/                      ← repository riset (GitHub: muhamadrizkihamid/nexttask)
├── src/                       ← aplikasi NextTask (guinea pig)
├── agent-squad-framework/     ← distributable KFD package
│   ├── install.sh             ← installer
│   ├── commands/kfd/          ← /kfd:* commands
│   ├── agents/squad-*.md      ← 7 global agents
│   └── templates/             ← template library
└── AGENT_SQUAD_GUIDE.md       ← dokumen ini
```

Orang yang install KFD tidak perlu tahu tentang NextTask. Mereka hanya perlu `bash install.sh`.

### Evolusi Versi

| Versi | Perubahan Utama |
|-------|----------------|
| v1.0–v3.0 | Agent files dasar, alur sprint linear |
| v4.0 | Shared libraries (jira.sh, git-remote.sh) |
| v5.0 | Migrasi ke Jira sebagai issue tracker |
| v5.1 | Dukungan multi-remote (GitHub + GitLab) |
| v5.2 | Auto-detect sprint mode + steering files + persistent context |
| v5.2+ | Rebrand ke KFD, global install, project-agnostic |

---

## 2. Permasalahan yang Dipecahkan

### Masalah 1: AI Terlalu Generik

Ketika Claude Code diminta "bantu saya buat fitur login", ia langsung menulis kode tanpa membaca requirement dengan benar, tanpa mempertimbangkan security, tanpa memastikan spec disetujui, dan tanpa verifikasi bahwa kode berjalan.

**Solusi KFD:** Setiap agent hanya boleh melakukan satu peran. Architect tidak boleh menulis kode. Developer tidak boleh mulai tanpa spec. Tester tidak boleh approve tanpa Security CLEAR.

### Masalah 2: Tidak Ada Audit Trail

Tidak ada cara mengetahui siapa yang membuat keputusan apa, kapan selesai, dan mengapa pendekatan tertentu dipilih.

**Solusi KFD:** Setiap agent wajib posting komentar ke Jira issue. Semua keputusan, output, dan handoff tercatat — bisa di-review kapanpun.

### Masalah 3: Tidak Ada Governance

AI tanpa governance bisa deploy kode yang belum ditest, push ke repository tanpa review, dan mengklaim task selesai padahal PO belum approve.

**Solusi KFD:** Tidak ada push ke main tanpa Tester APPROVED. Tidak ada DONE tanpa PO klik sendiri di Jira. Hard rules yang tidak bisa dilanggar agent manapun.

### Masalah 4: Pipeline yang Kaku

Sprint selalu menggunakan 7 agent penuh meski scope-nya hanya bugfix kecil.

**Solusi KFD:** Sprint Auto-Detect Mode — Scrum Master membaca Jira issue dan mengaktifkan hanya agent yang dibutuhkan.

### Masalah 5: Tidak Bisa Pindah Project

Framework terikat ke satu project dengan config yang hardcoded.

**Solusi KFD:** Semua agent bersifat global dan project-agnostic. Config project disimpan di `.kfd/` dan `.env.local` di masing-masing project. Pindah project = buka folder project, `/kfd:sprint`.

---

## 3. Inspirasi: AWS KIRO dan Adopsi Konsep

### Apa itu AWS KIRO?

AWS KIRO (diluncurkan 2025) adalah agentic IDE dari Amazon — spec-first AI development tool. Generate requirements, design, dan task breakdown dari satu kalimat. Autonomous code generation dengan human checkpoints. Pakai Claude untuk reasoning, Nova untuk code generation.

### Perbandingan

| Aspek | KFD | AWS KIRO |
|-------|-----|----------|
| **Governance** | Eksplisit PO checkpoint — PO yang klik DONE | Lebih otonom, sedikit checkpoint |
| **Tim simulasi** | 7 peran berbeda dengan batasan tegas | Single-developer centric |
| **Security gate** | Aktif DUA kali: planning + inline review | Security sebagai hook/plugin |
| **Audit trail** | Semua aktivitas tercatat di Jira | Audit internal tool |
| **Issue tracker** | Jira sebagai source of truth | Spec internal KIRO |
| **Multi-remote** | GitHub + GitLab, dikontrol GIT_REMOTE | GitHub-centric |
| **Multi-project** | Install sekali, pakai di semua project | Per-workspace setup |
| **Tech stack** | Agnostic — detect otomatis saat init | Lebih fokus ke Node/JS ecosystem |
| **Vendor lock-in** | Claude Code CLI, tidak terikat IDE | Terikat ekosistem AWS |

### Yang Diadopsi dari KIRO ke KFD

**1. Spec sebagai First-Class Artifact** — File formal per sprint: prompt file, UI spec, tester checklist. Semua di-commit ke repo, terlihat di git history.

**2. Steering Files Pattern** — Rules modular per domain (product, tech, structure, security, testing) dibaca hanya oleh agent yang relevan.

**3. Persistent Context** — `active-sprint.md` dan `completed-sprints.md` diupdate setiap sprint untuk menjaga memori antar sesi.

**4. Multi-Mode Pipeline** — 7 sprint mode yang dipilih otomatis berdasarkan Jira issue — sama dengan konsep adaptive pipeline KIRO.

### Kesimpulan

KIRO adalah **produk** dengan fitur fixed. KFD adalah **process definition** — setiap kemampuan KIRO bisa diimplementasikan sebagai perilaku agent yang diaktifkan sesuai scope. KFD lebih kuat untuk konteks enterprise dengan governance ketat; KIRO lebih cepat untuk developer velocity tanpa formal governance.

---

## 4. Filosofi Framework

**1. Separation of Concerns** — Setiap agent satu peran. Batasan ini bukan keterbatasan — ini kekuatan. Agent yang fokus menghasilkan output yang lebih baik.

**2. Governance by Design** — Setiap sprint butuh PO sign-off. KFD tidak pernah mengklaim DONE — hanya READY FOR PO REVIEW.

**3. Transparency First** — Semua aktivitas agent tercatat di Jira. Tidak ada "AI hitam" yang bekerja di balik layar.

**4. Composability** — Pipeline bukan satu jalur kaku. Sprint mode dipilih berdasarkan scope. Agent yang tidak relevan dilewati.

**5. Project Agnostic** — Agent tidak tahu apa-apa tentang project secara hardcoded. Semua dibaca dari `.kfd/steering/` dan `.env.local` di project masing-masing.

---

## 5. Arsitektur Agent Squad

### Gambaran Global

```
~/.claude/                          ← Global (semua project)
├── commands/kfd/
│   ├── init.md                     ← /kfd:init
│   ├── sprint.md                   ← /kfd:sprint
│   └── status.md                   ← /kfd:status
├── agents/
│   ├── squad-scrum-master.md
│   ├── squad-architect.md
│   ├── squad-app-designer.md
│   ├── squad-backend-developer.md
│   ├── squad-frontend-developer.md
│   ├── squad-security-analyst.md
│   └── squad-tester.md
└── kfd/                            ← Template library
    ├── lib/
    ├── steering/
    └── process/

your-project/                       ← Per project (dibuat saat /kfd:init)
├── .kfd/
│   ├── lib/jira.sh
│   ├── lib/git-remote.sh
│   ├── steering/                   ← Diisi sesuai project saat init
│   ├── context/
│   ├── process/
│   ├── tasks/                      ← Diisi per sprint
│   ├── checklist/
│   └── design/
└── .env.local                      ← Tokens + config (tidak di-commit)
```

### Alur Pipeline (Full Mode)

```
                    SCRUM MASTER (start)
                           │
                           ▼ auto-detect sprint mode
                       ARCHITECT
                           │
               ┌───────────┴───────────┐
               ▼                       ▼
          APP DESIGNER          SECURITY ANALYST
          (UI spec)             (planning review)
               │
    ┌──────────┴──────────┐
    ▼                     ▼
BACKEND DEV          FRONTEND DEV
(parallel)           (parallel)
    └──────────┬──────────┘
               ▼
        SECURITY ANALYST
        (inline review)
               │
               ▼
            TESTER
               │
               ▼
     SCRUM MASTER (close)
     push → docker → jira → notify PO
```

### 7 Agent dan Perannya

| Agent | Peran | Tidak Boleh |
|-------|-------|-------------|
| Scrum Master | Fasilitator + intelligent router | Membuat keputusan teknis, menulis kode |
| Architect | Desain sistem + buat spec | Menulis production code, desain UI |
| App Designer | UX + UI spec | Menyentuh arsitektur, menulis kode |
| Backend Developer | Implementasi API + data layer | Mulai tanpa spec, skip test |
| Frontend Developer | Implementasi UI | Business logic di UI, ubah API contract |
| Security Analyst | Review planning + inline (2x aktif) | Menulis kode fix |
| Tester | Verifikasi final | Interpretasi spec sendiri, partial approve |

---

## 6. Sprint Auto-Detect Mode

Scrum Master membaca Jira issue dan otomatis memilih pipeline. PO cukup pasang label di Jira — tidak perlu konfigurasi manual.

### Hierarki Deteksi

```
Priority 1: Jira Label    ← sinyal paling eksplisit
Priority 2: Issue Type    ← Bug, Story, Task, Sub-task
Priority 3: Judul Issue   ← keyword "fix", "api", "audit"
Default   : full mode
```

### 7 Sprint Modes

| Label Jira | Mode | Pipeline | Gunakan Untuk |
|------------|------|----------|--------------|
| *(kosong)* | `full` | 7 agent semua | Fitur baru dengan UI + API + DB |
| `api-only` | `api_only` | Skip Designer + FE | Perubahan API saja |
| `frontend-only` | `frontend_only` | Skip BE | UI pakai API yang sudah ada |
| `bugfix` | `bugfix` | Skip Designer | Bug non-kritikal, butuh spec |
| `hotfix` | `hotfix` | Skip Arch + Designer | Bug kritikal, scope jelas |
| `design` | `design` | Arch + Designer saja | Sprint perencanaan, tidak push code |
| `audit` | `audit` | Security Analyst saja | Periodic security review |

### Close Behavior per Mode

| Mode | Push Code | Verify App | Migrate DB |
|------|-----------|-----------|-----------|
| full | Ya | Ya | Jika ada schema change |
| api_only | Ya | Ya | Jika ada schema change |
| frontend_only | Ya | Ya | Tidak |
| bugfix | Ya | Ya | Jika ada schema change |
| hotfix | Ya | Ya | Jika ada schema change |
| design | **Tidak** | **Tidak** | **Tidak** |
| audit | **Tidak** | **Tidak** | **Tidak** |

---

## 7. Steering Files — Aturan Modular

CLAUDE.md yang monolitik dipecah menjadi 5 file yang dibaca hanya oleh agent yang relevan.

| File | Dibaca Oleh | Isi |
|------|------------|-----|
| `product.md` | SM, Architect, Designer | Nama project, target user, app URL, Jira |
| `tech.md` | Architect, BE Dev, FE Dev | Tech stack, file paths, patterns |
| `structure.md` | Semua agent | Folder structure, git remotes, naming |
| `security.md` | Security, Architect, Developers | Security rules, severity levels |
| `testing.md` | BE Dev, FE Dev, Tester | 4 mandatory outputs, test conventions |

`product.md`, `tech.md`, dan `structure.md` diisi otomatis saat `/kfd:init` berdasarkan jawaban user dan auto-detection.

`security.md` dan `testing.md` adalah template statis yang bisa dikustomisasi per project setelah init.

---

## 8. Persistent Context — Memori Antar Sesi

### Masalah

Claude Code tidak punya memori antar sesi. Tanpa persistent context, agent bisa mengulang keputusan yang sudah dibuat, tidak tahu tech debt dari sprint lalu, atau tidak tahu sudah loop-back ke berapa.

### Solusi

Dua file di `.kfd/context/` yang diupdate setiap sprint:

**`active-sprint.md`** — diupdate Scrum Master saat sprint start dan close:
```
Issue Key    : PROJ-X
Title        : [judul issue]
Sprint Mode  : full
Started      : 2026-04-23
Status       : IN PROGRESS
Loop-back    : 0/3
```

**`completed-sprints.md`** — log semua sprint selesai + open tech debt:
```
### PROJ-X — [judul] — 2026-04-23
Mode    : full
Outcome : APPROVED
Notes   : [keputusan non-obvious yang dibuat]

Open Tech Debt:
- [issue] — LOW — sprint PROJ-X
```

Semua agent membaca `active-sprint.md` di awal sesi untuk restore context.

---

## 9. Alur Sprint Lengkap

### Trigger oleh Product Owner

1. Buat Jira issue dengan description lengkap dan acceptance criteria
2. (Opsional) Pasang label sesuai scope: `hotfix`, `api-only`, `bugfix`, dll
3. Pindahkan issue ke status **IN PLANNING**
4. Set `ISSUE_KEY=PROJ-X` di `.env.local` project
5. Buka project di Claude Code → jalankan `/kfd:sprint`

### Eksekusi (Full Mode)

```
[1] SCRUM MASTER
    ✓ Baca Jira issue
    ✓ Auto-detect sprint mode
    ✓ Update active-sprint.md
    ✓ Move board: IN PLANNING → In Progress
    ✓ Post SPRINT STARTED ke Jira (sertakan mode yang terdeteksi)
    → Handoff: Architect

[2] ARCHITECT
    ✓ Baca issue + context + steering/tech.md
    ✓ Buat .kfd/tasks/[ISSUE_KEY]-PROMPT.md
    ✓ Buat .kfd/checklist/[ISSUE_KEY]-TESTER.md
    ✓ Post DONE ke Jira
    → Handoff: App Designer + Security Analyst (paralel)

[3a] APP DESIGNER (paralel dengan 3b)
    ✓ Baca issue + prompt file + steering/product.md
    ✓ Buat .kfd/design/[ISSUE_KEY]-UI-SPEC.md
    ✓ Post DONE ke Jira
    → Handoff: Backend Dev + Frontend Dev (keduanya mulai)

[3b] SECURITY ANALYST — Planning Review (paralel dengan 3a)
    ✓ Baca prompt file + steering/security.md
    ✓ Identifikasi security concerns di desain
    ✓ Post PLANNING REVIEW ke Jira
    → (tidak ada handoff — developer mulai setelah App Designer DONE)

[4a] BACKEND DEVELOPER (paralel dengan 4b)
    ✓ Baca prompt file + steering/tech.md + steering/security.md
    ✓ Implementasi sesuai spec (path dari steering/tech.md)
    ✓ Tulis tests
    ✓ Jalankan 4 mandatory outputs
    ✓ Post 4 outputs ke Jira
    ✓ Post DONE ke Jira
    → Handoff: Security Analyst

[4b] FRONTEND DEVELOPER (paralel dengan 4a)
    ✓ Baca UI spec + prompt file + steering/tech.md
    ✓ Mock API dulu, lalu integrate real API
    ✓ Handle semua states: loading, error, empty, success
    ✓ Jalankan 4 mandatory outputs
    ✓ Post 4 outputs ke Jira
    ✓ Post DONE ke Jira
    → Handoff: Security Analyst

[5] SECURITY ANALYST — Inline Review
    ✓ Review implementasi BE + FE
    ✓ Post CLEAR atau RISK ke Jira
    → Jika CLEAR: Handoff Tester
    → Jika HIGH RISK: Sprint BLOCKED, handoff Developer untuk fix

[6] TESTER
    ✓ Verifikasi 4 prerequisites (4 outputs dari tiap developer + Security verdict)
    ✓ Cek setiap item di .kfd/checklist/[ISSUE_KEY]-TESTER.md
    ✓ Post APPROVED atau REJECTED ke Jira
    → Jika APPROVED: Handoff Scrum Master
    → Jika REJECTED: Handoff Scrum Master untuk routing

[7] SCRUM MASTER — Sprint Close
    ✓ git add (src/ + .kfd/tasks/ + .kfd/checklist/ + .kfd/design/)
    ✓ git commit + push (sesuai GIT_REMOTE)
    ✓ docker-compose down → up --build → curl $APP_URL (harus 200)
    ✓ prisma migrate deploy (jika ada schema change)
    ✓ Update active-sprint.md + completed-sprints.md
    ✓ Move board: In Progress → IN REVIEW
    ✓ Post SPRINT REPORT ke Jira
    ✓ Notify PO: "Buka $APP_URL untuk review"
```

### Loop-Back Routing

| Temuan | Route Ke |
|--------|----------|
| Kode implementasi salah | Developer (BE/FE) |
| Vulnerability di desain | Architect |
| Spec ambigu | Architect |
| UI tidak sesuai spec | Frontend Developer |
| UI spec tidak jelas | App Designer |
| Scope berubah | PO eskalasi |
| Loop-back > 2x masalah sama | Architect (root cause) |
| Loop-back > 3x total | PO eskalasi — sprint halt |

---

## 10. Ketentuan Teknis

### Hard Rules

1. **IN PLANNING** = KFD mulai sprint. **BACKLOG** = tidak bertindak
2. Security HIGH = sprint BLOCKED
3. Tidak ada 4 mandatory outputs = Tester tidak bisa review
4. Tidak ada Security CLEAR = Tester tidak bisa approve
5. Tidak ada Tester APPROVED = tidak ada push ke main
6. App harus running sebelum board pindah ke IN REVIEW
7. Scrum Master → IN REVIEW. Product Owner → DONE
8. Setiap agent wajib post Jira comment saat selesai
9. Commit harus include src/ + .kfd/tasks/ + .kfd/checklist/ + .kfd/design/

### Format Komentar Jira

```
[NAMA AGENT] — [STATUS] — [YYYY-MM-DD]

Task    : [apa yang dikerjakan]
Output  : [file yang dibuat/dimodifikasi]
Verdict : [DONE / CLEAR / RISK / APPROVED / REJECTED]

Details:
- [detail]

Handoff : [agent berikutnya — apa yang harus dilakukan]
```

### Shared Libraries

**`.kfd/lib/jira.sh`**

| Fungsi | Kegunaan |
|--------|----------|
| `jira_read_issue KEY` | Print field utama issue |
| `jira_get_labels KEY` | Labels sebagai string |
| `jira_get_type KEY` | Issue type name |
| `jira_get_title KEY` | Judul issue |
| `jira_post_comment KEY TEXT` | Post komentar ke issue |
| `jira_transition KEY STATUS` | Pindah status board |

**`.kfd/lib/git-remote.sh`**

| Fungsi | Kegunaan |
|--------|----------|
| `git_push_all` | Push sesuai GIT_REMOTE setting |
| `git_remote_label` | Label human-readable remote aktif |

### Environment Variables

| Variable | Wajib | Keterangan |
|----------|-------|-----------|
| `ISSUE_KEY` | Ya | Set per sprint oleh PO |
| `PROJECT_NAME` | Ya | Nama project |
| `APP_URL` | Ya | URL app lokal (e.g. http://localhost:3000) |
| `GIT_DEFAULT_BRANCH` | Ya | Default: main |
| `GIT_REMOTE` | Ya | `origin` / `gitlab` / `both` |
| `GITHUB_TOKEN` | Ya | Personal Access Token GitHub |
| `GITHUB_OWNER` | Ya | GitHub username/org |
| `GITHUB_REPO` | Ya | Nama repo |
| `GITLAB_TOKEN` | Jika pakai GitLab | Personal Access Token GitLab |
| `GITLAB_URL` | Jika pakai GitLab | URL GitLab (e.g. https://gitlab.company.com) |
| `GITLAB_PROJECT` | Jika pakai GitLab | Path project di GitLab |
| `JIRA_URL` | Ya | URL Jira Cloud |
| `JIRA_TOKEN` | Ya | API Token Jira |
| `JIRA_EMAIL` | Ya | Email akun Jira |
| `JIRA_PROJECT` | Ya | Project key (e.g. PROJ) |
| `DOCKER_APP_SERVICE` | Jika pakai Docker | Nama service di docker-compose |
| `DATABASE_URL` | Jika ada DB | Connection string database |

---

## 11. Instalasi di Laptop Baru

Instalasi dilakukan **sekali per laptop**. Setelah install, perintah `/kfd:*` aktif di semua project di laptop tersebut.

### Prasyarat

Pastikan semua sudah terinstall:

```bash
# Cek Claude Code
claude --version

# Cek dependencies
python3 --version
jq --version
curl --version
git --version
```

Jika ada yang belum ada:
- **Claude Code**: https://claude.ai/code
- **jq**: `brew install jq` (Mac) / `apt install jq` (Linux) / `winget install jqlang.jq` (Windows)
- **python3**: https://python.org

### Langkah Install

**Step 1 — Clone repository**

```bash
git clone https://github.com/muhamadrizkihamid/nexttask
```

**Step 2 — Masuk ke folder installer**

```bash
cd nexttask/agent-squad-framework
```

**Step 3 — Jalankan installer**

```bash
bash install.sh
```

Tampilan yang muncul:

```
╔════════════════════════════════════════════════════╗
║                                                    ║
║    ██  ██  ████    ████                            ║
║    ██ ██   ██      ██  ██                          ║
║    ████    ████    ██  ██                          ║
║    ██ ██   ██      ██  ██                          ║
║    ██  ██  ██      ████                            ║
║                                                    ║
║    Kimid Falacy Done  —  v1.0                      ║
║    AI-powered sprint framework for Claude Code     ║
╚════════════════════════════════════════════════════╝

  ✓ Claude Code found
  ✓ Commands: /kfd:init  /kfd:sprint  /kfd:status
  ✓ 7 agents installed
  ✓ Template library installed

KFD installed successfully!
```

**Step 4 — Verifikasi**

Buka Claude Code di folder manapun, ketik:
```
/kfd:init
```

Jika muncul prompt setup, instalasi berhasil.

### Yang Diinstall

```
~/.claude/
├── commands/kfd/
│   ├── init.md       ← /kfd:init
│   ├── sprint.md     ← /kfd:sprint
│   └── status.md     ← /kfd:status
├── agents/
│   ├── squad-scrum-master.md
│   ├── squad-architect.md
│   ├── squad-app-designer.md
│   ├── squad-backend-developer.md
│   ├── squad-frontend-developer.md
│   ├── squad-security-analyst.md
│   └── squad-tester.md
└── kfd/
    ├── lib/jira.sh
    ├── lib/git-remote.sh
    ├── steering/security.md
    ├── steering/testing.md
    └── process/ (2 files)
```

### Update KFD

Jika ada versi baru:

```bash
cd nexttask
git pull
cd agent-squad-framework
bash install.sh
# Pilih "y" saat ditanya reinstall
```

---

## 12. Setup di Project Baru

Setup dilakukan **sekali per project**. Setelah setup, jalankan `/kfd:sprint` kapanpun ada sprint baru.

### Prasyarat

- KFD sudah terinstall di laptop (lihat bagian 11)
- Project sudah punya git remote (GitHub dan/atau GitLab)
- Jira project sudah ada dan bisa diakses
- Sudah punya Jira API Token, GitHub Token, GitLab Token

### Cara Mendapatkan Token

**Jira API Token:**
1. Buka https://id.atlassian.com/manage-profile/security/api-tokens
2. Klik "Create API token"
3. Copy tokennya

**GitHub Personal Access Token:**
1. GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Generate new token → centang scope `repo`
3. Copy tokennya

**GitLab Personal Access Token:**
1. GitLab → User Settings → Access Tokens
2. Buat token dengan scope: `api`, `write_repository`
3. Copy tokennya

### Langkah Setup Project

**Step 1 — Buka project di Claude Code**

```bash
cd /path/to/your-project
claude  # buka Claude Code di project ini
```

**Step 2 — Jalankan init**

```
/kfd:init
```

KFD akan:
1. Auto-detect tech stack dari file di project (`package.json`, `pom.xml`, `requirements.txt`, dll)
2. Tanya beberapa pertanyaan:

```
KFD — Kimid Falacy Done
Project Setup

Terdeteksi: Node.js project (Next.js 14)

Konfirmasi atau isi:
1. Nama project: [terdeteksi: nexttask]
2. App URL: http://localhost:3000
3. Git branch: main
4. Tech stack: [terdeteksi dari codebase]
5. Struktur folder: [terdeteksi dari codebase]
6. Docker service name: (kosong jika tidak pakai Docker)
7. GitHub repo: owner/repo
8. GitLab repo: group/project (kosong jika tidak pakai)
9. GitLab URL: https://gitlab.company.com (kosong jika tidak pakai)
10. Jira project key: PROJ
11. Jira URL: https://company.atlassian.net
12. Jira email: email@company.com
```

**Step 3 — Isi file `.env.local` yang dihasilkan**

Init menghasilkan `.env.local` dengan template:

```bash
# KFD — hanya isi 3 bagian ini:
GITHUB_TOKEN=your_github_token_here    ← isi token GitHub
GITLAB_TOKEN=your_gitlab_token_here    ← isi token GitLab (hapus baris ini jika tidak pakai)
JIRA_TOKEN=your_jira_token_here        ← isi token Jira
```

Semua field lain sudah otomatis terisi dari jawaban di Step 2.

**Step 4 — Verifikasi setup**

```
/kfd:status
```

Harus tampil info project tanpa error.

### Yang Dibuat di Project

```
your-project/
├── .kfd/
│   ├── lib/
│   │   ├── jira.sh           ← helper Jira
│   │   └── git-remote.sh     ← helper Git push
│   ├── steering/
│   │   ├── product.md        ← diisi saat init (nama project, URL, Jira)
│   │   ├── tech.md           ← diisi saat init (tech stack, file paths)
│   │   ├── structure.md      ← diisi saat init (folder structure, remotes)
│   │   ├── security.md       ← template statis (kustomisasi jika perlu)
│   │   └── testing.md        ← template statis (update perintah test-nya)
│   ├── context/
│   │   ├── active-sprint.md  ← status sprint aktif
│   │   └── completed-sprints.md ← history sprint + tech debt
│   ├── process/
│   │   ├── SPRINT_MODES.md
│   │   └── SCRUM_MASTER_PROCESS.md
│   ├── tasks/                ← diisi per sprint (Architect)
│   ├── checklist/            ← diisi per sprint (Architect)
│   └── design/               ← diisi per sprint (App Designer)
└── .env.local                ← tokens + config (tidak di-commit)
```

### Mulai Sprint

Setelah setup selesai, alur per sprint:

**1. Product Owner buat issue di Jira**

Isi description lengkap + acceptance criteria. Pasang label jika scope spesifik:
- Tidak pasang label → KFD pakai full pipeline
- `bugfix` → skip App Designer
- `hotfix` → langsung ke developer
- `api-only` → skip UI agents
- dll

**2. Product Owner pindahkan ke IN PLANNING**

**3. Set ISSUE_KEY di `.env.local`**

```bash
ISSUE_KEY=PROJ-42
```

**4. Jalankan sprint**

```
/kfd:sprint
```

KFD akan otomatis detect mode, aktifkan agent yang tepat, eksekusi sampai selesai, push code, verify app, dan notify PO untuk review.

**5. Product Owner review di `$APP_URL`**

Jika puas → pindahkan board ke DONE di Jira.
Jika ada yang kurang → pindahkan ke BLOCKED dan tambahkan komentar.

---

## 13. Skalabilitas dan Multi-Project

### Cara Pindah Project

KFD bersifat global — agent tidak tahu apa-apa secara hardcoded tentang project tertentu. Semua dibaca dari `.kfd/` dan `.env.local` di folder project aktif.

Untuk pindah project: cukup buka folder project lain di Claude Code.

```bash
# Project A
cd /projects/backend-service
claude
# → /kfd:sprint  (pakai config .kfd/ project A)

# Project B
cd /projects/mobile-api
claude
# → /kfd:sprint  (pakai config .kfd/ project B)
```

### Sprint Mode per Jenis Project

| Jenis Project | Mode Default Paling Sering |
|--------------|--------------------------|
| Fullstack app baru | `full` |
| Backend microservice | `api_only` |
| Frontend SPA | `frontend_only` |
| Legacy project (maintenance) | `bugfix`, `hotfix` |
| Sprint perencanaan | `design` |
| Periodic review | `audit` |

### Menambah Sprint Mode Baru

Jika ada kebutuhan pipeline baru:
1. Tambahkan entry di `.kfd/process/SPRINT_MODES.md`
2. Tambahkan deteksi label di `squad-scrum-master.md`
3. Tidak ada perubahan di agent lain

---

## Ringkasan

KFD adalah jawaban atas pertanyaan: **bagaimana mengelola development sprint dengan AI secara terstruktur, accountable, dan bisa dipakai di project manapun?**

```
Install sekali     →  bash install.sh
Setup per project  →  /kfd:init
Mulai sprint       →  /kfd:sprint
Cek status         →  /kfd:status
```

7 agent. 7 peran. 1 pipeline yang adaptatif. Governance yang tidak bisa dilanggar.

---

*KFD — Kimid Falacy Done*
*Dikembangkan di NextTask Research Project*
*Versi framework: 5.2+ | Dokumen: 1.1 | 2026-04-23*
