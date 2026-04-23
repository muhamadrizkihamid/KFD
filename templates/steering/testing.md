# STEERING: Testing Conventions
# Template — customize per project after init
# Read by: Backend Developer, Frontend Developer, Tester

---

## 4 MANDATORY OUTPUTS

Every developer must run these and post results as Jira comment before posting DONE.
Customize the exact commands for your project tech stack.

### Node.js / TypeScript projects
```bash
find . -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" \) | grep -v node_modules | grep -v .git | head -20
npm run build
npm test -- --watchAll=false
npx tsc --noEmit
```

### Python projects
```bash
find . -type f -name "*.py" | grep -v __pycache__ | grep -v .git | head -20
python -m build 2>/dev/null || pip install -e . --dry-run
pytest
flake8 . --count --max-line-length=127
```

### Java / Spring Boot projects
```bash
find . -type f -name "*.java" | grep -v .git | head -20
./mvnw compile -q || gradle compileJava -q
./mvnw test || gradle test
./mvnw verify -q || gradle check -q
```

### PHP / Laravel projects
```bash
find . -type f -name "*.php" | grep -v vendor | grep -v .git | head -20
composer install --dry-run
php artisan test
./vendor/bin/phpstan analyse
```

### Go projects
```bash
find . -type f -name "*.go" | grep -v .git | head -20
go build ./...
go test ./...
go vet ./...
```

---

## GENERAL TESTING PRINCIPLES

- Every public function must have a unit test (happy path + at least one edge case)
- Test file location should mirror source file location
- All tests must pass before posting DONE
- Build must be clean (zero errors) before posting DONE

---

NOTE: Update this file after `/agent-squad:init` with exact commands for your project.
The project's CI/CD pipeline commands are the source of truth.
