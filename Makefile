.PHONY: help install test lint \
        bench bench-task bench-generic bench-gcp bench-complextasks \
        docker-build docker-bench

# ── Configuration ────────────────────────────────────────────────────────────
PYTHON        ?= python3
TASK_FILE     ?= tasks/generic/crashloop-fix/task.yaml
TASKS_DIR     ?= tasks/generic
RESULTS_DIR   ?= results
IMAGE_TAG     ?= devops-bench:latest

# ── Help ─────────────────────────────────────────────────────────────────────
help:
	@echo ""
	@echo "DevOps Bench — Kubernetes agent benchmark toolkit"
	@echo ""
	@echo "Usage: make <target> [VAR=value ...]"
	@echo ""
	@echo "Setup:"
	@echo "  install           Install Python dependencies"
	@echo "  test              Run unit tests"
	@echo "  lint              Check code style"
	@echo ""
	@echo "Benchmarking (requires env vars — see .env.example):"
	@echo "  bench-task        Run a single task  (TASK_FILE=<path/to/task.yaml>)"
	@echo "  bench-generic     Run all generic (platform-agnostic) tasks"
	@echo "  bench-gcp         Run all GCP/GKE-specific tasks"
	@echo "  bench-complextasks Run multi-step complex tasks"
	@echo "  bench             Run the full task suite (generic + GCP + complex)"
	@echo ""
	@echo "Docker:"
	@echo "  docker-build      Build the evaluation container image"
	@echo "  docker-bench      Run bench-generic inside the container"
	@echo ""
	@echo "Variables (override on the command line):"
	@echo "  TASK_FILE         Path to a single task.yaml   [$(TASK_FILE)]"
	@echo "  TASKS_DIR         Directory of tasks to run    [$(TASKS_DIR)]"
	@echo "  IMAGE_TAG         Docker image tag             [$(IMAGE_TAG)]"
	@echo ""

# ── Setup ────────────────────────────────────────────────────────────────────
install:
	pip install -r requirements.txt

test:
	pytest tests/ -v

lint:
	@command -v flake8 >/dev/null 2>&1 && flake8 pkg/ deployers/ tests/ --max-line-length=120 || \
	  echo "flake8 not installed — skipping lint"

# ── Benchmark targets ────────────────────────────────────────────────────────

# Single task — set TASK_FILE=tasks/generic/<name>/task.yaml
bench-task:
	@echo "Running single task: $(TASK_FILE)"
	$(PYTHON) pkg/evaluator/evaluate.py $(TASK_FILE)

# All generic (platform-agnostic) tasks
bench-generic:
	@echo "Running generic task suite..."
	$(PYTHON) pkg/evaluator/evaluate.py tasks/generic/

# All GCP-specific tasks
bench-gcp:
	@echo "Running GCP task suite..."
	$(PYTHON) pkg/evaluator/evaluate.py tasks/gcp/

# Multi-step complex tasks
bench-complextasks:
	@echo "Running complex task suite..."
	$(PYTHON) pkg/evaluator/evaluate.py complextasks/

# Full suite
bench: bench-generic bench-gcp bench-complextasks

# ── Docker targets ───────────────────────────────────────────────────────────
docker-build:
	docker build -t $(IMAGE_TAG) .

docker-bench:
	docker run --rm \
	  -v ~/.config/gcloud:/root/.config/gcloud \
	  -v $(PWD)/$(RESULTS_DIR):/app/$(RESULTS_DIR) \
	  --env-file .env \
	  $(IMAGE_TAG) tasks/generic/
