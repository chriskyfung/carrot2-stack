# Carrot2 Stack Docker Build Makefile
# Provides streamlined targets for building and pushing multi-architecture images

.PHONY: help build build-cjk build-local build-cjk-local all clean

# ==============================================================================
# Configuration
# ==============================================================================

# Image registry and repository
REGISTRY ?= chriskyfung
IMAGE_NAME ?= carrot2
IMAGE_REPO = $(REGISTRY)/$(IMAGE_NAME)

# Version configuration
# Override with: make build VERSION=4.8.6
VERSION ?= 4.8.5

# Base image tag components
BASE_TAG = $(VERSION)
CJK_TAG = $(VERSION)-cjk

# Platform targets (multi-architecture)
PLATFORMS ?= linux/amd64,linux/arm64

# Build context
CONTEXT ?= .

# ==============================================================================
# Image Tags
# ==============================================================================

# Standard variant tags
TAG_LATEST = $(IMAGE_REPO):latest
TAG_VERSION = $(IMAGE_REPO):$(BASE_TAG)
TAG_VERSION_FULL = $(IMAGE_REPO):$(BASE_TAG)-noble

# CJK variant tags
TAG_CJK_LATEST = $(IMAGE_REPO):latest-cjk
TAG_CJK_VERSION = $(IMAGE_REPO):$(CJK_TAG)
TAG_CJK_VERSION_FULL = $(IMAGE_REPO):$(CJK_TAG)-noble

# ==============================================================================
# Build Arguments
# ==============================================================================

# Common build arguments
BUILD_ARGS_COMMON = --platform $(PLATFORMS)

# CJK-specific build arguments
BUILD_ARGS_CJK = $(BUILD_ARGS_COMMON) --build-arg CARROT2_VARIANT=cjk

# ==============================================================================
# Docker BuildX Flags
# ==============================================================================

# Default to push; set PUSH_FLAG=--load for local builds
PUSH_FLAG ?= --push

# ==============================================================================
# Targets
# ==============================================================================

## help: Display this help message
help:
	@echo "Carrot2 Stack Docker Build"
	@echo "=========================="
	@echo ""
	@echo "Usage: make [target] [options]"
	@echo ""
	@echo "Targets:"
	@echo "  build        Build and push standard variant (amd64 + arm64)"
	@echo "  build-cjk    Build and push CJK variant (amd64 + arm64)"
	@echo "  build-local  Build standard variant for local architecture only"
	@echo "  build-cjk-local  Build CJK variant for local architecture only"
	@echo "  all          Build and push both standard and CJK variants"
	@echo "  help         Display this help message"
	@echo ""
	@echo "Options:"
	@echo "  VERSION=x.x.x    Set Carrot2 version (default: $(VERSION))"
	@echo "  REGISTRY=name    Set image registry (default: $(REGISTRY))"
	@echo "  PUSH_FLAG=flag   Set push flag (--push or --load) (default: $(PUSH_FLAG))"
	@echo ""
	@echo "Examples:"
	@echo "  make build                    # Push standard:$(VERSION), standard:$(VERSION)-noble, standard:latest"
	@echo "  make build-cjk                # Push CJK:$(VERSION)-cjk, CJK:$(VERSION)-cjk-noble, CJK:latest-cjk"
	@echo "  make all                      # Push both variants"
	@echo "  make build-local              # Build standard for local testing"
	@echo "  make build VERSION=4.8.6      # Build with different version"

## build: Build and push standard variant (multi-architecture)
build:
	@echo "Building standard variant: $(IMAGE_REPO):$(VERSION)..."
	docker buildx build \
		$(BUILD_ARGS_COMMON) \
		-t $(TAG_VERSION_FULL) \
		-t $(TAG_VERSION) \
		-t $(TAG_LATEST) \
		$(PUSH_FLAG) \
		$(CONTEXT)

## build-cjk: Build and push CJK variant (multi-architecture)
build-cjk:
	@echo "Building CJK variant: $(IMAGE_REPO):$(VERSION)-cjk..."
	docker buildx build \
		$(BUILD_ARGS_CJK) \
		-t $(TAG_CJK_VERSION_FULL) \
		-t $(TAG_CJK_VERSION) \
		-t $(TAG_CJK_LATEST) \
		$(PUSH_FLAG) \
		$(CONTEXT)

## build-local: Build standard variant for local architecture (faster for testing)
build-local:
	@echo "Building standard variant (local architecture)..."
	docker buildx build \
		--platform local \
		-t $(TAG_VERSION)-local \
		--load \
		$(CONTEXT)

## build-cjk-local: Build CJK variant for local architecture (faster for testing)
build-cjk-local:
	@echo "Building CJK variant (local architecture)..."
	docker buildx build \
		--platform local \
		--build-arg CARROT2_VARIANT=cjk \
		-t $(TAG_CJK_VERSION)-local \
		--load \
		$(CONTEXT)

## all: Build and push both standard and CJK variants
all: build build-cjk
	@echo ""
	@echo "Build complete!"
	@echo "Standard tags: $(TAG_VERSION_FULL), $(TAG_VERSION), $(TAG_LATEST)"
	@echo "CJK tags:      $(TAG_CJK_VERSION_FULL), $(TAG_CJK_VERSION), $(TAG_CJK_LATEST)"

## clean: Remove local buildx builder cache (use with caution)
clean:
	@echo "Cleaning buildx cache..."
	@docker buildx prune -f || true
