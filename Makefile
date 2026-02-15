IMAGE_NAME ?= pg4ai
IMAGE_TAG ?= local
IMAGE_REF ?= $(IMAGE_NAME):$(IMAGE_TAG)
REGISTRY_IMAGE ?=
PLATFORMS ?= linux/amd64,linux/arm64

.PHONY: build-amd64 build-arm64 test-amd64 test-arm64 build-multiarch

build-amd64:
	docker buildx build --platform linux/amd64 --tag $(IMAGE_REF)-amd64 --load .

build-arm64:
	docker buildx build --platform linux/arm64 --tag $(IMAGE_REF)-arm64 --load .

test-amd64: build-amd64
	IMAGE_REF=$(IMAGE_REF)-amd64 EXPECT_ARCH=amd64 ./scripts/smoke-test.sh

test-arm64: build-arm64
	IMAGE_REF=$(IMAGE_REF)-arm64 EXPECT_ARCH=arm64 ./scripts/smoke-test.sh

build-multiarch:
	@if [ -z "$(REGISTRY_IMAGE)" ]; then \
		echo "REGISTRY_IMAGE must be set (example: ghcr.io/<owner>/<repo>)"; \
		exit 2; \
	fi
	docker buildx build \
		--platform $(PLATFORMS) \
		--tag $(REGISTRY_IMAGE):$(IMAGE_TAG) \
		--push \
		.
